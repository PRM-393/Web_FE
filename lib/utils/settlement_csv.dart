import '../models/finance.dart';
import 'format.dart';

// F13 / FR-SETTLE-07: xuat danh sach phieu doi soat ra CSV (mo duoc bang Excel).
// Dau BOM UTF-8 de Excel hien dung tieng Viet; dau phay phan cach, gia tri co dau phay / ngoac kep duoc boc lai.
const _statusLabels = {'PENDING': 'Chờ chi trả', 'PAID': 'Đã chi trả'};

String _cell(Object? value) {
  final s = value?.toString() ?? '';
  return RegExp(r'[",\n\r]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
}

String settlementsToCsv(List<Settlement> items, {bool includeBrand = false}) {
  final header = [
    if (includeBrand) 'Thương hiệu',
    'Từ ngày',
    'Đến ngày',
    'Số voucher',
    'Doanh thu gộp (VND)',
    'Hoa hồng (VND)',
    'Thực nhận (VND)',
    'Trạng thái',
    'Ngày chi trả',
    'Mã giao dịch',
  ];
  final rows = items.map((s) => [
        if (includeBrand) s.brandName ?? s.brandId,
        formatDate(s.periodStart),
        formatDate(s.periodEnd),
        s.voucherCount,
        s.grossRevenue,
        s.commissionAmount,
        s.payableAmount,
        _statusLabels[s.status] ?? s.status,
        s.paidAt == null ? '' : formatDateTime(s.paidAt!),
        s.bankTxnRef ?? '',
      ]);
  return '﻿${[header, ...rows].map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n';
}
