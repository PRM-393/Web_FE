import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/json_utils.dart';
import '../../models/redeem.dart';
import '../../providers/store_session_provider.dart';
import '../../routes.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';
import '../../widgets/portal_shell.dart';
import '../../widgets/qr_scanner_view.dart';

// FR-REDEEM-05..08: nhan vien quet QR hoac nhap OTP de xac nhan su dung voucher tai chi nhanh dang lam.
// Giao dien toi gian, nut lon, ket qua xanh / do doc duoc trong mot giay (NFR-USA-03).
class RedeemScreen extends StatelessWidget {
  const RedeemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreSessionProvider>().currentStore;
    return PortalShell(
      currentRoute: AppRoutes.storeRedeem,
      child: store == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const MessageView(icon: Icons.storefront_outlined, message: 'Hãy chọn chi nhánh làm việc trước.'),
                  FilledButton(
                    style: FilledButton.styleFrom(minimumSize: const Size(220, 48)),
                    onPressed: () => AppRoutes.go(context, AppRoutes.storeSelect),
                    child: const Text('Chọn chi nhánh'),
                  ),
                ],
              ),
            )
          : const _RedeemPanel(),
    );
  }
}

class _RedeemPanel extends StatefulWidget {
  const _RedeemPanel();

  @override
  State<_RedeemPanel> createState() => _RedeemPanelState();
}

