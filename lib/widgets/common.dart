import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Hien thi 3 trang thai cua mot danh sach tai tu API: dang tai / loi (co nut thu lai) / rong
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({
    super.key,
    required this.future,
    required this.builder,
    required this.onRetry,
    this.isEmpty,
    this.emptyMessage = 'Chưa có dữ liệu.',
  });

  final Future<T>? future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback onRetry;
  final bool Function(T data)? isEmpty;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return MessageView(
          icon: Icons.cloud_off,
          message: snapshot.error.toString(),
          onRetry: onRetry,
        );
      }
      final data = snapshot.data as T;
      if (isEmpty?.call(data) ?? false) {
        return MessageView(icon: Icons.inbox_outlined, message: emptyMessage);
      }
      return builder(context, data);
    },
  );
}

class MessageView extends StatelessWidget {
  const MessageView({
    super.key,
    required this.icon,
    required this.message,
    this.onRetry,
  });

  final IconData icon;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFE5F1E9),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    ),
  );
}

// Tieu de trang + cac nut thao tac ben phai
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.lg,
      AppSpacing.md,
    ),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -.7),
            ),
            if (subtitle != null)
              Text(
                subtitle!,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
          ],
        ),
        if (actions.isNotEmpty) Wrap(spacing: AppSpacing.sm, children: actions),
      ],
    ),
  );
}

// Nhan trang thai co mau (SRS muc 6)
class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key, this.label});

  final String status;

  // Ghi de nhan khi cung ma trang thai nhung khac nghia (vd. phieu doi soat PENDING = cho chi tra)
  final String? label;

  static const _labels = {
    'DRAFT': 'Nháp',
    'PENDING': 'Chờ duyệt',
    'APPROVED': 'Đã duyệt',
    'PUBLISHED': 'Đang bán',
    'SOLD_OUT': 'Hết hàng',
    'SUSPENDED': 'Bị đình chỉ',
    'PAUSED': 'Tạm dừng',
    'ENDED': 'Đã kết thúc',
    'REJECTED': 'Bị từ chối',
    'PAID': 'Đã chi trả',
    'MANUAL_PENDING': 'Chờ hoàn thủ công',
    'ACTIVE': 'Đang hoạt động',
    'INACTIVE': 'Đã vô hiệu hóa',
    'PAYMENT_MISMATCH': 'Lệch số tiền',
    'VISIBLE': 'Đang hiển thị',
    'HIDDEN': 'Đã ẩn',
  };

  static Color colorOf(String status) => switch (status) {
    'APPROVED' || 'PUBLISHED' || 'PAID' || 'ACTIVE' || 'VISIBLE' => AppColors.success,
    'PENDING' || 'MANUAL_PENDING' || 'PAYMENT_MISMATCH' => AppColors.secondary,
    'REJECTED' ||
    'ENDED' ||
    'INACTIVE' ||
    'SUSPENDED' ||
    'HIDDEN' ||
    'SOLD_OUT' => AppColors.danger,
    _ => AppColors.textSecondary,
  };

  @override
  Widget build(BuildContext context) {
    final color = colorOf(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label ?? _labels[status] ?? status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// The so lieu tren bang dieu khien / bao cao
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 260,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDF5EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 22, color: AppColors.primary),
                ),
                const Icon(
                  Icons.north_east,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 26,
                letterSpacing: -.7,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showMessage(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : null,
        behavior: SnackBarBehavior.floating,
      ),
    );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirm = 'Đồng ý',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(96, 40)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return result ?? false;
}

// Hop thoai nhap mot dong chu bat buoc (ly do tu choi, ma giao dich, phan hoi danh gia...).
// message: giai thich phia tren o nhap; validator: thay kiem tra mac dinh "khong duoc de trong" (vd. so tien hoa don).
Future<String?> promptTextDialog(
  BuildContext context, {
  required String title,
  required String label,
  String confirm = 'Xác nhận',
  int maxLines = 1,
  String? message,
  String? initialValue,
  TextInputType? keyboardType,
  FormFieldValidator<String>? validator,
}) => showDialog<String>(
  context: context,
  builder: (_) => _PromptDialog(
    title,
    label,
    confirm,
    maxLines,
    message: message,
    initialValue: initialValue,
    keyboardType: keyboardType,
    validator: validator,
  ),
);

class _PromptDialog extends StatefulWidget {
  const _PromptDialog(
    this.title,
    this.label,
    this.confirm,
    this.maxLines, {
    this.message,
    this.initialValue,
    this.keyboardType,
    this.validator,
  });

  final String title;
  final String label;
  final String confirm;
  final int maxLines;
  final String? message;
  final String? initialValue;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _controller = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, _controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 420,
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.message != null) ...[
              Text(widget.message!),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              controller: _controller,
              autofocus: true,
              maxLines: widget.maxLines,
              keyboardType: widget.keyboardType,
              decoration: InputDecoration(labelText: widget.label),
              validator: widget.validator ??
                  (v) => (v == null || v.trim().isEmpty)
                      ? 'Vui lòng nhập ${widget.label.toLowerCase()}'
                      : null,
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(
        style: FilledButton.styleFrom(minimumSize: const Size(96, 40)),
        onPressed: _submit,
        child: Text(widget.confirm),
      ),
    ],
  );
}
