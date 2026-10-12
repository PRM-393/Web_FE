import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme/app_theme.dart';

// Quet QR bang camera cua trinh duyet (FR-REDEEM-05). Tren web can HTTPS hoac localhost de duoc cap quyen camera.
// Moi lan doc duoc ma se goi onDetect voi chuoi tho; man cha quyet dinh dung / tiep tuc quet.
class QrScannerView extends StatefulWidget {
  const QrScannerView({super.key, required this.onDetect, this.paused = false});

  final ValueChanged<String> onDetect;
  final bool paused;

  @override
  State<QrScannerView> createState() => _QrScannerViewState();
}

class _QrScannerViewState extends State<QrScannerView> {
  final _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    formats: const [BarcodeFormat.qrCode],
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handle(BarcodeCapture capture) {
    if (widget.paused) return;
    for (final code in capture.barcodes) {
      final raw = code.rawValue;
      if (raw != null && raw.isNotEmpty) {
        widget.onDetect(raw);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: 1,
          child: MobileScanner(
            controller: _controller,
            onDetect: _handle,
            errorBuilder: (context, error) => Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(AppSpacing.md),
              alignment: Alignment.center,
              child: const Text(
                'Không mở được camera. Hãy cấp quyền camera cho trình duyệt hoặc dùng mã OTP.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ),
      );
}
