import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-REPORT-03: so lieu tong cua san cho quan tri vien
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminDashboard> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminService>().dashboard();
  }

  void _reload() {
    setState(() {
      _future = context.read<AdminService>().dashboard();
    });
  }

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.adminDashboard,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Bảng điều khiển',
              actions: [IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh))],
            ),
            Expanded(
              child: AsyncBody<AdminDashboard>(
                future: _future,
                onRetry: _reload,
                builder: (context, d) => SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      StatCard(label: 'Doanh thu toàn sàn', value: formatVnd(d.totalRevenue), icon: Icons.payments_outlined),
                      StatCard(label: 'Tổng hoa hồng', value: formatVnd(d.totalCommission), icon: Icons.percent),
                      StatCard(label: 'Thương hiệu hoạt động', value: '${d.totalActiveBrands}', icon: Icons.storefront_outlined),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
