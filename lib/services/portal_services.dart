import '../models/brand.dart';
import '../models/campaign.dart';
import '../models/finance.dart';
import '../models/json_utils.dart';
import '../models/redeem.dart';
import 'api_client.dart';

// Moi service boc mot nhom endpoint cua Web_BE. Widget khong goi ApiClient truc tiep.

// Ho so thuong hieu, chi nhanh, nhan vien, danh gia - FR-BRAND-*, FR-ENGAGE-04
class BrandService {
  BrandService(this._api);

  final ApiClient _api;

  Future<List<Brand>> myBrands() async =>
      asList(await _api.get('/brands/me'), Brand.fromJson);

  Future<Brand> register({
    required String name,
    String? description,
    String? logo,
    String? contactInfo,
    String? bankInfo,
  }) async {
    final json = await _api.post(
      '/brands',
      body: {
        'name': name,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (logo != null && logo.isNotEmpty) 'logo': logo,
        if (contactInfo != null && contactInfo.isNotEmpty)
          'contactInfo': contactInfo,
        if (bankInfo != null && bankInfo.isNotEmpty) 'bankInfo': bankInfo,
      },
    );
    return Brand.fromJson(json as Map<String, dynamic>);
  }

  // FR-BRAND-01/02: dang ky khi CHUA co tai khoan. Khac `register()` o tren: ham do goi POST /brands,
  // chi dung duoc khi da dang nhap bang vai tro BrandOwner. Ham nay la cua vao cong khai, may chu tao
  // tai khoan PENDING_ACTIVATION roi gui lien ket dat mat khau.
  Future<BrandRegistration> registerPublic({
    required String ownerEmail,
    required String ownerFullName,
    required String name,
    String? ownerPhone,
    String? description,
    String? contactInfo,
    String? bankInfo,
  }) async {
    final json = await _api.post(
      '/brands/register',
      body: {
        'ownerEmail': ownerEmail.trim(),
        'ownerFullName': ownerFullName.trim(),
        'name': name.trim(),
        'ownerPhone': ?_blankToNull(ownerPhone),
        'description': ?_blankToNull(description),
        'contactInfo': ?_blankToNull(contactInfo),
        'bankInfo': ?_blankToNull(bankInfo),
      },
    );
    return BrandRegistration.fromJson(json as Map<String, dynamic>);
  }

  static String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  Future<List<Store>> stores(String brandId) async =>
      asList(await _api.get('/brands/$brandId/stores'), Store.fromJson);

  Future<void> createStore(
    String brandId, {
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? phone,
    String? openingHours,
  }) => _api.post(
    '/brands/$brandId/stores',
    body: {
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (openingHours != null && openingHours.isNotEmpty)
        'openingHours': openingHours,
    },
  );

  // FR-BRAND-04: sua chi nhanh. Chi gui cac truong co thay doi; status = true de mo lai chi nhanh
  // da vo hieu (may chu doi hoi co toa do moi cho mo lai - DC-05).
  Future<void> updateStore(
    String storeId, {
    String? name,
    String? address,
    double? latitude,
    double? longitude,
    String? phone,
    String? openingHours,
    bool? status,
  }) => _api.patch(
    '/brands/stores/$storeId',
    body: {
      'name': ?name,
      'address': ?address,
      'latitude': ?latitude,
      'longitude': ?longitude,
      'phone': ?phone,
      'openingHours': ?openingHours,
      'status': ?status,
    },
  );

  Future<void> deactivateStore(String storeId) =>
      _api.patch('/brands/stores/$storeId/deactivate');

  Future<List<StaffMember>> staff(String brandId) async =>
      asList(await _api.get('/brands/$brandId/staff'), StaffMember.fromJson);

  Future<void> assignStaff({required String email, required String storeId}) =>
      _api.post('/brands/staff', body: {'email': email, 'storeId': storeId});

  Future<void> deactivateStaff(String assignmentId) =>
      _api.patch('/brands/staff/$assignmentId/deactivate');

  Future<List<Review>> reviews(String brandId) async =>
      asList(await _api.get('/brands/$brandId/reviews'), Review.fromJson);

  Future<void> replyReview(String reviewId, String reply) =>
      _api.patch('/reviews/$reviewId/reply', body: {'reply': reply});

  Future<BrandReport> report(
    String brandId, {
    Map<String, Object?>? query,
  }) async => BrandReport.fromJson(
    await _api.get('/brands/$brandId/report', query: query)
        as Map<String, dynamic>,
  );

  Future<List<Settlement>> settlements(String brandId) async => asList(
    await _api.get('/brands/$brandId/settlements'),
    Settlement.fromJson,
  );

  // FR-SETTLE-08: chi tiet phieu kem tung dong voucher. May chu chi tra phieu cua chinh thuong hieu
  // dang dang nhap (BrandResourceGuard), nen khong can loc them o day.
  Future<SettlementDetail> settlementDetail(String id) async =>
      SettlementDetail.fromJson(await _api.get('/settlements/$id') as Map<String, dynamic>);
}

