import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../models/campaign.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/brand_gate.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-CAMP-06/08: danh sach chien dich cua thuong hieu, gui duyet, tam dung / ban lai
class CampaignListScreen extends StatelessWidget {
  const CampaignListScreen({super.key});

  @override
  Widget build(BuildContext context) => PortalShell(
    currentRoute: AppRoutes.brandCampaigns,
    child: BrandGate(builder: (context, brand) => _CampaignList(brand: brand)),
  );
}

class _CampaignList extends StatefulWidget {
  const _CampaignList({required this.brand});

  final Brand brand;

  @override
  State<_CampaignList> createState() => _CampaignListState();
}

class _CampaignListState extends State<_CampaignList> {
  late Future<List<VoucherCampaign>> _future;

  CampaignService get _service => context.read<CampaignService>();

  @override
  void initState() {
    super.initState();
    _future = _service.byBrand(widget.brand.id);
  }

  void _reload() {
    setState(() {
      _future = _service.byBrand(widget.brand.id);
    });
  }

  Future<void> _openForm([VoucherCampaign? campaign]) async {
    final saved = await Navigator.pushNamed(
      context,
      AppRoutes.brandCampaignForm,
      arguments: campaign,
    );
    if (saved == true) _reload();
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

  Future<void> _submit(VoucherCampaign c) async {
    final ok = await confirmDialog(
      context,
      title: 'Gửi duyệt chiến dịch',
      message: 'Gửi "${c.title}" cho quản trị viên duyệt?',
      confirm: 'Gửi duyệt',
    );
    if (ok) await _run(() => _service.submit(c.id), 'Đã gửi duyệt chiến dịch.');
  }

  Future<void> _pause(VoucherCampaign c) async {
    final ok = await confirmDialog(
      context,
      title: 'Tạm dừng bán',
      message: 'Khách sẽ không mua mới được. Voucher đã bán vẫn dùng bình thường.',
      confirm: 'Tạm dừng',
    );
    if (ok) await _run(() => _service.pause(c.id), 'Đã tạm dừng chiến dịch.');
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      PageHeader(
        title: 'Chiến dịch voucher',
        subtitle: widget.brand.name,
        actions: [
          IconButton(
            tooltip: 'Tải lại',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Tạo chiến dịch'),
          ),
        ],
      ),
      if (!widget.brand.isApproved)
        const _Banner(
          'Thương hiệu chưa được duyệt: bạn có thể tạo chiến dịch nháp nhưng chưa gửi duyệt được.',
        ),
      Expanded(
        child: AsyncBody<List<VoucherCampaign>>(
          future: _future,
          onRetry: _reload,
          isEmpty: (list) => list.isEmpty,
          emptyMessage:
              'Chưa có chiến dịch nào. Bấm "Tạo chiến dịch" để bắt đầu.',
          builder: (context, campaigns) => ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            itemCount: campaigns.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) => _CampaignTile(
              campaign: campaigns[i],
              canSubmit: widget.brand.isApproved,
              onEdit: () => _openForm(campaigns[i]),
              onSubmit: () => _submit(campaigns[i]),
              onPause: () => _pause(campaigns[i]),
              onResume: () => _run(
                () => _service.resume(campaigns[i].id),
                'Đã mở bán lại chiến dịch.',
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _CampaignTile extends StatelessWidget {
  const _CampaignTile({
    required this.campaign,
    required this.canSubmit,
    required this.onEdit,
    required this.onSubmit,
    required this.onPause,
    required this.onResume,
  });

  final VoucherCampaign campaign;
  final bool canSubmit;
  final VoidCallback onEdit;
  final VoidCallback onSubmit;
  final VoidCallback onPause;
  final VoidCallback onResume;

  @override
  Widget build(BuildContext context) {
    final c = campaign;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: c.voucherType == 'DISCOUNT'
                    ? const Color(0xFFF6EBD5)
                    : const Color(0xFFE6F1E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.confirmation_number_outlined,
                    size: 36,
                    color: AppColors.primaryDark,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      VoucherType.labels[c.voucherType] ?? c.voucherType,
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  Text(
                    formatVnd(c.salePrice),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                StatusChip(c.status),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                Text(VoucherType.labels[c.voucherType] ?? c.voucherType),
                Text(
                  'Giá bán ${formatVnd(c.salePrice)} · Giá trị ${formatVnd(c.faceValue)}',
                ),
                Text(
                  'Đã bán ${c.soldQuantity}/${c.totalQuantity} · Còn ${c.remaining}',
                ),
                Text(
                  'Bán ${formatDate(c.saleStartAt)} – ${formatDate(c.saleEndAt)} · HSD ${formatDate(c.voucherExpireAt)}',
                ),
              ],
            ),
            if (c.rejectReason != null &&
                c.rejectReason!.isNotEmpty &&
                c.status == CampaignStatus.draft)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: Text(
                  'Lý do bị từ chối: ${c.rejectReason}',
                  style: const TextStyle(color: AppColors.danger),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: c.totalQuantity > 0
                    ? (c.soldQuantity / c.totalQuantity).clamp(0, 1)
                    : 0,
                minHeight: 5,
                backgroundColor: const Color(0xFFEDF2EC),
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                if (c.canEdit)
                  OutlinedButton.icon(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit),
                    label: const Text('Sửa'),
                  ),
                if (c.canSubmit)
                  FilledButton.tonalIcon(
                    onPressed: canSubmit ? onSubmit : null,
                    icon: const Icon(Icons.send),
                    label: const Text('Gửi duyệt'),
                  ),
                if (c.canPause)
                  OutlinedButton.icon(
                    onPressed: onPause,
                    icon: const Icon(Icons.pause),
                    label: const Text('Tạm dừng'),
                  ),
                if (c.canResume)
                  OutlinedButton.icon(
                    onPressed: onResume,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Bán lại'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      0,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.secondary.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline, color: AppColors.secondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
