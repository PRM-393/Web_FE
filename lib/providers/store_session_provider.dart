import 'package:flutter/foundation.dart';

import '../models/brand.dart';
import '../models/redeem.dart';
import '../services/portal_services.dart';

// Ca lam viec cua nhan vien cua hang: chi nhanh dang lam (FR-AUTH-12, BR-07), ket qua xac nhan gan nhat,
// lich su trong ngay (FR-REDEEM-10).
class StoreSessionProvider extends ChangeNotifier {
  StoreSessionProvider(this._service);

  final RedeemService _service;

  List<Store> _stores = const [];
  Store? _current;
  bool _loadingStores = false;
  String? _storesError;

  bool _submitting = false;
  RedeemResult? _lastResult;
  String? _lastError;

  List<RedemptionLog> _history = const [];

  List<Store> get stores => _stores;
  Store? get currentStore => _current;
  bool get isLoadingStores => _loadingStores;
  String? get storesError => _storesError;
  bool get isSubmitting => _submitting;
  RedeemResult? get lastResult => _lastResult;
  String? get lastError => _lastError;
  List<RedemptionLog> get history => _history;

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
    // FR-AUTH-12: server binds the selected branch to this session.
    await _service.selectStore(store.id);
    _current = store;
    clearResult();
  }

  void clearResult() {
    _lastResult = null;
    _lastError = null;
    notifyListeners();
  }

  // FR-REDEEM-05/06/07: gui nonce (tu QR) hoac OTP; thanh cong thi tai lai lich su ca
  Future<bool> redeem({String? nonce, String? otpCode, int? billAmount}) async {
    final store = _current;
    if (store == null || _submitting) return false;
    _submitting = true;
    _lastResult = null;
    _lastError = null;
    notifyListeners();
    try {
      _lastResult = await _service.redeem(
        storeId: store.id,
        nonce: nonce,
        otpCode: otpCode,
        billAmount: billAmount,
      );
      await _reloadHistorySilently();
      return true;
    } catch (e) {
      _lastError = e.toString();
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  Future<void> loadHistory() async {
    _history = await _service.historyToday();
    notifyListeners();
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
    _lastError = null;
    notifyListeners();
  }
}
