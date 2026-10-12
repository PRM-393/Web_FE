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

  Future<List<Brand>> myBrands() async => asList(await _api.get('/brands/me'), Brand.fromJson);

  Future<Brand> register({
    required String name,
    String? description,
    String? logo,
    String? contactInfo,
    String? bankInfo,
  }) async {
    final json = await _api.post('/brands', body: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      if (logo != null && logo.isNotEmpty) 'logo': logo,
      if (contactInfo != null && contactInfo.isNotEmpty) 'contactInfo': contactInfo,
      if (bankInfo != null && bankInfo.isNotEmpty) 'bankInfo': bankInfo,
    });
    return Brand.fromJson(json as Map<String, dynamic>);
  }

  Future<List<Store>> stores(String brandId) async => asList(await _api.get('/brands/$brandId/stores'), Store.fromJson);

  Future<void> createStore(
    String brandId, {
    required String name,
    required String address,
    required double latitude,
    required double longitude,
    String? phone,
    String? openingHours,
  }) =>
      _api.post('/brands/$brandId/stores', body: {
        'name': name,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (openingHours != null && openingHours.isNotEmpty) 'openingHours': openingHours,
      });

  Future<void> deactivateStore(String storeId) => _api.patch('/brands/stores/$storeId/deactivate');

  Future<List<StaffMember>> staff(String brandId) async =>
      asList(await _api.get('/brands/$brandId/staff'), StaffMember.fromJson);

  Future<void> assignStaff({required String email, required String storeId}) =>
      _api.post('/brands/staff', body: {'email': email, 'storeId': storeId});

  Future<void> deactivateStaff(String assignmentId) => _api.patch('/brands/staff/$assignmentId/deactivate');

  Future<List<Review>> reviews(String brandId) async =>
      asList(await _api.get('/brands/$brandId/reviews'), Review.fromJson);

  Future<void> replyReview(String reviewId, String reply) =>
      _api.patch('/reviews/$reviewId/reply', body: {'reply': reply});

  Future<BrandReport> report(String brandId) async =>
      BrandReport.fromJson(await _api.get('/brands/$brandId/report') as Map<String, dynamic>);

  Future<List<Settlement>> settlements(String brandId) async =>
      asList(await _api.get('/brands/$brandId/settlements'), Settlement.fromJson);
}

// Chien dich voucher cua thuong hieu - FR-CAMP-*
class CampaignService {
  CampaignService(this._api);

  final ApiClient _api;

  Future<List<VoucherCampaign>> byBrand(String brandId) async =>
      asList(await _api.get('/campaigns/brand/$brandId'), VoucherCampaign.fromJson);

  Future<void> create(String brandId, CampaignDraft draft) =>
      _api.post('/campaigns/brand/$brandId', body: draft.toJson());

  Future<void> update(String id, CampaignDraft draft) =>
      _api.patch('/campaigns/$id', body: draft.toJson(includeStores: false));

  Future<void> submit(String id) => _api.patch('/campaigns/$id/submit');

  Future<void> pause(String id) => _api.patch('/campaigns/$id/pause');

  Future<void> resume(String id) => _api.patch('/campaigns/$id/resume');
}

// Xac nhan su dung voucher tai cua hang - FR-REDEEM-05..10, FR-AUTH-12
class RedeemService {
  RedeemService(this._api);

  final ApiClient _api;

  Future<List<Store>> myStores() async => asList(await _api.get('/redeem/my-stores'), Store.fromJson);

  Future<RedeemResult> redeem({required String storeId, String? nonce, String? otpCode, int? billAmount}) async {
    final json = await _api.post('/redeem', body: {
      'storeId': storeId,
      'nonce': ?nonce,
      'otpCode': ?otpCode,
      'billAmount': ?billAmount,
    });
    return RedeemResult.fromJson(json as Map<String, dynamic>);
  }

  Future<List<RedemptionLog>> historyToday() async =>
      asList(await _api.get('/redeem/history/today'), RedemptionLog.fromJson);
}

// Chuc nang quan tri - UC-04, UC-05, FR-REPORT-03/04, FR-SETTLE-01/07, FR-REFUND-06
class AdminService {
  AdminService(this._api);

  final ApiClient _api;

  Future<AdminDashboard> dashboard() async =>
      AdminDashboard.fromJson(await _api.get('/admin/dashboard') as Map<String, dynamic>);

  Future<List<Brand>> pendingBrands() async => asList(await _api.get('/admin/pending/brands'), Brand.fromJson);

  Future<void> approveBrand(String id) => _api.patch('/brands/$id/approve');

  Future<void> rejectBrand(String id, String reason) => _api.patch('/brands/$id/reject', body: {'reason': reason});

  Future<List<VoucherCampaign>> pendingCampaigns() async =>
      asList(await _api.get('/admin/pending/campaigns'), VoucherCampaign.fromJson);

  Future<void> approveCampaign(String id) => _api.patch('/campaigns/$id/approve');

  Future<void> rejectCampaign(String id, String reason) =>
      _api.patch('/campaigns/$id/reject', body: {'reason': reason});

  Future<double> commissionRate() async {
    final json = await _api.get('/admin/commission-rate') as Map<String, dynamic>;
    return asDouble(json['rate']);
  }

  Future<void> setCommissionRate(double rate) => _api.post('/admin/commission-rate', body: {'rate': rate});

  Future<List<Settlement>> settlements() async => asList(await _api.get('/admin/settlements'), Settlement.fromJson);

  // Chot doi soat cho mot ky (thang), thoi gian gui theo UTC
  Future<int> runSettlement(DateTime periodStart, DateTime periodEnd) async {
    final json = await _api.post('/admin/settlements/run', body: {
      'periodStart': periodStart.toUtc().toIso8601String(),
      'periodEnd': periodEnd.toUtc().toIso8601String(),
    });
    return json is List ? json.length : 0;
  }

  Future<void> markSettlementPaid(String id, String bankTxnRef) =>
      _api.patch('/admin/settlements/$id/mark-paid', body: {'bankTxnRef': bankTxnRef});

  Future<List<RefundRequest>> manualPendingRefunds() async =>
      asList(await _api.get('/refunds/manual-pending'), RefundRequest.fromJson);

  Future<void> confirmManualRefund(String id) => _api.patch('/refunds/$id/confirm-manual');
}
