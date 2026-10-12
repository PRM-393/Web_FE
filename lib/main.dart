import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/env.dart';
import 'providers/auth_provider.dart';
import 'providers/brand_provider.dart';
import 'providers/store_session_provider.dart';
import 'routes.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/portal_services.dart';
import 'services/token_storage.dart';
import 'theme/app_theme.dart';

// Diem vao web: web thuong hieu, web cua hang va web quan tri dung chung mot app Flutter Web.
// Khoi tao service, khoi phuc phien dang nhap, dang ky Provider (Module 5).
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final api = ApiClient(baseUrl: Env.apiBaseUrl);
  final auth = AuthProvider(api: api, authService: AuthService(api), storage: TokenStorage());
  await auth.hydrate();

  runApp(buildApp(api: api, auth: auth));
}

// Tach ra de widget test dung lai voi ApiClient gia lap
Widget buildApp({required ApiClient api, required AuthProvider auth}) {
  final brandService = BrandService(api);
  final redeemService = RedeemService(api);
  return MultiProvider(
    providers: [
      Provider.value(value: brandService),
      Provider.value(value: redeemService),
      Provider(create: (_) => CampaignService(api)),
      Provider(create: (_) => AdminService(api)),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider(create: (_) => BrandProvider(brandService)),
      ChangeNotifierProvider(create: (_) => StoreSessionProvider(redeemService)),
    ],
    child: const VoucherWebApp(),
  );
}

class VoucherWebApp extends StatefulWidget {
  const VoucherWebApp({super.key});

  @override
  State<VoucherWebApp> createState() => _VoucherWebAppState();
}

class _VoucherWebAppState extends State<VoucherWebApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final AuthProvider _auth;
  late bool _wasLoggedIn;

  @override
  void initState() {
    super.initState();
    _auth = context.read<AuthProvider>();
    _wasLoggedIn = _auth.isLoggedIn;
    _auth.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }

  // Dang xuat hoac het phien (refresh token khong hop le): xoa du lieu cu va ve man dang nhap
  void _onAuthChanged() {
    if (_wasLoggedIn && !_auth.isLoggedIn) {
      context.read<BrandProvider>().reset();
      context.read<StoreSessionProvider>().reset();
      _navigatorKey.currentState?.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
    }
    _wasLoggedIn = _auth.isLoggedIn;
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Voucher Platform',
        debugShowCheckedModeBanner: false,
        navigatorKey: _navigatorKey,
        theme: buildAppTheme(),
        locale: const Locale('vi'),
        supportedLocales: const [Locale('vi'), Locale('en')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        initialRoute: AppRoutes.root,
        // Tren web, URL tren thanh dia chi la route ban dau; chi tao dung mot man (khong tach theo dau "/")
        onGenerateInitialRoutes: (name) => [AppRoutes.onGenerateRoute(RouteSettings(name: name), _auth)],
        onGenerateRoute: (settings) => AppRoutes.onGenerateRoute(settings, _auth),
      );
}
