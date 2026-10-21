import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/format.dart';

// FR-REPORT-03: only plot observed daily revenue; never fabricate trend data.
class RevenueChart extends StatelessWidget {
  const RevenueChart({super.key, required this.rows});
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final values = rows
        .map((r) => num.tryParse('${r['revenue']}')?.toDouble() ?? 0)
        .toList();
    if (values.isEmpty) return const SizedBox.shrink();
    final maximum = values.reduce(math.max);
    return Semantics(
      label: 'Biểu đồ doanh thu theo ngày. Cao nhất ${formatVnd(maximum)}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Cao nhất ${formatVnd(maximum)}',
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            width: double.infinity,
            child: CustomPaint(painter: _RevenuePainter(values)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Chi tiết từng ngày bên dưới',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _RevenuePainter extends CustomPainter {
  _RevenuePainter(this.values);
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = 8 + (size.height - 16) * i / 4;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    final high = math.max(1.0, values.reduce(math.max));
    final low = math.min(0.0, values.reduce(math.min));
    final points = [
      for (var i = 0; i < values.length; i++)
        Offset(
          values.length == 1
              ? size.width / 2
              : 8 + (size.width - 16) * i / (values.length - 1),
          size.height -
              8 -
              (values[i] - low) / (high - low) * (size.height - 24),
        ),
    ];
    final line = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      line.lineTo(point.dx, point.dy);
    }
    if (points.length > 1) {
      final area = Path.from(line)
        ..lineTo(points.last.dx, size.height - 8)
        ..lineTo(points.first.dx, size.height - 8)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x5538A887), Color(0x0038A887)],
          ).createShader(Offset.zero & size),
      );
      canvas.drawPath(
        line,
        Paint()
          ..color = AppColors.primary
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..strokeJoin = StrokeJoin.round,
      );
    }
    for (final p in points) {
      canvas.drawCircle(p, 5, Paint()..color = Colors.white);
      canvas.drawCircle(p, 3, Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(covariant _RevenuePainter oldDelegate) =>
      oldDelegate.values != values;
}
