import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/routes.dart';

import '../helpers/fake_backend.dart';

Map<String, dynamic> store(String id) => {
  'id': id,
  'brandId': 'b1',
  'name': 'Chi nhánh $id',
  'address': 'Q1',
  'status': true,
};

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    backend.on('POST', '/auth/select-store', (_) => {'ok': true});
    backend.on('GET', '/redeem/my-stores', (_) => [store('A'), store('B')]);
    backend.on('GET', '/redeem/history/today', (_) => []);
  });

  // Dang nhap nhan vien -> chon chi nhanh B -> sang man xac nhan, tab OTP
  Future<void> openOtpTab(WidgetTester tester) async {
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.storeStaff);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    expect(find.text('Chọn chi nhánh làm việc'), findsOneWidget);
    await tester.tap(find.text('Chi nhánh B'));
    await tester.pumpAndSettle();
    expect(find.text('Xác nhận sử dụng voucher'), findsOneWidget);

    await tester.tap(find.text('Nhập OTP'));
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
    'OTP hop le: gui kem chi nhanh dang lam, hien ket qua HOP LE mau xanh (NFR-USA-03)',
    (tester) async {
      backend.on(
        'POST',
        '/redeem',
        (_) => {
          'message': 'Redeem thanh cong.',
          'voucherItemId': 'v1',
          'redeemedAt': '2026-10-12T03:00:00.000Z',
        },
      );
      await openOtpTab(tester);

      await tester.enterText(find.byKey(const Key('redeem-bill')), '150.000');
      await tester.enterText(find.byKey(const Key('redeem-otp')), '123456');
      await tester.tap(find.byKey(const Key('redeem-otp-submit')));
      await tester.pumpAndSettle();

      expect(backend.bodyOf('POST', '/redeem'), {
        'storeId': 'B',
        'otpCode': '123456',
        'billAmount': 150000,
      });
      expect(find.byKey(const Key('redeem-success')), findsOneWidget);
      expect(find.text('HỢP LỆ'), findsOneWidget);
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
    'may chu tu choi: hien KHONG HOP LE kem nguyen nhan (FR-REDEEM-07)',
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

      await tester.enterText(find.byKey(const Key('redeem-otp')), '654321');
      await tester.tap(find.byKey(const Key('redeem-otp-submit')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('redeem-error')), findsOneWidget);
      expect(find.text('KHÔNG HỢP LỆ'), findsOneWidget);
      expect(
        find.text('Voucher không được áp dụng tại chi nhánh này.'),
        findsOneWidget,
      );
    },
  );

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
          'storeId': 'A',
          'method': 'OTP',
          'redeemedAt': '2026-10-12T02:30:00Z',
          'billAmount': '90000',
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
    expect(find.textContaining('Phương thức OTP'), findsOneWidget);
    expect(find.textContaining('90.000'), findsOneWidget);
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
