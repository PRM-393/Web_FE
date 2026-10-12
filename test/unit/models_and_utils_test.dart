import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/models/campaign.dart';
import 'package:voucher_platform_web/models/finance.dart';
import 'package:voucher_platform_web/models/redeem.dart';
import 'package:voucher_platform_web/utils/format.dart';
import 'package:voucher_platform_web/utils/validators.dart';

void main() {
  group('QrPayload (FR-REDEEM-02/05)', () {
    test('tach dung 4 phan voucherItemId.nonce.expiresAt.signature', () {
      final p = QrPayload.tryParse('item-1.abc123.1700000000000.sig')!;
      expect(p.voucherItemId, 'item-1');
      expect(p.nonce, 'abc123');
      expect(p.expiresAt, DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true));
    });

    test('chuoi sai dinh dang tra ve null', () {
      expect(QrPayload.tryParse('khong-phai-qr'), isNull);
      expect(QrPayload.tryParse('a.b.khongphaiso.d'), isNull);
      expect(QrPayload.tryParse('a..123.d'), isNull);
    });

    test('het han khi now >= expiresAt', () {
      final p = QrPayload.tryParse('i.n.1000.s')!;
      expect(p.isExpired(DateTime.fromMillisecondsSinceEpoch(999, isUtc: true)), isFalse);
      expect(p.isExpired(DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true)), isTrue);
    });
  });

  group('Model doc JSON tu PostgreSQL (numeric/bigint la chuoi)', () {
    test('VoucherCampaign doc gia dang chuoi va tinh ton kho con lai', () {
      final c = VoucherCampaign.fromJson({
        'id': 'c1',
        'brandId': 'b1',
        'title': 'Giảm 50k',
        'voucherType': 'PREPAID_VALUE',
        'salePrice': '80000.00',
        'faceValue': '100000',
        'totalQuantity': 100,
        'soldQuantity': 30,
        'reservedQuantity': 5,
        'limitPerUser': 5,
        'saleStartAt': '2026-10-01T00:00:00.000Z',
        'saleEndAt': '2026-10-31T00:00:00.000Z',
        'voucherExpireAt': '2026-11-30T00:00:00.000Z',
        'status': 'DRAFT',
      });
      expect(c.salePrice, 80000);
      expect(c.faceValue, 100000);
      expect(c.remaining, 65);
      expect(c.canEdit, isTrue);
      expect(c.canSubmit, isTrue);
      expect(c.canPause, isFalse);
    });

    test('Settlement doc bigint / decimal dang chuoi', () {
      final s = Settlement.fromJson({
        'id': 's1',
        'brandId': 'b1',
        'brandName': 'Highlands',
        'periodStart': '2026-09-01T00:00:00.000Z',
        'periodEnd': '2026-09-30T00:00:00.000Z',
        'grossRevenue': '1000000',
        'commissionRate': '0.1000',
        'commissionAmount': '100000',
        'payableAmount': '900000',
        'status': 'PENDING',
      });
      expect(s.grossRevenue, 1000000);
      expect(s.commissionRate, 0.1);
      expect(s.payableAmount, 900000);
      expect(s.isPaid, isFalse);
    });

    test('CampaignDraft gui thoi gian UTC va bo storeIds khi sua', () {
      final draft = CampaignDraft(
        title: 'A',
        voucherType: VoucherType.combo,
        salePrice: 1,
        faceValue: 2,
        totalQuantity: 3,
        limitPerUser: 5,
        saleStartAt: DateTime.utc(2026, 10, 1),
        saleEndAt: DateTime.utc(2026, 10, 2),
        voucherExpireAt: DateTime.utc(2026, 10, 20),
        storeIds: const ['s1'],
      );
      expect(draft.toJson()['storeIds'], ['s1']);
      expect(draft.toJson()['saleStartAt'], '2026-10-01T00:00:00.000Z');
      expect(draft.toJson(includeStores: false).containsKey('storeIds'), isFalse);
      expect(draft.toJson().containsKey('image'), isFalse);
    });
  });

  group('Dinh dang va ngay theo gio Viet Nam (CON-05, BR-25)', () {
    test('formatVnd co dau phan cach hang nghin', () {
      expect(formatVnd(1500000), contains('1.500.000'));
    });

    test('formatPercent', () {
      expect(formatPercent(0.1), '10%');
      expect(formatPercent(0.125), '12.5%');
    });

    test('ngay chon tren form doi sang UTC theo UTC+7', () {
      final day = DateTime(2026, 10, 12);
      expect(vnStartOfDayUtc(day), DateTime.utc(2026, 10, 11, 17));
      expect(vnEndOfDayUtc(day), DateTime.utc(2026, 10, 12, 16, 59, 59));
      expect(vnCalendarDay(DateTime.utc(2026, 10, 11, 17)), DateTime(2026, 10, 12));
    });
  });

  group('Validators', () {
    test('email va mat khau', () {
      expect(validateEmail(''), isNotNull);
      expect(validateEmail('abc'), isNotNull);
      expect(validateEmail('owner@brand.vn'), isNull);
      expect(validatePassword('123'), isNotNull);
      expect(validatePassword('123456'), isNull);
    });

    test('parseMoney chap nhan dau cham phan cach', () {
      expect(parseMoney('1.500.000'), 1500000);
      expect(parseMoney('50,000 ₫'), 50000);
      expect(parseMoney('abc'), isNull);
      expect(validateMoney('0', 'giá trị', allowZero: false), isNotNull);
    });

    test('OTP gom dung 6 chu so', () {
      expect(validateRedeemOtp('12345'), isNotNull);
      expect(validateRedeemOtp('12a456'), isNotNull);
      expect(validateRedeemOtp('123456'), isNull);
    });

    test('toa do chi nhanh', () {
      expect(validateLatitude('91'), isNotNull);
      expect(validateLatitude('10.77'), isNull);
      expect(validateLongitude('-181'), isNotNull);
      expect(validateLongitude('106.7'), isNull);
    });

    group('validateCampaignRules', () {
      final start = DateTime.utc(2026, 10, 1);
      final end = DateTime.utc(2026, 10, 31);
      String? check({int sale = 80, int face = 100, DateTime? s, DateTime? e, DateTime? x, int stores = 1}) =>
          validateCampaignRules(
            salePrice: sale,
            faceValue: face,
            saleStartAt: s ?? start,
            saleEndAt: e ?? end,
            voucherExpireAt: x ?? end.add(const Duration(days: 10)),
            storeCount: stores,
          );

      test('hop le khi han dung dung bang ngay ket thuc ban + 10 ngay (DC-10)', () => expect(check(), isNull));
      test('gia ban lon hon gia tri', () => expect(check(sale: 120), contains('Giá bán')));
      test('ngay ket thuc ban truoc ngay bat dau', () => expect(check(e: start), contains('kết thúc bán')));
      test('han dung chua du 10 ngay sau ket thuc ban',
          () => expect(check(x: end.add(const Duration(days: 9))), contains('10 ngày')));
      test('chua chon chi nhanh (DC-07)', () => expect(check(stores: 0), contains('chi nhánh')));
    });
  });
}
