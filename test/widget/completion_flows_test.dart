import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/routes.dart';

import '../helpers/fake_backend.dart';

void main() {
  testWidgets(
    'FR-AUTH-09 request password reset and consume hash-route query',
    (tester) async {
      useDesktopSize(tester);
      final backend = FakeBackend();
      backend.on('POST', '/auth/password-reset/request', (_) => {});
      backend.on('POST', '/auth/password-reset/confirm', (_) => {});
      final (app, _) = await buildTestApp(backend);
      await tester.pumpWidget(app);
      await openRoute(tester, AppRoutes.resetPassword);
      await tester.enterText(find.byType(TextFormField), 'owner@example.test');
      await tester.tap(find.text('Gửi liên kết'));
      await tester.pumpAndSettle();
      expect(
        backend.bodyOf('POST', '/auth/password-reset/request')['email'],
        'owner@example.test',
      );
      await openRoute(
        tester,
        '/reset-password?email=owner%40example.test&token=${'a' * 64}',
      );
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), 'NewPassword@123');
      await tester.enterText(fields.at(2), 'wrong');
      await tester.tap(find.text('Lưu mật khẩu'));
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu không khớp'), findsOneWidget);
      await tester.enterText(fields.at(2), 'NewPassword@123');
      await tester.tap(find.text('Lưu mật khẩu'));
      await tester.pumpAndSettle();
      expect(
        backend.bodyOf('POST', '/auth/password-reset/confirm')['token'],
        'a' * 64,
      );
    },
  );
  testWidgets('F03 create category and show backend reference rejection', (
    tester,
  ) async {
    useDesktopSize(tester);
    final backend = FakeBackend();
    backend.on('GET', '/admin/dashboard', (_) => {});
    backend.on(
      'GET',
      '/admin/categories',
      (_) => [
        {'id': 'c1', 'name': 'Ăn uống'},
      ],
    );
    backend.on('POST', '/admin/categories', (_) => {});
    backend.on(
      'DELETE',
      '/admin/categories/c1',
      (_) =>
          FakeBackend.error(400, 'Không thể xóa danh mục đang có chiến dịch.'),
    );
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.admin);
    await tester.pumpWidget(app);
    await openRoute(tester, AppRoutes.adminCategories);
    await tester.tap(find.text('Thêm danh mục'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Du lịch');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(backend.bodyOf('POST', '/admin/categories')['name'], 'Du lịch');
    await tester.tap(find.byTooltip('Xóa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Đồng ý'));
    await tester.pumpAndSettle();
    expect(
      find.text('Không thể xóa danh mục đang có chiến dịch.'),
      findsOneWidget,
    );
  });
}
