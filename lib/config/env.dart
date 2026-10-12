// Cau hinh moi truong, truyen qua --dart-define khi chay/build (NFR-MNT-02: khong hard-code).
//   flutter run -d chrome --web-port 5173 --dart-define=API_BASE_URL=http://localhost:3000/api
// Cong 5173 trung voi CORS_ORIGIN mac dinh trong .env cua Web_BE.
class Env {
  Env._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );
}
