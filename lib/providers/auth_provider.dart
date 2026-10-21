import 'package:flutter/foundation.dart';

import '../models/auth_user.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/token_storage.dart';

// Vai tro duoc dung web (FR-AUTH-07). Khach hang dung app di dong.
class Roles {
  Roles._();

  static const brandOwner = 'BRAND_OWNER';
  static const storeStaff = 'STORE_STAFF';
  static const admin = 'ADMIN';

  static const webRoles = {brandOwner, storeStaff, admin};
}

// Trang thai dang nhap toan web (Provider + ChangeNotifier).
// Phien duoc khoi phuc khi tai lai trang; het han access token thi tu lam moi bang refresh token.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    required ApiClient api,
    required this._authService,
    required this._storage,
  }) {
    api.accessTokenGetter = () => _session?.accessToken;
    api.onUnauthorized = _refreshSession;
  }

  final AuthService _authService;
  final TokenStorage _storage;

  LoginResponse? _session;
  Future<bool>? _refreshing;
  int _generation = 0;

  AuthUser? get user => _session?.user;
  bool get isLoggedIn => _session != null;
  String? get role => _session?.user.role;

  Future<void> hydrate() async {
    try {
      final saved = await _storage.read();
      _session = saved != null && Roles.webRoles.contains(saved.user.role)
          ? saved
          : null;
    } catch (_) {
      _session = null;
    }
    notifyListeners();
  }

  // Tai khoan khach hang khong duoc vao web: bao loi va khong luu phien
  Future<void> login(String email, String password) async {
    final generation = ++_generation;
    final session = await _authService.login(email.trim(), password);
    if (generation != _generation) return;
    if (!Roles.webRoles.contains(session.user.role)) {
      throw const ApiException(
        'Tài khoản khách hàng vui lòng dùng ứng dụng di động.',
      );
    }
    await _setSession(session);
  }

  Future<void> logout() async {
    ++_generation;
    final pendingLogout = _authService.logout();
    await _clearSession();
    try {
      await pendingLogout;
    } catch (_) {
      // bo qua loi mang, van xoa phien cuc bo
    }
  }

  Future<void> _setSession(LoginResponse session) async {
    await _storage.save(session);
    _session = session;
    notifyListeners();
  }

  Future<void> _clearSession() async {
    await _storage.clear();
    _session = null;
    notifyListeners();
  }

  // Goi tu ApiClient khi gap 401: lam moi token mot lan, cac request dong thoi dung chung ket qua
  Future<bool> _refreshSession() {
    if (_session == null) return Future.value(false);
    return _refreshing ??= () async {
      final generation = _generation;
      final refreshToken = _session?.refreshToken;
      if (refreshToken == null) return false;
      try {
        final session = await _authService.refresh(refreshToken);
        if (generation != _generation) return false;
        await _setSession(session);
        return true;
      } catch (_) {
        if (generation == _generation) await _clearSession();
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }
}