class _RedeemPanelState extends State<_RedeemPanel> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 2, vsync: this);
  final _otpFormKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _bill = TextEditingController();
  final _billFocus = FocusNode();
  bool _cameraOn = false;
  String? _billError;
  Timer? _lockTicker;

  @override
  void initState() {
    super.initState();
    _syncLockTicker();
  }

  @override
  void dispose() {
    _lockTicker?.cancel();
    _tabs.dispose();
    _otp.dispose();
    _bill.dispose();
    _billFocus.dispose();
    super.dispose();
  }

  int? get _billAmount => parseMoney(_bill.text);

  // Gia tri hoa don: de trong la khong gui (tru khi may chu bao BILL_REQUIRED), sai dinh dang thi bao loi tai o nhap
  bool _validateBill({String? requiredMessage}) {
    final text = _bill.text.trim();
    String? error;
    if (text.isEmpty) {
      error = requiredMessage;
    } else if (_billAmount == null || _billAmount! < 0) {
      error = 'Giá trị hóa đơn không hợp lệ';
    }
    setState(() => _billError = error);
    if (error != null) _billFocus.requestFocus();
    return error == null;
  }

  Future<void> _onScanned(String raw) async {
    final session = context.read<StoreSessionProvider>();
    // Dang hien ket qua hoac cho nhap hoa don: bo qua lan quet moi cho toi khi nhan vien xu ly xong
    if (session.isSubmitting || _hasOutcome(session) || session.billRequirement != null) return;
    if (!_validateBill()) return;
    await session.redeemQr(raw, billAmount: _billAmount);
    _afterSubmit(session);
  }

  Future<void> _submitOtp() async {
    final session = context.read<StoreSessionProvider>();
    if (session.isOtpLocked(DateTime.now())) return;
    final otpValid = _otpFormKey.currentState!.validate();
    if (!otpValid || !_validateBill()) return;
    final ok = await session.redeem(otpCode: _otp.text.trim(), billAmount: _billAmount);
    if (ok) _otp.clear();
    _afterSubmit(session);
  }

  // BR-03: gui lai dung ma vua quet / nhap, lan nay kem gia tri hoa don
  Future<void> _resubmitWithBill() async {
    final session = context.read<StoreSessionProvider>();
    final requirement = session.billRequirement;
    if (requirement == null || !_validateBill(requiredMessage: _billRequiredText(requirement))) return;
    final ok = await session.resubmitWithBill(_billAmount!);
    if (ok) _otp.clear();
    _afterSubmit(session);
  }

  void _afterSubmit(StoreSessionProvider session) {
    if (!mounted) return;
    if (session.billRequirement != null) _billFocus.requestFocus();
    _syncLockTicker();
    final failure = session.lastFailure;
    if (failure?.reason == RedeemReason.storeNotSelected) {
      // Phien chua gan chi nhanh (vd. dang nhap lai): chon lai chi nhanh roi xac nhan tiep
      showMessage(context, failure!.message, error: true);
      AppRoutes.go(context, AppRoutes.storeSelect);
    }
  }

  // FR-REDEEM-12: dem nguoc thoi gian khoa o nhap OTP, het khoa thi mo lai
  void _syncLockTicker() {
    final session = context.read<StoreSessionProvider>();
    if (!session.isOtpLocked(DateTime.now())) {
      _lockTicker?.cancel();
      _lockTicker = null;
      return;
    }
    _lockTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final now = DateTime.now();
      if (session.isOtpLocked(now)) {
        setState(() {});
      } else {
        _lockTicker?.cancel();
        _lockTicker = null;
        session.clearOtpLockIfExpired(now);
      }
    });
  }

  void _next() {
    setState(() => _billError = null);
    _bill.clear();
    _otp.clear();
    context.read<StoreSessionProvider>().clearResult();
  }

  bool _hasOutcome(StoreSessionProvider session) => session.lastResult != null || session.lastFailure != null;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<StoreSessionProvider>();
    final requirement = session.billRequirement;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Xác nhận sử dụng voucher',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: AppSpacing.md),
                if (_hasOutcome(session)) ...[
                  _ResultPanel(result: session.lastResult, failure: session.lastFailure),
                  const SizedBox(height: AppSpacing.sm),
                  FilledButton.icon(
                    key: const Key('redeem-next'),
                    onPressed: _next,
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Khách tiếp theo'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                TabBar(controller: _tabs, tabs: const [
                  Tab(icon: Icon(Icons.qr_code_scanner), text: 'Quét QR'),
                  Tab(icon: Icon(Icons.pin_outlined), text: 'Nhập OTP'),
                ]),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('redeem-bill'),
                  controller: _bill,
                  focusNode: _billFocus,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {
                    if (_billError != null) setState(() => _billError = null);
                  },
                  decoration: InputDecoration(
                    labelText: 'Giá trị hóa đơn (VND)',
                    helperText: 'Bắt buộc với voucher mệnh giá, không bắt buộc với loại khác (FR-REDEEM-08)',
                    errorText: _billError ?? (requirement == null ? null : _billRequiredText(requirement)),
                    errorMaxLines: 2,
                  ),
                ),
                if (requirement != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _BillRequiredActions(
                    submitting: session.isSubmitting,
                    onResubmit: _resubmitWithBill,
                    onCancel: _next,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  height: 460,
                  child: TabBarView(
                    controller: _tabs,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _qrTab(session, paused: session.isSubmitting || _hasOutcome(session) || requirement != null),
                      _otpTab(session),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _qrTab(StoreSessionProvider session, {required bool paused}) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_cameraOn)
            Expanded(child: QrScannerView(onDetect: _onScanned, paused: paused))
          else
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.border.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: const Icon(Icons.qr_code_2, size: 96, color: AppColors.textSecondary),
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          if (session.isSubmitting) const LinearProgressIndicator(),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            onPressed: () => setState(() => _cameraOn = !_cameraOn),
            icon: Icon(_cameraOn ? Icons.videocam_off : Icons.videocam),
            label: Text(_cameraOn ? 'Tắt camera' : 'Bật camera'),
          ),
        ],
      );

  Widget _otpTab(StoreSessionProvider session) {
    final now = DateTime.now();
    final locked = session.isOtpLocked(now);
    return SingleChildScrollView(
      child: Form(
        key: _otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (locked) ...[
              _OtpLockedBanner(
                lockedUntil: session.otpLockedUntil!,
                remaining: session.otpLockedUntil!.difference(now),
                onScanQr: () => _tabs.animateTo(0),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            TextFormField(
              key: const Key('redeem-otp'),
              controller: _otp,
              enabled: !locked,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 32, letterSpacing: 12, fontWeight: FontWeight.w700),
              decoration: const InputDecoration(hintText: '••••••', counterText: ''),
              validator: validateRedeemOtp,
              onFieldSubmitted: (_) => _submitOtp(),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              key: const Key('redeem-otp-submit'),
              onPressed: session.isSubmitting || locked ? null : _submitOtp,
              child: Text(session.isSubmitting ? 'Đang xác nhận...' : 'Xác nhận sử dụng'),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Mã OTP hiển thị dưới mã QR trên ứng dụng của khách, hiệu lực 60 giây.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

// BR-03: thong bao bat buoc nhap hoa don kem menh gia voucher
String _billRequiredText(BillRequirement r) => (r.faceValue ?? 0) > 0
    ? 'Voucher mệnh giá ${formatVnd(r.faceValue!)} bắt buộc nhập giá trị hóa đơn'
    : 'Voucher mệnh giá bắt buộc nhập giá trị hóa đơn';

// BILL_REQUIRED: ma cua khach chua bi tieu, nhap hoa don roi gui lai ngay voi dung ma do
class _BillRequiredActions extends StatelessWidget {
  const _BillRequiredActions({required this.submitting, required this.onResubmit, required this.onCancel});

  final bool submitting;
  final VoidCallback onResubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
        key: const Key('redeem-bill-required'),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.secondary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Mã của khách vẫn còn hiệu lực. Nhập giá trị hóa đơn rồi gửi lại, không cần quét lại mã.',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                FilledButton.icon(
                  key: const Key('redeem-resubmit'),
                  onPressed: submitting ? null : onResubmit,
                  icon: const Icon(Icons.send),
                  label: const Text('Gửi lại kèm hóa đơn'),
                ),
                TextButton(onPressed: submitting ? null : onCancel, child: const Text('Hủy')),
              ],
            ),
          ],
        ),
      );
}

// FR-REDEEM-12: o nhap OTP bi khoa, hien thoi diem mo khoa + dem nguoc; van quet QR duoc
class _OtpLockedBanner extends StatelessWidget {
  const _OtpLockedBanner({required this.lockedUntil, required this.remaining, required this.onScanQr});

