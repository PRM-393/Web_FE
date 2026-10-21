import 'json_utils.dart';

// Noi dung ma QR do app khach hang sinh ra (FR-REDEEM-02, NFR-SEC-02): "v1.<nonce 32 hex>.<expiresAtMs>.<chu ky base64url>".
// Ma khong chua id voucher. Web cua hang gui NGUYEN chuoi (raw) len may chu de kiem chu ky HMAC;
// o day chi tach phan han dung de bao som ma da het han.
class QrPayload {
  const QrPayload({required this.raw, required this.nonce, required this.expiresAt});

  static const version = 'v1';

  // Chuoi QR day du (da bo khoang trang dau / cuoi) gui len POST /redeem
  final String raw;
  final String nonce;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  static final _nonce = RegExp(r'^[0-9a-f]{32}$');
  static final _expires = RegExp(r'^\d{1,15}$');
  static final _signature = RegExp(r'^[A-Za-z0-9_-]+$');

  // Tra ve null neu chuoi quet duoc khong dung dinh dang (sai phien ban, thieu phan, nonce / han / chu ky sai dang)
  static QrPayload? tryParse(String raw) {
    final text = raw.trim();
    final parts = text.split('.');
    if (parts.length != 4 || parts[0] != version) return null;
    if (!_nonce.hasMatch(parts[1]) || !_expires.hasMatch(parts[2]) || !_signature.hasMatch(parts[3])) {
      return null;
    }
    return QrPayload(
      raw: text,
      nonce: parts[1],
      expiresAt: DateTime.fromMillisecondsSinceEpoch(int.parse(parts[2]), isUtc: true),
    );
  }
}

// Ma ly do loi nghiep vu cua POST /redeem (error.reason) - FR-REDEEM-07, FR-REDEEM-12, BR-03, BR-07
class RedeemReason {
  RedeemReason._();

  static const voucherUsed = 'VOUCHER_USED';
  static const wrongStore = 'WRONG_STORE';
  static const voucherExpired = 'VOUCHER_EXPIRED';
  static const tokenExpired = 'TOKEN_EXPIRED';
  static const tokenRevoked = 'TOKEN_REVOKED';
  static const tokenUsed = 'TOKEN_USED';
  static const tokenInvalid = 'TOKEN_INVALID';
  static const refundPending = 'VOUCHER_REFUND_PENDING';
  static const refunded = 'VOUCHER_REFUNDED';
  static const otpInvalid = 'OTP_INVALID';
  static const otpLocked = 'OTP_LOCKED';
  static const billRequired = 'BILL_REQUIRED';
  static const storeNotSelected = 'STORE_NOT_SELECTED';
  static const billEditExpired = 'BILL_EDIT_EXPIRED';
}

// Ly do xac nhan that bai: thong diep cua may chu + ma ly do + du lieu kem theo (de hien "da dung luc ... tai ...")
class RedeemFailure {
  const RedeemFailure(this.message, {this.reason, this.details = const {}});

  final String message;
  final String? reason;
  final Map<String, dynamic> details;
}

// BILL_REQUIRED (BR-03): ma CHUA bi tieu, giu lai QR / OTP vua gui de nhan vien nhap hoa don roi gui lai ngay
class BillRequirement {
  const BillRequirement({required this.message, this.qrPayload, this.otpCode, this.voucherType, this.faceValue});

  final String message;
  final String? qrPayload;
  final String? otpCode;
  final String? voucherType;
  final int? faceValue;
}

// Chien dich cua voucher vua xac nhan
class RedeemCampaign {
  const RedeemCampaign({required this.id, required this.title, required this.voucherType, required this.faceValue});

  final String id;
  final String title;
  final String voucherType;
  final int faceValue;

  factory RedeemCampaign.fromJson(Map<String, dynamic> json) => RedeemCampaign(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        voucherType: json['voucherType'] as String? ?? '',
        faceValue: asInt(json['faceValue']),
      );
}

// Ket qua xac nhan su dung tra ve tu POST /redeem
class RedeemResult {
  const RedeemResult({
    required this.message,
    required this.voucherItemId,
    this.redemptionLogId,
    this.voucherCode,
    this.redeemedAt,
    this.method,
    this.billAmount,
    this.billEditableUntil,
    this.campaign,
  });

  final String message;
  final String voucherItemId;
  final String? redemptionLogId;
  final String? voucherCode;
  final DateTime? redeemedAt;
  final String? method;
  final int? billAmount;
  final DateTime? billEditableUntil;
  final RedeemCampaign? campaign;

  factory RedeemResult.fromJson(Map<String, dynamic> json) => RedeemResult(
        message: json['message'] as String? ?? 'Xác nhận sử dụng thành công.',
        voucherItemId: json['voucherItemId'] as String? ?? '',
        redemptionLogId: json['redemptionLogId'] as String?,
        voucherCode: json['voucherCode'] as String?,
        redeemedAt: asDateOrNull(json['redeemedAt']),
        method: json['method'] as String?,
        billAmount: json['billAmount'] == null ? null : asInt(json['billAmount']),
        billEditableUntil: asDateOrNull(json['billEditableUntil']),
        campaign: json['campaign'] is Map<String, dynamic>
            ? RedeemCampaign.fromJson(json['campaign'] as Map<String, dynamic>)
            : null,
      );
}

// Lich su xac nhan trong ca cua nhan vien (FR-REDEEM-10); sua hoa don trong 10 phut (FR-REDEEM-08)
class RedemptionLog {
  const RedemptionLog({
    required this.id,
    required this.voucherItemId,
    required this.storeId,
    required this.method,
    required this.redeemedAt,
    this.billAmount,
    this.voucherCode,
    this.campaignTitle,
    this.voucherType,
    this.storeName,
    this.billUpdatedAt,
    this.billEditableUntil,
    this.billEditable = false,
  });

  final String id;
  final String voucherItemId;
  final String storeId;
  final String method;
  final DateTime redeemedAt;
  final int? billAmount;
  final String? voucherCode;
  final String? campaignTitle;
  final String? voucherType;
  final String? storeName;
  final DateTime? billUpdatedAt;
  final DateTime? billEditableUntil;
  final bool billEditable;

  factory RedemptionLog.fromJson(Map<String, dynamic> json) => RedemptionLog(
        id: json['id'] as String,
        voucherItemId: json['voucherItemId'] as String? ?? '',
        storeId: json['storeId'] as String? ?? '',
        method: json['method'] as String? ?? 'QR',
        redeemedAt: asDate(json['redeemedAt']),
        billAmount: json['billAmount'] == null ? null : asInt(json['billAmount']),
        voucherCode: json['voucherCode'] as String?,
        campaignTitle: json['campaignTitle'] as String?,
        voucherType: json['voucherType'] as String?,
        storeName: json['storeName'] as String?,
        billUpdatedAt: asDateOrNull(json['billUpdatedAt']),
        billEditableUntil: asDateOrNull(json['billEditableUntil']),
        billEditable: json['billEditable'] == true,
      );
}
