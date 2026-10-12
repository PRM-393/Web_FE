import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../providers/brand_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-BRAND-01/02/03: dang ky ho so thuong hieu va xem trang thai duyet.
// Trong luc cho duyet van tao duoc chi nhanh va chien dich nhap, nhung chua gui duyet chien dich (BR-26).
class BrandProfileScreen extends StatefulWidget {
  const BrandProfileScreen({super.key});

  @override
  State<BrandProfileScreen> createState() => _BrandProfileScreenState();
}

class _BrandProfileScreenState extends State<BrandProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BrandProvider>().ensureLoaded();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BrandProvider>();
    final Widget body;
    if (provider.error != null && !provider.isLoaded) {
      body = MessageView(icon: Icons.cloud_off, message: provider.error!, onRetry: provider.load);
    } else if (!provider.isLoaded) {
      body = const Center(child: CircularProgressIndicator());
    } else if (provider.brand == null) {
      body = const _RegisterBrandForm();
    } else {
      body = _BrandInfo(brand: provider.brand!);
    }
    return PortalShell(currentRoute: AppRoutes.brandProfile, child: body);
  }
}

class _BrandInfo extends StatelessWidget {
  const _BrandInfo({required this.brand});

  final Brand brand;

  @override
  Widget build(BuildContext context) {
    final (icon, color, note) = switch (brand.status) {
      BrandStatus.approved => (Icons.verified, AppColors.success, 'Hồ sơ đã được duyệt. Bạn có thể gửi duyệt chiến dịch.'),
      BrandStatus.rejected => (
          Icons.cancel_outlined,
          AppColors.danger,
          'Hồ sơ bị từ chối: ${brand.rejectReason ?? 'không có lý do'}. Vui lòng liên hệ quản trị viên.'
        ),
      _ => (
          Icons.hourglass_top,
          AppColors.secondary,
          'Hồ sơ đang chờ quản trị viên duyệt. Bạn vẫn tạo được chi nhánh và chiến dịch nháp.'
        ),
    };
    return ListView(
      children: [
        PageHeader(title: brand.name, subtitle: 'Hồ sơ thương hiệu'),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(icon, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    StatusChip(brand.status),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  Text(note),
                  const Divider(height: AppSpacing.xl),
                  _row('Mô tả', brand.description),
                  _row('Liên hệ', brand.contactInfo),
                  _row('Tài khoản nhận tiền', brand.bankInfo),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String? value) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 180, child: Text(label, style: const TextStyle(color: AppColors.textSecondary))),
            Expanded(child: Text(value == null || value.isEmpty ? '—' : value)),
          ],
        ),
      );
}

class _RegisterBrandForm extends StatefulWidget {
  const _RegisterBrandForm();

  @override
  State<_RegisterBrandForm> createState() => _RegisterBrandFormState();
}

class _RegisterBrandFormState extends State<_RegisterBrandForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _logo = TextEditingController();
  final _contact = TextEditingController();
  final _bank = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_name, _description, _logo, _contact, _bank]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await context.read<BrandProvider>().register(
            name: _name.text.trim(),
            description: _description.text.trim(),
            logo: _logo.text.trim(),
            contactInfo: _contact.text.trim(),
            bankInfo: _bank.text.trim(),
          );
      if (mounted) showMessage(context, 'Đã gửi hồ sơ, vui lòng chờ quản trị viên duyệt.');
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
        children: [
          const PageHeader(title: 'Đăng ký thương hiệu', subtitle: 'Hồ sơ sẽ ở trạng thái chờ duyệt (FR-BRAND-02)'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'Tên thương hiệu *'),
                      validator: (v) => validateRequired(v, 'tên thương hiệu'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _description,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Mô tả'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(controller: _logo, decoration: const InputDecoration(labelText: 'Đường dẫn logo')),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(controller: _contact, decoration: const InputDecoration(labelText: 'Thông tin liên hệ')),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(controller: _bank, decoration: const InputDecoration(labelText: 'Tài khoản nhận tiền')),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton(
                      onPressed: _submitting ? null : _submit,
                      child: Text(_submitting ? 'Đang gửi...' : 'Gửi hồ sơ'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
}
