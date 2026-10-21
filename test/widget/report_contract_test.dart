import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/routes.dart';

import '../helpers/fake_backend.dart';

void main() {
  // FR-REPORT-03: show actual BE totals and daily transactions, including narrow screens.
  for (final width in [375.0, 1400.0]) {
    testWidgets('dashboard renders BE report at $width px', (tester) async {
      tester.view.physicalSize = Size(width, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final backend = FakeBackend();
      backend.on(
        'GET',
        '/admin/dashboard',
        (_) => {
          'totalRevenue': 90000,
          'totalCommission': 9000,
          'totalActiveBrands': 2,
          'totalTransactions': 3,
          'refundedAmount': 10000,
          'transactionsByDay': [
            {'date': '2026-10-20', 'count': 3, 'revenue': 90000},
          ],
        },
      );
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.admin);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      expect(find.text('Giao dịch thành công'), findsOneWidget);
      expect(find.text('2026-10-20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  // FR-REFUND-06: recording a refund requires the external transaction reference.
  testWidgets('manual refund submits the bank reference', (tester) async {
    useDesktopSize(tester);
    final backend = FakeBackend();
    backend.on('GET', '/admin/dashboard', (_) => {});
    backend.on(
      'GET',
      '/refunds/manual-pending',
      (_) => [
        {
          'id': 'r1',
          'createdAt': '2026-10-20T00:00:00Z',
          'status': 'MANUAL_PENDING',
        },
      ],
    );
    backend.on('PATCH', '/refunds/r1/confirm-manual', (_) => {});
    backend.on('GET', '/admin/payment-mismatches', (_) => []);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.admin);
    await tester.pumpWidget(app);
    await openRoute(tester, AppRoutes.adminRefunds);
    // UC-07: mot hop thoai duy nhat, bat buoc nhap ma giao dich hoan
    await tester.tap(find.text('Đã hoàn tiền'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'BANK-123');
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();
    expect(backend.bodyOf('PATCH', '/refunds/r1/confirm-manual'), {
      'gatewayRefundId': 'BANK-123',
    });
  });
}
