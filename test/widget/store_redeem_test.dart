import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/routes.dart';
import 'package:voucher_platform_web/utils/format.dart';
import 'package:voucher_platform_web/widgets/qr_scanner_view.dart';

import '../helpers/fake_backend.dart';

Map<String, dynamic> store(String id) => {
  'id': id,
  'brandId': 'b1',
  'name': 'Chi nhánh $id',
  'address': 'Q1',
  'status': true,
};

// Chuoi QR dinh dang v1 con han (client chi kiem dinh dang + han, chu ky do may chu kiem)
String validQr() =>
    'v1.0123456789abcdef0123456789abcdef.${DateTime.now().add(const Duration(minutes: 1)).millisecondsSinceEpoch}.c2lnbmF0dXJl_-';

// Ket qua thanh cong theo hop dong moi cua POST /redeem
Map<String, dynamic> redeemOk({String method = 'OTP', int? billAmount}) => {
  'message': 'Xác nhận sử dụng thành công.',
  'redemptionLogId': 'l1',
  'voucherItemId': 'v1',
  'voucherCode': 'HL-7Q2K',
  'redeemedAt': '2026-10-12T03:00:00.000Z',
  'method': method,
  'billAmount': billAmount,
  'billEditableUntil': '2026-10-12T03:10:00.000Z',
  'campaign': {'id': 'c1', 'title': 'Giảm 50k Highlands', 'voucherType': 'PREPAID', 'faceValue': 100000},
};

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    backend.on('POST', '/auth/select-store', (_) => {'activeStoreId': 'B'});
    backend.on('GET', '/redeem/my-stores', (_) => [store('A'), store('B')]);
    backend.on('GET', '/redeem/history/today', (_) => []);
  });

  // Dang nhap nhan vien -> chon chi nhanh B (gan vao phien) -> sang man xac nhan (tab Quet QR)
  Future<void> openRedeem(WidgetTester tester) async {
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.storeStaff);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Chọn chi nhánh làm việc'), findsOneWidget);
    await tester.tap(find.text('Chi nhánh B'));
    await tester.pumpAndSettle();
    // FR-AUTH-12: chon chi nhanh goi POST /auth/select-store truoc khi redeem
    expect(backend.bodyOf('POST', '/auth/select-store'), {'storeId': 'B'});
    expect(find.text('Xác nhận sử dụng voucher'), findsOneWidget);
  }

  Future<void> openOtpTab(WidgetTester tester) async {
    await openRedeem(tester);
    await tester.tap(find.text('Nhập OTP'));
    await tester.pumpAndSettle();
  }

  Future<void> submitOtp(WidgetTester tester, String otp) async {
    await tester.enterText(find.byKey(const Key('redeem-otp')), otp);
    await tapVisible(tester, find.byKey(const Key('redeem-otp-submit')));
  }

  // Gia lap camera doc duoc ma: bat camera roi goi callback cua QrScannerView
  Future<void> scanQr(WidgetTester tester, String raw) async {
    if (find.byType(QrScannerView).evaluate().isEmpty) {
      await tapVisible(tester, find.text('Bật camera'));
    }
    tester.widget<QrScannerView>(find.byType(QrScannerView)).onDetect(raw);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'chua chon chi nhanh ma mo man xac nhan thi yeu cau chon truoc (FR-AUTH-12)',
    (tester) async {
      useDesktopSize(tester);
      final (app, _) = await buildTestApp(
        backend,
        loggedInAs: Roles.storeStaff,
      );
      await tester.pumpWidget(app);
      await openRoute(tester, AppRoutes.storeRedeem);
      expect(find.text('Hãy chọn chi nhánh làm việc trước.'), findsOneWidget);
    },
  );

  testWidgets('OTP sai dinh dang bao loi tai cho, khong goi API', (
    tester,
  ) async {
    await openOtpTab(tester);
    await tester.enterText(find.byKey(const Key('redeem-otp')), '12a4');
    await tester.tap(find.byKey(const Key('redeem-otp-submit')));
    await tester.pumpAndSettle();
    expect(find.text('Mã OTP gồm 6 chữ số'), findsOneWidget);
    expect(backend.called('POST', '/redeem'), isFalse);
  });

  testWidgets(
    'OTP hop le: gui otpCode kem chi nhanh dang lam, hien HOP LE mau xanh kem ten chien dich (NFR-USA-03)',
    (tester) async {
      backend.on('POST', '/redeem', (_) => redeemOk(billAmount: 150000));
      await openOtpTab(tester);

      await tester.enterText(find.byKey(const Key('redeem-bill')), '150.000');
      await submitOtp(tester, '123456');

      expect(backend.bodyOf('POST', '/redeem'), {
        'storeId': 'B',
        'otpCode': '123456',
        'billAmount': 150000,
      });
      expect(find.byKey(const Key('redeem-success')), findsOneWidget);
      expect(find.text('HỢP LỆ'), findsOneWidget);
      expect(find.text('Giảm 50k Highlands'), findsOneWidget);
      expect(find.text('Mã voucher: HL-7Q2K'), findsOneWidget);
      expect(find.textContaining('Hóa đơn: 150.000'), findsOneWidget);
      expect(
        find.textContaining('10:00'),
        findsOneWidget,
        reason: '03:00 UTC hien thi 10:00 gio Viet Nam',
      );

      await tapVisible(tester, find.byKey(const Key('redeem-next')));
      expect(find.byKey(const Key('redeem-success')), findsNothing);
    },
  );

  testWidgets(
    'quet QR: gui NGUYEN chuoi qrPayload (khong con nonce), thanh cong hien ten chien dich',
    (tester) async {
      backend.on('POST', '/redeem', (_) => redeemOk(method: 'QR'));
      await openRedeem(tester);
      final qr = validQr();

      await scanQr(tester, qr);

      final body = backend.bodyOf('POST', '/redeem');
      expect(body, {'storeId': 'B', 'qrPayload': qr});
      expect(body.containsKey('nonce'), isFalse);
      expect(find.byKey(const Key('redeem-success')), findsOneWidget);
      expect(find.text('Giảm 50k Highlands'), findsOneWidget);
      expect(find.textContaining('Quét QR'), findsWidgets);
    },
  );

  testWidgets('QR sai dinh dang (dinh dang cu) bao MA KHONG HOP LE, khong goi API', (tester) async {
    await openRedeem(tester);
    await scanQr(tester, 'item-1.abc123.1700000000000.sig');
    expect(find.text('MÃ KHÔNG HỢP LỆ'), findsOneWidget);
    expect(backend.called('POST', '/redeem'), isFalse);
  });

  testWidgets(
    'may chu tu choi (loi khong co reason): hien KHONG HOP LE kem nguyen nhan (FR-REDEEM-07)',
    (tester) async {
      backend.on(
        'POST',
        '/redeem',
        (_) => FakeBackend.error(
          400,
          'Voucher không được áp dụng tại chi nhánh này.',
        ),
      );
      await openOtpTab(tester);
      await submitOtp(tester, '654321');

      expect(find.byKey(const Key('redeem-error')), findsOneWidget);
      expect(find.text('KHÔNG HỢP LỆ'), findsOneWidget);
      expect(
        find.text('Voucher không được áp dụng tại chi nhánh này.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('VOUCHER_USED: hien DA SU DUNG kem gio va chi nhanh da dung', (tester) async {
    backend.on(
      'POST',
      '/redeem',
      (_) => FakeBackend.businessError(
        400,
        'VOUCHER_USED',
        'Voucher đã được sử dụng.',
        details: {'usedAt': '2026-10-12T03:00:00.000Z', 'storeId': 'q3', 'storeName': 'Chi nhánh Q3'},
      ),
    );
    await openOtpTab(tester);
    await submitOtp(tester, '123456');

    expect(find.byKey(const Key('redeem-error')), findsOneWidget);
    expect(find.text('ĐÃ SỬ DỤNG'), findsOneWidget);
    expect(find.text('Đã dùng lúc 10:00 12/10/2026 tại Chi nhánh Q3'), findsOneWidget);
  });

  testWidgets('WRONG_STORE: hien SAI CHI NHANH kem danh sach chi nhanh ap dung', (tester) async {
    backend.on(
      'POST',
      '/redeem',
      (_) => FakeBackend.businessError(
        400,
        'WRONG_STORE',
        'Voucher không áp dụng tại chi nhánh này.',
        details: {
          'stores': [
            {'id': 's3', 'name': 'Q3 Võ Văn Tần', 'address': '2 Võ Văn Tần'},
            {'id': 's7', 'name': 'Q7 Crescent', 'address': '5 Nguyễn Lương Bằng'},
          ],
        },
      ),
    );
    await openOtpTab(tester);
    await submitOtp(tester, '123456');

    expect(find.text('SAI CHI NHÁNH'), findsOneWidget);
    expect(find.text('Áp dụng tại:'), findsOneWidget);
    expect(find.text('• Q3 Võ Văn Tần — 2 Võ Văn Tần'), findsOneWidget);
    expect(find.text('• Q7 Crescent — 5 Nguyễn Lương Bằng'), findsOneWidget);
  });

  testWidgets('cac ly do khac: tieu de ngan theo reason', (tester) async {
    final cases = {
      'VOUCHER_EXPIRED': 'VOUCHER HẾT HẠN',
      'TOKEN_EXPIRED': 'MÃ ĐÃ HẾT HẠN',
      'TOKEN_REVOKED': 'MÃ KHÔNG HỢP LỆ',
      'TOKEN_USED': 'MÃ KHÔNG HỢP LỆ',
      'VOUCHER_REFUND_PENDING': 'ĐANG CHỜ HOÀN TIỀN',
      'VOUCHER_REFUNDED': 'ĐÃ HOÀN TIỀN',
      'OTP_INVALID': 'SAI MÃ OTP',
    };
    var reason = '';
    backend.on('POST', '/redeem', (_) => FakeBackend.businessError(400, reason, 'Thông điệp $reason'));
    await openOtpTab(tester);
    for (final entry in cases.entries) {
      reason = entry.key;
      await submitOtp(tester, '123456');
      expect(find.text(entry.value), findsOneWidget, reason: entry.key);
      if (entry.key != 'TOKEN_EXPIRED') {
        expect(find.text('Thông điệp ${entry.key}'), findsOneWidget, reason: entry.key);
      }
      await tapVisible(tester, find.byKey(const Key('redeem-next')));
      await tester.tap(find.text('Nhập OTP'));
      await tester.pumpAndSettle();
    }
  });

  testWidgets(
    'OTP_LOCKED: khoa o nhap OTP den lockedUntil, van quet QR duoc (FR-REDEEM-12)',
    (tester) async {
      final lockedUntil = DateTime.now().toUtc().add(const Duration(minutes: 15));
      backend.on('POST', '/redeem', (request) {
        return request.body.contains('qrPayload')
            ? redeemOk(method: 'QR')
            : FakeBackend.businessError(
                429,
                'OTP_LOCKED',
                'Nhập sai OTP quá nhiều lần.',
                details: {'lockedUntil': lockedUntil.toIso8601String()},
              );
      });
      await openOtpTab(tester);
      await submitOtp(tester, '000000');

      expect(find.byKey(const Key('redeem-error')), findsNothing, reason: 'khong phai ket qua cua voucher');
      expect(find.byKey(const Key('redeem-otp-locked')), findsOneWidget);
      expect(
        find.text('Ô nhập OTP bị khóa đến ${formatTime(lockedUntil)}, hãy quét mã QR'),
        findsOneWidget,
      );
      expect(find.textContaining('Mở khóa sau'), findsOneWidget);
      expect(tester.widget<TextFormField>(find.byKey(const Key('redeem-otp'))).enabled, isFalse);
      expect(tester.widget<FilledButton>(find.byKey(const Key('redeem-otp-submit'))).onPressed, isNull);

      final posts = backend.requests.where((r) => r.method == 'POST' && r.url.path == '/api/redeem').length;
      await tapVisible(tester, find.text('Chuyển sang quét QR'));
      final qr = validQr();
      await scanQr(tester, qr);
      expect(
        backend.requests.where((r) => r.method == 'POST' && r.url.path == '/api/redeem').length,
        posts + 1,
      );
      expect(backend.bodyOf('POST', '/redeem'), {'storeId': 'B', 'qrPayload': qr});
      expect(find.byKey(const Key('redeem-success')), findsOneWidget);
    },
  );

  testWidgets(
    'BILL_REQUIRED: khong hien do, bao loi tai o hoa don, gui lai DUNG ma kem hoa don -> HOP LE (BR-03)',
    (tester) async {
      backend.on('POST', '/redeem', (request) {
        return request.body.contains('billAmount')
            ? redeemOk(method: 'QR', billAmount: 150000)
            : FakeBackend.businessError(
                400,
                'BILL_REQUIRED',
                'Voucher mệnh giá bắt buộc nhập giá trị hóa đơn (BR-03).',
                details: {'voucherType': 'PREPAID', 'faceValue': 100000},
              );
      });
      await openRedeem(tester);
      final qr = validQr();
      await scanQr(tester, qr);

      expect(find.byKey(const Key('redeem-error')), findsNothing);
      expect(find.byKey(const Key('redeem-bill-required')), findsOneWidget);
      expect(find.textContaining('bắt buộc nhập giá trị hóa đơn'), findsOneWidget);
      expect(find.textContaining('100.000'), findsOneWidget);
      final billInput = tester.widget<EditableText>(
        find.descendant(of: find.byKey(const Key('redeem-bill')), matching: find.byType(EditableText)),
      );
      expect(billInput.focusNode.hasFocus, isTrue, reason: 'dua con tro vao o hoa don');

      // Bo trong ma bam gui lai: van bao bat buoc, khong goi may chu
      await tapVisible(tester, find.byKey(const Key('redeem-resubmit')));
      expect(backend.requests.where((r) => r.url.path == '/api/redeem').length, 1);

      await tester.enterText(find.byKey(const Key('redeem-bill')), '150.000');
      await tapVisible(tester, find.byKey(const Key('redeem-resubmit')));

      expect(backend.bodyOf('POST', '/redeem'), {'storeId': 'B', 'qrPayload': qr, 'billAmount': 150000});
      expect(find.byKey(const Key('redeem-success')), findsOneWidget);
      expect(find.byKey(const Key('redeem-bill-required')), findsNothing);
    },
  );

  testWidgets('BILL_REQUIRED voi OTP: giu OTP da nhap, gui lai kem hoa don', (tester) async {
    backend.on('POST', '/redeem', (request) {
      return request.body.contains('billAmount')
          ? redeemOk(billAmount: 90000)
          : FakeBackend.businessError(400, 'BILL_REQUIRED', 'Thiếu hóa đơn.', details: {'voucherType': 'PREPAID', 'faceValue': 100000});
    });
    await openOtpTab(tester);
    await submitOtp(tester, '123456');
    expect(find.byKey(const Key('redeem-bill-required')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('redeem-bill')), '90000');
    await tapVisible(tester, find.byKey(const Key('redeem-resubmit')));
    expect(backend.bodyOf('POST', '/redeem'), {'storeId': 'B', 'otpCode': '123456', 'billAmount': 90000});
    expect(find.byKey(const Key('redeem-success')), findsOneWidget);
  });

  testWidgets('STORE_NOT_SELECTED: dua nhan vien ve man chon chi nhanh', (tester) async {
    backend.on(
      'POST',
      '/redeem',
      (_) => FakeBackend.businessError(400, 'STORE_NOT_SELECTED', 'Vui lòng chọn chi nhánh làm việc trong phiên.'),
    );
    await openOtpTab(tester);
    await submitOtp(tester, '123456');

    expect(find.text('Chọn chi nhánh làm việc'), findsOneWidget);
    expect(find.text('Vui lòng chọn chi nhánh làm việc trong phiên.'), findsOneWidget);
  });

  testWidgets('lich su trong ngay hien cac luot xac nhan (FR-REDEEM-10)', (
    tester,
  ) async {
    backend.on(
      'GET',
      '/redeem/history/today',
      (_) => [
        {
          'id': 'l1',
          'voucherItemId': 'v1',
          'voucherCode': 'HL-1',
          'campaignTitle': 'Giảm 50k Highlands',
          'voucherType': 'PREPAID',
          'storeId': 'A',
          'storeName': 'Chi nhánh A',
          'method': 'OTP',
          'redeemedAt': '2026-10-12T02:30:00Z',
          'billAmount': '90000',
          'billEditable': false,
        },
      ],
    );
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.storeStaff);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Lịch sử trong ngày'));
    await tester.pumpAndSettle();
    expect(find.text('1 lượt xác nhận'), findsOneWidget);
    expect(find.text('Giảm 50k Highlands'), findsOneWidget);
    expect(find.textContaining('Mã HL-1'), findsOneWidget);
    expect(find.textContaining('Phương thức OTP'), findsOneWidget);
    expect(find.textContaining('90.000'), findsOneWidget);
    expect(find.text('Sửa hóa đơn'), findsNothing, reason: 'qua 10 phut thi khong sua duoc');
  });

  testWidgets('lich su: chi luot con trong 10 phut moi co "Sua hoa don", PATCH dung URL / body (FR-REDEEM-08)', (
    tester,
  ) async {
    Map<String, dynamic> log(String id, {required bool editable, int? bill}) => {
      'id': id,
      'voucherItemId': 'v-$id',
      'voucherCode': 'CODE-$id',
      'campaignTitle': 'Chiến dịch $id',
      'storeId': 'A',
      'storeName': 'Chi nhánh A',
      'method': 'QR',
      'redeemedAt': '2026-10-12T02:30:00Z',
      'billAmount': bill,
      'billEditable': editable,
    };
    backend.on('GET', '/redeem/history/today', (_) => [log('l1', editable: true, bill: 90000), log('l2', editable: false)]);
    backend.on('PATCH', '/redeem/logs/l1/bill', (_) => log('l1', editable: true, bill: 120000));
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.storeStaff);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch sử trong ngày'));
    await tester.pumpAndSettle();

    expect(find.text('Sửa hóa đơn'), findsOneWidget);
    expect(find.byKey(const Key('edit-bill-l1')), findsOneWidget);
    expect(find.byKey(const Key('edit-bill-l2')), findsNothing);

    await tester.tap(find.byKey(const Key('edit-bill-l1')));
    await tester.pumpAndSettle();
    final field = find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField));
    expect(tester.widget<TextFormField>(field).controller?.text, '90000', reason: 'dien san gia tri cu');

    await tester.enterText(field, 'abc');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();
    expect(find.text('Vui lòng nhập giá trị hóa đơn hợp lệ'), findsOneWidget);
    expect(backend.called('PATCH', '/redeem/logs/l1/bill'), isFalse);

    await tester.enterText(field, '120.000');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();
    expect(backend.bodyOf('PATCH', '/redeem/logs/l1/bill'), {'billAmount': 120000});
    expect(find.textContaining('Hóa đơn 120.000'), findsOneWidget);
    expect(find.text('Đã cập nhật giá trị hóa đơn.'), findsOneWidget);
  });

  testWidgets('lich su: qua han sua hoa don (BILL_EDIT_EXPIRED) thi bao loi', (tester) async {
    var expired = false;
    backend.on('GET', '/redeem/history/today', (_) => [
      {
        'id': 'l1',
        'storeId': 'A',
        'method': 'QR',
        'redeemedAt': '2026-10-12T02:30:00Z',
        'billEditable': !expired,
      },
    ]);
    backend.on('PATCH', '/redeem/logs/l1/bill', (_) {
      expired = true;
      return FakeBackend.businessError(
        400,
        'BILL_EDIT_EXPIRED',
        'Chỉ sửa được giá trị hóa đơn trong 10 phút sau khi xác nhận.',
      );
    });
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.storeStaff);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lịch sử trong ngày'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sửa hóa đơn'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextFormField)), '50000');
    await tester.tap(find.widgetWithText(FilledButton, 'Lưu'));
    await tester.pumpAndSettle();

    expect(find.text('Chỉ sửa được giá trị hóa đơn trong 10 phút sau khi xác nhận.'), findsOneWidget);
    expect(find.text('Sửa hóa đơn'), findsNothing, reason: 'tai lai lich su, het han thi an nut');
  });

  testWidgets(
    'man dien thoai (375px): menu dang Drawer, ket qua hien ngay khong can cuon',
    (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      backend.on('GET', '/redeem/my-stores', (_) => [store('A')]);
      backend.on(
        'POST',
        '/redeem',
        (_) => FakeBackend.error(400, 'Ma da duoc su dung.'),
      );
      final (app, _) = await buildTestApp(
        backend,
        loggedInAs: Roles.storeStaff,
      );
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      // Chi duoc gan 1 chi nhanh: da tu chon, vao man xac nhan qua Drawer
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Xác nhận sử dụng'));
      await tester.pumpAndSettle();
      expect(
        find.text('Chi nhánh A'),
        findsOneWidget,
        reason: 'chip chi nhanh dang lam tren thanh tieu de',
      );

      await tester.tap(find.text('Nhập OTP'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('redeem-otp')), '123456');
      await tapVisible(tester, find.byKey(const Key('redeem-otp-submit')));

      final panel = find.byKey(const Key('redeem-error'));
      expect(panel, findsOneWidget);
      // Khung ket qua nam tron trong man hinh 812px (NFR-USA-03)
      final rect = tester.getRect(panel);
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(812));
    },
  );
}
