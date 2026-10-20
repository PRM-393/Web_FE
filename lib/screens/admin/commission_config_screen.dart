import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';

// FR-SETTLE-01 / BR-09: quan tri vien cau hinh mot ty le hoa hong chung cho toan san.
// Ty le duoc chot vao don ngay luc thanh toan, nen thay doi o day chi an sang cac don
// thanh toan sau do; don cu va phieu doi soat da sinh giu nguyen ty le cu.
class CommissionConfigScreen extends StatefulWidget {
  const CommissionConfigScreen({super.key});

  @override
  State<CommissionConfigScreen> createState() => _CommissionConfigScreenState();
}

class _CommissionConfigScreenState extends State<CommissionConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _percentController = TextEditingController();
  late Future<CommissionRateInfo> _future;
  bool _busy = false;

  AdminService get _service => context.read<AdminService>();

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void dispose() {
    _percentController.dispose();
    super.dispose();
  }

  // Dien lai o nhap moi lan tai xong, de nguoi dung thay dung ty le may chu dang dung
  Future<CommissionRateInfo> _load() async {
    final info = await _service.commissionRate();
    // 10 thay vi 10.0, de nguoi dung sua tiep cho tu nhien
    if (mounted) _percentController.text = formatPercentValue(info.percent);
    return info;
  }

  void _reload() {
    setState(() {
      _future = _load();
    });
  }

  Future<void> _save() async {
    // Kiem tra tren form truoc (loi hien ngay duoi o nhap), may chu van kiem lai (NFR-SEC-03)
    if (!_formKey.currentState!.validate()) return;
    final percent = parseCommissionPercent(_percentController.text)!;
    final rate = commissionPercentToRate(percent);

    final ok = await confirmDialog(
      context,
      title: 'Đổi tỷ lệ hoa hồng',
      message: 'Áp dụng tỷ lệ ${formatPercent(rate)} cho các đơn thanh toán từ bây giờ?\n'
          'Đơn đã thanh toán và phiếu đối soát đã chốt vẫn giữ tỷ lệ cũ.',
      confirm: 'Áp dụng',
    );
    if (!ok) return;

    setState(() => _busy = true);
    try {
      await _service.setCommissionRate(rate);
      if (!mounted) return;
      showMessage(context, 'Đã cập nhật tỷ lệ hoa hồng ${formatPercent(rate)}.');
      _reload();
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: AppRoutes.adminCommission,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PageHeader(
              title: 'Tỷ lệ hoa hồng',
              subtitle: 'Tỷ lệ chung toàn sàn, được chốt vào đơn tại thời điểm thanh toán',
              actions: [IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh))],
            ),
            Expanded(
              child: AsyncBody<CommissionRateInfo>(
                future: _future,
                onRetry: _reload,
                builder: (context, info) => SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatCard(
                        label: info.isDefault ? 'Đang dùng tỷ lệ mặc định' : 'Tỷ lệ đang áp dụng',
                        value: formatPercent(info.rate),
                        icon: Icons.percent,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Wrap(
                                  spacing: AppSpacing.md,
                                  runSpacing: AppSpacing.md,
                                  crossAxisAlignment: WrapCrossAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 260,
                                      child: TextFormField(
                                        controller: _percentController,
                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                        validator: validateCommissionPercent,
                                        decoration: const InputDecoration(
                                          labelText: 'Tỷ lệ hoa hồng',
                                          suffixText: '%',
                                          helperText: 'Lớn hơn 0% và nhỏ hơn 100%, ví dụ 10',
                                        ),
                                        onFieldSubmitted: (_) {
                                          if (!_busy) _save();
                                        },
                                      ),
                                    ),
                                    Padding(
                                      // Canh nut ngang o nhap, chua tru phan helperText ben duoi
                                      padding: const EdgeInsets.only(top: 4),
                                      child: FilledButton.icon(
                                        style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
                                        onPressed: _busy ? null : _save,
                                        icon: const Icon(Icons.save_outlined),
                                        label: const Text('Lưu tỷ lệ'),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                const Text(
                                  'Tỷ lệ mới chỉ áp dụng cho các đơn thanh toán sau khi lưu. '
                                  'Đơn đã thanh toán giữ nguyên tỷ lệ đã chốt, nên phiếu đối soát cũ không đổi.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                if (info.updatedAt != null) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    'Thay đổi gần nhất: ${formatDateTime(info.updatedAt!)}'
                                    '${info.updatedBy == null ? '' : ' • bởi ${info.updatedBy}'}',
                                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
