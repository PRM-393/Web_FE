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

// UC-05, FR-SETTLE-01/03/07: cau hinh ty le hoa hong chung, chot doi soat thang truoc, danh dau da chi tra
class SettlementAdminScreen extends StatefulWidget {
  const SettlementAdminScreen({super.key});

  @override
  State<SettlementAdminScreen> createState() => _SettlementAdminScreenState();
}

class _SettlementAdminScreenState extends State<SettlementAdminScreen> {
  final _rateController = TextEditingController();
  late Future<List<Settlement>> _future;
  bool _busy = false;

  AdminService get _service => context.read<AdminService>();

  @override
  void initState() {
    super.initState();
    _future = _service.settlements();
    _service.commissionRate().then((rate) {
      if (mounted) _rateController.text = (rate * 100).toStringAsFixed(rate * 100 % 1 == 0 ? 0 : 1);
    }).catchError((_) {});
  }

  @override
  void dispose() {
    _rateController.dispose();
    super.dispose();
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

  // Nhap theo phan tram cho de doc, gui len may chu ty le 0..1 (BR-09)
  Future<void> _saveRate() async {
    final percent = double.tryParse(_rateController.text.trim().replaceAll(',', '.'));
    if (percent == null || percent < 0 || percent > 100) {
      showMessage(context, 'Tỷ lệ hoa hồng từ 0 đến 100%.', error: true);
      return;
    }
    await _guard(() async {
      await _service.setCommissionRate(percent / 100);
      if (mounted) showMessage(context, 'Đã cập nhật tỷ lệ hoa hồng ${formatPercent(percent / 100)}.');
    });
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
              title: 'Đối soát & hoa hồng',
              actions: [IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh))],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _rateController,
                          decoration: const InputDecoration(labelText: 'Tỷ lệ hoa hồng', suffixText: '%'),
                        ),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                        onPressed: _busy ? null : _saveRate,
                        child: const Text('Lưu tỷ lệ'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
                        onPressed: _busy ? null : _runLastMonth,
                        icon: const Icon(Icons.play_circle_outline),
                        label: const Text('Chốt đối soát tháng trước'),
                      ),
                    ],
                  ),
                ),
              ),
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
