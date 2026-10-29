import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/download/file_download.dart';
import '../../utils/settlement_csv.dart';
import '../../utils/validators.dart';
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

  // FR-SETTLE-07: may chu bat buoc CA ngay chuyen lan ma giao dich nen hop thoai phai hoi du hai.
  // Truoc day chi hoi ma giao dich va ngay bi gan cung bang thoi diem bam nut, khong khai duoc
  // lenh chuyen da thuc hien tu hom truoc.
  Future<void> _markPaid(Settlement s) async {
    final result = await showDialog<({String bankTxnRef, DateTime paidAt})>(
      context: context,
      builder: (_) => _MarkPaidDialog(settlement: s),
    );
    if (result == null) return;
    await _guard(() async {
      await _service.markSettlementPaid(s.id, result.bankTxnRef, result.paidAt);
      if (!mounted) return;
      showMessage(context, 'Đã ghi nhận chi trả.');
      _reload();
    });
  }

  // FR-SETTLE-07: xuat danh sach phieu ra CSV
  Future<void> _exportCsv() async {
    try {
      final items = await _future;
      final ok = await downloadTextFile('doi-soat-${DateTime.now().toIso8601String().substring(0, 10)}.csv', settlementsToCsv(items, includeBrand: true));
      if (mounted) showMessage(context, ok ? 'Đã xuất ${items.length} phiếu ra CSV.' : 'Chỉ xuất được CSV trên trình duyệt.');
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
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
                OutlinedButton.icon(onPressed: _exportCsv, icon: const Icon(Icons.download), label: const Text('Xuất CSV')),
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
                    onTap: () => AppRoutes.go(context, AppRoutes.adminSettlementDetail, arguments: list[i].id),
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

// FR-SETTLE-07: ghi nhan chi tra - bat buoc ngay chuyen + ma giao dich ngan hang.
// Ngay mac dinh la hom nay theo lich Viet Nam, khong cho chon ngay o tuong lai (may chu cung chan).
class _MarkPaidDialog extends StatefulWidget {
  const _MarkPaidDialog({required this.settlement});

  final Settlement settlement;

  @override
  State<_MarkPaidDialog> createState() => _MarkPaidDialogState();
}

class _MarkPaidDialogState extends State<_MarkPaidDialog> {
  final _formKey = GlobalKey<FormState>();
  final _ref = TextEditingController();
  late DateTime _paidAt = vnCalendarDay(DateTime.now());

  @override
  void dispose() {
    _ref.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final today = vnCalendarDay(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt,
      firstDate: vnCalendarDay(widget.settlement.periodStart),
      lastDate: today,
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    // Gui dau ngay theo gio VN quy ve UTC - may chu chi dung de ghi nhan, khong so sanh gio phut
    Navigator.pop(context, (bankTxnRef: _ref.text.trim(), paidAt: vnStartOfDayUtc(_paidAt)));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Đánh dấu đã chi trả'),
        content: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '${widget.settlement.brandName ?? widget.settlement.brandId} · '
                  'thực nhận ${formatVnd(widget.settlement.payableAmount)}',
                ),
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  key: const Key('mark-paid-ref'),
                  controller: _ref,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Mã giao dịch ngân hàng *'),
                  validator: validateBankTxnRef,
                ),
                const SizedBox(height: AppSpacing.md),
                OutlinedButton.icon(
                  key: const Key('mark-paid-date'),
                  onPressed: _pickDate,
                  icon: const Icon(Icons.event),
                  label: Text('Ngày chuyển: ${_paidAt.day}/${_paidAt.month}/${_paidAt.year}'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            key: const Key('mark-paid-submit'),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 40)),
            onPressed: _submit,
            child: const Text('Xác nhận'),
          ),
        ],
      );
}
