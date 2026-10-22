import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../providers/brand_provider.dart';
import '../../services/portal_services.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';

// FR-CAMP-01..05: tao chien dich (luu nhap) hoac sua chien dich nhap.
// Rang buoc: gia ban <= gia tri, so luong > 0, gioi han mua mac dinh 5, DC-10 ve ngay, it nhat 1 chi nhanh (DC-07).
// Tra ve true qua Navigator.pop khi luu thanh cong de man danh sach tai lai.
class CampaignFormScreen extends StatefulWidget {
  const CampaignFormScreen({super.key, this.campaign});

  // null = tao moi
  final VoucherCampaign? campaign;

  @override
  State<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _salePrice;
  late final TextEditingController _faceValue;
  late final TextEditingController _discountValue;
  late final TextEditingController _maxDiscount;
  late final TextEditingController _comboItems;
  late final TextEditingController _quantity;
  late final TextEditingController _limit;
  late final TextEditingController _image;
  late final TextEditingController _description;
  late final TextEditingController _terms;

  late String _voucherType;
  late String _discountType;
  DateTime? _saleStart;
  DateTime? _saleEnd;
  DateTime? _expire;
  final Set<String> _storeIds = {};
  bool _saving = false;
  String? _ruleError;

  bool get _isEdit => widget.campaign != null;

