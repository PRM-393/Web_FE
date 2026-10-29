import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/brand_identity.dart';

// FR-BRAND-01 / FR-BRAND-02: doanh nghiep tu dang ky ho so khi CHUA co tai khoan.
// Khac man "Dang ky thuong hieu" trong portal (brand_profile_screen): man do danh cho nguoi da dang nhap
// san bang vai tro BrandOwner. Truoc khi co man nay, khong co duong nao de mot thuong hieu moi vao he thong.
//
// May chu tao User BrandOwner PENDING_ACTIVATION + Brand PENDING roi gui lien ket dat mat khau,
// nen sau khi gui xong chi hien huong dan kiem tra email - khong tu dang nhap duoc ngay.
class BrandRegisterScreen extends StatefulWidget {
  const BrandRegisterScreen({super.key});

  @override
  State<BrandRegisterScreen> createState() => _BrandRegisterScreenState();
}

class _BrandRegisterScreenState extends State<BrandRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _ownerEmail = TextEditingController();
  final _ownerFullName = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _contactInfo = TextEditingController();
  final _bankInfo = TextEditingController();

  bool _submitting = false;
  String? _error;
  BrandRegistration? _done;

  @override
  void dispose() {
    for (final c in [_ownerEmail, _ownerFullName, _ownerPhone, _name, _description, _contactInfo, _bankInfo]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await context.read<BrandService>().registerPublic(
            ownerEmail: _ownerEmail.text,
            ownerFullName: _ownerFullName.text,
            ownerPhone: _ownerPhone.text,
            name: _name.text,
            description: _description.text,
            contactInfo: _contactInfo.text,
            bankInfo: _bankInfo.text,
          );
      if (!mounted) return;
      setState(() => _done = result);
    } catch (e) {
      // Loi nghiep vu cua may chu (email da co ho so, email thuoc vai tro khac) hien nguyen van
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _done == null ? _form() : _success(_done!),
                ),
              ),
            ),
          ),
        ),
      );

  Widget _form() => Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const BrandIdentity(),
            const SizedBox(height: AppSpacing.lg),
            Text('Đăng ký bán voucher', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.lg),
              child: Text(
                'Hồ sơ sẽ ở trạng thái chờ duyệt. Chúng tôi gửi liên kết đặt mật khẩu qua email ngay sau khi bạn gửi.',
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
            _section('Người đại diện'),
            TextFormField(
              key: const Key('register-owner-email'),
              controller: _ownerEmail,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email đăng nhập *'),
              validator: validateEmail,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              key: const Key('register-owner-name'),
              controller: _ownerFullName,
              decoration: const InputDecoration(labelText: 'Họ tên *'),
              validator: (v) => validateRequired(v, 'họ tên'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _ownerPhone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Số điện thoại'),
            ),
            _section('Thương hiệu'),
            TextFormField(
              key: const Key('register-brand-name'),
              controller: _name,
              decoration: const InputDecoration(labelText: 'Tên thương hiệu *'),
              validator: (v) => validateRequired(v, 'tên thương hiệu'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _description,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Giới thiệu'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _contactInfo,
              decoration: const InputDecoration(labelText: 'Hotline / thông tin liên hệ'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _bankInfo,
              decoration: const InputDecoration(
                labelText: 'Tài khoản nhận đối soát',
                helperText: 'Ngân hàng, số tài khoản và tên chủ tài khoản. Có thể bổ sung sau khi được duyệt.',
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!, key: const Key('register-error'), style: const TextStyle(color: AppColors.danger)),
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton(
              key: const Key('register-submit'),
              onPressed: _submitting ? null : _submit,
              child: Text(_submitting ? 'Đang gửi...' : 'Gửi hồ sơ'),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton(
              onPressed: () => AppRoutes.go(context, AppRoutes.login),
              child: const Text('Đã có tài khoản? Đăng nhập'),
            ),
          ],
        ),
      );

  Widget _success(BrandRegistration result) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mark_email_read_outlined, size: 56, color: AppColors.primary),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Đã nhận hồ sơ',
            key: const Key('register-success'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(result.message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: () => AppRoutes.go(context, AppRoutes.activate),
            child: const Text('Tôi đã nhận email, đặt mật khẩu ngay'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextButton(
            onPressed: () => AppRoutes.go(context, AppRoutes.login),
            child: const Text('Về trang đăng nhập'),
          ),
        ],
      );

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      );
}
