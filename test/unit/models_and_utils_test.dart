import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/models/brand.dart';
import 'package:voucher_platform_web/models/campaign.dart';
import 'package:voucher_platform_web/models/finance.dart';
import 'package:voucher_platform_web/models/json_utils.dart';
import 'package:voucher_platform_web/models/redeem.dart';
import 'package:voucher_platform_web/utils/format.dart';
import 'package:voucher_platform_web/utils/validators.dart';

void main() {
  group('QrPayload v1 (FR-REDEEM-02/05, NFR-SEC-02)', () {
    const nonce = '0123456789abcdef0123456789abcdef';
    const sig = 'Zk3_-aBcD0123456789xyzXYZ_abcdefghijklmnopq';

    test('tach dung v1.<nonce 32 hex>.<expiresAtMs>.<chu ky base64url>, giu nguyen chuoi de gui len', () {
      final p = QrPayload.tryParse(' v1.$nonce.1700000000000.$sig\n')!;
      expect(p.nonce, nonce);
      expect(p.expiresAt, DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true));
      expect(p.raw, 'v1.$nonce.1700000000000.$sig', reason: 'gui nguyen chuoi (da bo khoang trang) de may chu kiem chu ky');
    });

    test('tu choi dinh dang cu voucherItemId.nonce.exp.sig', () {
      expect(QrPayload.tryParse('item-1.abc123.1700000000000.sig'), isNull);
      expect(QrPayload.tryParse('3f2b8c1e-1111-2222-3333-444455556666.$nonce.1700000000000.$sig'), isNull);
    });

    test('tu choi sai phien ban', () {
      expect(QrPayload.tryParse('v2.$nonce.1700000000000.$sig'), isNull);
      expect(QrPayload.tryParse('V1.$nonce.1700000000000.$sig'), isNull);
    });

    test('tu choi thieu / thua phan hoac phan sai dang', () {
      expect(QrPayload.tryParse('khong-phai-qr'), isNull);
      expect(QrPayload.tryParse('v1.$nonce.1700000000000'), isNull, reason: 'thieu chu ky');
      expect(QrPayload.tryParse('v1.$nonce.1700000000000.$sig.extra'), isNull, reason: 'thua phan');
      expect(QrPayload.tryParse('v1.abc123.1700000000000.$sig'), isNull, reason: 'nonce khong du 32 hex');
      expect(QrPayload.tryParse('v1.${nonce.toUpperCase()}.1700000000000.$sig'), isNull, reason: 'nonce phai la hex thuong');
      expect(QrPayload.tryParse('v1.$nonce.khongphaiso.$sig'), isNull);
      expect(QrPayload.tryParse('v1.$nonce.-5.$sig'), isNull);
      expect(QrPayload.tryParse('v1.$nonce.1700000000000.chu+ky/sai='), isNull, reason: 'chu ky phai la base64url');
      expect(QrPayload.tryParse('v1..1700000000000.$sig'), isNull);
    });

    test('het han khi now >= expiresAt', () {
      final p = QrPayload.tryParse('v1.$nonce.1000.$sig')!;
      expect(p.isExpired(DateTime.fromMillisecondsSinceEpoch(999, isUtc: true)), isFalse);
      expect(p.isExpired(DateTime.fromMillisecondsSinceEpoch(1000, isUtc: true)), isTrue);
    });
  });

  group('Model F11 / F12 / F15 doc JSON moi', () {
    test('RedeemResult doc campaign, ma voucher, phuong thuc, hoa don', () {
      final r = RedeemResult.fromJson({
        'message': 'Xác nhận sử dụng thành công.',
        'redemptionLogId': 'l1',
        'voucherItemId': 'v1',
        'voucherCode': 'HL-ABC123',
        'redeemedAt': '2026-10-12T03:00:00.000Z',
        'method': 'QR',
        'billAmount': null,
        'billEditableUntil': '2026-10-12T03:10:00.000Z',
        'campaign': {'id': 'c1', 'title': 'Giảm 50k', 'voucherType': 'PREPAID', 'faceValue': '100000'},
      });
      expect(r.voucherCode, 'HL-ABC123');
      expect(r.method, 'QR');
      expect(r.billAmount, isNull);
      expect(r.campaign?.title, 'Giảm 50k');
      expect(r.campaign?.faceValue, 100000);
      expect(r.billEditableUntil, DateTime.utc(2026, 10, 12, 3, 10));
    });

    test('RedemptionLog doc lich su moi, billEditable mac dinh false', () {
      final log = RedemptionLog.fromJson({
        'id': 'l1',
        'voucherItemId': 'v1',
        'voucherCode': 'HL-1',
        'campaignTitle': 'Giảm 50k',
        'storeId': 's1',
        'storeName': 'Q1',
        'method': 'OTP',
        'billAmount': '90000',
        'redeemedAt': '2026-10-12T02:30:00Z',
        'billEditable': true,
      });
      expect(log.campaignTitle, 'Giảm 50k');
      expect(log.storeName, 'Q1');
      expect(log.billAmount, 90000);
      expect(log.billEditable, isTrue);
      expect(RedemptionLog.fromJson({'id': 'l2', 'redeemedAt': '2026-10-12T02:30:00Z'}).billEditable, isFalse);
    });

    test('RefundRequest doc khach hang, giao dich goc; PaymentMismatchOrder cong so tien da nhan', () {
      final r = RefundRequest.fromJson({
        'id': 'r1',
        'voucherItemId': 'v1',
        'status': 'MANUAL_PENDING',
        'createdAt': '2026-10-20T00:00:00Z',
        'amount': '50000',
        'customer': {'id': 'u1', 'email': 'a@test.vn', 'fullName': 'Nguyễn An', 'phone': null},
        'payment': {'id': 'p1', 'gateway': 'VNPAY', 'gatewayTxnId': 'TXN1', 'amount': '50000'},
      });
      expect(r.amount, 50000);
      expect(r.customer?.summary, 'Nguyễn An · a@test.vn');
      expect(r.payment?.gatewayTxnId, 'TXN1');
      expect(RefundRequest.fromJson({'id': 'r2', 'createdAt': 'x', 'customer': null, 'payment': null}).payment, isNull);

      final o = PaymentMismatchOrder.fromJson({
        'id': 'o1',
        'totalAmount': '100000',
        'refundedAmount': '0',
        'createdAt': '2026-10-20T00:00:00Z',
        'status': 'PAYMENT_MISMATCH',
        'payments': [
          {'id': 'p1', 'gatewayTxnId': 'T1', 'amount': 80000},
          {'id': 'p2', 'gatewayTxnId': 'T2', 'amount': '40000'},
        ],
      });
      expect(o.receivedAmount, 120000);
    });

    test('Review doc truong moi, thieu truong thi mac dinh an toan', () {
      final r = Review.fromJson({
        'id': 'rv1',
        'rating': 4,
        'createdAt': '2026-10-20T00:00:00Z',
        'campaignTitle': 'Giảm 50k',
        'reviewerName': 'An N.',
        'status': 'HIDDEN',
      });
      expect(r.isHidden, isTrue);
      expect(r.reviewerName, 'An N.');
      expect(r.withStatus('VISIBLE').isHidden, isFalse);
      expect(r.withStatus('VISIBLE').campaignTitle, 'Giảm 50k');
      final old = Review.fromJson({'id': 'rv2', 'rating': '5', 'createdAt': '2026-10-20T00:00:00Z'});
      expect(old.isHidden, isFalse);
      expect(old.campaignTitle, isNull);
    });

    test('PageResult doc trang { items, total, page, pageSize } va mang cu', () {
      final page = PageResult.fromJson({
        'items': [
          {'id': 'rv1', 'rating': 5, 'createdAt': '2026-10-20T00:00:00Z'},
        ],
        'total': 21,
        'page': 1,
        'pageSize': 20,
      }, Review.fromJson);
      expect(page.items, hasLength(1));
      expect(page.hasMore, isTrue);
      final legacy = PageResult.fromJson([
        {'id': 'rv1', 'rating': 5, 'createdAt': '2026-10-20T00:00:00Z'},
      ], Review.fromJson);
      expect(legacy.total, 1);
      expect(legacy.hasMore, isFalse);
    });

    test('formatTimeDate / formatTime theo gio Viet Nam', () {
      expect(formatTimeDate(DateTime.utc(2026, 10, 12, 3)), '10:00 12/10/2026');
      expect(formatTime(DateTime.utc(2026, 10, 12, 17, 5)), '00:05');
    });
  });

  group('Model doc JSON tu PostgreSQL (numeric/bigint la chuoi)', () {
    test('VoucherCampaign doc gia dang chuoi va tinh ton kho con lai', () {
      final c = VoucherCampaign.fromJson({
        'id': 'c1',
        'brandId': 'b1',
        'title': 'Giảm 50k',
        'voucherType': 'PREPAID',
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
        'voucherCount': 12,
        'commissionAmount': '100000',
        'payableAmount': '900000',
        'status': 'PENDING',
      });
      expect(s.grossRevenue, 1000000);
      expect(s.voucherCount, 12);
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
      expect(formatPercent(0.9999), '99.99%'); // khong lam tron thanh 100%
      expect(formatPercent(0.075), '7.5%');
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

    // F13 - T3: ty le hoa hong nhap theo phan tram, may chu chi nhan 0 < rate < 1 (FR-SETTLE-01, BR-09)
    test('ty le hoa hong phai lon hon 0% va nho hon 100%', () {
      expect(validateCommissionPercent('0'), contains('lớn hơn 0%'));
      expect(validateCommissionPercent('-5'), contains('lớn hơn 0%'));
      expect(validateCommissionPercent('100'), contains('nhỏ hơn 100%'));
      expect(validateCommissionPercent('150'), contains('nhỏ hơn 100%'));
      expect(validateCommissionPercent(''), isNotNull);
      expect(validateCommissionPercent('muoi'), isNotNull);
      expect(validateCommissionPercent('10'), isNull);
      expect(validateCommissionPercent('7,5'), isNull);
      expect(validateCommissionPercent('99.99'), isNull);
    });

    test('ty le hoa hong toi da 2 chu so thap phan', () {
      expect(validateCommissionPercent('7.555'), contains('thập phân'));
      expect(validateCommissionPercent('7.55'), isNull);
    });

    // Chia cho 100 de lai sai so dau cham dong thi may chu se tu choi vi qua 4 chu so thap phan
    test('doi phan tram sang ty le 0..1 khong de lai sai so', () {
      expect(commissionPercentToRate(10), 0.1);
      expect(commissionPercentToRate(7.5), 0.075);
      expect(commissionPercentToRate(2.9), 0.029);
      expect(commissionPercentToRate(99.99), 0.9999);
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
      test('gia ban phai lon hon 0', () => expect(check(sale: 0), contains('lớn hơn 0')));
    });

    group('FR-CAMP-12 truong gia tri theo loai voucher', () {
      final s = DateTime.utc(2026, 10, 1);
      final e = DateTime.utc(2026, 10, 31);
      final x = DateTime.utc(2026, 11, 30);
      String? check(String type, {int sale = 50000, int face = 100000, String? dt, int? dv, int? max, String? combo}) =>
          validateCampaignRules(
            salePrice: sale,
            faceValue: face,
            saleStartAt: s,
            saleEndAt: e,
            voucherExpireAt: x,
            storeCount: 1,
            voucherType: type,
            discountType: dt,
            discountValue: dv,
            maxDiscount: max,
            comboItems: combo,
          );

      test('PREPAID: gia tri phai lon hon gia ban', () {
        expect(check('PREPAID', sale: 100000, face: 100000), contains('mệnh giá'));
        expect(check('PREPAID'), isNull);
      });
      test('DISCOUNT: bat buoc kieu giam va gia tri', () {
        expect(check('DISCOUNT'), contains('kiểu giảm'));
        expect(check('DISCOUNT', dt: 'AMOUNT', dv: 20000), isNull);
      });
      test('DISCOUNT theo %: 1..100 va co muc giam toi da', () {
        expect(check('DISCOUNT', dt: 'PERCENT', dv: 20), contains('tối đa'));
        expect(check('DISCOUNT', dt: 'PERCENT', dv: 120, max: 10000), contains('1 đến 100'));
        expect(check('DISCOUNT', dt: 'PERCENT', dv: 20, max: 15000), isNull);
      });
      test('COMBO: bat buoc mo ta goi', () {
        expect(check('COMBO'), contains('Combo'));
        expect(check('COMBO', combo: '1 banh mi + 1 ca phe'), isNull);
      });
    });
  });
}
