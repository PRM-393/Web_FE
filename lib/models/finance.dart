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

// Mot dong trong phieu doi soat: ung voi dung mot voucher da ban (DC-06).
// Ty le hoa hong lay theo tung dong vi don cu giu ty le da chot luc thanh toan (BR-09).
class SettlementLine {
  const SettlementLine({
    required this.id,
    required this.voucherItemId,
    required this.amount,
    required this.commissionRate,
    required this.commissionAmount,
    this.orderId,
  });

  final String id;
  final String voucherItemId;
  final String? orderId;
  final int amount;
  final double commissionRate;
  final int commissionAmount;

  int get payableAmount => amount - commissionAmount;

  factory SettlementLine.fromJson(Map<String, dynamic> json) => SettlementLine(
    id: json['id'] as String? ?? '',
    voucherItemId: json['voucherItemId'] as String? ?? '',
    orderId: json['orderId'] as String?,
    amount: asInt(json['amount']),
    commissionRate: asDouble(json['commissionRate']),
    commissionAmount: asInt(json['commissionAmount']),
  );
}

// GET /settlements/:id tra ve { settlement, items } (FR-SETTLE-08)
class SettlementDetail {
  const SettlementDetail({required this.settlement, required this.items});

  final Settlement settlement;
  final List<SettlementLine> items;

  factory SettlementDetail.fromJson(Map<String, dynamic> json) => SettlementDetail(
    settlement: Settlement.fromJson(json['settlement'] as Map<String, dynamic>),
    items: asList(json['items'], SettlementLine.fromJson),
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
  const BrandReport({
    required this.totalCampaigns,
    required this.totalVoucherSold,
    required this.totalRevenue,
    this.grossRevenue = 0,
    this.refundedAmount = 0,
    this.totalVoucherUsed = 0,
    this.totalVoucherExpired = 0,
    this.totalVoucherRefunded = 0,
    this.usageRate = 0,
  });

  final int grossRevenue,
      refundedAmount,
      totalVoucherUsed,
      totalVoucherExpired,
      totalVoucherRefunded;
  final double usageRate;
  final int totalCampaigns;
  final int totalVoucherSold;
  final int totalRevenue;

  factory BrandReport.fromJson(Map<String, dynamic> json) => BrandReport(
    grossRevenue: asInt(json['grossRevenue']),
    refundedAmount: asInt(json['refundedAmount']),
    totalVoucherUsed: asInt(json['totalVoucherUsed']),
    totalVoucherExpired: asInt(json['totalVoucherExpired']),
    totalVoucherRefunded: asInt(json['totalVoucherRefunded']),
    usageRate: asDouble(json['usageRate']),
    totalCampaigns: asInt(json['totalCampaigns']),
    totalVoucherSold: asInt(json['totalVoucherSold']),
    totalRevenue: asInt(json['totalRevenue']),
  );
}

// Bang dieu khien quan tri (FR-REPORT-03)
class AdminDashboard {
  const AdminDashboard({
    required this.totalRevenue,
    required this.totalCommission,
    required this.totalActiveBrands,
    this.totalTransactions = 0,
    this.refundedAmount = 0,
    this.transactionsByDay = const [],
  });

  final int totalRevenue;
  final int totalCommission;
  final int totalActiveBrands;
  final int totalTransactions, refundedAmount;
  final List<Map<String, dynamic>> transactionsByDay;

