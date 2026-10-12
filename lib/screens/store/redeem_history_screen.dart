import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/store_session_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-REDEEM-10: nhan vien xem cac lan xac nhan do chinh minh thuc hien trong ngay
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
                  return Card(
                    child: ListTile(
                      leading: Icon(log.method == 'QR' ? Icons.qr_code : Icons.pin_outlined, color: AppColors.success),
                      title: Text(formatDateTime(log.redeemedAt)),
                      subtitle: Text([
                        'Phương thức ${log.method}',
                        storeNames[log.storeId] ?? 'Chi nhánh khác',
                        if (log.billAmount != null) 'Hóa đơn ${formatVnd(log.billAmount!)}',
                      ].join(' · ')),
                    ),
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
