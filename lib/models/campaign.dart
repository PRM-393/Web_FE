import 'json_utils.dart';

// Vong doi chien dich - SRS 6.1: DRAFT -> PENDING -> APPROVED -> PUBLISHED <-> PAUSED / SOLD_OUT -> ENDED
class CampaignStatus {
  CampaignStatus._();

  static const draft = 'DRAFT';
  static const pending = 'PENDING';
  static const approved = 'APPROVED';
  static const published = 'PUBLISHED';
  static const soldOut = 'SOLD_OUT';
  static const paused = 'PAUSED';
  static const ended = 'ENDED';
}

// Loai voucher (FR-CAMP-02)
class VoucherType {
  VoucherType._();

  static const discount = 'DISCOUNT';
  static const prepaid = 'PREPAID';
  static const combo = 'COMBO';

  static const labels = {
    discount: 'Mã giảm giá',
    prepaid: 'Voucher mệnh giá trả trước',
    combo: 'Combo / gói dịch vụ',
  };
}

// Kieu giam cua ma giam gia (FR-CAMP-12)
class DiscountType {
  DiscountType._();

  static const amount = 'AMOUNT';
  static const percent = 'PERCENT';

  static const labels = {amount: 'Giảm theo số tiền', percent: 'Giảm theo phần trăm'};
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
    this.categoryId,
    this.discountType,
    this.discountValue,
    this.maxDiscount,
    this.comboItems,
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
  final String? categoryId;
  final String? discountType;
  final int? discountValue;
  final int? maxDiscount;
  final String? comboItems;
  final String? rejectReason;

  int get remaining => totalQuantity - soldQuantity - reservedQuantity;

  // Chi sua noi dung khi con nhap (BR-17 khoa gia/han dung khi da ban, kiem tra lai o may chu)
  bool get canEdit => status == CampaignStatus.draft;
  bool get canSubmit => status == CampaignStatus.draft;
  bool get canPause => status == CampaignStatus.published;
  bool get canResume => status == CampaignStatus.paused;

  // FR-CAMP-15: chien dich het thoi gian ban duoc mo lai ve nhap de sua ngay roi gui duyet lai.
  // Khong co loi nay thi ENDED la het duong quay lai, phai tao chien dich moi tu dau.
  bool get canReopen => status == CampaignStatus.ended;

  factory VoucherCampaign.fromJson(Map<String, dynamic> json) => VoucherCampaign(
        id: json['id'] as String,
        brandId: json['brandId'] as String? ?? '',
        title: json['title'] as String? ?? '',
        voucherType: json['voucherType'] as String? ?? VoucherType.discount,
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
        categoryId: json['categoryId'] as String?,
        discountType: json['discountType'] as String?,
        discountValue: json['discountValue'] == null ? null : asInt(json['discountValue']),
        maxDiscount: json['maxDiscount'] == null ? null : asInt(json['maxDiscount']),
        comboItems: json['comboItems'] as String?,
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
    this.discountType,
    this.discountValue,
    this.maxDiscount,
    this.comboItems,
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
  final String? discountType;
  final int? discountValue;
  final int? maxDiscount;
  final String? comboItems;

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
        if (discountType != null) 'discountType': discountType,
        if (discountValue != null) 'discountValue': discountValue,
        if (maxDiscount != null) 'maxDiscount': maxDiscount,
        if (comboItems != null && comboItems!.isNotEmpty) 'comboItems': comboItems,
      };
}

// FR-CAMP-11: ton kho con lai theo thoi gian thuc (GET /campaigns/:id/stock).
// Tach khoi VoucherCampaign vi day la so doc lai lien tuc, khong phai thong tin cau hinh chien dich.
class CampaignStock {
  const CampaignStock({
    required this.totalQuantity,
    required this.soldQuantity,
    required this.reservedQuantity,
    required this.available,
  });

  final int totalQuantity;
  final int soldQuantity;
  final int reservedQuantity;

  // DC-03: totalQuantity - soldQuantity - reservedQuantity
  final int available;

  factory CampaignStock.fromJson(Map<String, dynamic> json) => CampaignStock(
        totalQuantity: asInt(json['totalQuantity']),
        soldQuantity: asInt(json['soldQuantity']),
        reservedQuantity: asInt(json['reservedQuantity']),
        available: asInt(json['available'] ?? json['remaining']),
      );
}
