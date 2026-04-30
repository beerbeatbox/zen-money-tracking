import 'dart:math' as math;
import 'package:baht/features/home/domain/entities/weekly_recap_data.dart';
import 'package:baht/features/home/presentation/widgets/weekly_money_review/weekly_recap_chrome.dart';
import 'package:flutter/material.dart';

/// Three mini bars: this week, last week, and your usual week (4-week average).
class MoneyPulseComparisonBars extends StatelessWidget {
  const MoneyPulseComparisonBars({
    super.key,
    required this.thisWeek,
    required this.lastWeek,
    required this.fourWeekAverage,
    this.maxBarHeight = 100,
  });

  final double thisWeek;
  final double lastWeek;
  final double fourWeekAverage;
  final double maxBarHeight;

  @override
  Widget build(BuildContext context) {
    final maxV = [thisWeek, lastWeek, fourWeekAverage]
        .map((e) => e)
        .reduce(math.max)
        .clamp(1.0, double.infinity);
    Widget bar(String label, double value, {required bool isPrimary}) {
      final h = (value / maxV) * maxBarHeight;
      return Expanded(
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 28,
                  height: h,
                  decoration: BoxDecoration(
                    color: kWeeklyRecapInk.withValues(
                      alpha: isPrimary ? 0.9 : 0.28,
                    ),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: kWeeklyRecapInk.withValues(alpha: 0.5),
                height: 1.1,
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        bar('This week', thisWeek, isPrimary: true),
        const SizedBox(width: 8),
        bar('Last week', lastWeek, isPrimary: false),
        const SizedBox(width: 8),
        bar('Your usual week', fourWeekAverage, isPrimary: false),
      ],
    );
  }
}

/// Stacked top vs other per day, Mon–Sun.
class DailyStackedSpendingChart extends StatelessWidget {
  const DailyStackedSpendingChart({
    super.key,
    required this.daily,
    required this.busiestIndex,
    required this.animationValue,
  });

  final List<DailyCategorySpend> daily;
  final int busiestIndex;
  final double animationValue;