// Chien dich voucher cua thuong hieu - FR-CAMP-*
class CampaignService {
  CampaignService(this._api);

  final ApiClient _api;

  Future<List<VoucherCampaign>> byBrand(String brandId) async => asList(
    await _api.get('/campaigns/brand/$brandId'),
    VoucherCampaign.fromJson,
  );

  Future<void> create(String brandId, CampaignDraft draft) =>
      _api.post('/campaigns/brand/$brandId', body: draft.toJson());

  Future<void> update(String id, CampaignDraft draft) =>
      _api.patch('/campaigns/$id', body: draft.toJson(includeStores: false));

  Future<void> submit(String id) => _api.patch('/campaigns/$id/submit');

  Future<void> pause(String id) => _api.patch('/campaigns/$id/pause');

  Future<void> resume(String id) => _api.patch('/campaigns/$id/resume');

  // FR-CAMP-15: mo lai chien dich da ket thuc -> may chu dua ve DRAFT de sua ngay ban roi gui duyet lai
  Future<void> reopen(String id) => _api.patch('/campaigns/$id/reopen');

  // FR-CAMP-11: ton kho con lai theo thoi gian thuc, doc lai rieng mot chien dich
  // ma khong phai tai lai ca danh sach
  Future<CampaignStock> stock(String id) async =>
      CampaignStock.fromJson(await _api.get('/campaigns/$id/stock') as Map<String, dynamic>);
}

// Xac nhan su dung voucher tai cua hang - FR-REDEEM-05..10, FR-AUTH-12
class RedeemService {
  RedeemService(this._api);

  final ApiClient _api;

  Future<List<Store>> myStores() async =>
      asList(await _api.get('/redeem/my-stores'), Store.fromJson);

  // FR-AUTH-12: may chu gan chi nhanh vao phien; chua chon thi POST /redeem bi tu choi (STORE_NOT_SELECTED)
  Future<void> selectStore(String storeId) =>
      _api.post('/auth/select-store', body: {'storeId': storeId});

  // FR-REDEEM-05/06: gui DUNG MOT trong hai - nguyen chuoi QR (may chu kiem chu ky) hoac OTP 6 so
  Future<RedeemResult> redeem({
    required String storeId,
    String? qrPayload,
    String? otpCode,
    int? billAmount,
  }) async {
    if ((qrPayload == null) == (otpCode == null)) {
      throw ArgumentError('Cần gửi đúng một trong hai: qrPayload hoặc otpCode.');
    }
    final json = await _api.post(
      '/redeem',
      body: {
        'storeId': storeId,
        'qrPayload': ?qrPayload,
        'otpCode': ?otpCode,
        'billAmount': ?billAmount,
      },
    );
    return RedeemResult.fromJson(json as Map<String, dynamic>);
  }

  Future<List<RedemptionLog>> historyToday() async =>
      asList(await _api.get('/redeem/history/today'), RedemptionLog.fromJson);

  // FR-REDEEM-08: sua gia tri hoa don trong 10 phut sau khi xac nhan, tra ve dong lich su da cap nhat
  Future<RedemptionLog> updateBill(String logId, int billAmount) async =>
      RedemptionLog.fromJson(
        await _api.patch('/redeem/logs/$logId/bill', body: {'billAmount': billAmount})
            as Map<String, dynamic>,
      );
}

