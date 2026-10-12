import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../models/finance.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_gate.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';
import '../../widgets/settlement_tile.dart';

// FR-SETTLE-08: thuong hieu xem phieu doi soat hang thang cua minh
class SettlementListScreen extends StatelessWidget {
  const SettlementListScreen({super.key});

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.brandSettlements,
        child: BrandGate(builder: (context, brand) => _Settlements(brand: brand)),
      );
}

class _Settlements extends StatefulWidget {
  const _Settlements({required this.brand});

  final Brand brand;

  @override
  State<_Settlements> createState() => _SettlementsState();
}

class _SettlementsState extends State<_Settlements> {
  late Future<List<Settlement>> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<BrandService>().settlements(widget.brand.id);
  }

  void _reload() {
    setState(() {
      _future = context.read<BrandService>().settlements(widget.brand.id);
    });
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Phiếu đối soát',
            subtitle: 'Doanh thu sau khi trừ hoa hồng sàn, chốt theo tháng',
            actions: [IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh))],
          ),
          Expanded(
            child: AsyncBody<List<Settlement>>(
              future: _future,
              onRetry: _reload,
              isEmpty: (list) => list.isEmpty,
              emptyMessage: 'Chưa có phiếu đối soát nào.',
              builder: (context, list) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                itemCount: list.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) => SettlementTile(settlement: list[i]),
              ),
            ),
          ),
        ],
      );
}
