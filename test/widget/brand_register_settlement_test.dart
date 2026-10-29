// Widget test phan may chu vua bo sung o Web_BE: dang ky ho so thuong hieu (T9), chi tiet phieu
// doi soat + chi tra kem ngay (T13), mo lai chien dich da ket thuc (T7), ly do tu choi (T8).
// Chay bang: flutter test
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/routes.dart';

import '../helpers/fake_backend.dart';

const _brandId = 'brand-1';
const _settlementId = 'settle-1';

Map<String, dynamic> _settlement({String status = 'PENDING'}) => {
      'id': _settlementId,
      'brandId': _brandId,
      'brandName': 'Highlands Coffee',
      'periodStart': '2026-09-01T00:00:00.000Z',
      'periodEnd': '2026-09-30T23:59:59.000Z',
      'voucherCount': 2,
      'grossRevenue': 100000,
      'commissionAmount': 12000,
      'payableAmount': 88000,
      'status': status,
    };

Map<String, dynamic> _campaign({required String id, required String status, String title = 'Combo trua'}) => {
      'id': id,
      'brandId': _brandId,
      'title': title,
      'voucherType': 'PREPAID',
      'salePrice': 40000,
      'faceValue': 50000,
      'totalQuantity': 10,
      'soldQuantity': 2,
      'reservedQuantity': 0,
      'limitPerUser': 5,
      'saleStartAt': '2026-09-01T00:00:00.000Z',
      'saleEndAt': '2026-09-30T00:00:00.000Z',
      'voucherExpireAt': '2026-10-20T00:00:00.000Z',
      'status': status,
    };

