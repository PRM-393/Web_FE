import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/models/redeem.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/providers/brand_provider.dart';
import 'package:voucher_platform_web/providers/store_session_provider.dart';
import 'package:voucher_platform_web/services/api_client.dart';
import 'package:voucher_platform_web/services/auth_service.dart';
import 'package:voucher_platform_web/services/portal_services.dart';

import '../helpers/fake_backend.dart';

// Chuoi QR dinh dang v1 con han (chu ky do may chu kiem, client chi kiem dinh dang)
String validQr({DateTime? expiresAt}) =>
    'v1.0123456789abcdef0123456789abcdef.${(expiresAt ?? DateTime.now().add(const Duration(minutes: 1))).millisecondsSinceEpoch}.c2lnbmF0dXJl_-';

Map<String, dynamic> store(String id, {bool active = true}) => {
  'id': id,
  'brandId': 'b1',
  'name': 'Chi nhánh $id',
  'address': 'Q1',
  'status': active,
};

void main() {
  late FakeBackend backend;
  late ApiClient api;

  setUp(() {
    backend = FakeBackend();
    backend.on('POST', '/auth/select-store', (_) => {'ok': true});
    api = ApiClient(baseUrl: baseUrl, httpClient: backend.client);
  });

  group('AuthProvider', () {
    AuthProvider build(MemoryTokenStorage storage) =>
        AuthProvider(api: api, authService: AuthService(api), storage: storage);

    test(
      'FR-AUTH-03: late refresh cannot restore a logged-out session',
      () async {
        final reply = Completer<Object?>();
        final started = Completer<void>();
        backend.on(
          'GET',
          '/admin/dashboard',
          (_) => FakeBackend.error(401, 'Expired'),
        );
        backend.on('POST', '/auth/refresh', (_) {
          started.complete();
          return reply.future;
        });
        backend.on('POST', '/auth/logout', (_) => {});
        final storage = MemoryTokenStorage(sessionFor(Roles.admin));
        final auth = build(storage);
        await auth.hydrate();
        final pending = expectLater(
          AdminService(api).dashboard(),
          throwsA(isA<ApiException>()),
        );
        await started.future;
        await auth.logout();
        reply.complete(loginJson(Roles.admin));
        await pending;
        expect(auth.isLoggedIn, isFalse);
        expect(storage.session, isNull);
      },
    );

    test(
      'dang nhap thanh cong luu phien va gan Bearer token cho request sau',
      () async {
        backend.on('POST', '/auth/login', (_) => loginJson(Roles.admin));
        backend.on(
          'GET',
          '/admin/dashboard',
          (_) => {
            'totalRevenue': 0,
            'totalCommission': 0,
            'totalActiveBrands': 0,
          },
        );
        final storage = MemoryTokenStorage();
        final auth = build(storage);

        await auth.login(' admin@test.vn ', 'secret1');
        expect(auth.isLoggedIn, isTrue);
        expect(storage.session?.user.role, Roles.admin);
        expect(backend.bodyOf('POST', '/auth/login')['email'], 'admin@test.vn');

        await AdminService(api).dashboard();
        expect(
          backend.requests.last.headers['Authorization'],
          'Bearer access-ADMIN',
        );
      },
    );

    test('tai khoan khach hang bi tu choi tren web', () async {
      backend.on('POST', '/auth/login', (_) => loginJson('CUSTOMER'));
      final auth = build(MemoryTokenStorage());
      await expectLater(
        auth.login('c@test.vn', 'secret1'),
        throwsA(isA<ApiException>()),
      );
      expect(auth.isLoggedIn, isFalse);
    });

    test('loi 401 tu may chu hien thong diep tieng Viet', () async {
      backend.on(
        'POST',
        '/auth/login',
        (_) => FakeBackend.error(401, 'Sai email hoặc mật khẩu.'),
      );
      final auth = build(MemoryTokenStorage());
      await expectLater(
        auth.login('a@test.vn', 'wrong12'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Sai email hoặc mật khẩu.',
          ),
        ),
      );
    });

    test('het han access token thi lam moi bang refresh token roi goi lai (FR-AUTH-03)', () async {
      var calls = 0;
      backend.on('GET', '/admin/dashboard', (r) {
        calls++;
        return r.headers['Authorization'] == 'Bearer access-new'
            ? {'totalRevenue': 1, 'totalCommission': 0, 'totalActiveBrands': 0}
            : FakeBackend.error(401, 'Unauthorized');
      });
      backend.on(
        'POST',
        '/auth/refresh',
        (_) => {
          'accessToken': 'access-new',
          'refreshToken': 'refresh-new',
          'user': {'id': 'u', 'email': 'a@test.vn', 'role': Roles.admin},
        },
      );
      final storage = MemoryTokenStorage(sessionFor(Roles.admin));
      final auth = build(storage);
      await auth.hydrate();

      final d = await AdminService(api).dashboard();
      expect(d.totalRevenue, 1);
      expect(calls, 2);
      expect(storage.session?.refreshToken, 'refresh-new');
    });

    test('refresh token khong hop le thi xoa phien', () async {
      backend.on(
        'GET',
        '/admin/dashboard',
        (_) => FakeBackend.error(401, 'Unauthorized'),
      );
      backend.on(
        'POST',
        '/auth/refresh',
        (_) => FakeBackend.error(401, 'Refresh token không hợp lệ.'),
      );
      final auth = build(MemoryTokenStorage(sessionFor(Roles.admin)));
      await auth.hydrate();

      await expectLater(
        AdminService(api).dashboard(),
        throwsA(isA<ApiException>()),
      );
      expect(auth.isLoggedIn, isFalse);
    });
  });

  group('BrandProvider', () {
    test('lay ho so dau tien va danh sach chi nhanh; activeStores bo chi nhanh da tat', () async {
      backend.on(
        'GET',
        '/brands/me',
        (_) => [
          {'id': 'b1', 'name': 'Highlands', 'status': 'APPROVED'},
        ],
      );
      backend.on(
        'GET',
        '/brands/b1/stores',
        (_) => [store('s1'), store('s2', active: false)],
      );
      final provider = BrandProvider(BrandService(api));

      await provider.load();
      expect(provider.brand?.name, 'Highlands');
      expect(provider.brand?.isApproved, isTrue);
      expect(provider.stores, hasLength(2));
      expect(provider.activeStores.map((s) => s.id), ['s1']);
    });

    test(
      'chua co ho so thi hasBrand = false va khong goi API chi nhanh',
      () async {
        backend.on('GET', '/brands/me', (_) => []);
        final provider = BrandProvider(BrandService(api));
        await provider.load();
        expect(provider.isLoaded, isTrue);
        expect(provider.hasBrand, isFalse);
        expect(backend.called('GET', '/brands/b1/stores'), isFalse);
      },
    );
  });

  group('StoreSessionProvider (FR-AUTH-12, BR-07)', () {
    test('chi duoc gan mot chi nhanh dang hoat dong thi tu chon', () async {
      backend.on(
        'GET',
        '/redeem/my-stores',
        (_) => [store('s1'), store('s2', active: false)],
      );
      final session = StoreSessionProvider(RedeemService(api));
      await session.loadStores();
      expect(session.stores.map((s) => s.id), ['s1']);
      expect(session.currentStore?.id, 's1');
      expect(backend.bodyOf('POST', '/auth/select-store'), {'storeId': 's1'});
    });

    test('redeem gui storeId cua chi nhanh dang lam va NGUYEN chuoi QR (qrPayload, khong con nonce); thanh cong thi tai lai lich su', () async {
      backend.on('GET', '/redeem/my-stores', (_) => [store('s1'), store('s2')]);
      backend.on(
        'POST',
        '/redeem',
        (_) => {'message': 'Redeem thanh cong.', 'voucherItemId': 'v1'},
      );
      backend.on(
        'GET',
        '/redeem/history/today',
        (_) => [
          {
            'id': 'l1',
            'voucherItemId': 'v1',
            'storeId': 's2',
            'method': 'QR',
            'redeemedAt': '2026-10-12T03:00:00Z',
          },
        ],
      );
      final session = StoreSessionProvider(RedeemService(api));
      await session.loadStores();
      expect(
        session.currentStore,
        isNull,
        reason: 'nhieu chi nhanh thi nhan vien phai tu chon',
      );
      await session.selectStore(session.stores[1]);

      final qr = validQr();
      final ok = await session.redeemQr(' $qr ', billAmount: 120000);
      expect(ok, isTrue);
      expect(backend.bodyOf('POST', '/redeem'), {
        'storeId': 's2',
        'qrPayload': qr,
        'billAmount': 120000,
      });
      expect(session.lastResult?.voucherItemId, 'v1');
      expect(session.history, hasLength(1));
    });

    test('chuoi QR sai dinh dang hoac da het han thi bao loi ngay, khong goi API', () async {
      backend.on('GET', '/redeem/my-stores', (_) => [store('s1')]);
      final session = StoreSessionProvider(RedeemService(api));
      await session.loadStores();

      expect(await session.redeemQr('item-1.abc.1700000000000.sig'), isFalse);
      expect(session.lastFailure?.reason, RedeemReason.tokenInvalid);

      final expired = validQr(expiresAt: DateTime.now().subtract(const Duration(seconds: 1)));
      expect(await session.redeemQr(expired), isFalse);
      expect(session.lastFailure?.reason, RedeemReason.tokenExpired);
      expect(backend.called('POST', '/redeem'), isFalse);
    });

    test('BILL_REQUIRED: chua phai ket qua cuoi, giu ma de gui lai kem hoa don (BR-03)', () async {
      backend.on('GET', '/redeem/my-stores', (_) => [store('s1')]);
      var calls = 0;
      backend.on('POST', '/redeem', (_) {
        calls++;
        return calls == 1
            ? FakeBackend.businessError(
                400,
                'BILL_REQUIRED',
                'Voucher mệnh giá bắt buộc nhập giá trị hóa đơn (BR-03).',
                details: {'voucherType': 'PREPAID', 'faceValue': 100000},
              )
            : {'message': 'ok', 'voucherItemId': 'v1'};
      });
      backend.on('GET', '/redeem/history/today', (_) => []);
      final session = StoreSessionProvider(RedeemService(api));
      await session.loadStores();
      final qr = validQr();

      expect(await session.redeemQr(qr), isFalse);
      expect(session.lastFailure, isNull, reason: 'khong hien khung do');
      expect(session.billRequirement?.qrPayload, qr);
      expect(session.billRequirement?.faceValue, 100000);

      expect(await session.resubmitWithBill(150000), isTrue);
      expect(backend.bodyOf('POST', '/redeem'), {'storeId': 's1', 'qrPayload': qr, 'billAmount': 150000});
      expect(session.billRequirement, isNull);
      expect(session.lastResult?.voucherItemId, 'v1');
    });

    test('OTP_LOCKED: khoa o nhap OTP den lockedUntil, khong gui OTP nua nhung van gui QR (FR-REDEEM-12)', () async {
      backend.on('GET', '/redeem/my-stores', (_) => [store('s1')]);
      final lockedUntil = DateTime.now().toUtc().add(const Duration(minutes: 15));
      backend.on(
        'POST',
        '/redeem',
        (_) => FakeBackend.businessError(
          429,
          'OTP_LOCKED',
          'Nhập sai OTP quá nhiều lần.',
          details: {'lockedUntil': lockedUntil.toIso8601String()},
        ),
      );
      final session = StoreSessionProvider(RedeemService(api));
      await session.loadStores();

      expect(await session.redeem(otpCode: '111111'), isFalse);
      expect(session.isOtpLocked(DateTime.now()), isTrue);
      expect(session.otpLockedUntil, lockedUntil);
      expect(session.lastFailure, isNull);

      final before = backend.requests.length;
      expect(await session.redeem(otpCode: '222222'), isFalse);
      expect(backend.requests.length, before, reason: 'dang khoa thi khong goi may chu');

      await session.redeemQr(validQr());
      expect(backend.bodyOf('POST', '/redeem').containsKey('qrPayload'), isTrue);
      expect(session.isOtpLocked(lockedUntil.add(const Duration(seconds: 1))), isFalse);
    });

    test('sua hoa don: PATCH dung URL / body va thay dong lich su (FR-REDEEM-08)', () async {
      backend.on('GET', '/redeem/my-stores', (_) => [store('s1')]);
      backend.on('GET', '/redeem/history/today', (_) => [
            {'id': 'l1', 'storeId': 's1', 'method': 'QR', 'redeemedAt': '2026-10-12T03:00:00Z', 'billEditable': true},
          ]);
      backend.on('PATCH', '/redeem/logs/l1/bill', (_) => {
            'id': 'l1',
            'storeId': 's1',
            'method': 'QR',
            'redeemedAt': '2026-10-12T03:00:00Z',
            'billAmount': 99000,
            'billEditable': true,
          });
      final session = StoreSessionProvider(RedeemService(api));
      await session.loadHistory();
      await session.updateBill('l1', 99000);
      expect(backend.bodyOf('PATCH', '/redeem/logs/l1/bill'), {'billAmount': 99000});
      expect(session.history.single.billAmount, 99000);
    });

    test(
      'redeem that bai giu thong diep loi cua may chu (FR-REDEEM-07)',
      () async {
        backend.on('GET', '/redeem/my-stores', (_) => [store('s1')]);
        backend.on(
          'POST',
          '/redeem',
          (_) =>
              FakeBackend.error(400, 'Mã đã hết hạn, vui lòng yêu cầu mã mới.'),
        );
        final session = StoreSessionProvider(RedeemService(api));
        await session.loadStores();

        final ok = await session.redeem(otpCode: '123456');
        expect(ok, isFalse);
        expect(session.lastError, 'Mã đã hết hạn, vui lòng yêu cầu mã mới.');
        expect(backend.bodyOf('POST', '/redeem'), {
          'storeId': 's1',
          'otpCode': '123456',
        });
      },
    );

    test('chua chon chi nhanh thi khong gui request', () async {
      final session = StoreSessionProvider(RedeemService(api));
      expect(await session.redeem(otpCode: '123456'), isFalse);
      expect(backend.requests, isEmpty);
    });
  });
}