  @override
  void initState() {
    super.initState();
    final c = widget.campaign;
    _title = TextEditingController(text: c?.title);
    _salePrice = TextEditingController(text: c == null ? '' : c.salePrice.toStringAsFixed(0));
    _faceValue = TextEditingController(text: c == null ? '' : c.faceValue.toStringAsFixed(0));
    _discountValue = TextEditingController(text: c?.discountValue?.toString() ?? '');
    _maxDiscount = TextEditingController(text: c?.maxDiscount?.toString() ?? '');
    _comboItems = TextEditingController(text: c?.comboItems);
    _discountType = c?.discountType ?? DiscountType.percent;
    _quantity = TextEditingController(text: c == null ? '100' : '${c.totalQuantity}');
    _limit = TextEditingController(text: c == null ? '5' : '${c.limitPerUser}');
    _image = TextEditingController(text: c?.image);
    _description = TextEditingController(text: c?.description);
    _terms = TextEditingController(text: c?.terms);
    _voucherType = c?.voucherType ?? VoucherType.discount;
    if (c != null) {
      _saleStart = vnCalendarDay(c.saleStartAt);
      _saleEnd = vnCalendarDay(c.saleEndAt);
      _expire = vnCalendarDay(c.voucherExpireAt);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BrandProvider>().ensureLoaded();
    });
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _salePrice,
      _faceValue,
      _discountValue,
      _maxDiscount,
      _comboItems,
      _quantity,
      _limit,
      _image,
      _description,
      _terms,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime> onPicked) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      firstDate: _isEdit ? today.subtract(const Duration(days: 365)) : today,
      lastDate: today.add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => onPicked(picked));
  }

  Future<void> _save() async {
    setState(() => _ruleError = null);
    final fieldsOk = _formKey.currentState!.validate();
    if (_saleStart == null || _saleEnd == null || _expire == null) {
      setState(() => _ruleError = 'Vui lòng chọn đủ ngày bắt đầu bán, kết thúc bán và hạn sử dụng');
      return;
    }
    if (!fieldsOk) return;

    final isDiscount = _voucherType == VoucherType.discount;
    final draft = CampaignDraft(
      title: _title.text.trim(),
      voucherType: _voucherType,
      salePrice: parseMoney(_salePrice.text)!,
      faceValue: parseMoney(_faceValue.text)!,
      totalQuantity: int.parse(_quantity.text.trim()),
      limitPerUser: int.parse(_limit.text.trim()),
      saleStartAt: vnStartOfDayUtc(_saleStart!),
      saleEndAt: vnEndOfDayUtc(_saleEnd!),
      voucherExpireAt: vnEndOfDayUtc(_expire!),
      storeIds: _storeIds.toList(),
      image: _image.text.trim(),
      description: _description.text.trim(),
      terms: _terms.text.trim(),
      discountType: isDiscount ? _discountType : null,
      discountValue: isDiscount ? parseMoney(_discountValue.text) : null,
      maxDiscount: isDiscount && _discountType == DiscountType.percent ? parseMoney(_maxDiscount.text) : null,
      comboItems: _voucherType == VoucherType.combo ? _comboItems.text.trim() : null,
    );
    final ruleError = validateCampaignRules(
      salePrice: draft.salePrice,
      faceValue: draft.faceValue,
      saleStartAt: draft.saleStartAt,
      saleEndAt: draft.saleEndAt,
      voucherExpireAt: draft.voucherExpireAt,
      storeCount: _isEdit ? 1 : draft.storeIds.length,
      voucherType: draft.voucherType,
      discountType: draft.discountType,
      discountValue: draft.discountValue,
      maxDiscount: draft.maxDiscount,
      comboItems: draft.comboItems,
    );
    if (ruleError != null) {
      setState(() => _ruleError = ruleError);
      return;
    }

    setState(() => _saving = true);
    final service = context.read<CampaignService>();
    try {
      if (_isEdit) {
        await service.update(widget.campaign!.id, draft);
      } else {
        await service.create(context.read<BrandProvider>().brand!.id, draft);
      }
      if (!mounted) return;
      showMessage(context, _isEdit ? 'Đã lưu thay đổi.' : 'Đã lưu chiến dịch nháp.');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _ruleError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final brand = context.watch<BrandProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Sửa chiến dịch' : 'Tạo chiến dịch mới')),
      body: brand.brand == null
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 760),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _section('Thông tin chung'),
                          TextFormField(
                            controller: _title,
                            decoration: const InputDecoration(labelText: 'Tiêu đề *'),
                            validator: (v) => validateRequired(v, 'tiêu đề'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            initialValue: _voucherType,
                            decoration: const InputDecoration(labelText: 'Loại voucher *'),
                            items: [
                              for (final e in VoucherType.labels.entries)
                                DropdownMenuItem(value: e.key, child: Text(e.value)),
                            ],
                            onChanged: (v) => setState(() => _voucherType = v!),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(controller: _image, decoration: const InputDecoration(labelText: 'Đường dẫn ảnh')),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _description,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Mô tả'),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextFormField(
                            controller: _terms,
                            maxLines: 3,
                            decoration: const InputDecoration(labelText: 'Điều kiện áp dụng'),
                          ),
                          _section('Giá và số lượng'),
                          _pair(
                            TextFormField(
                              controller: _salePrice,
                              decoration: const InputDecoration(labelText: 'Giá bán (VND) *'),
                              validator: (v) => validateMoney(v, 'giá bán'),
                            ),
                            TextFormField(
                              controller: _faceValue,
                              decoration: const InputDecoration(labelText: 'Giá trị voucher (VND) *'),
                              validator: (v) => validateMoney(v, 'giá trị voucher', allowZero: false),
                            ),
                          ),
                          // FR-CAMP-12: truong gia tri theo loai voucher
                          if (_voucherType == VoucherType.discount) ...[
                            const SizedBox(height: AppSpacing.md),
                            DropdownButtonFormField<String>(
                              key: const Key('campaign-discount-type'),
                              initialValue: _discountType,
                              decoration: const InputDecoration(labelText: 'Kiểu giảm *'),
                              items: [
                                for (final e in DiscountType.labels.entries)
                                  DropdownMenuItem(value: e.key, child: Text(e.value)),
                              ],
                              onChanged: (v) => setState(() => _discountType = v!),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _pair(
                              TextFormField(
                                controller: _discountValue,
                                decoration: InputDecoration(
                                  labelText: _discountType == DiscountType.percent ? 'Phần trăm giảm (1-100) *' : 'Số tiền giảm (VND) *',
                                ),
                                validator: (v) => validateMoney(v, 'giá trị giảm', allowZero: false),
                              ),
                              TextFormField(
                                controller: _maxDiscount,
                                enabled: _discountType == DiscountType.percent,
                                decoration: const InputDecoration(labelText: 'Giảm tối đa (VND, bắt buộc khi giảm %)'),
                              ),
                            ),
                          ],
                          if (_voucherType == VoucherType.combo) ...[
                            const SizedBox(height: AppSpacing.md),
                            TextFormField(
                              controller: _comboItems,
                              maxLines: 2,
                              decoration: const InputDecoration(labelText: 'Nội dung gói combo *'),
                              validator: (v) => validateRequired(v, 'nội dung gói'),
                            ),
                          ],
                          const SizedBox(height: AppSpacing.md),
                          _pair(
                            TextFormField(
                              controller: _quantity,
                              decoration: const InputDecoration(labelText: 'Số lượng phát hành *'),
                              validator: (v) => validatePositiveInt(v, 'Số lượng'),
                            ),
                            TextFormField(
                              controller: _limit,
                              decoration: const InputDecoration(labelText: 'Giới hạn mua mỗi người *'),
                              validator: (v) => validatePositiveInt(v, 'Giới hạn mua'),
                            ),
                          ),
                          _section('Thời gian (giờ Việt Nam)'),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              _dateButton('Bắt đầu bán', _saleStart, (d) => _saleStart = d),
                              _dateButton('Kết thúc bán', _saleEnd, (d) => _saleEnd = d),
                              _dateButton('Hạn sử dụng', _expire, (d) => _expire = d),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: AppSpacing.xs),
                            child: Text('Hạn sử dụng phải sau ngày kết thúc bán ít nhất 10 ngày.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                          ),
                          if (!_isEdit) ...[
                            _section('Chi nhánh áp dụng *'),
                            if (brand.activeStores.isEmpty)
                              const Text('Chưa có chi nhánh đang hoạt động. Hãy tạo chi nhánh trước.',
                                  style: TextStyle(color: AppColors.danger))
                            else
                              for (final s in brand.activeStores)
                                CheckboxListTile(
                                  value: _storeIds.contains(s.id),
                                  title: Text(s.name),
                                  subtitle: Text(s.address),
                                  onChanged: (v) => setState(() => v! ? _storeIds.add(s.id) : _storeIds.remove(s.id)),
                                ),
                          ],
                          if (_ruleError != null) ...[
                            const SizedBox(height: AppSpacing.md),
                            Text(_ruleError!, key: const Key('campaign-error'), style: const TextStyle(color: AppColors.danger)),
                          ],
                          const SizedBox(height: AppSpacing.lg),
                          FilledButton(
                            key: const Key('campaign-save'),
                            onPressed: _saving ? null : _save,
                            child: Text(_saving ? 'Đang lưu...' : (_isEdit ? 'Lưu thay đổi' : 'Lưu nháp')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _section(String text) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      );

  Widget _pair(Widget a, Widget b) => LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth < 520
            ? Column(children: [a, const SizedBox(height: AppSpacing.md), b])
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [Expanded(child: a), const SizedBox(width: AppSpacing.md), Expanded(child: b)],
              ),
      );

  Widget _dateButton(String label, DateTime? value, ValueChanged<DateTime> onPicked) => OutlinedButton.icon(
        onPressed: () => _pickDate(value, onPicked),
        icon: const Icon(Icons.event),
        label: Text(value == null ? label : '$label: ${value.day}/${value.month}/${value.year}'),
      );
}
