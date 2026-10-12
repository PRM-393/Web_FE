import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/brand.dart';
import '../../providers/brand_provider.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/validators.dart';
import '../../widgets/brand_gate.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-BRAND-05/06: tao tai khoan nhan vien, gan vao chi nhanh cua chinh thuong hieu (BR-19), vo hieu hoa.
// Moi lan gan la mot dong; mot nhan vien co the duoc gan nhieu chi nhanh.
class StaffListScreen extends StatelessWidget {
  const StaffListScreen({super.key});

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.brandStaff,
        child: BrandGate(builder: (context, brand) => _StaffList(brand: brand)),
      );
}

class _StaffList extends StatefulWidget {
  const _StaffList({required this.brand});

  final Brand brand;

  @override
  State<_StaffList> createState() => _StaffListState();
}

class _StaffListState extends State<_StaffList> {
  late Future<List<StaffMember>> _future;

  BrandService get _service => context.read<BrandService>();

  @override
  void initState() {
    super.initState();
    _future = _service.staff(widget.brand.id);
  }

  void _reload() {
    setState(() {
      _future = _service.staff(widget.brand.id);
    });
  }

  Future<void> _assign() async {
    final stores = context.read<BrandProvider>().activeStores;
    if (stores.isEmpty) {
      showMessage(context, 'Hãy tạo chi nhánh trước khi thêm nhân viên.', error: true);
      return;
    }
    final created = await showDialog<bool>(context: context, builder: (_) => _AssignDialog(stores: stores));
    if (created == true && mounted) {
      showMessage(context, 'Đã gán nhân viên vào chi nhánh.');
      _reload();
    }
  }

  Future<void> _deactivate(StaffMember m) async {
    final ok = await confirmDialog(context,
        title: 'Vô hiệu hóa nhân viên',
        message: '${m.email} sẽ không xác nhận sử dụng voucher tại ${m.storeName ?? 'chi nhánh này'} nữa.',
        confirm: 'Vô hiệu hóa');
    if (!ok) return;
    try {
      await _service.deactivateStaff(m.assignmentId);
      if (!mounted) return;
      showMessage(context, 'Đã vô hiệu hóa nhân viên.');
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PageHeader(
            title: 'Nhân viên cửa hàng',
            actions: [
              IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh)),
              FilledButton.icon(
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
                onPressed: _assign,
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Thêm nhân viên'),
              ),
            ],
          ),
          Expanded(
            child: AsyncBody<List<StaffMember>>(
              future: _future,
              onRetry: _reload,
              isEmpty: (list) => list.isEmpty,
              emptyMessage: 'Chưa có nhân viên nào.',
              builder: (context, staff) => ListView.separated(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                itemCount: staff.length,
                separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
                itemBuilder: (context, i) {
                  final m = staff[i];
                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.badge_outlined),
                      title: Text(m.fullName == null || m.fullName!.isEmpty ? m.email : '${m.fullName} · ${m.email}'),
                      subtitle: Text([
                        'Chi nhánh: ${m.storeName ?? m.storeId}',
                        if (m.assignedAt != null) 'Gán ngày ${formatDate(m.assignedAt!)}',
                      ].join(' · ')),
                      trailing: Wrap(
                        spacing: AppSpacing.sm,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusChip(m.active ? 'ACTIVE' : 'INACTIVE'),
                          if (m.active)
                            IconButton(
                              tooltip: 'Vô hiệu hóa',
                              icon: const Icon(Icons.person_off_outlined, color: AppColors.danger),
                              onPressed: () => _deactivate(m),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
}

class _AssignDialog extends StatefulWidget {
  const _AssignDialog({required this.stores});

  final List<Store> stores;

  @override
  State<_AssignDialog> createState() => _AssignDialogState();
}

class _AssignDialogState extends State<_AssignDialog> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  String? _storeId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await context.read<BrandService>().assignStaff(email: _email.text.trim(), storeId: _storeId!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Thêm nhân viên'),
        content: SizedBox(
          width: 440,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: 'Email nhân viên *'),
                  validator: validateEmail,
                ),
                const SizedBox(height: AppSpacing.sm),
                DropdownButtonFormField<String>(
                  initialValue: _storeId,
                  decoration: const InputDecoration(labelText: 'Chi nhánh *'),
                  items: [for (final s in widget.stores) DropdownMenuItem(value: s.id, child: Text(s.name))],
                  onChanged: (v) => setState(() => _storeId = v),
                  validator: (v) => v == null ? 'Vui lòng chọn chi nhánh' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!, style: const TextStyle(color: AppColors.danger)),
                ],
              ],
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
