// Kiem thu tich hop that: goi BE dang chay bang dung cac service cua web (khong mock).
// Chay BE truoc:  (BE) npx ts-node -T test/helpers/serve-memory.ts 3999
// Chay test Mobile live truoc (tao voucher + OTP redeem), roi:
//   flutter test test/live --dart-define=LIVE_API=http://localhost:3999/api
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/models/campaign.dart';
import 'package:voucher_platform_web/services/api_client.dart';
import 'package:voucher_platform_web/services/auth_service.dart';
import 'package:voucher_platform_web/services/portal_services.dart';

const liveApi = String.fromEnvironment('LIVE_API');
const stateFile = String.fromEnvironment('STATE_FILE', defaultValue: '../BE/.e2e-live.json');
const password = 'Voucher@123';

final results = <String, String?>{};

Future<T?> step<T>(String name, Future<T> Function() fn) async {
  try {
    final v = await fn();
    results[name] = null;
    return v;
  } catch (e) {
    results[name] = e.toString().split('\n').first;
    return null;
  }
}

void main() {
  test('FE <-> BE: thuong hieu, cua hang, quan tri', () async {
    final state = jsonDecode(File(stateFile).readAsStringSync()) as Map<String, dynamic>;
    final api = ApiClient(baseUrl: liveApi);
    String? access;
    api.accessTokenGetter = () => access;
    final auth = AuthService(api);
    final brands = BrandService(api);
    final campaigns = CampaignService(api);
    final redeem = RedeemService(api);
    final admin = AdminService(api);

    // ---- nhan vien cua hang: redeem voucher khach vua mua tren app ----
    access = (await step('cua hang: dang nhap', () => auth.login('staff@highlands.local', password)))?.accessToken;
    final myStores = await step('cua hang: chi nhanh duoc gan', () => redeem.myStores());
    final storeId = myStores?.first.id;
    await step('cua hang: chon chi nhanh', () => redeem.selectStore(storeId!));
    await step('cua hang: redeem bang OTP tu app', () => redeem.redeem(storeId: storeId!, otpCode: state['otpCode'] as String?));
    await step('cua hang: lich su trong ngay', () => redeem.historyToday());
    await step('cua hang: dang xuat', () => auth.logout());

    // ---- chu thuong hieu ----
    access = (await step('thuong hieu: dang nhap', () => auth.login('owner@highlands.local', password)))?.accessToken;
    final mine = await step('thuong hieu: ho so', () => brands.myBrands());
    final brandId = mine?.first.id;
    final stores = await step('thuong hieu: chi nhanh', () => brands.stores(brandId!));
    await step('thuong hieu: tao chi nhanh', () => brands.createStore(brandId!, name: 'CN Live', address: '1 Le Loi, Q1', latitude: 10.77, longitude: 106.70));
    await step('thuong hieu: nhan vien', () => brands.staff(brandId!));
    final now = DateTime.now().toUtc();
    final draft = CampaignDraft(
      title: 'Live test 50K',
      voucherType: 'PREPAID',
      salePrice: 40000,
      faceValue: 50000,
      totalQuantity: 10,
      limitPerUser: 2,
      saleStartAt: now.add(const Duration(days: 1)),
      saleEndAt: now.add(const Duration(days: 10)),
      voucherExpireAt: now.add(const Duration(days: 30)),
      storeIds: [stores!.first.id],
    );
    await step('chien dich: tao', () => campaigns.create(brandId!, draft));
    final list = await step('chien dich: danh sach', () => campaigns.byBrand(brandId!));
    final created = list?.firstWhere((c) => c.title == 'Live test 50K');
    await step('chien dich: sua', () => campaigns.update(created!.id, draft));
    await step('chien dich: gui duyet', () => campaigns.submit(created!.id));
    await step('thuong hieu: danh gia', () => brands.reviews(brandId!));
    await step('thuong hieu: bao cao', () => brands.report(brandId!));
    await step('thuong hieu: doi soat', () => brands.settlements(brandId!));

    // ---- quan tri ----
    access = (await step('quan tri: dang nhap', () => auth.login('admin@voucher.local', password)))?.accessToken;
    await step('quan tri: dashboard', () => admin.dashboard());
    await step('quan tri: thuong hieu cho duyet', () => admin.pendingBrands());
    final pending = await step('quan tri: chien dich cho duyet', () => admin.pendingCampaigns());
    await step('quan tri: duyet chien dich', () => admin.approveCampaign(pending!.firstWhere((c) => c.id == created!.id).id));
    final rate = await step('quan tri: xem ty le hoa hong', () => admin.commissionRate());
    await step('quan tri: doi ty le hoa hong', () => admin.setCommissionRate(rate?.rate ?? 0.1));
    await step('quan tri: hang doi hoan thu cong', () => admin.manualPendingRefunds());
    final start = DateTime.utc(now.year, now.month);
    await step('quan tri: chot doi soat', () => admin.runSettlement(start, DateTime.utc(now.year, now.month + 1)));
    await step('quan tri: danh sach doi soat', () => admin.settlements());

    final failed = results.entries.where((e) => e.value != null).toList();
    stdout.writeln('\n=== FE: ${results.length - failed.length}/${results.length} buoc qua');
    for (final e in results.entries) {
      stdout.writeln('${e.value == null ? 'OK  ' : 'FAIL'} ${e.key}${e.value == null ? '' : ' -> ${e.value}'}');
    }
  }, skip: liveApi.isEmpty ? 'can --dart-define=LIVE_API' : null, timeout: const Timeout(Duration(minutes: 2)));
}
