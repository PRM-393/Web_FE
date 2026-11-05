import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_backend.dart';

void main() {
  testWidgets('man dang nhap co o dang ky thuong hieu; gui ho so goi API cong khai', (tester) async {
    useDesktopSize(tester);
    final backend = FakeBackend();
    backend.on('POST', '/brands/register', (_) => {'brandId': 'b9', 'status': 'PENDING', 'message': 'Đã nhận hồ sơ thương hiệu.'});
    final (app, _) = await buildTestApp(backend);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('login-register-brand')));
    await tester.pumpAndSettle();
    // Thieu truong bat buoc thi chua goi may chu
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    expect(backend.called('POST', '/brands/register'), isFalse);

    await tester.enterText(find.byKey(const Key('register-owner-email')), 'chu@brand.vn');
    await tester.enterText(find.byKey(const Key('register-owner-name')), 'Chu Thuong Hieu');
    await tester.enterText(find.byKey(const Key('register-brand-name')), 'Thuong Hieu Moi');
    await tester.ensureVisible(find.byKey(const Key('register-submit')));
    await tester.tap(find.byKey(const Key('register-submit')));
    await tester.pumpAndSettle();
    expect(backend.bodyOf('POST', '/brands/register'), {
      'ownerEmail': 'chu@brand.vn',
      'ownerFullName': 'Chu Thuong Hieu',
      'name': 'Thuong Hieu Moi',
    });
    expect(find.byKey(const Key('register-success')), findsOneWidget);
  });
}
