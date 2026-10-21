import 'package:flutter/foundation.dart';

import '../models/brand.dart';
import '../models/json_utils.dart';
import '../models/redeem.dart';
import '../services/api_client.dart';
import '../services/portal_services.dart';

// Ca lam viec cua nhan vien cua hang: chi nhanh dang lam (FR-AUTH-12, BR-07), ket qua xac nhan gan nhat,
// lich su trong ngay (FR-REDEEM-10).
class StoreSessionProvider extends ChangeNotifier {
  StoreSessionProvider(this._service);

  final RedeemService _service;

  // FR-REDEEM-12: thieu thoi diem mo khoa tu may chu thi khoa theo mac dinh 15 phut
  static const defaultOtpLock = Duration(minutes: 15);

  List<Store> _stores = const [];
  Store? _current;
  bool _loadingStores = false;
  String? _storesError;

  bool _submitting = false;
  RedeemResult? _lastResult;
  RedeemFailure? _lastFailure;
  BillRequirement? _billRequirement;
  DateTime? _otpLockedUntil;

  List<RedemptionLog> _history = const [];

  List<Store> get stores => _stores;
  Store? get currentStore => _current;
  bool get isLoadingStores => _loadingStores;
  String? get storesError => _storesError;
  bool get isSubmitting => _submitting;
  RedeemResult? get lastResult => _lastResult;
  RedeemFailure? get lastFailure => _lastFailure;
  String? get lastError => _lastFailure?.message;
  BillRequirement? get billRequirement => _billRequirement;
  DateTime? get otpLockedUntil => _otpLockedUntil;
  List<RedemptionLog> get history => _history;

  bool isOtpLocked(DateTime now) => _otpLockedUntil != null && now.isBefore(_otpLockedUntil!);

  Future<void> loadStores() async {
    _loadingStores = true;
    _storesError = null;
    notifyListeners();
    try {
      _stores = (await _service.myStores()).where((s) => s.active).toList();
      // Chi duoc gan mot chi nhanh thi chon luon
      if (_stores.length == 1) await selectStore(_stores.first);
      if (_current != null && !_stores.any((s) => s.id == _current!.id)) {
        _current = null;
      }
    } catch (e) {
      _storesError = e.toString();
    } finally {
      _loadingStores = false;
      notifyListeners();
    }
  }

  Future<void> selectStore(Store store) async {
    // FR-AUTH-12: may chu gan chi nhanh vao phien (POST /auth/select-store) truoc khi cho redeem
    await _service.selectStore(store.id);
    _current = store;
    clearResult();
  }

  void clearResult() {
    _lastResult = null;
    _lastFailure = null;
    _billRequirement = null;
    notifyListeners();
  }

  // FR-REDEEM-05: kiem tra nhanh dinh dang + han cua chuoi QR roi gui NGUYEN chuoi len may chu (kiem chu ky)
  Future<bool> redeemQr(String raw, {int? billAmount}) async {
    if (_current == null || _submitting) return false;
    final payload = QrPayload.tryParse(raw);
    if (payload == null) {
      return _failLocally(RedeemReason.tokenInvalid, 'Mã QR không đúng định dạng của hệ thống.');
    }
    if (payload.isExpired(DateTime.now().toUtc())) {
      return _failLocally(RedeemReason.tokenExpired, 'Mã QR đã hết hạn, nhờ khách làm mới mã trên ứng dụng.');
    }
    return redeem(qrPayload: payload.raw, billAmount: billAmount);
  }

  // BR-03: gui lai dung ma vua bi BILL_REQUIRED, lan nay kem gia tri hoa don
  Future<bool> resubmitWithBill(int billAmount) async {
    final pending = _billRequirement;
    if (pending == null) return false;
    return redeem(qrPayload: pending.qrPayload, otpCode: pending.otpCode, billAmount: billAmount);
  }

  // FR-REDEEM-05/06/07: gui mot trong hai (chuoi QR hoac OTP); thanh cong thi tai lai lich su ca
  Future<bool> redeem({String? qrPayload, String? otpCode, int? billAmount}) async {
    final store = _current;
    if (store == null || _submitting) return false;
    if ((qrPayload == null) == (otpCode == null)) return false;
    // FR-REDEEM-12: o nhap OTP dang bi khoa thi khong gui, van quet QR duoc
    if (otpCode != null && isOtpLocked(DateTime.now())) return false;
    _submitting = true;
    _lastResult = null;
    _lastFailure = null;
    _billRequirement = null;
    notifyListeners();
    try {
      _lastResult = await _service.redeem(
        storeId: store.id,
        qrPayload: qrPayload,
        otpCode: otpCode,
        billAmount: billAmount,
      );
      await _reloadHistorySilently();
      return true;
    } on ApiException catch (e) {
      final details = e.details ?? const <String, dynamic>{};
      switch (e.reason) {
        case RedeemReason.billRequired:
          // Ma chua bi tieu: giu lai de gui lai kem hoa don, khong phai ket qua cuoi
          _billRequirement = BillRequirement(
            message: e.message,
            qrPayload: qrPayload,
            otpCode: otpCode,
            voucherType: details['voucherType'] as String?,
            faceValue: details['faceValue'] == null ? null : asInt(details['faceValue']),
          );
        case RedeemReason.otpLocked:
          _otpLockedUntil = asDateOrNull(details['lockedUntil']) ?? DateTime.now().toUtc().add(defaultOtpLock);
        default:
          _lastFailure = RedeemFailure(e.message, reason: e.reason, details: details);
      }
      return false;
    } catch (e) {
      _lastFailure = RedeemFailure(e.toString());
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  // O nhap OTP het thoi gian khoa
  void clearOtpLockIfExpired(DateTime now) {
    if (_otpLockedUntil != null && !isOtpLocked(now)) {
      _otpLockedUntil = null;
      notifyListeners();
    }
  }

  bool _failLocally(String reason, String message) {
    _lastResult = null;
    _billRequirement = null;
    _lastFailure = RedeemFailure(message, reason: reason);
    notifyListeners();
    return false;
  }

  Future<void> loadHistory() async {
    _history = await _service.historyToday();
    notifyListeners();
  }

  // FR-REDEEM-08: sua hoa don trong 10 phut; het han (BILL_EDIT_EXPIRED) thi tai lai lich su de an nut sua
  Future<void> updateBill(String logId, int billAmount) async {
    try {
      final updated = await _service.updateBill(logId, billAmount);
      _history = [for (final log in _history) log.id == updated.id ? updated : log];
      notifyListeners();
    } on ApiException catch (e) {
      if (e.reason == RedeemReason.billEditExpired) {
        await _reloadHistorySilently();
        notifyListeners();
      }
      rethrow;
    }
  }

  Future<void> _reloadHistorySilently() async {
    try {
      _history = await _service.historyToday();
    } catch (_) {
      // lich su se duoc tai lai khi mo man Lich su
    }
  }

  void reset() {
    _stores = const [];
    _current = null;
    _history = const [];
    _lastResult = null;
    _lastFailure = null;
    _billRequirement = null;
    _otpLockedUntil = null;
    notifyListeners();
  }
}
