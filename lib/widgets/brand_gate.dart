import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/brand.dart';
import '../providers/brand_provider.dart';
import '../routes.dart';
import 'common.dart';

// Bao boc cac man cua portal thuong hieu: tai ho so mot lan, chua co ho so thi huong dan dang ky (FR-BRAND-01).
class BrandGate extends StatefulWidget {
  const BrandGate({super.key, required this.builder});

  final Widget Function(BuildContext context, Brand brand) builder;

  @override
  State<BrandGate> createState() => _BrandGateState();
}

class _BrandGateState extends State<BrandGate> {
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
    if (provider.error != null && !provider.isLoaded) {
      return MessageView(icon: Icons.cloud_off, message: provider.error!, onRetry: provider.load);
    }
    if (!provider.isLoaded) return const Center(child: CircularProgressIndicator());
    final brand = provider.brand;
    if (brand == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const MessageView(
              icon: Icons.business_outlined,
              message: 'Bạn chưa có hồ sơ thương hiệu. Hãy gửi hồ sơ để quản trị viên duyệt.',
            ),
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(220, 48)),
              onPressed: () => AppRoutes.go(context, AppRoutes.brandProfile),
              child: const Text('Đăng ký thương hiệu'),
            ),
          ],
        ),
      );
    }
    return widget.builder(context, brand);
  }
}