// Chuc nang quan tri - UC-04, UC-05, FR-REPORT-03/04, FR-SETTLE-01/07, FR-REFUND-06
class AdminService {
  Future<List<Map<String, dynamic>>> categories() async => (await _api.get('/admin/categories') as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  Future<void> saveCategory(String name, {String? id}) async {
    if (id == null) { await _api.post('/admin/categories', body: {'name': name}); }
    else { await _api.patch('/admin/categories/$id', body: {'name': name}); }
  }
  Future<void> deleteCategory(String id) => _api.delete('/admin/categories/$id');
  AdminService(this._api);

  final ApiClient _api;

  Future<AdminDashboard> dashboard({Map<String, Object?>? query}) async =>
      AdminDashboard.fromJson(
        await _api.get('/admin/dashboard', query: query)
            as Map<String, dynamic>,
      );

  Future<List<Brand>> pendingBrands() async =>
      asList(await _api.get('/admin/pending/brands'), Brand.fromJson);

  Future<void> approveBrand(String id) => _api.patch('/brands/$id/approve');

  Future<void> rejectBrand(String id, String reason) =>
      _api.patch('/brands/$id/reject', body: {'reason': reason});

  // FR-BRAND-09: thuong hieu theo trang thai (APPROVED / SUSPENDED ...)
  Future<List<Brand>> brandsByStatus(String status) async =>
      asList(await _api.get('/brands', query: {'status': status}), Brand.fromJson);

  // Dinh chi: chien dich dang ban chuyen tam dung; khoi phuc: thuong hieu hoat dong lai
  Future<void> suspendBrand(String id, String reason) =>
      _api.patch('/brands/$id/suspend', body: {'reason': reason});

  Future<void> reinstateBrand(String id) => _api.patch('/brands/$id/reinstate');

  Future<List<VoucherCampaign>> pendingCampaigns() async => asList(
    await _api.get('/admin/pending/campaigns'),
    VoucherCampaign.fromJson,
  );

  Future<void> approveCampaign(String id) =>
      _api.patch('/campaigns/$id/approve');

  Future<void> rejectCampaign(String id, String reason) =>
      _api.patch('/campaigns/$id/reject', body: {'reason': reason});

  // FR-SETTLE-01: ty le hoa hong chung kem lan thay doi gan nhat
  Future<CommissionRateInfo> commissionRate() async =>
      CommissionRateInfo.fromJson(await _api.get('/admin/commission-rate') as Map<String, dynamic>);

  // rate la ty le 0..1 (man hinh nhap theo phan tram roi quy doi), may chu kiem lai 0 < rate < 1
  Future<void> setCommissionRate(double rate) => _api.post('/admin/commission-rate', body: {'rate': rate});

  Future<List<Settlement>> settlements() async =>
      asList(await _api.get('/admin/settlements'), Settlement.fromJson);

  // Chot doi soat cho mot ky (thang), thoi gian gui theo UTC
  Future<int> runSettlement(DateTime periodStart, DateTime periodEnd) async {
    final json = await _api.post(
      '/admin/settlements/run',
      body: {
        'periodStart': periodStart.toUtc().toIso8601String(),
        'periodEnd': periodEnd.toUtc().toIso8601String(),
      },
    );
    return json is List ? json.length : 0;
  }

  // FR-SETTLE-07: may chu bat buoc CA ngay chuyen lan ma giao dich, va tu choi ngay o tuong lai.
  // paidAt gui theo UTC; man hinh cho chon ngay theo lich Viet Nam.
  Future<void> markSettlementPaid(String id, String bankTxnRef, DateTime paidAt) => _api.patch(
    '/admin/settlements/$id/mark-paid',
    body: {'bankTxnRef': bankTxnRef.trim(), 'paidAt': paidAt.toUtc().toIso8601String()},
  );

  Future<SettlementDetail> settlementDetail(String id) async =>
      SettlementDetail.fromJson(await _api.get('/settlements/$id') as Map<String, dynamic>);

  // UC-07: hang doi hoan tien thu cong (cong thanh toan khong hoan tu dong duoc)
  Future<List<RefundRequest>> manualPendingRefunds() async =>
      asList(await _api.get('/refunds/manual-pending'), RefundRequest.fromJson);

  // Da hoan tay: bat buoc ma giao dich hoan; may chu chan tong tien hoan vuot giao dich da nhan (DC-12)
  Future<void> confirmManualRefund(String id, String gatewayRefundId) =>
      _api.patch(
        '/refunds/$id/confirm-manual',
        body: {'gatewayRefundId': gatewayRefundId.trim()},
      );

  // Khong hoan duoc: yeu cau chuyen FAILED, voucher duoc khoi phuc cho khach
  Future<void> failManualRefund(String id, String reason) =>
      _api.patch('/refunds/$id/fail-manual', body: {'reason': reason.trim()});

  // UC-07: don thanh toan lech so tien, cho quan tri vien hoan lai thu cong
  Future<List<PaymentMismatchOrder>> paymentMismatches() async => asList(
    await _api.get('/admin/payment-mismatches'),
    PaymentMismatchOrder.fromJson,
  );

  Future<void> confirmMismatchRefund(String orderId, String gatewayRefundId) =>
      _api.patch(
        '/admin/payment-mismatches/$orderId/confirm-refund',
        body: {'gatewayRefundId': gatewayRefundId.trim()},
      );

  // FR-ENGAGE-05: danh sach danh gia de kiem duyet, loc theo trang thai / thuong hieu, co phan trang
  Future<PageResult<Review>> reviews({
    String? status,
    String? brandId,
    int page = 1,
    int pageSize = 20,
  }) async => PageResult.fromJson(
    await _api.get(
      '/admin/reviews',
      query: {
        'status': status,
        'brandId': brandId,
        'page': page,
        'pageSize': pageSize,
      },
    ),
    Review.fromJson,
  );

  // An danh gia vi pham: bat buoc ly do (ghi AuditLog); tra ve danh gia + diem trung binh moi cua chien dich
  Future<ReviewModeration> hideReview(String id, String reason) async =>
      ReviewModeration.fromJson(
        await _api.patch('/admin/reviews/$id/hide', body: {'reason': reason.trim()})
            as Map<String, dynamic>,
      );

  Future<ReviewModeration> unhideReview(String id) async =>
      ReviewModeration.fromJson(
        await _api.patch('/admin/reviews/$id/unhide') as Map<String, dynamic>,
      );
}
