import '../models/auth_user.dart';
import 'api_client.dart';

// FR-AUTH-06: chu thuong hieu, nhan vien cua hang, quan tri vien dang nhap bang email + mat khau.
// Khach hang dang nhap OTP tren app di dong, khong thuoc web nay.
class AuthService {
  AuthService(this._api);

  final ApiClient _api;

  Future<LoginResponse> login(String email, String password) async {
    final json = await _api.post('/auth/login', body: {'email': email, 'password': password}, authenticated: false);
    return LoginResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<LoginResponse> refresh(String refreshToken) async {
    final json = await _api.post('/auth/refresh', body: {'refreshToken': refreshToken}, authenticated: false);
    return LoginResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<void> logout() => _api.post('/auth/logout');
}
