// Widget test hang doi hoan tien (UC-07, F12) va kiem duyet danh gia (FR-ENGAGE-05, F15).
// Chay bang: flutter test
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/routes.dart';

import '../helpers/fake_backend.dart';

Map<String, dynamic> manualRefund(String id) => {
  'id': id,
  'voucherItemId': 'v-$id',
  'status': 'MANUAL_PENDING',
  'statusLabel': 'Chờ hoàn thủ công',
  'reason': 'Không dùng nữa',
  'rejectReason': null,
  'createdAt': '2026-10-20T03:00:00.000Z',
  'decidedAt': null,
  'amount': '50000',
  'voucherCode': 'HL-$id',
  'voucherStatus': 'REFUND_PENDING',
  'campaignId': 'c1',
  'campaignTitle': 'Giảm 50k Highlands',
  'paymentRefund': null,
  'customer': {'id': 'u1', 'email': 'an@test.vn', 'fullName': 'Nguyễn An', 'phone': '0901234567'},
  'payment': {'id': 'p1', 'gateway': 'VNPAY', 'gatewayTxnId': 'TXN-777', 'amount': '50000'},
};

Map<String, dynamic> mismatchOrder(String id) => {
  'id': id,
  'userId': 'u1',
  'campaignId': 'c1',
  'campaignTitle': 'Combo trưa',
  'customer': {'id': 'u1', 'email': 'binh@test.vn', 'fullName': 'Trần Bình', 'phone': null},
  'quantity': 2,
  'unitPrice': '50000',
  'totalAmount': '100000',
  'refundedAmount': '0',
  'createdAt': '2026-10-19T03:00:00.000Z',
  'status': 'PAYMENT_MISMATCH',
  'payments': [
    {'id': 'p9', 'gatewayTxnId': 'TXN-999', 'amount': 120000},
  ],
};

Map<String, dynamic> review(String id, {String status = 'VISIBLE', int rating = 4}) => {
  'id': id,
  'campaignId': 'c1',
  'campaignTitle': 'Giảm 50k Highlands',
  'brandId': 'b1',
  'brandName': 'Highlands',
  'rating': rating,
  'comment': 'Bình luận $id',
  'brandReply': null,
  'brandRepliedAt': null,
  'createdAt': '2026-10-20T03:00:00.000Z',
  'reviewerName': 'Khách $id',
  'voucherItemId': 'v-$id',
  'status': status,
};

