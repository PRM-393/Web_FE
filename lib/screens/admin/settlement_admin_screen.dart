import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';
import '../../widgets/settlement_tile.dart';

// UC-05, FR-SETTLE-03/07: chot doi soat thang truoc, danh dau da chi tra.
// Cau hinh ty le hoa hong (FR-SETTLE-01) nam o man rieng: CommissionConfigScreen.
class SettlementAdminScreen extends StatefulWidget {
  const SettlementAdminScreen({super.key});

  @override
  State<SettlementAdminScreen> createState() => _SettlementAdminScreenState();
}

class _SettlementAdminScreenState extends State<SettlementAdminScreen> {
  late Future<List<Settlement>> _future;
  bool _busy = false;

  AdminService get _service => context.read<AdminService>();

  @override
  void initState() {
    super.initState();
    _future = _service.settlements();
  }

  void _reload() {
    setState(() {
      _future = _service.settlements();
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Ky doi soat la thang lich truoc theo gio Viet Nam (BR-25)
  Future<void> _runLastMonth() async {
    final nowVn = DateTime.now().toUtc().add(const Duration(hours: 7));
    final firstOfThisMonth = DateTime(nowVn.year, nowVn.month);
    final firstOfLastMonth = DateTime(nowVn.year, nowVn.month - 1);
    final start = vnStartOfDayUtc(firstOfLastMonth);
    final end = vnStartOfDayUtc(firstOfThisMonth).subtract(const Duration(milliseconds: 1));
    final ok = await confirmDialog(context,
        title: 'Chốt đối soát',
        message: 'Chốt đối soát tháng ${firstOfLastMonth.month}/${firstOfLastMonth.year} cho tất cả thương hiệu?',
        confirm: 'Chốt');
    if (!ok) return;
    await _guard(() async {
      final count = await _service.runSettlement(start, end);
      if (!mounted) return;
      showMessage(context, 'Đã tạo $count phiếu đối soát.');
      _reload();
    });
  }

  Future<void> _markPaid(Settlement s) async {
    final ref = await promptTextDialog(context, title: 'Đánh dấu đã chi trả', label: 'Mã giao dịch ngân hàng');
    if (ref == null) return;
    await _guard(() async {
      await _service.markSettlementPaid(s.id, ref);
      if (!mounted) return;
      showMessage(context, 'Đã ghi nhận chi trả.');
      _reload();
    });
  }

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.adminSettlements,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Đối soát',
              actions: [
                OutlinedButton.icon(
                  onPressed: _busy ? null : _runLastMonth,
                  icon: const Icon(Icons.play_circle_outline),
                  label: const Text('Chốt đối soát tháng trước'),
                ),
                IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh)),
              ],
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
                  itemBuilder: (context, i) => SettlementTile(
                    settlement: list[i],
                    showBrand: true,
                    trailing: list[i].isPaid
                        ? null
                        : OutlinedButton.icon(
                            onPressed: _busy ? null : () => _markPaid(list[i]),
                            icon: const Icon(Icons.done_all),
                            label: const Text('Đánh dấu đã chi trả'),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
