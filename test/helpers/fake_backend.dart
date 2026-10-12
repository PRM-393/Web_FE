import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:voucher_platform_web/main.dart';
import 'package:voucher_platform_web/models/auth_user.dart';
import 'package:voucher_platform_web/providers/auth_provider.dart';
import 'package:voucher_platform_web/services/api_client.dart';
import 'package:voucher_platform_web/services/auth_service.dart';
import 'package:voucher_platform_web/services/token_storage.dart';

const baseUrl = 'http://api.test/api';

typedef Handler = Object? Function(http.Request request);

// Gia lap Web_BE: dang ky handler theo "METHOD /duong-dan", ghi lai moi request de kiem tra
class FakeBackend {
  final Map<String, Handler> _handlers = {};
  final List<http.Request> requests = [];

  void on(String method, String path, Handler handler) => _handlers['$method $path'] = handler;

  // Tra loi loi theo dinh dang AllExceptionsFilter cua BE
  static http.Response error(int status, String message) =>
      http.Response(jsonEncode({'statusCode': status, 'message': message}), status,
          headers: {'content-type': 'application/json; charset=utf-8'});

  late final client = MockClient((request) async {
    requests.add(request);
    final path = request.url.path.replaceFirst('/api', '');
    final handler = _handlers['${request.method} $path'];
    if (handler == null) return error(404, 'Không có handler cho ${request.method} $path');
    final result = handler(request);
    if (result is http.Response) return result;
    return http.Response(jsonEncode(result), 200, headers: {'content-type': 'application/json; charset=utf-8'});
  });

  Map<String, dynamic> bodyOf(String method, String path) {
    final r = requests.lastWhere((r) => r.method == method && r.url.path == '/api$path');
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  bool called(String method, String path) => requests.any((r) => r.method == method && r.url.path == '/api$path');
}

// Luu phien trong bo nho thay cho flutter_secure_storage (khong co plugin khi chay test)
class MemoryTokenStorage extends TokenStorage {
  MemoryTokenStorage([this.session]);

  LoginResponse? session;

  @override
  Future<void> save(LoginResponse value) async => session = value;

  @override
  Future<LoginResponse?> read() async => session;

  @override
  Future<void> clear() async => session = null;
}

LoginResponse sessionFor(String role, {String email = 'user@test.vn'}) => LoginResponse(
      accessToken: 'access-$role',
      refreshToken: 'refresh-$role',
      user: AuthUser(id: 'u-$role', email: email, role: role),
    );

Map<String, dynamic> loginJson(String role, {String email = 'user@test.vn'}) => {
      'accessToken': 'access-$role',
      'refreshToken': 'refresh-$role',
      'user': {'id': 'u-$role', 'email': email, 'role': role},
    };

// Dung toan bo app voi backend gia; loggedInAs != null thi khoi dong voi phien da luu
Future<(Widget, AuthProvider)> buildTestApp(FakeBackend backend, {String? loggedInAs}) async {
  final api = ApiClient(baseUrl: baseUrl, httpClient: backend.client);
  final auth = AuthProvider(
    api: api,
    authService: AuthService(api),
    storage: MemoryTokenStorage(loggedInAs == null ? null : sessionFor(loggedInAs)),
  );
  await auth.hydrate();
  return (buildApp(api: api, auth: auth), auth);
}

// Mo mot route nhu khi go URL tren trinh duyet
Future<void> openRoute(WidgetTester tester, String route) async {
  final navigator = tester.state<NavigatorState>(find.byType(Navigator).first);
  navigator.pushNamedAndRemoveUntil(route, (_) => false);
  await tester.pumpAndSettle();
}

// Man desktop de NavigationRail hien day du
void useDesktopSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

// Cuon toi widget (form dai, nut nam duoi man hinh) roi moi bam
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}
