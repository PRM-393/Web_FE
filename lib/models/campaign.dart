import 'json_utils.dart';

// Vong doi chien dich - SRS muc 6: DRAFT -> PENDING -> APPROVED -> PUBLISHED <-> PAUSED -> ENDED
class CampaignStatus {
  CampaignStatus._();

  static const draft = 'DRAFT';
  static const pending = 'PENDING';
  static const approved = 'APPROVED';
  static const published = 'PUBLISHED';
  static const paused = 'PAUSED';
  static const ended = 'ENDED';
}

// Loai voucher (FR-CAMP-02)
class VoucherType {
  VoucherType._();

  static const discountCode = 'DISCOUNT_CODE';
  static const prepaidValue = 'PREPAID_VALUE';
  static const combo = 'COMBO';

  static const labels = {
    discountCode: 'Mã giảm giá',
    prepaidValue: 'Voucher mệnh giá trả trước',
    combo: 'Combo / gói dịch vụ',
  };
}

class VoucherCampaign {
  const VoucherCampaign({
    required this.id,
    required this.brandId,
    required this.title,
    required this.voucherType,
    required this.salePrice,
    required this.faceValue,
    required this.totalQuantity,
    required this.soldQuantity,
    required this.reservedQuantity,
    required this.limitPerUser,
    required this.saleStartAt,
    required this.saleEndAt,
    required this.voucherExpireAt,
    required this.status,
    this.image,
    this.description,
    this.terms,
    this.discountPercent,
    this.rejectReason,
  });

  final String id;
  final String brandId;
  final String title;
  final String voucherType;
  final double salePrice;
  final double faceValue;
  final int totalQuantity;
  final int soldQuantity;
  final int reservedQuantity;
  final int limitPerUser;
  final DateTime saleStartAt;
  final DateTime saleEndAt;
  final DateTime voucherExpireAt;
  final String status;
  final String? image;
  final String? description;
  final String? terms;
  final double? discountPercent;
  final String? rejectReason;

  int get remaining => totalQuantity - soldQuantity - reservedQuantity;

  // Chi sua noi dung khi con nhap (BR-17 khoa gia/han dung khi da ban, kiem tra lai o may chu)
  bool get canEdit => status == CampaignStatus.draft;
  bool get canSubmit => status == CampaignStatus.draft;
  bool get canPause => status == CampaignStatus.published;
  bool get canResume => status == CampaignStatus.paused;

  factory VoucherCampaign.fromJson(Map<String, dynamic> json) => VoucherCampaign(
        id: json['id'] as String,
        brandId: json['brandId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        voucherType: json['voucherType'] as String? ?? VoucherType.discountCode,
        salePrice: asDouble(json['salePrice']),
        faceValue: asDouble(json['faceValue']),
        totalQuantity: asInt(json['totalQuantity']),
        soldQuantity: asInt(json['soldQuantity']),
        reservedQuantity: asInt(json['reservedQuantity']),
        limitPerUser: asInt(json['limitPerUser'], 5),
        saleStartAt: asDate(json['saleStartAt']),
        saleEndAt: asDate(json['saleEndAt']),
        voucherExpireAt: asDate(json['voucherExpireAt']),
        status: json['status'] as String? ?? CampaignStatus.draft,
        image: json['image'] as String?,
        description: json['description'] as String?,
        terms: json['terms'] as String?,
        discountPercent: asDoubleOrNull(json['discountPercent']),
        rejectReason: json['rejectReason'] as String?,
      );
}

// Du lieu form tao / sua chien dich, khop CreateCampaignDto cua may chu
class CampaignDraft {
  CampaignDraft({
    required this.title,
    required this.voucherType,
    required this.salePrice,
    required this.faceValue,
    required this.totalQuantity,
    required this.limitPerUser,
    required this.saleStartAt,
    required this.saleEndAt,
    required this.voucherExpireAt,
    this.storeIds = const [],
    this.image,
    this.description,
    this.terms,
    this.discountPercent,
  });

  final String title;
  final String voucherType;
  final int salePrice;
  final int faceValue;
  final int totalQuantity;
  final int limitPerUser;
  final DateTime saleStartAt;
  final DateTime saleEndAt;
  final DateTime voucherExpireAt;
  final List<String> storeIds;
  final String? image;
  final String? description;
  final String? terms;
  final double? discountPercent;

  // Thoi gian gui len may chu theo UTC (CON-05); includeStores=false khi sua vi UpdateCampaignDto khong nhan storeIds
  Map<String, dynamic> toJson({bool includeStores = true}) => {
        'title': title,
        'voucherType': voucherType,
        'salePrice': salePrice,
        'faceValue': faceValue,
        'totalQuantity': totalQuantity,
        'limitPerUser': limitPerUser,
        'saleStartAt': saleStartAt.toUtc().toIso8601String(),
        'saleEndAt': saleEndAt.toUtc().toIso8601String(),
        'voucherExpireAt': voucherExpireAt.toUtc().toIso8601String(),
        if (includeStores) 'storeIds': storeIds,
        if (image != null && image!.isNotEmpty) 'image': image,
        if (description != null && description!.isNotEmpty) 'description': description,
        if (terms != null && terms!.isNotEmpty) 'terms': terms,
        if (discountPercent != null) 'discountPercent': discountPercent,
      };
}
