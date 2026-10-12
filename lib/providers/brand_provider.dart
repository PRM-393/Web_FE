import 'package:flutter/foundation.dart';

import '../models/brand.dart';
import '../services/portal_services.dart';

// Thuong hieu dang quan ly va danh sach chi nhanh, dung chung cho cac man cua portal thuong hieu.
// Moi chu thuong hieu quan ly mot ho so (lay ho so dau tien cua GET /brands/me).
class BrandProvider extends ChangeNotifier {
  BrandProvider(this._service);

  final BrandService _service;

  Brand? _brand;
  List<Store> _stores = const [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  Brand? get brand => _brand;
  List<Store> get stores => _stores;
  List<Store> get activeStores => _stores.where((s) => s.active).toList();
  bool get isLoading => _loading;
  bool get isLoaded => _loaded;
  String? get error => _error;
  bool get hasBrand => _brand != null;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final brands = await _service.myBrands();
      _brand = brands.isEmpty ? null : brands.first;
      _stores = _brand == null ? const [] : await _service.stores(_brand!.id);
      _loaded = true;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Chi tai khi chua co du lieu (cac man goi trong initState)
  Future<void> ensureLoaded() => _loaded || _loading ? Future.value() : load();

  // FR-BRAND-01/02: gui ho so, cho quan tri vien duyet
  Future<void> register({
    required String name,
    String? description,
    String? logo,
    String? contactInfo,
    String? bankInfo,
  }) async {
    _brand = await _service.register(
      name: name,
      description: description,
      logo: logo,
      contactInfo: contactInfo,
      bankInfo: bankInfo,
    );
    notifyListeners();
  }

  Future<void> reloadStores() async {
    if (_brand == null) return;
    _stores = await _service.stores(_brand!.id);
    notifyListeners();
  }

  // Goi khi dang xuat de nguoi dang nhap sau khong thay du lieu cu
  void reset() {
    _brand = null;
    _stores = const [];
    _loaded = false;
    _error = null;
    notifyListeners();
  }
}
