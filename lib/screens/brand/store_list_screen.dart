import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../providers/brand_provider.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/validators.dart';
import '../../widgets/brand_gate.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-BRAND-04: tao, vo hieu hoa chi nhanh (ten, dia chi, toa do, gio mo cua, dien thoai).
// Toa do bat buoc khi chi nhanh hoat dong (DC-05) de khach tim voucher gan day.
class StoreListScreen extends StatelessWidget {
  const StoreListScreen({super.key});

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.brandStores,
        child: BrandGate(builder: (context, brand) => _StoreList(brand: brand)),
      );
}

class _StoreList extends StatelessWidget {
  const _StoreList({required this.brand});

  final Brand brand;

  Future<void> _add(BuildContext context) async {
    final created = await showDialog<bool>(context: context, builder: (_) => _StoreDialog(brandId: brand.id));
    if (created == true && context.mounted) {
      await context.read<BrandProvider>().reloadStores();
      if (context.mounted) showMessage(context, 'Đã thêm chi nhánh.');
    }
  }

  Future<void> _deactivate(BuildContext context, Store store) async {
    final ok = await confirmDialog(context,
        title: 'Vô hiệu hóa chi nhánh',
        message: 'Chi nhánh "${store.name}" sẽ không nhận xác nhận sử dụng voucher nữa.',
        confirm: 'Vô hiệu hóa');
    if (!ok || !context.mounted) return;
    try {
      await context.read<BrandService>().deactivateStore(store.id);
      if (!context.mounted) return;
      await context.read<BrandProvider>().reloadStores();
      if (context.mounted) showMessage(context, 'Đã vô hiệu hóa chi nhánh.');
    } catch (e) {
      if (context.mounted) showMessage(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stores = context.watch<BrandProvider>().stores;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageHeader(
          title: 'Chi nhánh',
          subtitle: '${stores.where((s) => s.active).length} chi nhánh đang hoạt động',
          actions: [
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: () => _add(context),
              icon: const Icon(Icons.add),
              label: const Text('Thêm chi nhánh'),
            ),
          ],
        ),
        Expanded(
          child: stores.isEmpty
              ? const MessageView(icon: Icons.storefront_outlined, message: 'Chưa có chi nhánh nào.')
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  itemCount: stores.length,
                  separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, i) {
                    final s = stores[i];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.storefront),
                        title: Text(s.name),
                        subtitle: Text([
                          s.address,
                          if (s.phone != null) 'ĐT: ${s.phone}',
                          if (s.openingHours != null) 'Mở cửa: ${s.openingHours}',
                        ].join(' · ')),
                        trailing: Wrap(
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusChip(s.active ? 'ACTIVE' : 'INACTIVE'),
                            if (s.active)
                              IconButton(
                                tooltip: 'Vô hiệu hóa',
                                icon: const Icon(Icons.block, color: AppColors.danger),
                                onPressed: () => _deactivate(context, s),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _StoreDialog extends StatefulWidget {
  const _StoreDialog({required this.brandId});

  final String brandId;

  @override
  State<_StoreDialog> createState() => _StoreDialogState();
}

class _StoreDialogState extends State<_StoreDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _address = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _phone = TextEditingController();
  final _hours = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _address, _lat, _lng, _phone, _hours]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<BrandService>().createStore(
            widget.brandId,
            name: _name.text.trim(),
            address: _address.text.trim(),
            latitude: double.parse(_lat.text.trim()),
            longitude: double.parse(_lng.text.trim()),
            phone: _phone.text.trim(),
            openingHours: _hours.text.trim(),
          );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Thêm chi nhánh'),
        content: SizedBox(
          width: 480,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Tên chi nhánh *'),
                    validator: (v) => validateRequired(v, 'tên chi nhánh'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _address,
                    decoration: const InputDecoration(labelText: 'Địa chỉ *'),
                    validator: (v) => validateRequired(v, 'địa chỉ'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(children: [
                    Expanded(
                      child: TextFormField(
                        controller: _lat,
                        decoration: const InputDecoration(labelText: 'Vĩ độ *', hintText: '10.7769'),
                        validator: validateLatitude,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: TextFormField(
                        controller: _lng,
                        decoration: const InputDecoration(labelText: 'Kinh độ *', hintText: '106.7009'),
                        validator: validateLongitude,
                      ),
                    ),
                  ]),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(controller: _phone, decoration: const InputDecoration(labelText: 'Điện thoại')),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _hours,
                    decoration: const InputDecoration(labelText: 'Giờ mở cửa', hintText: '08:00 - 22:00'),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(_error!, style: const TextStyle(color: AppColors.danger)),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(96, 40)),
            onPressed: _saving ? null : _save,
            child: const Text('Lưu'),
          ),
        ],
      );
}
