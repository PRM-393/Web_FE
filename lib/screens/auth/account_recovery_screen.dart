import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../../routes.dart';
import '../../utils/validators.dart';
import '../../widgets/brand_identity.dart';

// FR-AUTH-08..10: request a link or consume a one-use activation/reset link.
class AccountRecoveryScreen extends StatefulWidget {
  const AccountRecoveryScreen({
    super.key,
    required this.activation,
    this.email = '',
    this.token,
  });
  final bool activation;
  final String email;
  final String? token;
  @override
  State<AccountRecoveryScreen> createState() => _AccountRecoveryScreenState();
}

class _AccountRecoveryScreenState extends State<AccountRecoveryScreen> {
  final _form = GlobalKey<FormState>();
  late final _email = TextEditingController(text: widget.email);
  final _password = TextEditingController();
  bool _busy = false;
  String? _error, _success;
  bool get _confirm => widget.token?.isNotEmpty ?? false;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final service = context.read<AuthService>();
      if (_confirm) {
        await service.completeRecovery(
          activation: widget.activation,
          email: _email.text.trim(),
          token: widget.token!,
          password: _password.text,
        );
      } else {
        await service.requestRecovery(
          _email.text.trim(),
          activation: widget.activation,
        );
      }
      if (mounted) {
        setState(
          () => _success = _confirm
              ? 'Đã cập nhật tài khoản. Bạn có thể đăng nhập.'
              : 'Nếu tài khoản phù hợp, email hướng dẫn sẽ được gửi. Kiểm tra cả thư rác.',
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const BrandIdentity(),
                const SizedBox(height: 32),
                Text(
                  widget.activation
                      ? 'Kích hoạt tài khoản'
                      : 'Đặt lại mật khẩu',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 16),
                if (_success != null)
                  Text(_success!)
                else ...[
                  const Text(
                    'Liên kết có hiệu lực 24 giờ và chỉ dùng một lần.',
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _email,
                    readOnly: _confirm,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: validateEmail,
                  ),
                  if (_confirm) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Mật khẩu mới',
                      ),
                      validator: (v) =>
                          (v?.length ?? 0) < 8 || (v?.length ?? 0) > 128
                          ? 'Mật khẩu từ 8 đến 128 ký tự'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Nhập lại mật khẩu',
                      ),
                      validator: (v) =>
                          v != _password.text ? 'Mật khẩu không khớp' : null,
                    ),
                  ],
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy
                          ? 'Đang xử lý…'
                          : _confirm
                          ? 'Lưu mật khẩu'
                          : 'Gửi liên kết',
                    ),
                  ),
                ],
                TextButton(
                  onPressed: () => AppRoutes.go(context, AppRoutes.login),
                  child: const Text('Về đăng nhập'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
