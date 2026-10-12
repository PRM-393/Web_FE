import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../models/finance.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/brand_gate.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-REPORT-01/02: so lieu tong hop cua thuong hieu
class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.brandReports,
        child: BrandGate(builder: (context, brand) => _Report(brand: brand)),
      );
}

class _Report extends StatefulWidget {
  const _Report({required this.brand});

  final Brand brand;

  @override
  State<_Report> createState() => _ReportState();
}

class _ReportState extends State<_Report> {
  late Future<BrandReport> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<BrandService>().report(widget.brand.id);
  }

  void _reload() {
    setState(() {
      _future = context.read<BrandService>().report(widget.brand.id);
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Báo cáo',
            subtitle: widget.brand.name,
            actions: [IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh))],
          ),
          Expanded(
            child: AsyncBody<BrandReport>(
              future: _future,
              onRetry: _reload,
              builder: (context, r) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: [
                    StatCard(label: 'Tổng chiến dịch', value: '${r.totalCampaigns}', icon: Icons.campaign_outlined),
                    StatCard(label: 'Voucher đã bán', value: '${r.totalVoucherSold}', icon: Icons.confirmation_number_outlined),
                    StatCard(label: 'Doanh thu', value: formatVnd(r.totalRevenue), icon: Icons.payments_outlined),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}
