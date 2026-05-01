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
    this.todayBudgetRemaining,
  });

  final double todaySpending;
  final double netBalance;
  final double? todayBudgetRemaining;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMasked = ref.watch(amountMaskControllerProvider);

    final remaining = todayBudgetRemaining;
    final bool isOverBudget = (remaining ?? 0) < 0;

    final double? budgetProgress = () {
      if (remaining == null) return null;
      final total = todaySpending + remaining;
      if (total <= 0) return null;
      return (todaySpending / total).clamp(0.0, 1.0);
    }();

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(right: -12, top: -12, child: _SpendingBlob()),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Spent today',
              style: DashboardSectionHeaderStyles.titleStyle(
                color: Colors.white.withValues(alpha: 0.65),
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
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            const DashboardDoodleDivider.curl(
              color: Color(0x73FFFFFF),
            ),
            if (budgetProgress != null) ...[
              const SizedBox(height: 14),
              _BudgetProgressBar(
                progress: budgetProgress,
                remaining: remaining!,
                isOverBudget: isOverBudget,
                isMasked: isMasked,
              ),
            ],
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
                    color: Colors.white.withValues(alpha: 0.65),
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

class _BudgetProgressBar extends StatelessWidget {
  const _BudgetProgressBar({
    required this.progress,
    required this.remaining,
    required this.isOverBudget,
    required this.isMasked,
  });

  final double progress;
  final double remaining;
  final bool isOverBudget;
  final bool isMasked;

  static const _amberColor = Color(0xFFFFBBA8);

  @override
  Widget build(BuildContext context) {
    final absLabel = formatCurrencyUnsignedMasked(
      remaining.abs(),
      isMasked: isMasked,
    );
    final label = isOverBudget ? '$absLabel over budget' : '$absLabel left today';

    final barColor = isOverBudget
        ? _amberColor.withValues(alpha: 0.85)
        : Colors.white;
    final trackColor = isOverBudget
        ? _amberColor.withValues(alpha: 0.20)
        : Colors.white.withValues(alpha: 0.20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 4,
            backgroundColor: trackColor,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isOverBudget
                ? _amberColor.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.55),
          ),
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
        color: Colors.white.withValues(alpha: 0.18),
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
      size: const Size(180, 140),
      painter: _SpendingBlobPainter(),
    );
  }
}

class _SpendingBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final blobPaint =
        Paint()
          ..color = const Color(0xFF2E7A6A)
          ..style = PaintingStyle.fill;

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

    final dotPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.25)
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
