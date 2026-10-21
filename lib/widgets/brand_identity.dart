import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandIdentity extends StatelessWidget {
  const BrandIdentity({super.key, this.light = false});
  final bool light;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: light ? const Color(0xFFD8F5A2) : AppColors.primary,
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          Icons.confirmation_number_outlined,
          size: 24,
          color: light ? AppColors.primaryDark : Colors.white,
        ),
      ),
      const SizedBox(width: 10),
      Flexible(
        child: Text(
          'vouch.',
          style: TextStyle(
            fontSize: 30,
            letterSpacing: -1.5,
            fontWeight: FontWeight.w800,
            color: light ? Colors.white : AppColors.primaryDark,
          ),
        ),
      ),
    ],
  );
}

// Decorative product illustration, independent of transaction data.
class VoucherArtwork extends StatelessWidget {
  const VoucherArtwork({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 360,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 250,
          height: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: .15),
              width: 32,
            ),
          ),
        ),
        Transform.rotate(
          angle: -.12,
          child: Container(
            width: 290,
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: const Color(0xFFDFF5BB),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: .18),
                  blurRadius: 30,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'VOUCH. / ĐẶC QUYỀN',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Icon(Icons.north_east, color: AppColors.primaryDark),
                  ],
                ),
                SizedBox(height: 22),
                Text(
                  'Một ưu đãi.\nNgàn kết nối.',
                  style: TextStyle(
                    fontSize: 30,
                    height: 1.15,
                    letterSpacing: -1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 20),
                Divider(color: Color(0xFF9FBD7F)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'TRẢI NGHIỆM NHIỀU HƠN',
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 1,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.qr_code_2,
                      size: 34,
                      color: AppColors.primaryDark,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class PortalWelcome extends StatelessWidget {
  const PortalWelcome({super.key, required this.title, required this.subtitle});
  final String title, subtitle;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(28),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [AppColors.primaryDark, Color(0xFF176A5B)],
      ),
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'VOUCH. WORKSPACE',
                style: TextStyle(
                  color: Color(0xFFD8F5A2),
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -.7,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(color: Color(0xFFD3E7DF), height: 1.5),
              ),
            ],
          ),
        ),
        if (MediaQuery.sizeOf(context).width > 700) ...[
          const SizedBox(width: 24),
          const Icon(
            Icons.auto_graph_rounded,
            size: 72,
            color: Color(0xFFD8F5A2),
          ),
        ],
      ],
    ),
  );
}
