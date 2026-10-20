// Widget test man cau hinh ty le hoa hong (F13 - T3).
// Chay bang: flutter test
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/routes.dart';

import '../helpers/fake_backend.dart';

void main() {
  late FakeBackend backend;

  // Mo thang man cau hinh ty le hoa hong voi vai tro quan tri vien
  Future<void> start(WidgetTester tester, {Map<String, dynamic>? rate}) async {
    useDesktopSize(tester);
    backend.on('GET', '/admin/commission-rate',
        (_) => rate ?? {'rate': 0.1, 'isDefault': false, 'updatedBy': 'admin-1', 'updatedAt': null});
    backend.on('POST', '/admin/commission-rate', (_) => {'message': 'Da cap nhat ty le hoa hong.', 'rate': 0.15});
    final (app, _) = await buildTestApp(backend, loggedInAs: Roles.admin);
    await tester.pumpWidget(app);
    await tester.pumpAndSettle();
    await openRoute(tester, AppRoutes.adminCommission);
  }

  // Doi ty le roi xac nhan o hop thoai. Form chua hop le thi khong co hop thoai nao mo ra.
  Future<void> saveRate(WidgetTester tester, String percent) async {
    await tester.enterText(find.widgetWithText(TextFormField, 'Tỷ lệ hoa hồng'), percent);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Lưu tỷ lệ'));
    final confirm = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.widgetWithText(FilledButton, 'Áp dụng'),
    );
    if (confirm.evaluate().isNotEmpty) await tapVisible(tester, confirm);
  }

  setUp(() => backend = FakeBackend());

  testWidgets('hien ty le dang ap dung va dien san vao o nhap (FR-SETTLE-01)', (tester) async {
    await start(tester);

    expect(find.text('Tỷ lệ đang áp dụng'), findsOneWidget);
    expect(find.text('10%'), findsOneWidget);
    expect(tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Tỷ lệ hoa hồng')).controller?.text, '10');
  });

  testWidgets('bao dang dung ty le mac dinh khi chua ai cau hinh', (tester) async {
    await start(tester, rate: {'rate': 0.1, 'isDefault': true, 'updatedBy': null, 'updatedAt': null});

    expect(find.text('Đang dùng tỷ lệ mặc định'), findsOneWidget);
  });

  testWidgets('chan ty le bang 0 va bang 100 ngay tren form (BR-09)', (tester) async {
    await start(tester);

    await saveRate(tester, '0');
    expect(find.text('Tỷ lệ hoa hồng phải lớn hơn 0%'), findsOneWidget);

    await saveRate(tester, '100');
    expect(find.text('Tỷ lệ hoa hồng phải nhỏ hơn 100%'), findsOneWidget);

    // Khong goi may chu khi form chua hop le
    expect(backend.called('POST', '/admin/commission-rate'), isFalse);
  });

  testWidgets('chan o nhap de trong hoac khong phai so', (tester) async {
    await start(tester);

    await saveRate(tester, '');
    expect(find.text('Vui lòng nhập tỷ lệ hoa hồng, ví dụ 10'), findsOneWidget);

    await saveRate(tester, 'muoi');
    expect(find.text('Vui lòng nhập tỷ lệ hoa hồng, ví dụ 10'), findsOneWidget);
    expect(backend.called('POST', '/admin/commission-rate'), isFalse);
  });

  testWidgets('gui ty le 0..1 len may chu, khong gui phan tram', (tester) async {
    await start(tester);

    await saveRate(tester, '15');

    expect(backend.bodyOf('POST', '/admin/commission-rate'), {'rate': 0.15});
    expect(find.textContaining('Đã cập nhật tỷ lệ hoa hồng'), findsOneWidget);
  });

  testWidgets('chap nhan phan tram le va dau phay thap phan', (tester) async {
    await start(tester);

    await saveRate(tester, '7,5');

    expect(backend.bodyOf('POST', '/admin/commission-rate'), {'rate': 0.075});
  });

  testWidgets('hien loi cua may chu khi bi tu choi', (tester) async {
    await start(tester);
    backend.on('POST', '/admin/commission-rate',
        (_) => FakeBackend.error(400, 'Ty le hoa hong phai lon hon 0 va nho hon 1.'));

    await saveRate(tester, '15');

    expect(find.textContaining('Ty le hoa hong phai lon hon 0 va nho hon 1'), findsOneWidget);
  });
}
