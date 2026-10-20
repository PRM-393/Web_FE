import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/store_session_provider.dart';
import '../routes.dart';
import '../theme/app_theme.dart';

class PortalNavItem {
  const PortalNavItem(this.route, this.label, this.icon);

  final String route;
  final String label;
  final IconData icon;
}

// Menu theo vai tro (khop cac khu vuc trong AppRoutes)
const _brandNav = [
  PortalNavItem(AppRoutes.brandCampaigns, 'Chiến dịch', Icons.campaign_outlined),
  PortalNavItem(AppRoutes.brandStores, 'Chi nhánh', Icons.storefront_outlined),
  PortalNavItem(AppRoutes.brandStaff, 'Nhân viên', Icons.badge_outlined),
  PortalNavItem(AppRoutes.brandReviews, 'Đánh giá', Icons.star_outline),
  PortalNavItem(AppRoutes.brandReports, 'Báo cáo', Icons.bar_chart),
  PortalNavItem(AppRoutes.brandSettlements, 'Đối soát', Icons.receipt_long_outlined),
  PortalNavItem(AppRoutes.brandProfile, 'Hồ sơ thương hiệu', Icons.business_outlined),
];

const _storeNav = [
  PortalNavItem(AppRoutes.storeRedeem, 'Xác nhận sử dụng', Icons.qr_code_scanner),
  PortalNavItem(AppRoutes.storeHistory, 'Lịch sử trong ngày', Icons.history),
  PortalNavItem(AppRoutes.storeSelect, 'Đổi chi nhánh', Icons.swap_horiz),
];

const _adminNav = [
  PortalNavItem(AppRoutes.adminDashboard, 'Bảng điều khiển', Icons.dashboard_outlined),
  PortalNavItem(AppRoutes.adminBrands, 'Duyệt thương hiệu', Icons.verified_outlined),
  PortalNavItem(AppRoutes.adminCampaigns, 'Duyệt chiến dịch', Icons.fact_check_outlined),
  PortalNavItem(AppRoutes.adminSettlements, 'Đối soát', Icons.account_balance_outlined),
  PortalNavItem(AppRoutes.adminCommission, 'Tỷ lệ hoa hồng', Icons.percent),
  PortalNavItem(AppRoutes.adminRefunds, 'Hoàn tiền thủ công', Icons.currency_exchange),
];

// Khung chung cua moi man sau dang nhap: thanh tren (ten khu vuc, tai khoan, dang xuat) + menu.
// Man rong (>= 900px) dung NavigationRail co dinh; man hep (dien thoai cua nhan vien) dung Drawer.
class PortalShell extends StatelessWidget {
  const PortalShell({super.key, required this.currentRoute, required this.child, this.floatingActionButton});

  final String currentRoute;
  final Widget child;
  final Widget? floatingActionButton;

  static const wideBreakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final (title, items) = switch (auth.role) {
      Roles.brandOwner => ('Kênh thương hiệu', _brandNav),
      Roles.storeStaff => ('Web cửa hàng', _storeNav),
      Roles.admin => ('Quản trị hệ thống', _adminNav),
      _ => ('Voucher Platform', const <PortalNavItem>[]),
    };
    final selected = items.indexWhere((i) => i.route == currentRoute);
    final wide = MediaQuery.sizeOf(context).width >= wideBreakpoint;
    final store = auth.role == Roles.storeStaff ? context.watch<StoreSessionProvider>().currentStore : null;

    void open(int index) {
      if (index == selected) return;
      AppRoutes.go(context, items[index].route);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1)),
        actions: [
          if (store != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Chip(avatar: const Icon(Icons.storefront, size: 18), label: Text(store.name)),
            ),
          if (wide && auth.user != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(child: Text(auth.user!.email, style: const TextStyle(color: AppColors.textSecondary))),
            ),
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      drawer: wide || items.isEmpty
          ? null
          : Drawer(
              child: SafeArea(
                child: ListView(
                  children: [
                    ListTile(
                      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      subtitle: auth.user == null ? null : Text(auth.user!.email),
                    ),
                    const Divider(),
                    for (var i = 0; i < items.length; i++)
                      ListTile(
                        leading: Icon(items[i].icon),
                        title: Text(items[i].label),
                        selected: i == selected,
                        onTap: () {
                          Navigator.pop(context);
                          open(i);
                        },
                      ),
                  ],
                ),
              ),
            ),
      floatingActionButton: floatingActionButton,
      body: wide && items.isNotEmpty
          ? Row(
              children: [
                NavigationRail(
                  extended: true,
                  minExtendedWidth: 220,
                  selectedIndex: selected < 0 ? null : selected,
                  onDestinationSelected: open,
                  destinations: [
                    for (final item in items)
                      NavigationRailDestination(icon: Icon(item.icon), label: Text(item.label)),
                  ],
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            )
          : child,
    );
  }
}
