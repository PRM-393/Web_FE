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

// FR-BRAND-04: tao, sua, vo hieu hoa va mo lai chi nhanh (ten, dia chi, toa do, gio mo cua, dien thoai).
// Toa do bat buoc khi chi nhanh hoat dong (DC-05) de khach tim voucher gan day.
// BR-24: may chu tu choi vo hieu hoa chi nhanh ap dung cuoi cung cua chien dich con voucher chua dung;
// man hinh chi viec hien nguyen van ly do tra ve.
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

  Future<void> _openDialog(BuildContext context, {Store? store}) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _StoreDialog(brandId: brand.id, store: store),
    );
    if (saved == true && context.mounted) {
      await context.read<BrandProvider>().reloadStores();
      if (context.mounted) {
        showMessage(context, store == null ? 'Đã thêm chi nhánh.' : 'Đã lưu thay đổi.');
      }
    }
  }

  Future<void> _deactivate(BuildContext context, Store store) async {
    final ok = await confirmDialog(context,
        title: 'Vô hiệu hóa chi nhánh',
        message: 'Chi nhánh "${store.name}" sẽ không nhận xác nhận sử dụng voucher nữa.',
        confirm: 'Vô hiệu hóa');
    if (!ok || !context.mounted) return;
    await _run(context, () => context.read<BrandService>().deactivateStore(store.id),
        success: 'Đã vô hiệu hóa chi nhánh.');
  }

  // Mo lai chi nhanh: may chu chan neu chi nhanh thieu toa do (DC-05), ly do hien ngay tren man hinh
  Future<void> _reactivate(BuildContext context, Store store) async {
    await _run(context, () => context.read<BrandService>().updateStore(store.id, status: true),
        success: 'Đã mở lại chi nhánh.');
  }

  Future<void> _run(BuildContext context, Future<void> Function() action, {required String success}) async {
    try {
      await action();
      if (!context.mounted) return;
      await context.read<BrandProvider>().reloadStores();
      if (context.mounted) showMessage(context, success);
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
              onPressed: () => _openDialog(context),
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
                          // DC-05: toa do la thu khach dung de tim chi nhanh gan nhat, hien ra cho de doi chieu
                          if (s.latitude != null && s.longitude != null)
                            'Tọa độ: ${s.latitude!.toStringAsFixed(4)}, ${s.longitude!.toStringAsFixed(4)}'
                          else
                            'Chưa có tọa độ',
                        ].join(' · ')),
                        trailing: Wrap(
                          spacing: AppSpacing.sm,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            StatusChip(s.active ? 'ACTIVE' : 'INACTIVE'),
                            IconButton(
                              tooltip: 'Sửa',
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => _openDialog(context, store: s),
                            ),
                            if (s.active)
                              IconButton(
                                tooltip: 'Vô hiệu hóa',
                                icon: const Icon(Icons.block, color: AppColors.danger),
                                onPressed: () => _deactivate(context, s),
                              )
                            else
                              TextButton.icon(
                                onPressed: () => _reactivate(context, s),
                                icon: const Icon(Icons.restart_alt),
                                label: const Text('Mở lại'),
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

// Dung chung cho them moi va sua: store != null la dang sua
class _StoreDialog extends StatefulWidget {
  const _StoreDialog({required this.brandId, this.store});

  final String brandId;
  final Store? store;

  @override
  State<_StoreDialog> createState() => _StoreDialogState();
}

class _StoreDialogState extends State<_StoreDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _lat;
  late final TextEditingController _lng;
  late final TextEditingController _phone;
  late final TextEditingController _hours;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.store != null;

  @override
  void initState() {
    super.initState();
    final s = widget.store;
    _name = TextEditingController(text: s?.name ?? '');
    _address = TextEditingController(text: s?.address ?? '');
    _lat = TextEditingController(text: s?.latitude?.toString() ?? '');
    _lng = TextEditingController(text: s?.longitude?.toString() ?? '');
    _phone = TextEditingController(text: s?.phone ?? '');
    _hours = TextEditingController(text: s?.openingHours ?? '');
  }

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
      final service = context.read<BrandService>();
      if (_isEdit) {
        await service.updateStore(
          widget.store!.id,
          name: _name.text.trim(),
          address: _address.text.trim(),
          latitude: double.parse(_lat.text.trim()),
          longitude: double.parse(_lng.text.trim()),
          phone: _phone.text.trim(),
          openingHours: _hours.text.trim(),
        );
      } else {
        await service.createStore(
          widget.brandId,
          name: _name.text.trim(),
          address: _address.text.trim(),
          latitude: double.parse(_lat.text.trim()),
          longitude: double.parse(_lng.text.trim()),
          phone: _phone.text.trim(),
          openingHours: _hours.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(_isEdit ? 'Sửa chi nhánh' : 'Thêm chi nhánh'),
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
                  const SizedBox(height: AppSpacing.xs),
                  // DC-05: noi ro vi sao toa do la bat buoc, de nguoi dung khong tuong la truong thua
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Chi nhánh đang hoạt động bắt buộc có tọa độ để khách tìm được trên bản đồ.',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
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
            key: const Key('store-save'),
            style: FilledButton.styleFrom(minimumSize: const Size(96, 40)),
            onPressed: _saving ? null : _save,
            child: const Text('Lưu'),
          ),
        ],
      );
}
