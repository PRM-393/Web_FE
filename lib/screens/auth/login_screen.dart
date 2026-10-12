import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';

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
      Navigator.pushNamedAndRemoveUntil(context, AppRoutes.homeOf(auth.role), (_) => false);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.local_offer, size: 48, color: AppColors.primary),
                        const SizedBox(height: AppSpacing.sm),
                        Text('Đăng nhập',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: AppSpacing.xs),
                        const Text(
                          'Dành cho chủ thương hiệu, nhân viên cửa hàng và quản trị viên',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextFormField(
                          key: const Key('login-email'),
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline)),
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
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
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
                              ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Đăng nhập'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        const Text(
                          'Khách hàng vui lòng dùng ứng dụng di động để mua và sử dụng voucher.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
}
