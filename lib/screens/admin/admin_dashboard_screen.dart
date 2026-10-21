import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/report_period.dart';
import '../../widgets/portal_shell.dart';
import '../../widgets/brand_identity.dart';
import '../../widgets/revenue_chart.dart';

// FR-REPORT-03: so lieu tong cua san cho quan tri vien
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<AdminDashboard> _future;
  Map<String, Object?> _query = {};

  @override
  void initState() {
    super.initState();
    _future = context.read<AdminService>().dashboard(query: _query);
  }

  void _reload() {
    setState(() {
      _future = context.read<AdminService>().dashboard(query: _query);
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
          actions: [
            ReportPeriod(
              onChanged: (query) {
                _query = query;
                _reload();
              },
            ),
            IconButton(
              tooltip: 'Tải lại',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
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
                  const PortalWelcome(
                    title: 'Toàn cảnh kinh doanh, trong tầm tay.',
                    subtitle: 'Theo dõi hiệu quả toàn sàn và những giao dịch tạo nên giá trị.',
                  ),
                  StatCard(
                    label: 'Doanh thu sau hoàn tiền',
                    value: formatVnd(d.totalRevenue),
                    icon: Icons.payments_outlined,
                  ),
                  StatCard(
                    label: 'Tổng hoa hồng',
                    value: formatVnd(d.totalCommission),
                    icon: Icons.percent,
                  ),
                  StatCard(
                    label: 'Thương hiệu hoạt động',
                    value: '${d.totalActiveBrands}',
                    icon: Icons.storefront_outlined,
                  ),
                  StatCard(
                    label: 'Giao dịch thành công',
                    value: '${d.totalTransactions}',
                    icon: Icons.receipt_long_outlined,
                  ),
                  StatCard(
                    label: 'Đã hoàn tiền',
                    value: formatVnd(d.refundedAmount),
                    icon: Icons.currency_exchange,
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Doanh thu theo ngày · Giờ Việt Nam',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 16),
                            RevenueChart(rows: d.transactionsByDay),
                            const SizedBox(height: 16),
                            if (d.transactionsByDay.isEmpty)
                              const Text(
                                'Chưa có giao dịch trong khoảng thời gian này.',
                              ),
                            for (final row in d.transactionsByDay)
                              ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text('${row['date']}'),
                                subtitle: Text('${row['count']} giao dịch'),
                                trailing: Text(
                                  formatVnd(
                                    num.tryParse('${row['revenue']}') ?? 0,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
