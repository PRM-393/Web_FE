import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../models/finance.dart';
import '../../models/campaign.dart';
import '../../providers/brand_provider.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/brand_gate.dart';
import '../../widgets/common.dart';
import '../../widgets/report_period.dart';
import '../../widgets/portal_shell.dart';
import '../../widgets/brand_identity.dart';

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
  late Future<List<VoucherCampaign>> _campaigns;
  final Map<String, Object?> _query = {};

  @override
  void initState() {
    super.initState();
    _campaigns = context.read<CampaignService>().byBrand(widget.brand.id);
    _future = context.read<BrandService>().report(
      widget.brand.id,
      query: _query,
    );
  }

  void _reload() {
    setState(() {
      _future = context.read<BrandService>().report(
        widget.brand.id,
        query: _query,
      );
    });
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PageHeader(
        title: 'Báo cáo',
        subtitle: widget.brand.name,
        actions: [
          ReportPeriod(
            onChanged: (query) {
              _query.remove('from');
              _query.remove('to');
              _query.addAll(query);
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
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            FutureBuilder<List<VoucherCampaign>>(
              future: _campaigns,
              builder: (context, snapshot) => SizedBox(
                width: 260,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Chiến dịch'),
                  isExpanded: true,
                  items: [
                    const DropdownMenuItem(
                      value: '',
                      child: Text('Tất cả chiến dịch'),
                    ),
                    for (final c in snapshot.data ?? <VoucherCampaign>[])
                      DropdownMenuItem(
                        value: c.id,
                        child: Text(c.title, overflow: TextOverflow.ellipsis),
                      ),
                  ],
                  onChanged: (value) {
                    _query['campaignId'] = value;
                    _reload();
                  },
                ),
              ),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Chi nhánh đã sử dụng',
                ),
                isExpanded: true,
                items: [
                  const DropdownMenuItem(
                    value: '',
                    child: Text('Tất cả chi nhánh'),
                  ),
                  for (final s in context.watch<BrandProvider>().stores)
                    DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name, overflow: TextOverflow.ellipsis),
                    ),
                ],
                onChanged: (value) {
                  _query['storeId'] = value;
                  _reload();
                },
              ),
            ),
            const Text(
              'Ngày tính theo thanh toán (UTC+7). Lọc chi nhánh chỉ gồm voucher đã sử dụng tại đó.',
            ),
          ],
        ),
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
                const PortalWelcome(
                  title: 'Hiểu hiệu quả. Tăng trưởng bền vững.',
                  subtitle: 'Theo dõi doanh thu và hành trình sử dụng voucher của khách hàng.',
                ),
                StatCard(
                  label: 'Tổng chiến dịch',
                  value: '${r.totalCampaigns}',
                  icon: Icons.campaign_outlined,
                ),
                StatCard(
                  label: 'Voucher đã bán',
                  value: '${r.totalVoucherSold}',
                  icon: Icons.confirmation_number_outlined,
                ),
                StatCard(
                  label: 'Doanh thu sau hoàn tiền',
                  value: formatVnd(r.totalRevenue),
                  icon: Icons.payments_outlined,
                ),
                StatCard(
                  label: 'Đã hoàn tiền',
                  value: formatVnd(r.refundedAmount),
                  icon: Icons.currency_exchange,
                ),
                StatCard(
                  label: 'Đã sử dụng',
                  value: '${r.totalVoucherUsed}',
                  icon: Icons.check_circle_outline,
                ),
                StatCard(
                  label: 'Đã hết hạn',
                  value: '${r.totalVoucherExpired}',
                  icon: Icons.timer_off_outlined,
                ),
                StatCard(
                  label: 'Voucher đã hoàn',
                  value: '${r.totalVoucherRefunded}',
                  icon: Icons.undo,
                ),
                StatCard(
                  label: 'Tỷ lệ sử dụng',
                  value: '${r.usageRate.toStringAsFixed(1)}%',
                  icon: Icons.donut_large,
                ),
              ],
            ),
          ),
        ),
      ),
    ],
  );
}
