import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/routes.dart';
import 'package:voucher_platform_web/screens/auth/login_screen.dart';
import 'package:voucher_platform_web/screens/shared/message_screens.dart';

import '../helpers/fake_backend.dart';

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    backend.on('GET', '/admin/dashboard', (_) => {'totalRevenue': 2500000, 'totalCommission': 250000, 'totalActiveBrands': 3});
    backend.on('GET', '/brands/me', (_) => [
          {'id': 'b1', 'name': 'Highlands', 'status': 'APPROVED'},
        ]);
    backend.on('GET', '/brands/b1/stores', (_) => []);
    backend.on('GET', '/campaigns/brand/b1', (_) => []);
    backend.on('GET', '/redeem/my-stores', (_) => []);
  });

  group('Dang nhap (FR-AUTH-06)', () {
    testWidgets('bo trong thi bao loi tai tung o, khong goi API', (tester) async {
      useDesktopSize(tester);
      final (app, _) = await buildTestApp(backend);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pump();
      expect(find.text('Vui lòng nhập email'), findsOneWidget);
      expect(find.text('Vui lòng nhập mật khẩu'), findsOneWidget);
      expect(backend.requests, isEmpty);
    });

    testWidgets('quan tri vien dang nhap thanh cong vao bang dieu khien', (tester) async {
      useDesktopSize(tester);
      backend.on('POST', '/auth/login', (_) => loginJson(Roles.admin, email: 'admin@test.vn'));
      final (app, auth) = await buildTestApp(backend);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('login-email')), 'admin@test.vn');
      await tester.enterText(find.byKey(const Key('login-password')), 'secret1');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      expect(auth.isLoggedIn, isTrue);
      expect(find.text('Quản trị hệ thống'), findsOneWidget);
      expect(find.text('Thương hiệu hoạt động'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('sai mat khau hien thong diep cua may chu', (tester) async {
      useDesktopSize(tester);
      backend.on('POST', '/auth/login', (_) => FakeBackend.error(401, 'Sai email hoặc mật khẩu.'));
      final (app, _) = await buildTestApp(backend);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('login-email')), 'a@test.vn');
      await tester.enterText(find.byKey(const Key('login-password')), 'wrong12');
      await tester.tap(find.byKey(const Key('login-submit')));
      await tester.pumpAndSettle();

      expect(find.text('Sai email hoặc mật khẩu.'), findsOneWidget);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('dang xuat quay ve man dang nhap va xoa phien', (tester) async {
      useDesktopSize(tester);
      backend.on('POST', '/auth/logout', (_) => {'message': 'ok'});
      final (app, auth) = await buildTestApp(backend, loggedInAs: Roles.admin);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.text('Bảng điều khiển'), findsWidgets);

      await tester.tap(find.byTooltip('Đăng xuất'));
      await tester.pumpAndSettle();
      expect(auth.isLoggedIn, isFalse);
      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });

  group('Chan route theo vai tro (FR-AUTH-07)', () {
    testWidgets('chua dang nhap mo /admin/dashboard thi hien man dang nhap', (tester) async {
      useDesktopSize(tester);
      final (app, _) = await buildTestApp(backend);
      await tester.pumpWidget(app);
      await openRoute(tester, AppRoutes.adminDashboard);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(backend.called('GET', '/admin/dashboard'), isFalse);
    });

    testWidgets('nhan vien cua hang mo trang quan tri thi bi chan', (tester) async {
      useDesktopSize(tester);
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.storeStaff);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await openRoute(tester, AppRoutes.adminSettlements);
      expect(find.byType(ForbiddenScreen), findsOneWidget);
    });

    testWidgets('chu thuong hieu da dang nhap vao "/" thi den danh sach chien dich', (tester) async {
      useDesktopSize(tester);
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.brandOwner);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.text('Kênh thương hiệu'), findsOneWidget);
      expect(find.text('Chiến dịch voucher'), findsOneWidget);
      expect(find.textContaining('Chưa có chiến dịch nào'), findsOneWidget);
    });

    testWidgets('menu ben trai chuyen sang man khac', (tester) async {
      useDesktopSize(tester);
      backend.on('GET', '/admin/pending/brands', (_) => [
            {'id': 'b9', 'name': 'Phúc Long', 'status': 'PENDING', 'description': 'Trà và cà phê'},
          ]);
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.admin);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Duyệt thương hiệu'));
      await tester.pumpAndSettle();
      expect(find.text('Hồ sơ thương hiệu chờ duyệt'), findsOneWidget);
      expect(find.text('Phúc Long'), findsOneWidget);
    });

    testWidgets('URL khong ton tai hien trang 404', (tester) async {
      useDesktopSize(tester);
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.admin);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await openRoute(tester, '/khong-co');
      expect(find.byType(NotFoundScreen), findsOneWidget);
    });
  });
}