  @override
  Widget build(BuildContext context) {
    if (daily.length != 7) {
      return const SizedBox.shrink();
    }
    final totals = daily.map((d) => d.totalAmount).toList();
    final maxV = totals
        .fold(0.0, math.max)
        .clamp(1.0, double.infinity);
    const maxBarH = 160.0;
    final t = Curves.easeOutCubic.transform(animationValue);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (i) {
        final d = daily[i];
        final totalH = (d.totalAmount / maxV) * maxBarH * t;
        final topH =
            d.totalAmount > 0
                ? (d.topCategoryAmount / d.totalAmount) * totalH
                : 0.0;
        final otherH = (totalH - topH).clamp(0.0, totalH);
        final isBusy = i == busiestIndex && d.totalAmount > 0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: maxBarH * t,
                  child: d.totalAmount > 0
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (topH > 0.5)
                              Container(
                                width: double.infinity,
                                height: topH,
                                decoration: BoxDecoration(
                                  color: kWeeklyRecapInk.withValues(
                                    alpha: isBusy ? 0.9 : 0.42,
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(4),
                                  ),
                                ),
                              ),
                            if (otherH > 0.5)
                              Container(
                                width: double.infinity,
                                height: otherH,
                                decoration: BoxDecoration(
                                  color: kWeeklyRecapInk.withValues(
                                    alpha: isBusy ? 0.2 : 0.14,
                                  ),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(3),
                                  ),
                                ),
                              ),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
                const SizedBox(height: 4),
                Text(
                  d.barLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: kWeeklyRecapInk.withValues(alpha: 0.55),
                  ),
                ),
                Text(
                  _weekday[i],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: kWeeklyRecapInk.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

const _weekday = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

/// Dots for small-purchase count (capped for layout).
class MoneyLeakDotCluster extends StatelessWidget {
  const MoneyLeakDotCluster({super.key, required this.purchaseCount});

  final int purchaseCount;

  @override
  Widget build(BuildContext context) {
    final n = purchaseCount > 0 ? math.min(purchaseCount, 18) : 0;
    if (n == 0) {
      return const SizedBox(height: 40);
    }
    return SizedBox(
      height: 48,
      child: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: List.generate(
            n,
            (i) => Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kWeeklyRecapInk.withValues(alpha: 0.2 + (i % 3) * 0.1),
                border: Border.all(
                  color: kWeeklyRecapInk.withValues(alpha: 0.25),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CategoryShiftComparisonBars extends StatelessWidget {
  const CategoryShiftComparisonBars({
    super.key,
    required this.baseline,
    required this.thisWeek,
  });

  final double baseline;
  final double thisWeek;

  @override
  Widget build(BuildContext context) {
    final maxV = [baseline, thisWeek, 1.0]
        .map((e) => e)
        .reduce(math.max);
    const h = 120.0;
    Widget col(String label, double v, {required bool isThisWeek}) {
      final barH = (v / maxV) * h;
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: kWeeklyRecapInk.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: h,
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: 40,
                  height: barH.clamp(0.0, h),
                  decoration: BoxDecoration(
                    color: isThisWeek
                        ? kWeeklyRecapInk
                        : kWeeklyRecapInk.withValues(alpha: 0.22),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        col('Your usual week', baseline, isThisWeek: false),
        const SizedBox(width: 20),
        col('This week', thisWeek, isThisWeek: true),
      ],
    );
  }
}

class WeekShareDonut extends StatelessWidget {
  const WeekShareDonut({super.key, required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _DonutSharePainter(share: share),
        child: Center(
          child: Text(
            '${(share * 100).round()}%',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: kWeeklyRecapInk,
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutSharePainter extends CustomPainter {
  _DonutSharePainter({required this.share});

  final double share;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide / 2;
    final stroke = 10.0;
    final bg = Paint()
      ..color = kWeeklyRecapInk.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final fg = Paint()
      ..color = kWeeklyRecapInk
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    final rect = Rect.fromCircle(center: c, radius: r - stroke / 2);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi, false, bg);
    final sweep = (share.clamp(0.0, 1.0)) * 2 * math.pi;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, fg);
  }

  @override
  bool shouldRepaint(covariant _DonutSharePainter oldDelegate) {
    return oldDelegate.share != share;
  }
}

class MonthPaceBar extends StatelessWidget {
  const MonthPaceBar({
    super.key,
    required this.monthToDate,
    required this.projected,
  });

  final double monthToDate;
  final double? projected;

  @override
  Widget build(BuildContext context) {
    if (projected == null || projected! <= 0) {
      return const SizedBox.shrink();
    }
    final maxV = math.max(monthToDate, projected!);
    final fill = (monthToDate / maxV).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: fill,
            minHeight: 12,
            backgroundColor: kWeeklyRecapInk.withValues(alpha: 0.1),
            color: kWeeklyRecapInk.withValues(alpha: 0.5),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'This far',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kWeeklyRecapInk.withValues(alpha: 0.45),
              ),
            ),
            Text(
              'Pace to month-end',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: kWeeklyRecapInk.withValues(alpha: 0.45),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class NextMoveActionCard extends StatelessWidget {
  const NextMoveActionCard({super.key, required this.nextMove, required this.isActive});

  final WeeklyReviewNextMove nextMove;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return RecapReveal(
      isActive: isActive,
      delay: const Duration(milliseconds: 200),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(
          color: kWeeklyRecapInk.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kWeeklyRecapInk.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle_rounded, size: 22, color: kWeeklyRecapInk.withValues(alpha: 0.75)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    nextMove.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: kWeeklyRecapInk,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _TargetMeter(fraction: 0.72, isActive: isActive),
            const SizedBox(height: 12),
            Text(
              nextMove.body,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.45,
                color: kWeeklyRecapInk.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetMeter extends StatefulWidget {
  const _TargetMeter({required this.fraction, required this.isActive});

  final double fraction;
  final bool isActive;

  @override
  State<_TargetMeter> createState() => _TargetMeterState();
}

class _TargetMeterState extends State<_TargetMeter> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isActive) _c.forward();
  }

  @override
  void didUpdateWidget(covariant _TargetMeter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _c.forward(from: 0);
    } else if (!widget.isActive && oldWidget.isActive) {
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final v = Curves.easeOutCubic.transform(_c.value) * widget.fraction;
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: v.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: kWeeklyRecapInk.withValues(alpha: 0.1),
            color: kWeeklyRecapInk,
          ),
        );
      },
    );
  }
}

class PatternReviewChip extends StatelessWidget {
  const PatternReviewChip({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kWeeklyRecapInk.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kWeeklyRecapInk.withValues(alpha: 0.12)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: kWeeklyRecapInk,
        ),
      ),
    );
  }
}
