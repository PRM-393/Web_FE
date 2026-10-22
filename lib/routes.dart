import 'package:flutter/material.dart';

import 'models/campaign.dart';
import 'screens/auth/account_recovery_screen.dart';
import 'screens/admin/category_admin_screen.dart';
import 'providers/auth_provider.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/brand_approval_screen.dart';
import 'screens/admin/campaign_approval_screen.dart';
import 'screens/admin/commission_config_screen.dart';
import 'screens/admin/refund_admin_screen.dart';
import 'screens/admin/review_moderation_screen.dart';
import 'screens/admin/settlement_admin_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/brand/brand_profile_screen.dart';
import 'screens/brand/campaign_form_screen.dart';
import 'screens/brand/campaign_list_screen.dart';
import 'screens/brand/report_screen.dart';
import 'screens/brand/review_list_screen.dart';
import 'screens/brand/settlement_list_screen.dart';
import 'screens/brand/staff_list_screen.dart';
import 'screens/brand/store_list_screen.dart';
import 'screens/shared/message_screens.dart';
import 'screens/store/redeem_screen.dart';
import 'screens/store/redeem_history_screen.dart';
import 'screens/store/store_select_screen.dart';

// Named routes (Navigator 1.0 - Module 5) cho 3 khu vuc /brand, /store, /admin trong cung mot app Flutter Web.
// Chan theo vai tro (FR-AUTH-07): chua dang nhap -> man dang nhap; sai vai tro -> man "khong co quyen".
// An menu chi la phu, may chu luon kiem tra quyen lai (NFR-SEC-03).
class AppRoutes {
  AppRoutes._();

  static const root = '/';
  static const login = '/login';
  static const activate = '/activate';
  static const resetPassword = '/reset-password';
  static const adminCategories = '/admin/categories';
  static const forbidden = '/forbidden';

  static const brandCampaigns = '/brand/campaigns';
  static const brandCampaignForm = '/brand/campaign-form';
  static const brandStores = '/brand/stores';
  static const brandStaff = '/brand/staff';
  static const brandReviews = '/brand/reviews';
  static const brandSettlements = '/brand/settlements';
  static const brandReports = '/brand/reports';
  static const brandProfile = '/brand/profile';

  static const storeSelect = '/store/select';
  static const storeRedeem = '/store/redeem';
  static const storeHistory = '/store/history';

  static const adminDashboard = '/admin/dashboard';
  static const adminBrands = '/admin/brands';
  static const adminCampaigns = '/admin/campaigns';
  static const adminSettlements = '/admin/settlements';
  static const adminCommission = '/admin/commission';
  static const adminRefunds = '/admin/refunds';
  static const adminReviews = '/admin/reviews';

  // Trang chu theo vai tro sau khi dang nhap
  static String homeOf(String? role) => switch (role) {
        Roles.brandOwner => brandCampaigns,
        Roles.storeStaff => storeSelect,
        Roles.admin => adminDashboard,
        _ => login,
      };

  static String? requiredRole(String name) {
    if (name.startsWith('/brand/')) return Roles.brandOwner;
    if (name.startsWith('/store/')) return Roles.storeStaff;
    if (name.startsWith('/admin/')) return Roles.admin;
    return null;
  }

  // Chuyen sang mot muc menu: thay man hien tai, khong chong lich su
  static void go(BuildContext context, String name, {Object? arguments}) =>
      Navigator.pushReplacementNamed(context, name, arguments: arguments);

  static Route<dynamic> onGenerateRoute(RouteSettings settings, AuthProvider auth) {
    final uri = Uri.parse(settings.name ?? root);
    final name = uri.path;
    final role = requiredRole(name);

    final Widget page;
    if (name == activate || name == resetPassword) {
      page = AccountRecoveryScreen(activation: name == activate, email: uri.queryParameters['email'] ?? '', token: uri.queryParameters['token']);
    } else if (name == root) {
      page = auth.isLoggedIn ? _pageFor(homeOf(auth.role), null) : const LoginScreen();
    } else if (name == login) {
      page = auth.isLoggedIn ? _pageFor(homeOf(auth.role), null) : const LoginScreen();
    } else if (role != null && !auth.isLoggedIn) {
      page = const LoginScreen();
    } else if (role != null && auth.role != role) {
      page = const ForbiddenScreen();
    } else {
      page = _pageFor(name, settings.arguments);
    }

    // Web: chuyen trang khong hieu ung truot nhu tren mobile
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (_, _, _) => page,
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    );
  }

  static Widget _pageFor(String name, Object? args) => switch (name) {
        login => const LoginScreen(),
        forbidden => const ForbiddenScreen(),
        brandCampaigns => const CampaignListScreen(),
        brandCampaignForm => CampaignFormScreen(campaign: args as VoucherCampaign?),
        brandStores => const StoreListScreen(),
        brandStaff => const StaffListScreen(),
        brandReviews => const ReviewListScreen(),
        brandSettlements => const SettlementListScreen(),
        brandReports => const ReportScreen(),
        brandProfile => const BrandProfileScreen(),
        storeSelect => const StoreSelectScreen(),
        storeRedeem => const RedeemScreen(),
        storeHistory => const RedeemHistoryScreen(),
        adminDashboard => const AdminDashboardScreen(),
        adminCategories => const CategoryAdminScreen(),
        adminBrands => const BrandApprovalScreen(),
        adminCampaigns => const CampaignApprovalScreen(),
        adminSettlements => const SettlementAdminScreen(),
        adminCommission => const CommissionConfigScreen(),
        adminRefunds => const RefundAdminScreen(),
        adminReviews => const ReviewModerationScreen(),
        _ => const NotFoundScreen(),
      };
}

