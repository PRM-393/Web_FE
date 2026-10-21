// Widget test portal thuong hieu: man chi nhanh va man nhan vien (F07 - T5).
// Chay bang: flutter test
// Backend duoc gia lap bang FakeBackend, khong goi ra mang that.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/routes.dart';

import '../helpers/fake_backend.dart';

Map<String, dynamic> store(
  String id, {
  String name = 'Q1 Lê Lợi',
  bool active = true,
  double? latitude = 10.7769,
  double? longitude = 106.7009,
}) => {
  'id': id,
  'brandId': 'b1',
  'name': name,
  'address': '1 Lê Lợi',
  'latitude': latitude,
  'longitude': longitude,
  'status': active,
};

void main() {
  late FakeBackend backend;

  void stubBrand({List<Map<String, dynamic>>? stores}) {
    backend.on('GET', '/brands/me', (_) => [
          {'id': 'b1', 'name': 'Highlands', 'status': 'APPROVED'},
        ]);
    backend.on('GET', '/brands/b1/stores', (_) => stores ?? [store('s1')]);
  }

  Future<void> openStores(WidgetTester tester) async {
    useDesktopSize(tester);
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.brandOwner);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await openRoute(tester, AppRoutes.brandStores);
  }

  setUp(() => backend = FakeBackend());

  group('FR-BRAND-04 - chi nhanh', () {
    testWidgets('DC-05: toa do sai bi chan ngay tren form, khong goi API', (tester) async {
      stubBrand(stores: const []);
      backend.on('POST', '/brands/b1/stores', (_) => store('s9'));
      await openStores(tester);

      await tester.tap(find.text('Thêm chi nhánh'));
      await tester.pumpAndSettle();
      expect(find.text('Thêm chi nhánh'), findsWidgets);
      expect(
        find.textContaining('bắt buộc có tọa độ'),
        findsOneWidget,
        reason: 'form phai noi ro vi sao toa do la bat buoc (DC-05)',
      );

      await tester.enterText(find.widgetWithText(TextFormField, 'Tên chi nhánh *'), 'Highlands Thủ Đức');
      await tester.enterText(find.widgetWithText(TextFormField, 'Địa chỉ *'), '12 Võ Văn Ngân');
      await tester.enterText(find.widgetWithText(TextFormField, 'Vĩ độ *'), '200');
      await tester.enterText(find.widgetWithText(TextFormField, 'Kinh độ *'), '106.75');
      await tapVisible(tester, find.byKey(const Key('store-save')));

      expect(find.text('Vĩ độ từ -90 đến 90'), findsOneWidget);
      expect(backend.called('POST', '/brands/b1/stores'), isFalse);

      await tester.enterText(find.widgetWithText(TextFormField, 'Vĩ độ *'), '10.8494');
      await tapVisible(tester, find.byKey(const Key('store-save')));

      expect(backend.bodyOf('POST', '/brands/b1/stores'), {
        'name': 'Highlands Thủ Đức',
        'address': '12 Võ Văn Ngân',
        'latitude': 10.8494,
        'longitude': 106.75,
      });
    });

    testWidgets('sua chi nhanh: form mo san du lieu cu va gui PATCH', (tester) async {
      stubBrand();
      backend.on('PATCH', '/brands/stores/s1', (_) => store('s1', name: 'Q1 Lê Lợi (mới)'));
      await openStores(tester);

      // Toa do hien tren danh sach de doi chieu (DC-05)
      expect(find.textContaining('Tọa độ: 10.7769, 106.7009'), findsOneWidget);

      await tester.tap(find.byTooltip('Sửa'));
      await tester.pumpAndSettle();
      expect(find.text('Sửa chi nhánh'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Q1 Lê Lợi'), findsOneWidget);

      await tester.enterText(find.widgetWithText(TextFormField, 'Q1 Lê Lợi'), 'Q1 Lê Lợi (mới)');
      await tapVisible(tester, find.byKey(const Key('store-save')));

      final body = backend.bodyOf('PATCH', '/brands/stores/s1');
      expect(body['name'], 'Q1 Lê Lợi (mới)');
      expect(body['latitude'], 10.7769);
      expect(body.containsKey('status'), isFalse, reason: 'sua thong tin khong duoc tu doi trang thai');
    });

    testWidgets('chi nhanh da vo hieu co nut mo lai, gui status = true', (tester) async {
      stubBrand(stores: [store('s1', active: false)]);
      backend.on('PATCH', '/brands/stores/s1', (_) => store('s1'));
      await openStores(tester);

      expect(find.byTooltip('Vô hiệu hóa'), findsNothing);
      await tester.tap(find.text('Mở lại'));
      await tester.pumpAndSettle();

      expect(backend.bodyOf('PATCH', '/brands/stores/s1'), {'status': true});
    });

    testWidgets('BR-24: may chu tu choi vo hieu hoa thi hien nguyen van ly do', (tester) async {
      stubBrand();
      backend.on(
        'PATCH',
        '/brands/stores/s1/deactivate',
        (_) => FakeBackend.error(
          400,
          'Đây là chi nhánh áp dụng cuối cùng còn hoạt động của chiến dịch "Combo trưa" '
              'và khách vẫn còn voucher chưa dùng. Hãy thêm chi nhánh áp dụng khác cho chiến dịch đó '
              'rồi vô hiệu hóa lại (BR-24).',
        ),
      );
      await openStores(tester);

      await tester.tap(find.byTooltip('Vô hiệu hóa'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Vô hiệu hóa'));
      await tester.pumpAndSettle();

      expect(find.textContaining('chi nhánh áp dụng cuối cùng'), findsOneWidget);
      expect(find.textContaining('Combo trưa'), findsOneWidget);
    });
  });

  group('FR-BRAND-06 - nhan vien', () {
    testWidgets('xac nhan vo hieu hoa noi ro la khoa ca tai khoan va thu hoi phien', (tester) async {
      stubBrand();
      backend.on('GET', '/brands/b1/staff', (_) => [
            {
              'id': 'a1',
              'email': 'nv1@highlands.vn',
              'storeId': 's1',
              'storeName': 'Q1 Lê Lợi',
              'active': true,
            },
          ]);
      backend.on('PATCH', '/brands/staff/a1/deactivate', (_) => {'message': 'ok'});
      useDesktopSize(tester);
      final (app, _) = await buildTestApp(backend, loggedInAs: Roles.brandOwner);
      await tester.pumpWidget(app);
      await tester.pumpAndSettle();
      await openRoute(tester, AppRoutes.brandStaff);

      await tester.tap(find.byTooltip('Vô hiệu hóa'));
      await tester.pumpAndSettle();

      expect(find.textContaining('mọi chi nhánh'), findsOneWidget);
      expect(find.textContaining('thu hồi ngay'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Vô hiệu hóa'));
      await tester.pumpAndSettle();
      expect(backend.called('PATCH', '/brands/staff/a1/deactivate'), isTrue);
    });
  });
}
