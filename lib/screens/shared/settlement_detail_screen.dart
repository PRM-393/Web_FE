import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/finance.dart';
import '../../routes.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/download/file_download.dart';
import '../../utils/settlement_csv.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';
import '../../widgets/settlement_tile.dart';

// FR-SETTLE-08: chi tiet mot phieu doi soat - tung dong ung voi mot voucher da ban.
// Dung chung cho portal thuong hieu (/brand/settlement-detail) va quan tri (/admin/settlement-detail):
// cung mot endpoint GET /settlements/:id, may chu tu chan thuong hieu xem phieu cua nguoi khac.
//
// BR-09: ty le hoa hong hien theo TUNG DONG, khong phai ty le hien hanh cua san. Don cu giu ty le da
// chot luc thanh toan nen mot phieu co the co nhieu ty le khac nhau - thuong hieu phai doi chieu duoc.
class SettlementDetailScreen extends StatefulWidget {
  const SettlementDetailScreen({super.key, required this.settlementId, required this.adminView});

  final String settlementId;
  final bool adminView;

  @override
  State<SettlementDetailScreen> createState() => _SettlementDetailScreenState();
}

class _SettlementDetailScreenState extends State<SettlementDetailScreen> {
  late Future<SettlementDetail> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<SettlementDetail> _load() => widget.adminView
      ? context.read<AdminService>().settlementDetail(widget.settlementId)
      : context.read<BrandService>().settlementDetail(widget.settlementId);

  void _reload() => setState(() => _future = _load());

  // FR-SETTLE-07: tai rieng mot phieu ra CSV de doi chieu voi sao ke ngan hang
  Future<void> _exportCsv(SettlementDetail detail) async {
    try {
      final ok = await downloadTextFile(
        'phieu-doi-soat-${formatDate(detail.settlement.periodStart).replaceAll('/', '-')}.csv',
        settlementLinesToCsv(detail),
      );
      if (mounted) {
        showMessage(context, ok ? 'Đã xuất ${detail.items.length} dòng ra CSV.' : 'Chỉ xuất được CSV trên trình duyệt.');
      }
    } catch (e) {
      if (mounted) showMessage(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) => PortalShell(
        currentRoute: widget.adminView ? AppRoutes.adminSettlements : AppRoutes.brandSettlements,
        child: AsyncBody<SettlementDetail>(
          future: _future,
          onRetry: _reload,
          builder: (context, detail) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PageHeader(
                title: 'Chi tiết phiếu đối soát',
                subtitle: 'Kỳ ${formatDate(detail.settlement.periodStart)} – ${formatDate(detail.settlement.periodEnd)}',
                actions: [
                  OutlinedButton.icon(
                    onPressed: () => _exportCsv(detail),
                    icon: const Icon(Icons.download),
                    label: const Text('Xuất CSV'),
                  ),
                  IconButton(tooltip: 'Tải lại', onPressed: _reload, icon: const Icon(Icons.refresh)),
                  TextButton.icon(
                    onPressed: () => AppRoutes.go(
                      context,
                      widget.adminView ? AppRoutes.adminSettlements : AppRoutes.brandSettlements,
                    ),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Về danh sách'),
                  ),
                ],
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                  children: [
                    SettlementTile(settlement: detail.settlement, showBrand: widget.adminView),
                    const SizedBox(height: AppSpacing.md),
                    Text('${detail.items.length} voucher trong kỳ', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    const Padding(
                      padding: EdgeInsets.only(top: AppSpacing.xs, bottom: AppSpacing.sm),
                      child: Text(
                        'Tỷ lệ hoa hồng tính theo tỷ lệ đã chốt vào từng đơn lúc thanh toán, '
                        'nên các dòng có thể khác nhau nếu sàn đổi tỷ lệ giữa kỳ.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    if (detail.items.isEmpty)
                      const MessageView(icon: Icons.inbox_outlined, message: 'Phiếu này chưa có dòng nào.')
                    else
                      Card(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            key: const Key('settlement-lines'),
                            columns: const [
                              DataColumn(label: Text('Mã voucher')),
                              DataColumn(label: Text('Giá bán'), numeric: true),
                              DataColumn(label: Text('Tỷ lệ'), numeric: true),
                              DataColumn(label: Text('Hoa hồng'), numeric: true),
                              DataColumn(label: Text('Thực nhận'), numeric: true),
                            ],
                            rows: [
                              for (final line in detail.items)
                                DataRow(cells: [
                                  // Hien 8 ky tu dau cho vua bang; day du van nam trong file CSV
                                  DataCell(Text(line.voucherItemId.length > 8
                                      ? line.voucherItemId.substring(0, 8)
                                      : line.voucherItemId)),
                                  DataCell(Text(formatVnd(line.amount))),
                                  DataCell(Text(formatPercent(line.commissionRate))),
                                  DataCell(Text(formatVnd(line.commissionAmount))),
                                  DataCell(Text(formatVnd(line.payableAmount))),
                                ]),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}
