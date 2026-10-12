import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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

class _RedeemPanelState extends State<_RedeemPanel> {
  final _otpFormKey = GlobalKey<FormState>();
  final _otp = TextEditingController();
  final _bill = TextEditingController();
  bool _cameraOn = false;
  String? _localError;

  @override
  void dispose() {
    _otp.dispose();
    _bill.dispose();
    super.dispose();
  }

  // Gia tri hoa don khong bat buoc; nhap sai dinh dang thi bao loi thay vi bo qua
  int? _billAmount() => parseMoney(_bill.text);

  bool _billValid() {
    if (_bill.text.trim().isEmpty) return true;
    if (_billAmount() == null) {
      setState(() => _localError = 'Giá trị hóa đơn không hợp lệ');
      return false;
    }
    return true;
  }

  Future<void> _onScanned(String raw) async {
    final session = context.read<StoreSessionProvider>();
    if (session.isSubmitting || session.lastResult != null || session.lastError != null) return;
    setState(() => _localError = null);
    final payload = QrPayload.tryParse(raw);
    if (payload == null) {
      setState(() => _localError = 'Mã QR không đúng định dạng của hệ thống.');
      return;
    }
    if (payload.isExpired(DateTime.now().toUtc())) {
      setState(() => _localError = 'Mã QR đã hết hạn, nhờ khách làm mới mã trên ứng dụng.');
      return;
    }
    if (!_billValid()) return;
    await session.redeem(nonce: payload.nonce, billAmount: _billAmount());
  }

  Future<void> _submitOtp() async {
    setState(() => _localError = null);
    if (!_otpFormKey.currentState!.validate() || !_billValid()) return;
    final ok = await context.read<StoreSessionProvider>().redeem(otpCode: _otp.text.trim(), billAmount: _billAmount());
    if (ok) _otp.clear();
  }

  void _next() {
    setState(() => _localError = null);
    _bill.clear();
    context.read<StoreSessionProvider>().clearResult();
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<StoreSessionProvider>();
    final hasOutcome = session.lastResult != null || session.lastError != null || _localError != null;

    return DefaultTabController(
      length: 2,
      child: ListView(
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
                  if (hasOutcome) ...[
                    _ResultPanel(result: session.lastResult, error: _localError ?? session.lastError),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      key: const Key('redeem-next'),
                      onPressed: _next,
                      icon: const Icon(Icons.arrow_forward),
                      label: const Text('Khách tiếp theo'),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                  const TabBar(tabs: [
                    Tab(icon: Icon(Icons.qr_code_scanner), text: 'Quét QR'),
                    Tab(icon: Icon(Icons.pin_outlined), text: 'Nhập OTP'),
                  ]),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    key: const Key('redeem-bill'),
                    controller: _bill,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Giá trị hóa đơn (VND)',
                      helperText: 'Bắt buộc với voucher mệnh giá, không bắt buộc với loại khác (FR-REDEEM-08)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 460,
                    child: TabBarView(
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _qrTab(session),
                        _otpTab(session),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrTab(StoreSessionProvider session) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_cameraOn)
            Expanded(
              child: QrScannerView(
                onDetect: _onScanned,
                paused: session.isSubmitting || session.lastResult != null || session.lastError != null,
              ),
            )
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

  Widget _otpTab(StoreSessionProvider session) => Form(
        key: _otpFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              key: const Key('redeem-otp'),
              controller: _otp,
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
              onPressed: session.isSubmitting ? null : _submitOtp,
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
      );
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({required this.result, required this.error});

  final RedeemResult? result;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final success = error == null && result != null;
    final color = success ? AppColors.success : AppColors.danger;
    return Container(
      key: Key(success ? 'redeem-success' : 'redeem-error'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Icon(success ? Icons.check_circle : Icons.cancel, color: Colors.white, size: 72),
          const SizedBox(height: AppSpacing.sm),
          Text(
            success ? 'HỢP LỆ' : 'KHÔNG HỢP LỆ',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            success
                ? 'Đã xác nhận lúc ${formatDateTime(result!.redeemedAt ?? DateTime.now())}'
                : error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
