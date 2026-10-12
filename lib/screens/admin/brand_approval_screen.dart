import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-BRAND-03, FR-REPORT-04: duyet / tu choi ho so thuong hieu kem ly do
class BrandApprovalScreen extends StatefulWidget {
  const BrandApprovalScreen({super.key});

  @override
  State<BrandApprovalScreen> createState() => _BrandApprovalScreenState();
}

class _BrandApprovalScreenState extends State<BrandApprovalScreen> {
  late Future<List<Brand>> _future;

  AdminService get _service => context.read<AdminService>();

  @override
  void initState() {
    super.initState();
    _future = _service.pendingBrands();
  }

  void _reload() {
    setState(() {
      _future = _service.pendingBrands();
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

  Future<void> _reject(Brand b) async {
    final reason = await promptTextDialog(context, title: 'Từ chối "${b.name}"', label: 'Lý do từ chối', confirm: 'Từ chối');
    if (reason != null) await _run(() => _service.rejectBrand(b.id, reason), 'Đã từ chối hồ sơ.');
  }

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.adminBrands,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Hồ sơ thương hiệu chờ duyệt',
              actions: [IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh))],
            ),
            Expanded(
              child: AsyncBody<List<Brand>>(
                future: _future,
                onRetry: _reload,
                isEmpty: (list) => list.isEmpty,
                emptyMessage: 'Không có hồ sơ nào đang chờ duyệt.',
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
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(spacing: AppSpacing.sm, children: [
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
