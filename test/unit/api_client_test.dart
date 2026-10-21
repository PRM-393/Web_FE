import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voucher_platform_web/services/api_client.dart';

// F01: ApiClient doc dinh dang { data, error, meta } va van tuong thich phan hoi cu
void main() {
  ApiClient clientReturning(int status, Object body) => ApiClient(
        baseUrl: 'http://api.test/api',
        httpClient: MockClient(
          (_) async => http.Response(jsonEncode(body), status, headers: {'content-type': 'application/json; charset=utf-8'}),
        ),
      );

  test('phan hoi boc { data, error, meta } tra ve phan data', () async {
    final api = clientReturning(200, {
      'data': {'items': [1, 2], 'total': 2, 'page': 1, 'pageSize': 20},
      'error': null,
      'meta': {'page': 1, 'pageSize': 20, 'total': 2, 'totalPages': 1},
    });
    expect(await api.get('/vouchers'), {'items': [1, 2], 'total': 2, 'page': 1, 'pageSize': 20});
  });

  test('data null (vd. dang xuat) tra ve null', () async {
    final api = clientReturning(200, {'data': null, 'error': null, 'meta': null});
    expect(await api.post('/auth/logout'), isNull);
  });

  test('phan hoi dinh dang cu (khong boc) giu nguyen', () async {
    final api = clientReturning(200, [
      {'id': 'a'},
    ]);
    expect(await api.get('/wallet'), [
      {'id': 'a'},
    ]);
  });

  test('loi dinh dang moi: lay error.message', () async {
    final api = clientReturning(400, {
      'data': null,
      'error': {'code': 400, 'message': 'Mã đã hết hạn, vui lòng yêu cầu mã mới.', 'path': '/api/redeem', 'timestamp': 'x'},
      'meta': null,
    });
    await expectLater(
      api.post('/redeem', body: {}),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Mã đã hết hạn, vui lòng yêu cầu mã mới.')
          .having((e) => e.statusCode, 'statusCode', 400)),
    );
  });

  test('loi nghiep vu: doc error.reason va error.details (FR-REDEEM-07)', () async {
    final api = clientReturning(400, {
      'data': null,
      'error': {
        'code': 400,
        'message': 'Voucher đã được sử dụng lúc 10:00 12/10/2026 tại Q1.',
        'reason': 'VOUCHER_USED',
        'details': {'usedAt': '2026-10-12T03:00:00.000Z', 'storeId': 's1', 'storeName': 'Q1'},
        'path': '/api/redeem',
        'timestamp': 'x',
      },
      'meta': null,
    });
    await expectLater(
      api.post('/redeem', body: {}),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Voucher đã được sử dụng lúc 10:00 12/10/2026 tại Q1.')
          .having((e) => e.statusCode, 'statusCode', 400)
          .having((e) => e.reason, 'reason', 'VOUCHER_USED')
          .having((e) => e.details, 'details', {'usedAt': '2026-10-12T03:00:00.000Z', 'storeId': 's1', 'storeName': 'Q1'})),
    );
  });

  test('loi nghiep vu co details la danh sach long nhau (WRONG_STORE) va status 429 (OTP_LOCKED)', () async {
    final wrongStore = clientReturning(400, {
      'data': null,
      'error': {
        'code': 400,
        'message': 'Voucher không áp dụng tại chi nhánh này.',
        'reason': 'WRONG_STORE',
        'details': {
          'stores': [
            {'id': 's2', 'name': 'Q3', 'address': '2 Võ Văn Tần'},
          ],
        },
      },
      'meta': null,
    });
    await expectLater(
      wrongStore.post('/redeem', body: {}),
      throwsA(isA<ApiException>().having((e) => (e.details!['stores'] as List).first['name'], 'store', 'Q3')),
    );

    final locked = clientReturning(429, {
      'data': null,
      'error': {'code': 429, 'message': 'Khóa OTP.', 'reason': 'OTP_LOCKED', 'details': {'lockedUntil': '2026-10-21T03:15:00.000Z'}},
      'meta': null,
    });
    await expectLater(
      locked.post('/redeem', body: {}),
      throwsA(isA<ApiException>()
          .having((e) => e.statusCode, 'statusCode', 429)
          .having((e) => e.reason, 'reason', 'OTP_LOCKED')
          .having((e) => e.details?['lockedUntil'], 'lockedUntil', '2026-10-21T03:15:00.000Z')),
    );
  });

  test('loi khong co reason / details (loi thuong, dinh dang cu) thi ca hai la null', () async {
    final plain = clientReturning(404, {
      'data': null,
      'error': {'code': 404, 'message': 'Không tìm thấy.', 'path': '/api/x', 'timestamp': 'x'},
      'meta': null,
    });
    await expectLater(
      plain.get('/x'),
      throwsA(isA<ApiException>()
          .having((e) => e.reason, 'reason', isNull)
          .having((e) => e.details, 'details', isNull)),
    );

    final legacy = clientReturning(400, {'statusCode': 400, 'message': 'Sai.', 'reason': 'IGNORED'});
    await expectLater(
      legacy.get('/x'),
      throwsA(isA<ApiException>()
          .having((e) => e.message, 'message', 'Sai.')
          .having((e) => e.reason, 'reason', isNull)
          .having((e) => e.details, 'details', isNull)),
    );

    final nullDetails = clientReturning(400, {
      'data': null,
      'error': {'code': 400, 'message': 'Mã này đã được dùng.', 'reason': 'TOKEN_USED', 'details': null},
      'meta': null,
    });
    await expectLater(
      nullDetails.post('/redeem', body: {}),
      throwsA(isA<ApiException>()
          .having((e) => e.reason, 'reason', 'TOKEN_USED')
          .having((e) => e.details, 'details', isNull)),
    );
  });

  test('loi dinh dang cu: message dang mang thi noi bang xuong dong', () async {
    final api = clientReturning(400, {
      'statusCode': 400,
      'message': ['email must be an email', 'password too short'],
    });
    await expectLater(
      api.post('/auth/login', body: {}),
      throwsA(isA<ApiException>().having((e) => e.message, 'message', 'email must be an email\npassword too short')),
    );
  });
}
