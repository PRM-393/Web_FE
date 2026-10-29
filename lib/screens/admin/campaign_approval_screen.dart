import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// UC-04, FR-CAMP-07: quan tri vien duyet hoac tu choi chien dich kem ly do
class CampaignApprovalScreen extends StatefulWidget {
  const CampaignApprovalScreen({super.key});

  @override
  State<CampaignApprovalScreen> createState() => _CampaignApprovalScreenState();
}

class _CampaignApprovalScreenState extends State<CampaignApprovalScreen> {
  late Future<List<VoucherCampaign>> _future;

  AdminService get _service => context.read<AdminService>();

  @override
  void initState() {
    super.initState();
    _future = _service.pendingCampaigns();
  }

  void _reload() {
    setState(() {
      _future = _service.pendingCampaigns();
    });
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    try {
      await action();
      if (!mounted) return;
      showMessage(context, success);
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  // UC-04 luong 3a: ly do bat buoc va phai du y nghia - may chu doi it nhat 10 ky tu.
  // Kiem ngay tren hop thoai de quan tri vien khong bam "Tu choi" roi moi nhan loi 400.
  Future<void> _reject(VoucherCampaign c) async {
    final reason = await promptTextDialog(
      context,
      title: 'Từ chối "${c.title}"',
      label: 'Lý do từ chối',
      confirm: 'Từ chối',
      maxLines: 3,
      message: 'Lý do được gửi lại cho thương hiệu kèm chiến dịch về nháp, hãy nêu rõ cần sửa gì.',
      validator: validateRejectReason,
    );
    if (reason != null) await _run(() => _service.rejectCampaign(c.id, reason), 'Đã từ chối chiến dịch.');
  }

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.adminCampaigns,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Chiến dịch chờ duyệt',
              actions: [IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh))],
            ),
            Expanded(
              child: AsyncBody<List<VoucherCampaign>>(
                future: _future,
                onRetry: _reload,
                isEmpty: (list) => list.isEmpty,
                emptyMessage: 'Không có chiến dịch nào đang chờ duyệt.',
                builder: (context, campaigns) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  itemCount: campaigns.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final c = campaigns[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.xs, children: [
                              Text(VoucherType.labels[c.voucherType] ?? c.voucherType),
                              Text('Giá bán ${formatVnd(c.salePrice)} · Giá trị ${formatVnd(c.faceValue)}'),
                              Text('Số lượng ${c.totalQuantity} · Tối đa ${c.limitPerUser}/người'),
                              Text('Bán ${formatDate(c.saleStartAt)} – ${formatDate(c.saleEndAt)} · HSD ${formatDate(c.voucherExpireAt)}'),
                            ]),
                            if (c.description != null && c.description!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(c.description!),
                            ],
                            if (c.terms != null && c.terms!.isNotEmpty)
                              Text('Điều kiện: ${c.terms}', style: const TextStyle(color: AppColors.textSecondary)),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(spacing: AppSpacing.sm, children: [
                              FilledButton.icon(
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () => _run(() => _service.approveCampaign(c.id), 'Đã duyệt "${c.title}".'),
                                icon: const Icon(Icons.check),
                                label: const Text('Duyệt'),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                onPressed: () => _reject(c),
                                icon: const Icon(Icons.close),
                                label: const Text('Từ chối'),
                              ),
                            ]),
                          ],
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
