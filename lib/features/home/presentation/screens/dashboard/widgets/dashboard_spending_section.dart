import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/utils/formatters.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_doodle_divider.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_section_header_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardSpendingSection extends ConsumerWidget {
  const DashboardSpendingSection({
    super.key,
    required this.todaySpending,
    required this.netBalance,
  });

  final double todaySpending;
  final double netBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMasked = ref.watch(amountMaskControllerProvider);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(right: -8, top: -8, child: _SpendingBlob()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spent today',
              style: DashboardSectionHeaderStyles.titleStyle(
                color: Colors.grey[700]!,
              ),
            ),
            const SizedBox(
              height: DashboardSectionHeaderStyles.spacingBelowTitle,
            ),
            Text(
              formatCurrencySignedMasked(-todaySpending, isMasked: isMasked),
              style: const TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            const DashboardDoodleDivider.curl(color: Color(0xFF6BADA0)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Balance',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: Colors.grey[700],
                  ),
                ),
                _BalanceBadge(
                  label: formatNetBalanceMasked(netBalance, isMasked: isMasked),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _BalanceBadge extends StatelessWidget {
  const _BalanceBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF1A5C52),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Mint-green organic blob + scattered dots for the spending card background.
class _SpendingBlob extends StatelessWidget {
  const _SpendingBlob();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(140, 110),
      painter: _SpendingBlobPainter(),
    );
  }
}

class _SpendingBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blobPaint =
        Paint()
          ..color = const Color(0xFFD4EDE8)
          ..style = PaintingStyle.fill;

    // Organic blob shape in upper-right
    final path = Path();
    path.moveTo(size.width * 0.55, size.height * 0.05);
    path.cubicTo(
      size.width * 0.80,
      -size.height * 0.10,
      size.width * 1.10,
      size.height * 0.10,
      size.width * 1.00,
      size.height * 0.45,
    );
    path.cubicTo(
      size.width * 0.95,
      size.height * 0.70,
      size.width * 0.75,
      size.height * 0.80,
      size.width * 0.55,
      size.height * 0.70,
    );
    path.cubicTo(
      size.width * 0.30,
      size.height * 0.58,
      size.width * 0.28,
      size.height * 0.30,
      size.width * 0.55,
      size.height * 0.05,
    );
    path.close();
    canvas.drawPath(path, blobPaint);

    // Small scattered dots
    final dotPaint =
        Paint()
          ..color = const Color(0xFF6BADA0).withValues(alpha: 0.55)
          ..style = PaintingStyle.fill;

    final dots = [
      Offset(size.width * 0.18, size.height * 0.22),
      Offset(size.width * 0.88, size.height * 0.82),
      Offset(size.width * 0.72, size.height * 0.12),
    ];
    final radii = [4.0, 3.5, 2.5];

    for (var i = 0; i < dots.length; i++) {
      canvas.drawCircle(dots[i], radii[i], dotPaint);
    }
  }

  @override
  bool shouldRepaint(_SpendingBlobPainter _) => false;
}