  factory AdminDashboard.fromJson(Map<String, dynamic> json) => AdminDashboard(
    totalRevenue: asInt(json['totalRevenue']),
    totalCommission: asInt(json['totalCommission']),
    totalActiveBrands: asInt(json['totalActiveBrands']),
    totalTransactions: asInt(json['totalTransactions']),
    refundedAmount: asInt(json['refundedAmount']),
    transactionsByDay: (json['transactionsByDay'] as List? ?? [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(),
  );
}

// Thong tin lien he cua khach de quan tri vien doi chieu khi hoan tien (UC-07)
class CustomerInfo {
  const CustomerInfo({required this.id, required this.email, this.fullName, this.phone});

  final String id;
  final String email;
  final String? fullName;
  final String? phone;

  // "Ho ten - email - so dien thoai" (noi bang dau cham giua), bo phan trong
  String get summary => [
    if (fullName != null && fullName!.trim().isNotEmpty) fullName!.trim(),
    email,
    if (phone != null && phone!.trim().isNotEmpty) phone!.trim(),
  ].where((s) => s.isNotEmpty).join(' · ');

  static CustomerInfo? fromJsonOrNull(Object? json) => json is Map<String, dynamic>
      ? CustomerInfo(
          id: json['id'] as String? ?? '',
          email: json['email'] as String? ?? '',
          fullName: json['fullName'] as String?,
          phone: json['phone'] as String?,
        )
      : null;
}

// Giao dich thanh toan goc cua voucher can hoan
class RefundPayment {
  const RefundPayment({required this.id, required this.amount, this.gateway, this.gatewayTxnId});

  final String id;
  final String? gateway;
  final String? gatewayTxnId;
  final int amount;

  static RefundPayment? fromJsonOrNull(Object? json) => json is Map<String, dynamic>
      ? RefundPayment(
          id: json['id'] as String? ?? '',
          gateway: json['gateway'] as String?,
          gatewayTxnId: json['gatewayTxnId'] as String?,
          amount: asInt(json['amount']),
        )
      : null;
}

// Yeu cau hoan tien cho quan tri vien xac nhan thu cong (FR-REFUND-06, UC-07)
class RefundRequest {
  const RefundRequest({
    required this.id,
    required this.voucherItemId,
    required this.status,
    required this.createdAt,
    this.reason,
    this.statusLabel,
    this.rejectReason,
    this.decidedAt,
    this.amount,
    this.voucherCode,
    this.voucherStatus,
    this.campaignId,
    this.campaignTitle,
    this.customer,
    this.payment,
  });

  final String id;
  final String voucherItemId;
  final String status;
  final DateTime createdAt;
  final String? reason;
  final String? statusLabel;
  final String? rejectReason;
  final DateTime? decidedAt;

  // So tien se hoan cho khach (don gia voucher)
  final int? amount;
  final String? voucherCode;
  final String? voucherStatus;
  final String? campaignId;
  final String? campaignTitle;
  final CustomerInfo? customer;
  final RefundPayment? payment;

  factory RefundRequest.fromJson(Map<String, dynamic> json) => RefundRequest(
    id: json['id'] as String,
    voucherItemId: json['voucherItemId'] as String? ?? '',
    status: json['status'] as String? ?? '',
    createdAt: asDate(json['createdAt']),
    reason: json['reason'] as String?,
    statusLabel: json['statusLabel'] as String?,
    rejectReason: json['rejectReason'] as String?,
    decidedAt: asDateOrNull(json['decidedAt']),
    amount: json['amount'] == null ? null : asInt(json['amount']),
    voucherCode: json['voucherCode'] as String?,
    voucherStatus: json['voucherStatus'] as String?,
    campaignId: json['campaignId'] as String?,
    campaignTitle: json['campaignTitle'] as String?,
    customer: CustomerInfo.fromJsonOrNull(json['customer']),
    payment: RefundPayment.fromJsonOrNull(json['payment']),
  );
}

// Giao dich da nhan cua don lech so tien
class MismatchPayment {
  const MismatchPayment({required this.id, required this.amount, this.gatewayTxnId});

  final String id;
  final String? gatewayTxnId;
  final int amount;

  factory MismatchPayment.fromJson(Map<String, dynamic> json) => MismatchPayment(
    id: json['id'] as String? ?? '',
    gatewayTxnId: json['gatewayTxnId'] as String?,
    amount: asInt(json['amount']),
  );
}

// Don hang co so tien nhan duoc khac so tien phai tra (PAYMENT_MISMATCH) - UC-07
class PaymentMismatchOrder {
  const PaymentMismatchOrder({
    required this.id,
    required this.totalAmount,
    required this.refundedAmount,
    required this.createdAt,
    required this.status,
    this.campaignId,
    this.campaignTitle,
    this.customer,
    this.payments = const [],
  });

  final String id;
  final String? campaignId;
  final String? campaignTitle;
  final CustomerInfo? customer;

  // So tien don phai tra
  final int totalAmount;
  final int refundedAmount;
  final DateTime createdAt;
  final String status;
  final List<MismatchPayment> payments;

  // Tong so tien thuc nhan tu cong thanh toan
  int get receivedAmount => payments.fold(0, (sum, p) => sum + p.amount);

  factory PaymentMismatchOrder.fromJson(Map<String, dynamic> json) => PaymentMismatchOrder(
    id: json['id'] as String,
    campaignId: json['campaignId'] as String?,
    campaignTitle: json['campaignTitle'] as String?,
    customer: CustomerInfo.fromJsonOrNull(json['customer']),
    totalAmount: asInt(json['totalAmount']),
    refundedAmount: asInt(json['refundedAmount']),
    createdAt: asDate(json['createdAt']),
    status: json['status'] as String? ?? 'PAYMENT_MISMATCH',
    payments: asList(json['payments'], MismatchPayment.fromJson),
  );
}
