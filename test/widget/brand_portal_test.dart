import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/models/campaign.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/routes.dart';

import '../helpers/fake_backend.dart';

Map<String, dynamic> campaign(String id, String status) => {
      'id': id,
      'brandId': 'b1',
      'title': 'Chiến dịch $id',
      'voucherType': 'PREPAID',
      'salePrice': '50000',
      'faceValue': '100000',
      'totalQuantity': 100,
      'soldQuantity': 10,
      'reservedQuantity': 0,
      'limitPerUser': 5,
      'saleStartAt': '2026-10-01T00:00:00Z',
      'saleEndAt': '2026-10-31T00:00:00Z',
      'voucherExpireAt': '2026-11-30T00:00:00Z',
      'status': status,
    };

void main() {
  late FakeBackend backend;

  void stubBrand({String status = 'APPROVED'}) {
    backend.on('GET', '/brands/me', (_) => [
          {'id': 'b1', 'name': 'Highlands', 'status': status},
        ]);
    backend.on('GET', '/brands/b1/stores', (_) => [
          {'id': 's1', 'brandId': 'b1', 'name': 'Q1 Lê Lợi', 'address': '1 Lê Lợi', 'status': true},
        ]);
  }

  Future<void> start(WidgetTester tester) async {
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.brandOwner);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
  }

  setUp(() => backend = FakeBackend());

  testWidgets('chua co ho so thuong hieu thi huong dan dang ky (FR-BRAND-01)', (tester) async {
    backend.on('GET', '/brands/me', (_) => []);
    backend.on('POST', '/brands', (_) => {'id': 'b1', 'name': 'Highlands', 'status': 'PENDING'});
    await start(tester);

    expect(find.textContaining('Bạn chưa có hồ sơ thương hiệu'), findsOneWidget);
    await tester.tap(find.text('Đăng ký thương hiệu'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Tên thương hiệu *'), 'Highlands');
    await tester.tap(find.text('Gửi hồ sơ'));
    await tester.pumpAndSettle();

    expect(backend.bodyOf('POST', '/brands'), {'name': 'Highlands'});
    expect(find.text('Chờ duyệt'), findsOneWidget);
  });

  testWidgets('danh sach chien dich: nut theo trang thai, gui duyet goi API (FR-CAMP-06/08)', (tester) async {
    stubBrand();
    backend.on('GET', '/campaigns/brand/b1', (_) => [campaign('A', 'DRAFT'), campaign('B', 'PUBLISHED')]);
    backend.on('PATCH', '/campaigns/A/submit', (_) => campaign('A', 'PENDING'));
    await start(tester);

    expect(find.text('Chiến dịch A'), findsOneWidget);
    expect(find.text('Nháp'), findsOneWidget);
    expect(find.text('Đang bán'), findsOneWidget);
    expect(find.text('Sửa'), findsOneWidget);
    expect(find.text('Tạm dừng'), findsOneWidget);

    await tester.tap(find.text('Gửi duyệt').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Gửi duyệt').last);
    await tester.pumpAndSettle();
    expect(backend.called('PATCH', '/campaigns/A/submit'), isTrue);
  });

  testWidgets('thuong hieu chua duoc duyet thi khong gui duyet duoc (BR-26)', (tester) async {
    stubBrand(status: 'PENDING');
    backend.on('GET', '/campaigns/brand/b1', (_) => [campaign('A', 'DRAFT')]);
    await start(tester);

    expect(find.textContaining('BR-26'), findsOneWidget);
    final button = tester.widget<FilledButton>(find.ancestor(of: find.text('Gửi duyệt'), matching: find.byType(FilledButton)));
    expect(button.onPressed, isNull);
  });

  testWidgets('form tao moi bat buoc chon du 3 ngay truoc khi gui', (tester) async {
    stubBrand();
    backend.on('GET', '/campaigns/brand/b1', (_) => []);
    backend.on('POST', '/campaigns/brand/b1', (_) => campaign('N', 'DRAFT'));
    await start(tester);

    await tester.tap(find.text('Tạo chiến dịch'));
    await tester.pumpAndSettle();
    expect(find.text('Tạo chiến dịch mới'), findsOneWidget);

    await tapVisible(tester, find.byKey(const Key('campaign-save')));
    expect(find.textContaining('Vui lòng chọn đủ ngày'), findsOneWidget);
    expect(backend.called('POST', '/campaigns/brand/b1'), isFalse);
  });

  testWidgets('sua chien dich: DC-10 chan han dung qua som', (tester) async {
    stubBrand();
    backend.on('PATCH', '/campaigns/A', (_) => campaign('A', 'DRAFT'));
    final draft = VoucherCampaign.fromJson({
      ...campaign('A', 'DRAFT'),
      'soldQuantity': 0,
      'voucherExpireAt': '2026-11-05T00:00:00Z',
    });
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.brandOwner);
    await tester.pumpWidget(app);
    await openRoute(tester, AppRoutes.brandProfile);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pushNamed(AppRoutes.brandCampaignForm, arguments: draft);
    await tester.pumpAndSettle();

    expect(find.text('Sửa chiến dịch'), findsOneWidget);
    await tapVisible(tester, find.byKey(const Key('campaign-save')));
    expect(find.text('Hạn sử dụng phải sau ngày kết thúc bán ít nhất 10 ngày'), findsOneWidget);
    expect(backend.called('PATCH', '/campaigns/A'), isFalse);
  });

  testWidgets('sua chien dich hop le gui PATCH dung du lieu, khong kem storeIds', (tester) async {
    stubBrand();
    backend.on('GET', '/campaigns/brand/b1', (_) => []);
    backend.on('PATCH', '/campaigns/A', (_) => campaign('A', 'DRAFT'));
    final draft = VoucherCampaign.fromJson({...campaign('A', 'DRAFT'), 'soldQuantity': 0});
    await start(tester);
    final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
    navigator.pushNamed(AppRoutes.brandCampaignForm, arguments: draft);
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Tiêu đề *'), 'Giảm 50% cuối tuần');
    await tester.enterText(find.widgetWithText(TextFormField, 'Giá bán (VND) *'), '45.000');
    await tapVisible(tester, find.byKey(const Key('campaign-save')));

    final body = backend.bodyOf('PATCH', '/campaigns/A');
    expect(body['title'], 'Giảm 50% cuối tuần');
    expect(body['salePrice'], 45000);
    expect(body['faceValue'], 100000);
    expect(body.containsKey('storeIds'), isFalse);
    // Ngay giu nguyen theo gio Viet Nam: 01/10 00:00 (UTC+7) = 30/09 17:00 UTC
    expect(body['saleStartAt'], '2026-09-30T17:00:00.000Z');
    expect(find.text('Chiến dịch voucher'), findsOneWidget, reason: 'luu xong quay ve danh sach');
  });

  testWidgets('ma giam % bat buoc muc giam toi da, du thi gui dung truong FR-CAMP-12', (tester) async {
    stubBrand();
    backend.on('GET', '/campaigns/brand/b1', (_) => []);
    backend.on('PATCH', '/campaigns/D', (_) => campaign('D', 'DRAFT'));
    final draft = VoucherCampaign.fromJson({
      ...campaign('D', 'DRAFT'),
      'soldQuantity': 0,
      'voucherType': 'DISCOUNT',
      'discountType': 'PERCENT',
      'discountValue': '20',
    });
    await start(tester);
    tester.state<NavigatorState>(find.byType(Navigator).first).pushNamed(AppRoutes.brandCampaignForm, arguments: draft);
    await tester.pumpAndSettle();

    await tapVisible(tester, find.byKey(const Key('campaign-save')));
    expect(find.textContaining('mức giảm tối đa'), findsOneWidget);
    expect(backend.called('PATCH', '/campaigns/D'), isFalse);

    await tester.enterText(find.widgetWithText(TextFormField, 'Giảm tối đa (VND, bắt buộc khi giảm %)'), '15.000');
    await tapVisible(tester, find.byKey(const Key('campaign-save')));
    final body = backend.bodyOf('PATCH', '/campaigns/D');
    expect(body['voucherType'], 'DISCOUNT');
    expect(body['discountType'], 'PERCENT');
    expect(body['discountValue'], 20);
    expect(body['maxDiscount'], 15000);
  });

  testWidgets('them nhan vien gan vao chi nhanh (FR-BRAND-05)', (tester) async {
    stubBrand();
    backend.on('GET', '/campaigns/brand/b1', (_) => []);
    backend.on('GET', '/brands/b1/staff', (_) => []);
    backend.on('POST', '/brands/staff', (_) => {'id': 'as1'});
    await start(tester);

    await tester.tap(find.text('Nhân viên'));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có nhân viên nào.'), findsOneWidget);

    await tester.tap(find.text('Thêm nhân viên'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, 'Email nhân viên *'), 'nv1@highlands.vn');
    await tester.tap(find.widgetWithText(DropdownButtonFormField<String>, 'Chi nhánh *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Q1 Lê Lợi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(backend.bodyOf('POST', '/brands/staff'), {'email': 'nv1@highlands.vn', 'storeId': 's1'});
  });
}
