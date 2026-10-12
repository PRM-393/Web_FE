import 'json_utils.dart';

// Noi dung ma QR do app khach hang sinh ra (FR-REDEEM-02): "voucherItemId.nonce.expiresAtMs.signature".
// Web cua hang chi gui nonce len may chu; chu ky va han dung duoc may chu kiem tra lai (NFR-SEC-02).
class QrPayload {
  const QrPayload({required this.voucherItemId, required this.nonce, required this.expiresAt});

  final String voucherItemId;
  final String nonce;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !now.isBefore(expiresAt);

  // Tra ve null neu chuoi quet duoc khong dung dinh dang
  static QrPayload? tryParse(String raw) {
    final parts = raw.trim().split('.');
    if (parts.length != 4 || parts.any((p) => p.isEmpty)) return null;
    final expiresMs = int.tryParse(parts[2]);
    if (expiresMs == null) return null;
    return QrPayload(
      voucherItemId: parts[0],
      nonce: parts[1],
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresMs, isUtc: true),
    );
  }
}

// Ket qua xac nhan su dung tra ve tu POST /redeem
class RedeemResult {
  const RedeemResult({required this.message, required this.voucherItemId, this.redeemedAt});

  final String message;
  final String voucherItemId;
  final DateTime? redeemedAt;

  factory RedeemResult.fromJson(Map<String, dynamic> json) => RedeemResult(
        message: json['message'] as String? ?? 'Xác nhận sử dụng thành công.',
        voucherItemId: json['voucherItemId'] as String? ?? '',
        redeemedAt: asDateOrNull(json['redeemedAt']),
      );
}

// Lich su xac nhan trong ca cua nhan vien (FR-REDEEM-10)
class RedemptionLog {
  const RedemptionLog({
    required this.id,
    required this.voucherItemId,
    required this.storeId,
    required this.method,
    required this.redeemedAt,
    this.billAmount,
  });

  final String id;
  final String voucherItemId;
  final String storeId;
  final String method;
  final DateTime redeemedAt;
  final int? billAmount;

  factory RedemptionLog.fromJson(Map<String, dynamic> json) => RedemptionLog(
        id: json['id'] as String,
        voucherItemId: json['voucherItemId'] as String? ?? '',
        storeId: json['storeId'] as String? ?? '',
        method: json['method'] as String? ?? 'QR',
        redeemedAt: asDate(json['redeemedAt']),
        billAmount: json['billAmount'] == null ? null : asInt(json['billAmount']),
      );
}
