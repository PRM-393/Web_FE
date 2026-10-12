import 'package:flutter/material.dart';

import '../models/finance.dart';
import '../theme/app_theme.dart';
import '../utils/format.dart';
import 'common.dart';

// The phieu doi soat, dung chung cho portal thuong hieu va quan tri
class SettlementTile extends StatelessWidget {
  const SettlementTile({super.key, required this.settlement, this.showBrand = false, this.trailing});

  final Settlement settlement;
  final bool showBrand;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final s = settlement;
    return Card(
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
            ]),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.lg,
              runSpacing: AppSpacing.xs,
              children: [
                Text('Doanh thu gộp: ${formatVnd(s.grossRevenue)}'),
                Text('Hoa hồng (${formatPercent(s.commissionRate)}): ${formatVnd(s.commissionAmount)}'),
                Text('Thực nhận: ${formatVnd(s.payableAmount)}', style: const TextStyle(fontWeight: FontWeight.w600)),
                if (s.isPaid && s.paidAt != null) Text('Chi trả ${formatDateTime(s.paidAt!)} · Mã GD ${s.bankTxnRef ?? '—'}'),
              ],
            ),
            if (trailing != null) ...[const SizedBox(height: AppSpacing.sm), trailing!],
          ],
        ),
      ),
    );
  }
}
