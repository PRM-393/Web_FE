import 'package:flutter_test/flutter_test.dart';
import 'package:voucher_platform_web/models/finance.dart';
import 'package:voucher_platform_web/utils/settlement_csv.dart';

// F13 / FR-SETTLE-07: noi dung file CSV doi soat
void main() {
  Settlement settlement({String status = 'PAID', String? brandName = 'Highlands, Coffee'}) => Settlement.fromJson({
        'id': 's1',
        'brandId': 'b1',
        'periodStart': '2026-09-30T17:00:00.000Z',
        'periodEnd': '2026-10-31T17:00:00.000Z',
        'grossRevenue': 240000,
        'voucherCount': 3,
        'commissionAmount': 24000,
        'payableAmount': 216000,
        'status': status,
        'paidAt': '2026-11-01T03:00:00.000Z',
        'bankTxnRef': 'VCB-001',
        'brandName': brandName,
      });

  test('co BOM, dong tieu de va so lieu theo gio Viet Nam', () {
    final csv = settlementsToCsv([settlement()]);
    expect(csv.startsWith('﻿'), isTrue);
    final lines = csv.substring(1).trim().split('\r\n');
    expect(lines.first, 'Từ ngày,Đến ngày,Số voucher,Doanh thu gộp (VND),Hoa hồng (VND),Thực nhận (VND),Trạng thái,Ngày chi trả,Mã giao dịch');
    expect(lines[1], startsWith('01/10/2026,01/11/2026,3,240000,24000,216000,Đã chi trả,'));
    expect(lines[1], endsWith(',VCB-001'));
  });

  test('ban quan tri co cot thuong hieu; gia tri co dau phay duoc boc ngoac kep', () {
    final csv = settlementsToCsv([settlement(status: 'PENDING')], includeBrand: true);
    final row = csv.substring(1).trim().split('\r\n')[1];
    expect(row, startsWith('"Highlands, Coffee",'));
    expect(row, contains(',Chờ chi trả,'));
  });
}