  final DateTime lockedUntil;
  final Duration remaining;
  final VoidCallback onScanQr;

  @override
  Widget build(BuildContext context) {
    final seconds = remaining.inSeconds < 0 ? 0 : remaining.inSeconds;
    final countdown = '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Container(
      key: const Key('redeem-otp-locked'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.danger.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.danger),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock, color: AppColors.danger),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Ô nhập OTP bị khóa đến ${formatTime(lockedUntil)}, hãy quét mã QR',
                  style: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text('Mở khóa sau $countdown', style: const TextStyle(color: AppColors.textSecondary)),
          TextButton.icon(
            onPressed: onScanQr,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Chuyển sang quét QR'),
          ),
        ],
      ),
    );
  }
}

// Noi dung khung ket qua that bai: tieu de lon + mot dong chi tiet (+ danh sach chi nhanh khi sai chi nhanh)
class _FailureView {
  const _FailureView(this.headline, this.detail, [this.bullets = const []]);

  final String headline;
  final String detail;
  final List<String> bullets;
}

// FR-REDEEM-07: moi ma ly do cua may chu -> tieu de ngan nhan vien doc duoc ngay
_FailureView _describeFailure(RedeemFailure f) {
  switch (f.reason) {
    case RedeemReason.voucherUsed:
      final usedAt = asDateOrNull(f.details['usedAt']);
      final storeName = f.details['storeName'] as String?;
      if (usedAt == null && (storeName == null || storeName.isEmpty)) return _FailureView('ĐÃ SỬ DỤNG', f.message);
      return _FailureView('ĐÃ SỬ DỤNG', [
        'Đã dùng',
        if (usedAt != null) 'lúc ${formatTimeDate(usedAt)}',
        if (storeName != null && storeName.isNotEmpty) 'tại $storeName',
      ].join(' '));
    case RedeemReason.wrongStore:
      final stores = f.details['stores'];
      final bullets = [
        if (stores is List)
          for (final s in stores.whereType<Map>())
            [s['name'], s['address']].whereType<String>().where((v) => v.isNotEmpty).join(' — '),
      ].where((s) => s.isNotEmpty).toList();
      return bullets.isEmpty ? _FailureView('SAI CHI NHÁNH', f.message) : _FailureView('SAI CHI NHÁNH', 'Áp dụng tại:', bullets);
    case RedeemReason.voucherExpired:
      return _FailureView('VOUCHER HẾT HẠN', f.message);
    case RedeemReason.tokenExpired:
      return const _FailureView('MÃ ĐÃ HẾT HẠN', 'Nhờ khách làm mới mã trên ứng dụng rồi quét / nhập lại.');
    case RedeemReason.tokenRevoked || RedeemReason.tokenUsed || RedeemReason.tokenInvalid:
      return _FailureView('MÃ KHÔNG HỢP LỆ', f.message);
    case RedeemReason.refundPending:
      return _FailureView('ĐANG CHỜ HOÀN TIỀN', f.message);
    case RedeemReason.refunded:
      return _FailureView('ĐÃ HOÀN TIỀN', f.message);
    case RedeemReason.otpInvalid:
      return _FailureView('SAI MÃ OTP', f.message);
    case RedeemReason.storeNotSelected:
      return _FailureView('CHƯA CHỌN CHI NHÁNH', f.message);
    default:
      return _FailureView('KHÔNG HỢP LỆ', f.message);
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result, required this.failure});

  final RedeemResult? result;
  final RedeemFailure? failure;

  static const _white = TextStyle(color: Colors.white, fontSize: 16);

  @override
  Widget build(BuildContext context) {
    final success = failure == null && result != null;
    final color = success ? AppColors.success : AppColors.danger;
    final children = success ? _successLines(result!) : _failureLines(_describeFailure(failure!));
    return Container(
      key: Key(success ? 'redeem-success' : 'redeem-error'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(success ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 72),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }

  static Widget _headline(String text) => Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
      );

  List<Widget> _successLines(RedeemResult r) => [
        _headline('HỢP LỆ'),
        if (r.campaign != null && r.campaign!.title.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            r.campaign!.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: AppSpacing.xs),
        if (r.voucherCode != null && r.voucherCode!.isNotEmpty)
          Text('Mã voucher: ${r.voucherCode}', textAlign: TextAlign.center, style: _white),
        Text(
          [
            'Xác nhận lúc ${formatTimeDate(r.redeemedAt ?? DateTime.now())}',
            if (r.method != null) r.method == 'OTP' ? 'Mã OTP' : 'Quét QR',
          ].join(' · '),
          textAlign: TextAlign.center,
          style: _white,
        ),
        if (r.billAmount != null)
          Text('Hóa đơn: ${formatVnd(r.billAmount!)}', textAlign: TextAlign.center, style: _white),
      ];

  List<Widget> _failureLines(_FailureView view) => [
        _headline(view.headline),
        const SizedBox(height: AppSpacing.xs),
        Text(view.detail, textAlign: TextAlign.center, style: _white),
        if (view.bullets.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.xs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [for (final b in view.bullets) Text('• $b', style: _white)],
            ),
          ),
      ];
}
