import '../models/auth_user.dart';
import 'api_client.dart';

// FR-AUTH-06: chu thuong hieu, nhan vien cua hang, quan tri vien dang nhap bang email + mat khau.
// Khach hang dang nhap OTP tren app di dong, khong thuoc web nay.
class AuthService {
  AuthService(this._api, {this.deviceId});
  final Future<String> Function()? deviceId;

  final ApiClient _api;

  Future<LoginResponse> login(String email, String password) async {
    final json = await _api.post('/auth/login', body: {'email': email, 'password': password, if (deviceId != null) 'deviceId': await deviceId!()}, authenticated: false);
    return LoginResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<LoginResponse> refresh(String refreshToken) async {
    final json = await _api.post('/auth/refresh', body: {'refreshToken': refreshToken}, authenticated: false);
    return LoginResponse.fromJson(json as Map<String, dynamic>);
  }

  Future<void> requestRecovery(String email, {required bool activation}) => _api.post(activation ? '/auth/activation/request' : '/auth/password-reset/request', body: {'email': email}, authenticated: false);
  Future<void> completeRecovery({required bool activation, required String email, required String token, required String password}) => _api.post(activation ? '/auth/activate' : '/auth/password-reset/confirm', body: {'email': email, 'token': token, 'password': password}, authenticated: false);
  Future<void> logout() => _api.post('/auth/logout');
}