void main() {
  late FakeBackend backend;

  setUp(() {
    backend = FakeBackend();
    backend.on('GET', '/admin/dashboard', (_) => {});
    backend.on('GET', '/refunds/manual-pending', (_) => [manualRefund('r1')]);
    backend.on('GET', '/admin/payment-mismatches', (_) => [mismatchOrder('o1')]);
  });

  Future<void> openAdmin(WidgetTester tester, String route) async {
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.admin);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await openRoute(tester, route);
  }

  Finder inDialog(Finder finder) => find.descendant(of: find.byType(AlertDialog), matching: finder);

  int count(String method, String path) =>
      backend.requests.where((r) => r.method == method && r.url.path == '/api$path').length;

  group('Hang doi hoan tien (UC-07)', () {
    testWidgets('hien du thong tin: chien dich, ma voucher, so tien, khach, giao dich goc, ly do + ghi chu DC-12', (tester) async {
      await openAdmin(tester, AppRoutes.adminRefunds);

      expect(find.text('Giảm 50k Highlands'), findsOneWidget);
      expect(find.textContaining('HL-r1'), findsOneWidget);
      expect(find.textContaining('50.000'), findsWidgets);
      expect(find.textContaining('Nguyễn An · an@test.vn · 0901234567'), findsOneWidget);
      expect(find.textContaining('VNPAY · mã TXN-777'), findsOneWidget);
      expect(find.textContaining('Không dùng nữa'), findsOneWidget);
      expect(find.textContaining('DC-12'), findsOneWidget);
    });

    testWidgets('"Da hoan tien": khong gui duoc khi bo trong ma giao dich, gui gatewayRefundId roi tai lai', (tester) async {
      backend.on('PATCH', '/refunds/r1/confirm-manual', (_) => {'id': 'r1', 'status': 'COMPLETED'});
      await openAdmin(tester, AppRoutes.adminRefunds);

      await tester.tap(find.byKey(const Key('refund-confirm-r1')));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Xác nhận')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập mã giao dịch hoàn tiền'), findsOneWidget);
      expect(backend.called('PATCH', '/refunds/r1/confirm-manual'), isFalse);

      await tester.enterText(inDialog(find.byType(TextFormField)), '   ');
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Xác nhận')));
      await tester.pumpAndSettle();
      expect(backend.called('PATCH', '/refunds/r1/confirm-manual'), isFalse, reason: 'chi co khoang trang');

      await tester.enterText(inDialog(find.byType(TextFormField)), ' RF-001 ');
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Xác nhận')));
      await tester.pumpAndSettle();
      expect(backend.bodyOf('PATCH', '/refunds/r1/confirm-manual'), {'gatewayRefundId': 'RF-001'});
      expect(find.text('Đã xác nhận hoàn tiền.'), findsOneWidget);
      expect(count('GET', '/refunds/manual-pending'), 2, reason: 'tai lai hang doi sau khi xu ly');
    });

    testWidgets('"Khong hoan duoc": bat buoc ly do, gui PATCH fail-manual', (tester) async {
      backend.on('PATCH', '/refunds/r1/fail-manual', (_) => {'id': 'r1', 'status': 'FAILED'});
      await openAdmin(tester, AppRoutes.adminRefunds);

      await tester.tap(find.byKey(const Key('refund-fail-r1')));
      await tester.pumpAndSettle();
      expect(find.textContaining('voucher được khôi phục'), findsOneWidget);
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Xác nhận')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập lý do không hoàn được'), findsOneWidget);
      expect(backend.called('PATCH', '/refunds/r1/fail-manual'), isFalse);

      await tester.enterText(inDialog(find.byType(TextFormField)), 'Tài khoản khách đã đóng');
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Xác nhận')));
      await tester.pumpAndSettle();
      expect(backend.bodyOf('PATCH', '/refunds/r1/fail-manual'), {'reason': 'Tài khoản khách đã đóng'});
      expect(find.textContaining('voucher đã được khôi phục cho khách'), findsOneWidget);
    });

    testWidgets('hien loi cua may chu (DC-12 vuot so tien da nhan)', (tester) async {
      backend.on(
        'PATCH',
        '/refunds/r1/confirm-manual',
        (_) => FakeBackend.businessError(400, 'REFUND_EXCEEDS_PAYMENT', 'Số tiền hoàn vượt giao dịch đã nhận.'),
      );
      await openAdmin(tester, AppRoutes.adminRefunds);

      await tester.tap(find.byKey(const Key('refund-confirm-r1')));
      await tester.pumpAndSettle();
      await tester.enterText(inDialog(find.byType(TextFormField)), 'RF-002');
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Xác nhận')));
      await tester.pumpAndSettle();
      expect(find.text('Số tiền hoàn vượt giao dịch đã nhận.'), findsOneWidget);
    });

    testWidgets('tab "Don lech so tien": so tien phai tra va da nhan, xac nhan bat buoc ma giao dich', (tester) async {
      backend.on('PATCH', '/admin/payment-mismatches/o1/confirm-refund', (_) => {'message': 'ok', 'paymentRefundId': 'pr1'});
      await openAdmin(tester, AppRoutes.adminRefunds);

      await tester.tap(find.text('Đơn lệch số tiền'));
      await tester.pumpAndSettle();
      expect(find.text('Combo trưa'), findsOneWidget);
      expect(find.textContaining('Trần Bình · binh@test.vn'), findsOneWidget);
      expect(find.textContaining('100.000'), findsOneWidget, reason: 'so tien phai tra');
      expect(find.textContaining('120.000'), findsWidgets, reason: 'so tien da nhan');
      expect(find.textContaining('TXN-999'), findsOneWidget);
      expect(find.textContaining('Nhận thừa: 20.000'), findsOneWidget);

      await tester.tap(find.byKey(const Key('mismatch-confirm-o1')));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Xác nhận')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập mã giao dịch hoàn tiền'), findsOneWidget);
      expect(backend.called('PATCH', '/admin/payment-mismatches/o1/confirm-refund'), isFalse);

      await tester.enterText(inDialog(find.byType(TextFormField)), 'RF-MM-1');
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Xác nhận')));
      await tester.pumpAndSettle();
      expect(backend.bodyOf('PATCH', '/admin/payment-mismatches/o1/confirm-refund'), {'gatewayRefundId': 'RF-MM-1'});
      expect(find.textContaining('Đã hủy'), findsOneWidget);
      expect(count('GET', '/admin/payment-mismatches'), 2);
    });
  });

  group('Kiem duyet danh gia (FR-ENGAGE-05)', () {
    void stubReviews({int total = 2}) {
      backend.on('GET', '/admin/reviews', (request) {
        final status = request.url.queryParameters['status'];
        final page = int.parse(request.url.queryParameters['page'] ?? '1');
        final all = [review('rv1'), review('rv2', status: 'HIDDEN', rating: 1)];
        final items = page > 1
            ? [review('rv3')]
            : all.where((r) => status == null || r['status'] == status).toList();
        return {'items': items, 'total': status == null ? total : items.length, 'page': page, 'pageSize': 20};
      });
    }

    testWidgets('menu quan tri co muc "Danh gia", liet ke va loc theo trang thai', (tester) async {
      stubReviews();
      useDesktopSize(tester);
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.admin);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Đánh giá'));
      await tester.pumpAndSettle();
      expect(find.text('Kiểm duyệt đánh giá'), findsOneWidget);
      expect(backend.requests.last.url.queryParameters, {'page': '1', 'pageSize': '20'});
      expect(find.text('Bình luận rv1'), findsOneWidget);
      expect(find.text('Bình luận rv2'), findsOneWidget);
      expect(find.textContaining('Giảm 50k Highlands · Highlands'), findsWidgets);
      expect(find.textContaining('Khách rv1'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'Đã ẩn'));
      await tester.pumpAndSettle();
      expect(backend.requests.last.url.queryParameters['status'], 'HIDDEN');
      expect(find.text('Bình luận rv1'), findsNothing);
      expect(find.text('Bình luận rv2'), findsOneWidget);
      expect(find.text('Hiện lại'), findsOneWidget);
    });

    testWidgets('"An" bat buoc ly do, goi PATCH hide va bao diem trung binh moi', (tester) async {
      stubReviews();
      backend.on('PATCH', '/admin/reviews/rv1/hide', (_) => {...review('rv1', status: 'HIDDEN'), 'avgRating': 4.5, 'reviewCount': 3});
      await openAdmin(tester, AppRoutes.adminReviews);

      await tester.tap(find.byKey(const Key('review-hide-rv1')));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Ẩn')));
      await tester.pumpAndSettle();
      expect(find.text('Vui lòng nhập lý do ẩn'), findsOneWidget);
      expect(backend.called('PATCH', '/admin/reviews/rv1/hide'), isFalse);

      await tester.enterText(inDialog(find.byType(TextFormField)), 'Ngôn từ xúc phạm');
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Ẩn')));
      await tester.pumpAndSettle();
      expect(backend.bodyOf('PATCH', '/admin/reviews/rv1/hide'), {'reason': 'Ngôn từ xúc phạm'});
      expect(find.textContaining('Điểm trung bình chiến dịch: 4.5'), findsOneWidget);
      expect(find.byKey(const Key('review-unhide-rv1')), findsOneWidget, reason: 'cap nhat tai cho');
    });

    testWidgets('"Hien lai" goi PATCH unhide', (tester) async {
      stubReviews();
      backend.on('PATCH', '/admin/reviews/rv2/unhide', (_) => {...review('rv2'), 'avgRating': 2.5, 'reviewCount': 2});
      await openAdmin(tester, AppRoutes.adminReviews);

      await tester.tap(find.byKey(const Key('review-unhide-rv2')));
      await tester.pumpAndSettle();
      await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Hiện lại')));
      await tester.pumpAndSettle();
      expect(backend.called('PATCH', '/admin/reviews/rv2/unhide'), isTrue);
      expect(find.textContaining('Điểm trung bình chiến dịch: 2.5'), findsOneWidget);
      expect(find.byKey(const Key('review-hide-rv2')), findsOneWidget);
    });

    testWidgets('con trang sau thi co nut "Tai them"', (tester) async {
      stubReviews(total: 3);
      await openAdmin(tester, AppRoutes.adminReviews);

      await tapVisible(tester, find.byKey(const Key('reviews-load-more')));
      expect(backend.requests.last.url.queryParameters['page'], '2');
      expect(find.text('Bình luận rv3'), findsOneWidget);
      expect(find.byKey(const Key('reviews-load-more')), findsNothing);
    });
  });

  testWidgets('portal thuong hieu: hien chien dich, nguoi danh gia, nhan "Da bi an" va van phan hoi duoc', (tester) async {
    backend.on('GET', '/brands/me', (_) => [
      {'id': 'b1', 'name': 'Highlands', 'status': 'APPROVED'},
    ]);
    backend.on('GET', '/brands/b1/stores', (_) => []);
    backend.on('GET', '/campaigns/brand/b1', (_) => []);
    backend.on('GET', '/brands/b1/reviews', (_) => [
      review('rv1', status: 'HIDDEN', rating: 1),
      review('rv2'),
    ]);
    backend.on('PATCH', '/reviews/rv1/reply', (_) => {'id': 'rv1'});
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.brandOwner);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await openRoute(tester, AppRoutes.brandReviews);

    expect(find.text('Giảm 50k Highlands'), findsNWidgets(2));
    expect(find.text('Khách rv1'), findsOneWidget);
    expect(find.text('Đã bị ẩn'), findsOneWidget, reason: 'chi danh gia rv1 bi an');

    await tester.tap(find.text('Phản hồi').first);
    await tester.pumpAndSettle();
    await tester.enterText(inDialog(find.byType(TextFormField)), 'Xin lỗi quý khách');
    await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Gửi')));
    await tester.pumpAndSettle();
    expect(backend.bodyOf('PATCH', '/reviews/rv1/reply'), {'reply': 'Xin lỗi quý khách'});
  });

  testWidgets('portal thuong hieu: REVIEW_ALREADY_REPLIED hien thong diep', (tester) async {
    backend.on('GET', '/brands/me', (_) => [
      {'id': 'b1', 'name': 'Highlands', 'status': 'APPROVED'},
    ]);
    backend.on('GET', '/brands/b1/stores', (_) => []);
    backend.on('GET', '/campaigns/brand/b1', (_) => []);
    backend.on('GET', '/brands/b1/reviews', (_) => [review('rv1')]);
    backend.on(
      'PATCH',
      '/reviews/rv1/reply',
      (_) => FakeBackend.businessError(400, 'REVIEW_ALREADY_REPLIED', 'Đánh giá này đã được phản hồi.'),
    );
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.brandOwner);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await openRoute(tester, AppRoutes.brandReviews);

    await tester.tap(find.text('Phản hồi'));
    await tester.pumpAndSettle();
    await tester.enterText(inDialog(find.byType(TextFormField)), 'Cảm ơn');
    await tester.tap(inDialog(find.widgetWithText(FilledButton, 'Gửi')));
    await tester.pumpAndSettle();
    expect(find.text('Đánh giá này đã được phản hồi.'), findsOneWidget);
    expect(count('GET', '/brands/b1/reviews'), 2, reason: 'tai lai de hien phan hoi da co');
  });
}
