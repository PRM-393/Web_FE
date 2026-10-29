import 'package:flutter/material.dart';

import '../models/finance.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

// The phieu doi soat, dung chung cho portal thuong hieu va quan tri
class SettlementTile extends StatelessWidget {
  const SettlementTile({super.key, required this.settlement, this.showBrand = false, this.trailing, this.onTap});

  final Settlement settlement;
  final bool showBrand;
  final Widget? trailing;

  // FR-SETTLE-08: bam vao the de mo chi tiet tung dong voucher. Null = the chi de hien thi
  // (chinh man chi tiet cung dung lai the nay cho phan tong quan).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = settlement;
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(
                  '${showBrand ? '${s.brandName ?? s.brandId} · ' : ''}Kỳ ${formatDate(s.periodStart)} – ${formatDate(s.periodEnd)}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              StatusChip(s.status, label: s.isPaid ? 'Đã chi trả' : 'Chờ chi trả'),
              if (onTap != null)
                const Padding(
                  padding: EdgeInsets.only(left: AppSpacing.xs),
                  child: Icon(Icons.chevron_right, color: AppColors.textSecondary),
                ),
            ]),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                Text('Doanh thu gộp: ${formatVnd(s.grossRevenue)}'),
                Text('${s.voucherCount} voucher'),
                Text('Hoa hồng: ${formatVnd(s.commissionAmount)}'),
                Text('Thực nhận: ${formatVnd(s.payableAmount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (s.isPaid && s.paidAt != null) Text('Chi trả ${formatDateTime(s.paidAt!)} · Mã GD ${s.bankTxnRef ?? '—'}'),
              ],
            ),
            if (trailing != null) ...[const SizedBox(height: AppSpacing.sm), trailing!],
          ],
        ),
        ),
      ),
    );
  }
}
