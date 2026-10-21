import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/store_session_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-AUTH-12: sau dang nhap, nhan vien chon chi nhanh lam viec trong so chi nhanh duoc gan dang hoat dong.
// Chi nhanh da chon gan voi phien va duoc gui kem moi lan xac nhan su dung (BR-07).
class StoreSelectScreen extends StatefulWidget {
  const StoreSelectScreen({super.key});

  @override
  State<StoreSelectScreen> createState() => _StoreSelectScreenState();
}

class _StoreSelectScreenState extends State<StoreSelectScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<StoreSessionProvider>().loadStores();
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<StoreSessionProvider>();
    final Widget body;
    if (session.isLoadingStores) {
      body = const Center(child: CircularProgressIndicator());
    } else if (session.storesError != null) {
      body = MessageView(
        icon: Icons.cloud_off,
        message: session.storesError!,
        onRetry: session.loadStores,
      );
    } else if (session.stores.isEmpty) {
      body = MessageView(
        icon: Icons.store_mall_directory_outlined,
        message: 'Tài khoản chưa được gán chi nhánh đang hoạt động nào. Vui lòng liên hệ chủ thương hiệu.',
        onRetry: session.loadStores,
      );
    } else {
      body = ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        children: [
          for (final s in session.stores)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  leading: const Icon(
                    Icons.storefront,
                    color: AppColors.primary,
                  ),
                  title: Text(
                    s.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(s.address),
                  trailing: session.currentStore?.id == s.id
                      ? const Icon(Icons.check_circle, color: AppColors.success)
                      : const Icon(Icons.chevron_right),
                  onTap: () async {
                    try {
                      await session.selectStore(s);
                      if (context.mounted) {
                        AppRoutes.go(context, AppRoutes.storeRedeem);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        showMessage(context, e.toString(), error: true);
                      }
                    }
                  },
                ),
              ),
            ),
        ],
      );
    }
    return PortalShell(
      currentRoute: AppRoutes.storeSelect,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: 'Chọn chi nhánh làm việc'),
          Expanded(child: body),
        ],
      ),
    );
  }
}
