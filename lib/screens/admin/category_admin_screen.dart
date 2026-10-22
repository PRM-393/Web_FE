import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/portal_services.dart';
import '../../routes.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// F03: category CRUD. Server enforces references and admin permissions.
class CategoryAdminScreen extends StatefulWidget {
  const CategoryAdminScreen({super.key});
  @override
  State<CategoryAdminScreen> createState() => _CategoryAdminScreenState();
}

class _CategoryAdminScreenState extends State<CategoryAdminScreen> {
  late Future<List<Map<String, dynamic>>> _future;
  AdminService get service => context.read<AdminService>();
  @override
  void initState() {
    super.initState();
    _future = service.categories();
  }

  void reload() => setState(() => _future = service.categories());
  Future<void> edit([Map<String, dynamic>? row]) async {
    final name = await promptTextDialog(
      context,
      title: row == null ? 'Thêm danh mục' : 'Sửa danh mục: ${row['name']}',
      label: 'Tên danh mục',
    );
    if (name == null) return;
    if (name.length > 100) {
      if (mounted) showMessage(context, 'Tên tối đa 100 ký tự', error: true);
      return;
    }
    try {
      await service.saveCategory(name, id: row?['id'] as String?);
      reload();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  Future<void> remove(Map<String, dynamic> row) async {
    if (!await confirmDialog(
      context,
      title: 'Xóa danh mục',
      message: 'Xóa ${row['name']}? Danh mục có chiến dịch không thể xóa.',
    )) {
      return;
    }
    try {
      await service.deleteCategory(row['id'] as String);
      reload();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => PortalShell(
    currentRoute: AppRoutes.adminCategories,
    child: Column(
      children: [
        PageHeader(
          title: 'Danh mục ngành hàng',
          actions: [
            FilledButton.icon(
              onPressed: edit,
              icon: const Icon(Icons.add),
              label: const Text('Thêm danh mục'),
            ),
          ],
        ),
        Expanded(
          child: AsyncBody<List<Map<String, dynamic>>>(
            future: _future,
            onRetry: reload,
            isEmpty: (rows) => rows.isEmpty,
            builder: (context, rows) => ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: rows.length,
              itemBuilder: (context, i) => Card(
                child: ListTile(
                  title: Text('${rows[i]['name']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Sửa',
                        onPressed: () => edit(rows[i]),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Xóa',
                        onPressed: () => remove(rows[i]),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
