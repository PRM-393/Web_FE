import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/redeem.dart';
import '../../providers/store_session_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-REDEEM-10: nhan vien xem cac lan xac nhan do chinh minh thuc hien trong ngay.
// FR-REDEEM-08: sua gia tri hoa don trong 10 phut sau khi xac nhan.
class RedeemHistoryScreen extends StatefulWidget {
  const RedeemHistoryScreen({super.key});

  @override
  State<RedeemHistoryScreen> createState() => _RedeemHistoryScreenState();
}

class _RedeemHistoryScreenState extends State<RedeemHistoryScreen> {
  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<StoreSessionProvider>().loadHistory();
  }

  void _reload() {
    setState(() {
      _future = context.read<StoreSessionProvider>().loadHistory();
    });
  }

  Future<void> _editBill(RedemptionLog log) async {
    final until = log.billEditableUntil;
    final text = await promptTextDialog(
      context,
      title: 'Sửa giá trị hóa đơn',
      label: 'Giá trị hóa đơn (VND)',
      confirm: 'Lưu',
      message: until == null
          ? 'Chỉ sửa được trong 10 phút sau khi xác nhận.'
          : 'Chỉ sửa được trong 10 phút sau khi xác nhận (đến ${formatTime(until)}).',
      initialValue: log.billAmount?.toString(),
      keyboardType: TextInputType.number,
      validator: (v) => validateMoney(v, 'giá trị hóa đơn'),
    );
    if (text == null || !mounted) return;
    try {
      await context.read<StoreSessionProvider>().updateBill(log.id, parseMoney(text)!);
      if (mounted) showMessage(context, 'Đã cập nhật giá trị hóa đơn.');
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<StoreSessionProvider>();
    final storeNames = {for (final s in session.stores) s.id: s.name};
    return PortalShell(
      currentRoute: AppRoutes.storeHistory,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Lịch sử trong ngày',
            subtitle: '${session.history.length} lượt xác nhận',
            actions: [IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh))],
          ),
          Expanded(
            child: AsyncBody<void>(
              future: _future,
              onRetry: _reload,
              isEmpty: (_) => session.history.isEmpty,
              emptyMessage: 'Hôm nay chưa có lượt xác nhận nào.',
              builder: (context, _) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                itemCount: session.history.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final log = session.history[i];
                  return _HistoryCard(
                    log: log,
                    storeName: log.storeName ?? storeNames[log.storeId] ?? 'Chi nhánh khác',
                    onEditBill: log.billEditable ? () => _editBill(log) : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.log, required this.storeName, this.onEditBill});

  final RedemptionLog log;
  final String storeName;
  final VoidCallback? onEditBill;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(log.method == 'QR' ? Icons.qr_code : Icons.pin_outlined, color: AppColors.success),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.campaignTitle ?? 'Voucher',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      [
                        if (log.voucherCode != null && log.voucherCode!.isNotEmpty) 'Mã ${log.voucherCode}',
                        storeName,
                      ].join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    Text(
                      [
                        formatDateTime(log.redeemedAt),
                        'Phương thức ${log.method}',
                        if (log.billAmount != null) 'Hóa đơn ${formatVnd(log.billAmount!)}',
                      ].join(' · '),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    if (onEditBill != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      OutlinedButton.icon(
                        key: Key('edit-bill-${log.id}'),
                        onPressed: onEditBill,
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Sửa hóa đơn'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
