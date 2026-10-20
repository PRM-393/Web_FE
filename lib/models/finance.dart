import 'json_utils.dart';

// Phieu doi soat theo thang (FR-SETTLE-02..08)
class Settlement {
  const Settlement({
    required this.id,
    required this.brandId,
    required this.periodStart,
    required this.periodEnd,
    required this.grossRevenue,
    required this.voucherCount,
    required this.commissionAmount,
    required this.payableAmount,
    required this.status,
    this.brandName,
    this.paidAt,
    this.bankTxnRef,
  });

  final String id;
  final String brandId;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int grossRevenue;
  final int voucherCount;
  final int commissionAmount;
  final int payableAmount;
  final String status;
  final String? brandName;
  final DateTime? paidAt;
  final String? bankTxnRef;

  bool get isPaid => status == 'PAID';

  factory Settlement.fromJson(Map<String, dynamic> json) => Settlement(
        id: json['id'] as String,
        brandId: json['brandId'] as String? ?? '',
        periodStart: asDate(json['periodStart']),
        periodEnd: asDate(json['periodEnd']),
        grossRevenue: asInt(json['grossRevenue']),
        voucherCount: asInt(json['voucherCount']),
        commissionAmount: asInt(json['commissionAmount']),
        payableAmount: asInt(json['payableAmount']),
        status: json['status'] as String? ?? 'PENDING',
        brandName: json['brandName'] as String?,
        paidAt: asDateOrNull(json['paidAt']),
        bankTxnRef: json['bankTxnRef'] as String?,
      );
}

// Ty le hoa hong chung cua san + lan thay doi gan nhat (FR-SETTLE-01, NFR-SEC-07)
class CommissionRateInfo {
  const CommissionRateInfo({required this.rate, this.isDefault = false, this.updatedBy, this.updatedAt});

  // Ty le 0..1, vd 0.1 = 10%
  final double rate;

  // true khi may chu dang dung ty le mac dinh vi chua ai cau hinh
  final bool isDefault;
  final String? updatedBy;
  final DateTime? updatedAt;

  double get percent => rate * 100;

  factory CommissionRateInfo.fromJson(Map<String, dynamic> json) => CommissionRateInfo(
        rate: asDouble(json['rate']),
        isDefault: json['isDefault'] == true,
        updatedBy: json['updatedBy'] as String?,
        updatedAt: asDateOrNull(json['updatedAt']),
      );
}

// Bao cao cua thuong hieu (FR-REPORT-01/02)
class BrandReport {
  const BrandReport({required this.totalCampaigns, required this.totalVoucherSold, required this.totalRevenue});

  final int totalCampaigns;
  final int totalVoucherSold;
  final int totalRevenue;

  factory BrandReport.fromJson(Map<String, dynamic> json) => BrandReport(
        totalCampaigns: asInt(json['totalCampaigns']),
        totalVoucherSold: asInt(json['totalVoucherSold']),
        totalRevenue: asInt(json['totalRevenue']),
      );
}

// Bang dieu khien quan tri (FR-REPORT-03)
class AdminDashboard {
  const AdminDashboard({required this.totalRevenue, required this.totalCommission, required this.totalActiveBrands});

  final int totalRevenue;
  final int totalCommission;
  final int totalActiveBrands;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) => AdminDashboard(
        totalRevenue: asInt(json['totalRevenue']),
        totalCommission: asInt(json['totalCommission']),
        totalActiveBrands: asInt(json['totalActiveBrands']),
      );
}

// Yeu cau hoan tien cho quan tri vien xac nhan thu cong (FR-REFUND-06)
class RefundRequest {
  const RefundRequest({
    required this.id,
    required this.voucherItemId,
    required this.status,
    required this.createdAt,
    this.reason,
  });

  final String id;
  final String voucherItemId;
  final String status;
  final DateTime createdAt;
  final String? reason;

  factory RefundRequest.fromJson(Map<String, dynamic> json) => RefundRequest(
        id: json['id'] as String,
        voucherItemId: json['voucherItemId'] as String? ?? '',
        status: json['status'] as String? ?? '',
        createdAt: asDate(json['createdAt']),
        reason: json['reason'] as String?,
      );
}
