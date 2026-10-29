import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-BRAND-03, FR-REPORT-04: duyet / tu choi ho so thuong hieu kem ly do.
// FR-BRAND-09 (F07): dinh chi thuong hieu dang hoat dong / khoi phuc thuong hieu bi dinh chi.
const _tabs = ['PENDING', 'APPROVED', 'SUSPENDED'];

class BrandApprovalScreen extends StatefulWidget {
  const BrandApprovalScreen({super.key});

  @override
  State<BrandApprovalScreen> createState() => _BrandApprovalScreenState();
}

class _BrandApprovalScreenState extends State<BrandApprovalScreen> {
  late Future<List<Brand>> _future;
  String _tab = _tabs.first;

  AdminService get _service => context.read<AdminService>();

  Future<List<Brand>> _load() => _tab == 'PENDING' ? _service.pendingBrands() : _service.brandsByStatus(_tab);

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  void _select(String tab) {
    if (tab == _tab) return;
    _tab = tab;
    _reload();
  }

  // FR-BRAND-09: ly do dinh chi duoc gui vao email cho chu thuong hieu, may chu doi it nhat 10 ky tu
  Future<void> _suspend(Brand b) async {
    final reason = await promptTextDialog(
      context,
      title: 'Đình chỉ "${b.name}"',
      label: 'Lý do đình chỉ',
      confirm: 'Đình chỉ',
      maxLines: 3,
      message: 'Chiến dịch đang bán sẽ chuyển tạm dừng. Voucher khách đã mua vẫn dùng được bình thường.',
      validator: validateRejectReason,
    );
    if (reason != null) {
      await _run(() => _service.suspendBrand(b.id, reason), 'Đã đình chỉ "${b.name}". Các chiến dịch đang bán đã tạm dừng.');
    }
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

  // UC-06 luong 3a: ly do tu choi di kem email gui cho chu thuong hieu nen rong la vo nghia
  Future<void> _reject(Brand b) async {
    final reason = await promptTextDialog(
      context,
      title: 'Từ chối "${b.name}"',
      label: 'Lý do từ chối',
      confirm: 'Từ chối',
      maxLines: 3,
      message: 'Lý do được gửi qua email cho chủ thương hiệu, hãy nêu rõ cần bổ sung gì.',
      validator: validateRejectReason,
    );
    if (reason != null) await _run(() => _service.rejectBrand(b.id, reason), 'Đã từ chối hồ sơ.');
  }

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.adminBrands,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Thương hiệu',
              actions: [IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh))],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
              child: SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'PENDING', label: Text('Chờ duyệt'), icon: Icon(Icons.hourglass_top)),
                  ButtonSegment(value: 'APPROVED', label: Text('Đang hoạt động'), icon: Icon(Icons.verified_outlined)),
                  ButtonSegment(value: 'SUSPENDED', label: Text('Bị đình chỉ'), icon: Icon(Icons.block)),
                ],
                selected: {_tab},
                onSelectionChanged: (s) => _select(s.first),
              ),
            ),
            Expanded(
              child: AsyncBody<List<Brand>>(
                future: _future,
                onRetry: _reload,
                isEmpty: (list) => list.isEmpty,
                emptyMessage: switch (_tab) {
                  'APPROVED' => 'Chưa có thương hiệu nào đang hoạt động.',
                  'SUSPENDED' => 'Không có thương hiệu nào bị đình chỉ.',
                  _ => 'Không có hồ sơ nào đang chờ duyệt.',
                },
                builder: (context, brands) => ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  itemCount: brands.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final b = brands[i];
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(b.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                            if (b.description != null && b.description!.isNotEmpty) Text(b.description!),
                            if (b.contactInfo != null) Text('Liên hệ: ${b.contactInfo}'),
                            if (b.bankInfo != null) Text('Tài khoản nhận tiền: ${b.bankInfo}'),
                            if (_tab == 'SUSPENDED' && b.rejectReason != null)
                              Text('Lý do đình chỉ: ${b.rejectReason}', style: const TextStyle(color: AppColors.danger)),
                            const SizedBox(height: AppSpacing.sm),
                            if (_tab == 'APPROVED')
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                onPressed: () => _suspend(b),
                                icon: const Icon(Icons.block),
                                label: const Text('Đình chỉ'),
                              ),
                            if (_tab == 'SUSPENDED')
                              FilledButton.icon(
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () => _run(() => _service.reinstateBrand(b.id), 'Đã khôi phục "${b.name}".'),
                                icon: const Icon(Icons.restart_alt),
                                label: const Text('Khôi phục'),
                              ),
                            if (_tab == 'PENDING') Wrap(spacing: AppSpacing.sm, children: [
                              FilledButton.icon(
                                style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                                onPressed: () => _run(() => _service.approveBrand(b.id), 'Đã duyệt "${b.name}".'),
                                icon: const Icon(Icons.check),
                                label: const Text('Duyệt'),
                              ),
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger),
                                onPressed: () => _reject(b),
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
