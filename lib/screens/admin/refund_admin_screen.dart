import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// UC-07, FR-REFUND-06: hang doi hoan tien thu cong cua quan tri vien.
//  - Tab 1: yeu cau hoan tien cong thanh toan khong hoan tu dong duoc -> hoan tay roi xac nhan / bao khong hoan duoc.
//  - Tab 2: don thanh toan lech so tien -> hoan lai so tien da nhan, don chuyen sang da huy.
// DC-12: tong tien hoan khong vuot so tien da nhan, may chu luon kiem tra lai.
class RefundAdminScreen extends StatefulWidget {
  const RefundAdminScreen({super.key});

  @override
  State<RefundAdminScreen> createState() => _RefundAdminScreenState();
}

class _RefundAdminScreenState extends State<RefundAdminScreen> {
  late Future<List<RefundRequest>> _refunds;
  late Future<List<PaymentMismatchOrder>> _mismatches;
  bool _busy = false;

  AdminService get _service => context.read<AdminService>();

  @override
  void initState() {
    super.initState();
    _refunds = _service.manualPendingRefunds();
    _mismatches = _service.paymentMismatches();
  }

  void _reload() {
    setState(() {
      _refunds = _service.manualPendingRefunds();
      _mismatches = _service.paymentMismatches();
    });
  }

  // Loi tu may chu (vd. DC-12 "So tien hoan vuot giao dich da nhan.") hien nguyen van
  Future<void> _guard(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      showMessage(context, success);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  // Da hoan tay: bat buoc ma giao dich hoan
  Future<void> _confirmManual(RefundRequest r) async {
    final amount = r.amount == null ? 'tiền' : formatVnd(r.amount!);
    final reference = await promptTextDialog(
      context,
      title: 'Xác nhận đã hoàn tiền',
      message: 'Chỉ xác nhận sau khi đã chuyển $amount cho khách qua cổng thanh toán hoặc ngân hàng.',
      label: 'Mã giao dịch hoàn tiền',
    );
    if (reference == null) return;
    await _guard(() => _service.confirmManualRefund(r.id, reference), 'Đã xác nhận hoàn tiền.');
  }

  // Khong hoan duoc: bat buoc ly do, voucher duoc khoi phuc cho khach
  Future<void> _failManual(RefundRequest r) async {
    final reason = await promptTextDialog(
      context,
      title: 'Không hoàn được tiền',
      message: 'Yêu cầu sẽ chuyển sang thất bại và voucher được khôi phục cho khách.',
      label: 'Lý do không hoàn được',
      maxLines: 3,
    );
    if (reason == null) return;
    await _guard(
      () => _service.failManualRefund(r.id, reason),
      'Đã ghi nhận không hoàn được, voucher đã được khôi phục cho khách.',
    );
  }

  Future<void> _confirmMismatch(PaymentMismatchOrder o) async {
    final remaining = o.receivedAmount - o.refundedAmount;
    final reference = await promptTextDialog(
      context,
      title: 'Xác nhận đã hoàn tiền',
      message: 'Chỉ xác nhận sau khi đã hoàn ${formatVnd(remaining)} đã nhận cho khách. Đơn sẽ chuyển sang Đã hủy.',
      label: 'Mã giao dịch hoàn tiền',
    );
    if (reference == null) return;
    await _guard(
      () => _service.confirmMismatchRefund(o.id, reference),
      'Đã ghi nhận hoàn tiền, đơn đã chuyển sang Đã hủy.',
    );
  }

  EdgeInsets get _listPadding => const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg);

