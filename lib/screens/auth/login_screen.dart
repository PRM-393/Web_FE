import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/brand_identity.dart';

// FR-AUTH-06: dang nhap email + mat khau cho chu thuong hieu, nhan vien cua hang, quan tri vien.
// Thanh cong thi vao trang chu cua vai tro (AppRoutes.homeOf).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _submitting = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      await auth.login(_emailController.text, _passwordController.text);
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.homeOf(auth.role),
        (_) => false,
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1000;
        final form = Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(wide ? 48 : 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: _form(context),
            ),
          ),
        );
        return Row(
          children: [
            if (wide)
              Expanded(
                child: Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(44),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF083F38), Color(0xFF176A5B)],
                    ),
                    borderRadius: BorderRadius.circular(32),
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const BrandIdentity(light: true),
                        const SizedBox(height: 42),
                        const Text(
                          'Kết nối ưu đãi.\nNuôi dưỡng khách hàng.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            height: 1.15,
                            letterSpacing: -1.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Không gian vận hành dành cho thương hiệu, cửa hàng và những trải nghiệm đáng nhớ.',
                          style: TextStyle(
                            color: Color(0xFFCEE5DC),
                            fontSize: 16,
                            height: 1.6,
                          ),
                        ),
                        const VoucherArtwork(),
                        const Divider(color: Color(0xFF407B6B)),
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              color: Color(0xFFD8F5A2),
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Một nền tảng. Mọi điểm chạm.',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            Expanded(child: form),
          ],
        );
      },
    ),
  );

  Widget _form(BuildContext context) => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: BrandIdentity()),
        const SizedBox(height: 36),
        const Text(
          'CHÀO MỪNG TRỞ LẠI',
          style: TextStyle(
            fontSize: 11,
            letterSpacing: 2,
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Đăng nhập',
          textAlign: TextAlign.left,
          style: Theme.of(context).textTheme.headlineSmall
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'Dành cho chủ thương hiệu, nhân viên cửa hàng và quản trị viên',
          textAlign: TextAlign.left,
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.lg),
        TextFormField(
          key: const Key('login-email'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(
            labelText: 'Email',
            prefixIcon: Icon(Icons.mail_outline),
          ),
          validator: validateEmail,
        ),
        const SizedBox(height: AppSpacing.md),
        TextFormField(
          key: const Key('login-password'),
          controller: _passwordController,
          obscureText: _obscure,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            labelText: 'Mật khẩu',
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              tooltip: _obscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          ),
          validator: validatePassword,
          onFieldSubmitted: (_) => _submit(),
        ),
        if (_error != null) ...[
          const SizedBox(height: AppSpacing.md),
          Text(_error!, style: const TextStyle(color: AppColors.danger)),
        ],
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          key: const Key('login-submit'),
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Đăng nhập'),
        ),
        const SizedBox(height: AppSpacing.md),
        const Text(
          'Khách hàng vui lòng dùng ứng dụng di động để mua và sử dụng voucher.',
          textAlign: TextAlign.left,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    ),
  );
}