void main() {
  late FakeBackend backend;

  setUp(() => backend = FakeBackend());

  // ---- T9: FR-BRAND-01/02 - dang ky cong khai -----------------------------
  group('FR-BRAND-01 - dang ky ho so thuong hieu', () {
    Future<void> start(WidgetTester tester) async {
      useDesktopSize(tester);
      final (app, _) = await buildTestApp(backend);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await openRoute(tester, AppRoutes.registerBrand);
    }

    Future<void> fill(WidgetTester tester, {String email = 'chu@banhmi.vn', String name = 'Banh Mi Sai Gon'}) async {
      await tester.enterText(find.byKey(const Key('register-owner-email')), email);
      await tester.enterText(find.byKey(const Key('register-owner-name')), 'Tran Thi B');
      await tester.enterText(find.byKey(const Key('register-brand-name')), name);
    }

    testWidgets('man dang nhap co loi vao dang ky danh cho doanh nghiep', (tester) async {
      useDesktopSize(tester);
      final (app, _) = await buildTestApp(backend);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const Key('login-register-brand')));
      expect(find.text('Đăng ký bán voucher'), findsOneWidget);
    });

    testWidgets('gui ho so hop le: goi POST /brands/register va hien huong dan kiem tra email', (tester) async {
      backend.on('POST', '/brands/register', (_) => {
            'brandId': _brandId,
            'status': 'PENDING',
            'message': 'Đã nhận hồ sơ thương hiệu. Vui lòng kiểm tra email để đặt mật khẩu.',
          });
      await start(tester);
      await fill(tester);
      await tapVisible(tester, find.byKey(const Key('register-submit')));

      expect(backend.called('POST', '/brands/register'), isTrue);
      final body = backend.bodyOf('POST', '/brands/register');
      expect(body['ownerEmail'], 'chu@banhmi.vn');
      expect(body['name'], 'Banh Mi Sai Gon');
      // Truong de trong khong duoc gui len thanh chuoi rong
      expect(body.containsKey('ownerPhone'), isFalse);
      expect(body.containsKey('bankInfo'), isFalse);

      expect(find.byKey(const Key('register-success')), findsOneWidget);
      expect(find.textContaining('kiểm tra email'), findsOneWidget);
    });

    testWidgets('thieu email / ten thuong hieu thi chan ngay tren form, khong goi API', (tester) async {
      await start(tester);
      await tapVisible(tester, find.byKey(const Key('register-submit')));

      expect(backend.called('POST', '/brands/register'), isFalse);
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập tên thương hiệu'), findsOneWidget);
    });

    testWidgets('may chu tu choi (email da co ho so) thi hien nguyen van ly do', (tester) async {
      backend.on('POST', '/brands/register',
          (_) => FakeBackend.error(400, 'Email này đã đăng ký hồ sơ thương hiệu. Vui lòng đăng nhập để xem trạng thái duyệt.'));
      await start(tester);
      await fill(tester);
      await tapVisible(tester, find.byKey(const Key('register-submit')));

      expect(find.byKey(const Key('register-success')), findsNothing);
      expect(find.textContaining('đã đăng ký hồ sơ thương hiệu'), findsOneWidget);
    });
  });

  // ---- T13: FR-SETTLE-07/08 - chi tiet phieu va chi tra -------------------
  group('FR-SETTLE-07/08 - phieu doi soat', () {
    Future<void> startAdmin(WidgetTester tester, {String status = 'PENDING'}) async {
      useDesktopSize(tester);
      backend.on('GET', '/admin/settlements', (_) => [_settlement(status: status)]);
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.admin);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await openRoute(tester, AppRoutes.adminSettlements);
    }

    testWidgets('bam vao phieu mo man chi tiet, moi dong mot voucher kem ty le da chot (BR-09)', (tester) async {
      backend.on('GET', '/settlements/$_settlementId', (_) => {
            'settlement': _settlement(),
            'items': [
              {'id': 'l1', 'voucherItemId': 'abcdef1234', 'orderId': 'o1', 'amount': 50000, 'commissionRate': 0.1, 'commissionAmount': 5000},
              // Dong thu hai co ty le khac: don cu chot truoc khi san doi ty le
              {'id': 'l2', 'voucherItemId': 'bbbbbb2222', 'orderId': 'o2', 'amount': 50000, 'commissionRate': 0.14, 'commissionAmount': 7000},
            ],
          });
      await startAdmin(tester);
      await tapVisible(tester, find.textContaining('Highlands Coffee'));

      expect(find.text('Chi tiết phiếu đối soát'), findsOneWidget);
      expect(find.byKey(const Key('settlement-lines')), findsOneWidget);
      expect(find.text('2 voucher trong kỳ'), findsOneWidget);
      // Hai ty le khac nhau trong cung mot phieu - day la ly do phai hien theo tung dong
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('14%'), findsOneWidget);
      // Ma voucher rut gon 8 ky tu dau cho vua cot
      expect(find.text('abcdef12'), findsOneWidget);
    });

    testWidgets('danh dau chi tra: bat buoc ma giao dich, gui kem ngay chuyen (FR-SETTLE-07)', (tester) async {
      backend.on('PATCH', '/admin/settlements/$_settlementId/mark-paid', (_) => _settlement(status: 'PAID'));
      await startAdmin(tester);
      await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Đánh dấu đã chi trả'));

      // Bam xac nhan khi chua nhap ma giao dich: bao loi, khong goi API
      await tapVisible(tester, find.byKey(const Key('mark-paid-submit')));
      expect(find.text('Vui lòng nhập mã giao dịch ngân hàng'), findsOneWidget);
      expect(backend.called('PATCH', '/admin/settlements/$_settlementId/mark-paid'), isFalse);

      await tester.enterText(find.byKey(const Key('mark-paid-ref')), 'FT26102900123');
      await tapVisible(tester, find.byKey(const Key('mark-paid-submit')));

      final body = backend.bodyOf('PATCH', '/admin/settlements/$_settlementId/mark-paid');
      expect(body['bankTxnRef'], 'FT26102900123');
      // Ngay chuyen mac dinh la hom nay, luon duoc gui len - may chu bat buoc truong nay
      expect(body['paidAt'], isA<String>());
      expect(DateTime.parse(body['paidAt'] as String).isAfter(DateTime.utc(2026)), isTrue);
    });

    testWidgets('thuong hieu mo duoc chi tiet phieu cua minh tu portal', (tester) async {
      useDesktopSize(tester);
      backend.on('GET', '/brands/me', (_) => [
            {'id': _brandId, 'name': 'Highlands Coffee', 'status': 'APPROVED'},
          ]);
      backend.on('GET', '/brands/$_brandId/stores', (_) => [
            {'id': 's1', 'brandId': _brandId, 'name': 'Q1 Le Loi', 'address': '1 Le Loi', 'status': true},
          ]);
      backend.on('GET', '/brands/$_brandId/settlements', (_) => [_settlement()]);
      backend.on('GET', '/settlements/$_settlementId', (_) => {'settlement': _settlement(), 'items': []});
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.brandOwner);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await openRoute(tester, AppRoutes.brandSettlements);

      await tapVisible(tester, find.textContaining('Kỳ '));
      expect(find.text('Chi tiết phiếu đối soát'), findsOneWidget);
      expect(find.text('Phiếu này chưa có dòng nào.'), findsOneWidget);
    });
  });

  // ---- T7: FR-CAMP-15 - mo lai chien dich da ket thuc ---------------------
  group('FR-CAMP-15 - mo lai chien dich da ket thuc', () {
    Future<void> startBrand(WidgetTester tester, List<Map<String, dynamic>> campaigns) async {
      useDesktopSize(tester);
      backend.on('GET', '/brands/me', (_) => [
            {'id': _brandId, 'name': 'Highlands Coffee', 'status': 'APPROVED'},
          ]);
      backend.on('GET', '/brands/$_brandId/stores', (_) => [
            {'id': 's1', 'brandId': _brandId, 'name': 'Q1 Le Loi', 'address': '1 Le Loi', 'status': true},
          ]);
      backend.on('GET', '/campaigns/brand/$_brandId', (_) => campaigns);
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.brandOwner);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await openRoute(tester, AppRoutes.brandCampaigns);
    }

    testWidgets('chien dich ENDED co nut "Mo lai", xac nhan thi goi PATCH reopen', (tester) async {
      backend.on('PATCH', '/campaigns/c-ended/reopen', (_) => _campaign(id: 'c-ended', status: 'DRAFT'));
      await startBrand(tester, [_campaign(id: 'c-ended', status: 'ENDED')]);

      expect(find.byKey(const Key('campaign-reopen')), findsOneWidget);
      await tapVisible(tester, find.byKey(const Key('campaign-reopen')));
      // Hop thoai noi ro mo lai KHONG dua thang len ban, phai gui duyet lai
      expect(find.textContaining('gửi duyệt lần nữa'), findsOneWidget);
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Mở lại'));

      expect(backend.called('PATCH', '/campaigns/c-ended/reopen'), isTrue);
    });

    testWidgets('chien dich dang ban khong co nut "Mo lai"', (tester) async {
      await startBrand(tester, [_campaign(id: 'c-pub', status: 'PUBLISHED')]);
      expect(find.byKey(const Key('campaign-reopen')), findsNothing);
    });
  });

  // ---- T8: UC-04 luong 3a - ly do tu choi --------------------------------
  group('UC-04 - tu choi chien dich bat buoc ly do du y nghia', () {
    testWidgets('ly do qua ngan bi chan ngay tren hop thoai, khop nguong cua may chu', (tester) async {
      useDesktopSize(tester);
      backend.on('GET', '/admin/pending/campaigns', (_) => [_campaign(id: 'c-pending', status: 'PENDING')]);
      backend.on('PATCH', '/campaigns/c-pending/reject', (_) => _campaign(id: 'c-pending', status: 'DRAFT'));
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.admin);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await openRoute(tester, AppRoutes.adminCampaigns);

      await tapVisible(tester, find.widgetWithText(OutlinedButton, 'Từ chối'));
      await tester.enterText(find.widgetWithText(TextFormField, 'Lý do từ chối'), 'ko duyet');
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Từ chối'));

      expect(find.text('Lý do cần ít nhất 10 ký tự'), findsOneWidget);
      expect(backend.called('PATCH', '/campaigns/c-pending/reject'), isFalse);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Lý do từ chối'),
        'Hạn sử dụng quá sát ngày kết thúc bán, vui lòng giãn thêm.',
      );
      await tapVisible(tester, find.widgetWithText(FilledButton, 'Từ chối'));

      expect(backend.bodyOf('PATCH', '/campaigns/c-pending/reject')['reason'],
          'Hạn sử dụng quá sát ngày kết thúc bán, vui lòng giãn thêm.');
    });
  });
}
