import 'json_utils.dart';

// Trang thai ho so thuong hieu - SRS muc 6
class BrandStatus {
  BrandStatus._();

  static const pending = 'PENDING';
  static const approved = 'APPROVED';
  static const rejected = 'REJECTED';
}

// Ho so thuong hieu (FR-BRAND-01..03)
class Brand {
  const Brand({
    required this.id,
    required this.name,
    required this.status,
    this.logo,
    this.description,
    this.contactInfo,
    this.bankInfo,
    this.rejectReason,
  });

  final String id;
  final String name;
  final String status;
  final String? logo;
  final String? description;
  final String? contactInfo;
  final String? bankInfo;
  final String? rejectReason;

  bool get isApproved => status == BrandStatus.approved;

  factory Brand.fromJson(Map<String, dynamic> json) => Brand(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        status: json['status'] as String? ?? BrandStatus.pending,
        logo: json['logo'] as String?,
        description: json['description'] as String?,
        contactInfo: json['contactInfo'] as String?,
        bankInfo: json['bankInfo'] as String?,
        rejectReason: json['rejectReason'] as String?,
      );
}

// Chi nhanh cua thuong hieu (FR-BRAND-04, DC-05)
class Store {
  const Store({
    required this.id,
    required this.brandId,
    required this.name,
    required this.address,
    required this.active,
    this.latitude,
    this.longitude,
    this.phone,
    this.openingHours,
  });

  final String id;
  final String brandId;
  final String name;
  final String address;
  final bool active;
  final double? latitude;
  final double? longitude;
  final String? phone;
  final String? openingHours;

  factory Store.fromJson(Map<String, dynamic> json) => Store(
        id: json['id'] as String,
        brandId: json['brandId'] as String? ?? '',
        name: json['name'] as String? ?? '',
        address: json['address'] as String? ?? '',
        active: json['status'] as bool? ?? true,
        latitude: asDoubleOrNull(json['latitude']),
        longitude: asDoubleOrNull(json['longitude']),
        phone: json['phone'] as String?,
        openingHours: json['openingHours'] as String?,
      );
}

// Nhan vien duoc gan vao chi nhanh (FR-BRAND-05/06) - phan hoi cua GET /brands/:id/staff
class StaffMember {
  const StaffMember({
    required this.assignmentId,
    required this.email,
    required this.storeId,
    required this.active,
    this.storeName,
    this.fullName,
    this.assignedAt,
  });

  final String assignmentId;
  final String email;
  final String storeId;
  final bool active;
  final String? storeName;
  final String? fullName;
  final DateTime? assignedAt;

  factory StaffMember.fromJson(Map<String, dynamic> json) => StaffMember(
        assignmentId: json['id'] as String,
        email: json['email'] as String? ?? '',
        storeId: json['storeId'] as String? ?? '',
        active: json['active'] as bool? ?? true,
        storeName: json['storeName'] as String?,
        fullName: json['fullName'] as String?,
        assignedAt: asDateOrNull(json['assignedAt']),
      );
}

// Danh gia cua khach hang va phan hoi cua thuong hieu (FR-ENGAGE-02..05)
class Review {
  const Review({
    required this.id,
    required this.rating,
    required this.createdAt,
    this.comment,
    this.brandReply,
  });

  final String id;
  final int rating;
  final DateTime createdAt;
  final String? comment;
  final String? brandReply;

  bool get hasReply => brandReply != null && brandReply!.isNotEmpty;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] as String,
        rating: asInt(json['rating']),
        createdAt: asDate(json['createdAt']),
        comment: json['comment'] as String?,
        brandReply: json['brandReply'] as String?,
      );
}
