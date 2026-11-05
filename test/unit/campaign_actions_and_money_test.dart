import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/models/campaign.dart';
import 'package:voucher_platform_web/models/finance.dart';

// Quy tac hien nut tren the chien dich va doc so lieu dong tien tu may chu
Map<String, dynamic> _campaign(String status, {int sold = 0, int reserved = 0}) => {
      'id': 'c1',
      'brandId': 'b1',
      'title': 'Chien dich',
      'voucherType': 'PREPAID',
      'salePrice': 100000,
      'faceValue': 120000,
      'totalQuantity': 10,
      'soldQuantity': sold,
      'reservedQuantity': reserved,
      'limitPerUser': 5,
      'saleStartAt': '2026-10-01T00:00:00Z',
      'saleEndAt': '2026-12-01T00:00:00Z',
      'voucherExpireAt': '2027-01-01T00:00:00Z',
      'status': status,
    };

void main() {
  test('sua: moi trang thai tru cho duyet va da ket thuc; cho duyet thi rut ve nhap', () {
    for (final s in ['DRAFT', 'APPROVED', 'PUBLISHED', 'SOLD_OUT', 'PAUSED']) {
      expect(VoucherCampaign.fromJson(_campaign(s)).canEdit, isTrue, reason: s);
    }
    expect(VoucherCampaign.fromJson(_campaign('PENDING')).canEdit, isFalse);
    expect(VoucherCampaign.fromJson(_campaign('PENDING')).canWithdraw, isTrue);
    expect(VoucherCampaign.fromJson(_campaign('ENDED')).canEdit, isFalse);
    expect(VoucherCampaign.fromJson(_campaign('DRAFT')).editNeedsReapproval, isFalse);
    expect(VoucherCampaign.fromJson(_campaign('PUBLISHED')).editNeedsReapproval, isTrue);
  });

  test('xoa: chi khi chua ban, chua giu cho va khong cho duyet', () {
    expect(VoucherCampaign.fromJson(_campaign('DRAFT')).canDelete, isTrue);
    expect(VoucherCampaign.fromJson(_campaign('PUBLISHED', sold: 1)).canDelete, isFalse);
    expect(VoucherCampaign.fromJson(_campaign('PUBLISHED', reserved: 1)).canDelete, isFalse);
    expect(VoucherCampaign.fromJson(_campaign('PENDING')).canDelete, isFalse);
  });

  test('bao cao doc du cac chi so dong tien', () {
    final r = BrandReport.fromJson({
      'totalCampaigns': 1,
      'totalVoucherSold': 3,
      'grossRevenue': 300000,
      'refundedAmount': 100000,
      'totalRevenue': 200000,
      'totalCommission': 20000,
      'brandPayable': 180000,
      'brandPaid': 90000,
      'brandUnpaid': 90000,
    });
    expect([r.grossRevenue, r.totalCommission, r.brandPayable, r.brandPaid, r.brandUnpaid], [300000, 20000, 180000, 90000, 90000]);
    final d = AdminDashboard.fromJson({
      'totalRevenue': 200000,
      'totalCommission': 20000,
      'totalActiveBrands': 1,
      'grossRevenue': 300000,
      'brandPayable': 180000,
      'brandPaid': 90000,
      'brandUnpaid': 90000,
    });
    expect([d.grossRevenue, d.brandPayable, d.brandPaid, d.brandUnpaid], [300000, 180000, 90000, 90000]);
  });
}
