import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes.dart';
import '../../widgets/common.dart';

// Sai vai tro khi mo mot khu vuc (FR-AUTH-07)
class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({super.key});

  @override
  Widget build(BuildContext context) => _FullPageMessage(
        icon: Icons.block,
        message: 'Tài khoản của bạn không có quyền xem trang này.',
        action: 'Về trang của tôi',
        onAction: () => AppRoutes.go(context, AppRoutes.homeOf(context.read<AuthProvider>().role)),
      );
}

class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) => _FullPageMessage(
        icon: Icons.search_off,
        message: 'Không tìm thấy trang.',
        action: 'Về trang chủ',
        onAction: () => AppRoutes.go(context, AppRoutes.root),
      );
}

class _FullPageMessage extends StatelessWidget {
  const _FullPageMessage({required this.icon, required this.message, required this.action, required this.onAction});

  final IconData icon;
  final String message;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              MessageView(icon: icon, message: message),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(200, 48)),
                onPressed: onAction,
                child: Text(action),
              ),
            ],
          ),
        ),
      );
}