  @override
  Widget build(BuildContext context) => PortalShell(
    currentRoute: AppRoutes.adminRefunds,
    child: DefaultTabController(
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Hàng đợi hoàn tiền',
            subtitle: 'Tổng tiền hoàn không bao giờ vượt quá số tiền khách đã thanh toán (DC-12), máy chủ luôn kiểm tra lại.',
            actions: [
              IconButton(
                tooltip: 'Tải lại',
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: TabBar(
              tabs: [
                Tab(text: 'Hoàn tiền thủ công'),
                Tab(text: 'Đơn lệch số tiền'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                AsyncBody<List<RefundRequest>>(
                  future: _refunds,
                  onRetry: _reload,
                  isEmpty: (list) => list.isEmpty,
                  emptyMessage: 'Không có yêu cầu nào cần xử lý thủ công.',
                  builder: (context, list) => ListView.separated(
                    padding: _listPadding,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => _RefundCard(
                      refund: list[i],
                      onConfirm: _busy ? null : () => _confirmManual(list[i]),
                      onFail: _busy ? null : () => _failManual(list[i]),
                    ),
                  ),
                ),
                AsyncBody<List<PaymentMismatchOrder>>(
                  future: _mismatches,
                  onRetry: _reload,
                  isEmpty: (list) => list.isEmpty,
                  emptyMessage: 'Không có đơn nào lệch số tiền.',
                  builder: (context, list) => ListView.separated(
                    padding: _listPadding,
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) => _MismatchCard(
                      order: list[i],
                      onConfirm: _busy ? null : () => _confirmMismatch(list[i]),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

// Mot dong "Nhan: gia tri" trong the
class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value, {this.emphasize = false});

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: AppSpacing.xs),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: '$label: ', style: const TextStyle(color: AppColors.textSecondary)),
          TextSpan(text: value, style: emphasize ? const TextStyle(fontWeight: FontWeight.w700) : null),
        ],
      ),
    ),
  );
}

class _RefundCard extends StatelessWidget {
  const _RefundCard({required this.refund, this.onConfirm, this.onFail});

  final RefundRequest refund;
  final VoidCallback? onConfirm;
  final VoidCallback? onFail;

  @override
  Widget build(BuildContext context) {
    final r = refund;
    final payment = r.payment;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.currency_exchange, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    r.campaignTitle ?? 'Voucher',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                StatusChip(r.status, label: r.statusLabel),
              ],
            ),
            _InfoLine('Mã voucher', r.voucherCode ?? r.voucherItemId),
            _InfoLine('Số tiền cần hoàn', r.amount == null ? 'Chưa xác định' : formatVnd(r.amount!), emphasize: true),
            _InfoLine('Khách hàng', r.customer?.summary ?? 'Không rõ'),
            _InfoLine(
              'Giao dịch gốc',
              payment == null
                  ? 'Không tìm thấy giao dịch đã nhận'
                  : [
                      if (payment.gateway != null) payment.gateway!,
                      if (payment.gatewayTxnId != null) 'mã ${payment.gatewayTxnId}',
                      formatVnd(payment.amount),
                    ].join(' · '),
            ),
            _InfoLine('Lý do', r.reason == null || r.reason!.isEmpty ? 'Không ghi lý do' : r.reason!),
            _InfoLine('Yêu cầu lúc', formatDateTime(r.createdAt)),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  key: Key('refund-confirm-${r.id}'),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: onConfirm,
                  icon: const Icon(Icons.done_all),
                  label: const Text('Đã hoàn tiền'),
                ),
                OutlinedButton.icon(
                  key: Key('refund-fail-${r.id}'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                  onPressed: onFail,
                  icon: const Icon(Icons.block),
                  label: const Text('Không hoàn được'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MismatchCard extends StatelessWidget {
  const _MismatchCard({required this.order, this.onConfirm});

  final PaymentMismatchOrder order;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final diff = o.receivedAmount - o.totalAmount;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rule, color: AppColors.secondary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    o.campaignTitle ?? 'Đơn hàng',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
                StatusChip(o.status),
              ],
            ),
            _InfoLine('Mã đơn', o.id),
            _InfoLine('Khách hàng', o.customer?.summary ?? 'Không rõ'),
            _InfoLine('Số tiền phải trả', formatVnd(o.totalAmount)),
            _InfoLine('Số tiền đã nhận', formatVnd(o.receivedAmount), emphasize: true),
            if (diff != 0) _InfoLine(diff > 0 ? 'Nhận thừa' : 'Nhận thiếu', formatVnd(diff.abs())),
            for (final p in o.payments) _InfoLine('Giao dịch', '${p.gatewayTxnId ?? p.id} · ${formatVnd(p.amount)}'),
            if (o.refundedAmount > 0) _InfoLine('Đã hoàn', formatVnd(o.refundedAmount)),
            _InfoLine('Tạo lúc', formatDateTime(o.createdAt)),
            const SizedBox(height: AppSpacing.sm),
            FilledButton.icon(
              key: Key('mismatch-confirm-${o.id}'),
              style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
              onPressed: onConfirm,
              icon: const Icon(Icons.done_all),
              label: const Text('Đã hoàn tiền'),
            ),
          ],
        ),
      ),
    );
  }
}
