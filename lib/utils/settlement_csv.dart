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

// FR-SETTLE-08: xuat CHI TIET mot phieu - moi dong mot voucher, kem ty le hoa hong da chot cua don (BR-09).
// Ma voucher ghi day du o day (bang tren man hinh chi hien 8 ky tu dau cho vua cot).
String settlementLinesToCsv(SettlementDetail detail) {
  final s = detail.settlement;
  final header = ['Mã voucher', 'Mã đơn', 'Giá bán (VND)', 'Tỷ lệ hoa hồng', 'Hoa hồng (VND)', 'Thực nhận (VND)'];
  final rows = detail.items.map((l) => [
        l.voucherItemId,
        l.orderId ?? '',
        l.amount,
        formatPercent(l.commissionRate),
        l.commissionAmount,
        l.payableAmount,
      ]);
  // Dong tong o cuoi de doi chieu nhanh voi so tren phieu
  final total = ['TỔNG', '', s.grossRevenue, '', s.commissionAmount, s.payableAmount];
  return '﻿${[header, ...rows, total].map((r) => r.map(_cell).join(',')).join('\r\n')}\r\n';
}
