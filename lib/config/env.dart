// Cau hinh moi truong (NFR-MNT-02: khong hard-code dia chi trong tung man hinh).
// Mac dinh tro toi BE da deploy tren Render nen ca nhom chay ngay khong can cau hinh:
//   flutter run -d chrome --web-port 5173
// Chay voi BE tren may minh thi truyen them:
//   flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://localhost:3000/api
// Doi BE production: sua defaultBackend duoi day (va bien API_BASE_URL tren Vercel neu co dat).
class Env {
  Env._();

  static const defaultBackend = 'https://voucher-platform-api.onrender.com/api';

  // Chi de demo local: --dart-define=DEMO_LOGIN=true cho phep nhap ten ngan (admin, owner, staff, user) va mat khau 123.
  static const bool demoLogin = bool.fromEnvironment('DEMO_LOGIN');

  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: defaultBackend);
}
