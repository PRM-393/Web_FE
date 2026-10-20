import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-REFUND-06: cong thanh toan khong hoan tu dong duoc -> quan tri vien hoan thu cong roi xac nhan tren he thong
class RefundAdminScreen extends StatefulWidget {
  const RefundAdminScreen({super.key});

  @override
  State<RefundAdminScreen> createState() => _RefundAdminScreenState();
}

class _RefundAdminScreenState extends State<RefundAdminScreen> {
  late Future<List<RefundRequest>> _future;

  AdminService get _service => context.read<AdminService>();

  @override
  void initState() {
    super.initState();
    _future = _service.manualPendingRefunds();
  }

  void _reload() {
    setState(() {
      _future = _service.manualPendingRefunds();
    });
  }

  Future<void> _confirm(RefundRequest r) async {
    final ok = await confirmDialog(
      context,
      title: 'Xác nhận đã hoàn tiền',
      message: 'Chỉ xác nhận sau khi đã chuyển tiền hoàn cho khách qua cổng thanh toán hoặc ngân hàng.',
      confirm: 'Đã hoàn tiền',
    );
    if (!ok) return;
    if (!mounted) return;
    final reference = await promptTextDialog(
      context,
      title: 'Ghi nhận giao dịch hoàn tiền',
      label: 'Mã giao dịch hoàn tiền',
    );
    if (reference == null) return;
    try {
      await _service.confirmManualRefund(r.id, reference);
      if (!mounted) return;
      showMessage(context, 'Đã xác nhận hoàn tiền.');
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => PortalShell(
    currentRoute: AppRoutes.adminRefunds,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Hoàn tiền thủ công',
          subtitle: 'Yêu cầu ở trạng thái chờ hoàn thủ công',
          actions: [
            IconButton(
              tooltip: 'Tải lại',
              onPressed: _reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        Expanded(
          child: AsyncBody<List<RefundRequest>>(
            future: _future,
            onRetry: _reload,
            isEmpty: (list) => list.isEmpty,
            emptyMessage: 'Không có yêu cầu nào cần xử lý thủ công.',
            builder: (context, list) => ListView.separated(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final r = list[i];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.currency_exchange),
                    title: Text('Yêu cầu ngày ${formatDateTime(r.createdAt)}'),
                    subtitle: Text(
                      r.reason == null || r.reason!.isEmpty
                          ? 'Không ghi lý do'
                          : 'Lý do: ${r.reason}',
                    ),
                    trailing: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 40),
                      ),
                      onPressed: () => _confirm(r),
                      child: const Text('Đã hoàn tiền'),
                    ),
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
