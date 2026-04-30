import 'package:baht/core/utils/formatters.dart';
import 'package:baht/features/home/domain/entities/weekly_recap_data.dart';
import 'package:baht/features/home/presentation/utils/weekly_review_aggregation.dart';
import 'package:baht/features/home/presentation/widgets/weekly_money_review/weekly_recap_chrome.dart';
import 'package:baht/features/home/presentation/widgets/weekly_money_review/weekly_review_viz.dart';
import 'package:flutter/material.dart';

const _weekdayShort = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _fmtPct(double? p) {
  if (p == null) return '—';
  final sign = p > 0 ? '+' : '';
  return '$sign${p.toStringAsFixed(0)}%';
}

/// Builds the Weekly Money Review story in display order.
List<Widget> buildWeeklyReviewSlides({
  required WeeklyRecapData data,
  required List<Color> colors,
  required int pageIndex,
}) {
  final showLeaks = shouldShowWeeklyReviewMoneyLeaksSlide(
    totalSpent: data.totalSpent,
    smallPurchaseCount: data.smallPurchaseCount,
    smallPurchaseTotal: data.smallPurchaseTotal,
  );
  final showShift = shouldShowWeeklyReviewCategoryShiftSlide(data.categoryShift);

  final slides = <Widget>[];
  var i = 0;

  slides.add(
    _IntroSlide(
      data: data,
      backgroundColor: colors[i],
      isActive: pageIndex == i,
    ),
  );
  i++;

  slides.add(
    _MoneyPulseSlide(
      data: data,
      backgroundColor: colors[i],
      isActive: pageIndex == i,
    ),
  );
  i++;

  slides.add(
    _WhereItWentSlide(
      data: data,
      backgroundColor: colors[i],
      isActive: pageIndex == i,
    ),
  );
  i++;

  if (showLeaks) {
    slides.add(
      _MoneyLeakSlide(
        data: data,
        backgroundColor: colors[i],
        isActive: pageIndex == i,
      ),
    );
    i++;
  }

  if (showShift) {
    slides.add(
      _CategoryShiftSlide(
        shift: data.categoryShift!,
        backgroundColor: colors[i],
        isActive: pageIndex == i,
      ),
    );
    i++;
  }

  slides.add(
    _BiggestDecisionSlide(
      data: data,
      backgroundColor: colors[i],
      isActive: pageIndex == i,
    ),
  );
  i++;

  slides.add(
    _NextMoveSlide(
      data: data,
      backgroundColor: colors[i],
      isActive: pageIndex == i,
    ),
  );

  return slides;
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final label = formatWeekRangeKicker(data.weekStart, data.weekEnd);
    return WeeklyReviewSlideScaffold(
      backgroundColor: backgroundColor,
      seed: 0,
      decorativeText: '${data.weekStart.day}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RecapReveal(
            isActive: isActive,
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: recapKickerStyle(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 20),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 100),
            child: Text(
              'Your Weekly\nMoney Review',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kWeeklyRecapInk.withValues(alpha: 0.92),
                fontSize: data.hasActivity ? 36 : 30,
                fontWeight: FontWeight.w900,
                height: 1.08,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 200),
            child: data.hasActivity
                ? PatternReviewChip(label: patternTypeLabel(data.reviewPattern))
                : Text(
                    'A quiet week — tap through for a quick look',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: kWeeklyRecapInk.withValues(alpha: 0.55),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _MoneyPulseSlide extends StatelessWidget {
  const _MoneyPulseSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final spent = formatAmountWithComma(data.totalSpent, decimalDigits: 2);
    final delta = data.spentChangeVsPreviousAmount;
    final deltaStr = formatAmountWithComma(delta.abs(), decimalDigits: 2);
    final deltaLine =
        data.previousWeekTotalSpent <= 0
            ? 'Log next week too — then you’ll see a week-over-week compare'
            : (delta >= 0
                ? '฿$deltaStr more than last week · ${_fmtPct(data.spentChangeVsPreviousPercent)}'
                : '฿$deltaStr less than last week · ${_fmtPct(data.spentChangeVsPreviousPercent)}');
    return WeeklyReviewSlideScaffold(
      backgroundColor: backgroundColor,
      seed: 1,
      decorativeText: '◉',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecapReveal(
            isActive: isActive,
            child: Text(
              'THIS WEEK',
              textAlign: TextAlign.center,
              style: recapKickerStyle(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 20),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 100),
            child: Text(
              data.hasActivity ? '฿$spent' : '฿0',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kWeeklyRecapInk,
                fontSize: 52,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.0,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 8),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 180),
            child: Text(
              'Your spending this week',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kWeeklyRecapInk.withValues(alpha: 0.5),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 210),
            child: SizedBox(
              height: 100,
              child: MoneyPulseComparisonBars(
                thisWeek: data.totalSpent,
                lastWeek: data.previousWeekTotalSpent,
                fourWeekAverage: data.baselineAverageSpent,
                maxBarHeight: 80,
              ),
            ),
          ),
          const SizedBox(height: 16),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 250),
            child: Text(
              deltaLine,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kWeeklyRecapInk.withValues(alpha: 0.7),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WhereItWentSlide extends StatelessWidget {
  const _WhereItWentSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final busy = data.busiestSpendingDayIndex.clamp(0, 6);
    final rhythmLine = data.hasActivity
        ? spendingRhythmBusiestLine(
            daily: data.dailyCategorySpending,
            busiestIndex: busy,
            weekdayShort: _weekdayShort,
          )
        : 'Log spending to see where your money went this week.';

    final topCat = data.topCategory;
    final topAmt = data.topCategoryAmount;
    final hasTopCategory =
        topCat != null && topCat.isNotEmpty && topAmt > 0;
    final topFmt =
        hasTopCategory ? formatAmountWithComma(topAmt, decimalDigits: 2) : null;

    return WeeklyReviewSlideScaffold(
      backgroundColor: backgroundColor,
      seed: 2,
      decorativeText: '⌁',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecapReveal(
            isActive: isActive,
            child: Text(
              'WHERE IT WENT',
              textAlign: TextAlign.center,
              style: recapKickerStyle(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 16),
          if (data.hasActivity && hasTopCategory && topFmt != null) ...[
            RecapReveal(
              isActive: isActive,
              delay: const Duration(milliseconds: 80),
              child: Text(
                topCat,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kWeeklyRecapInk,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(height: 8),
            RecapReveal(
              isActive: isActive,
              delay: const Duration(milliseconds: 140),
              child: Text(
                '฿$topFmt · Your top category',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kWeeklyRecapInk.withValues(alpha: 0.55),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 20),
          ] else if (!data.hasActivity) ...[
            RecapReveal(
              isActive: isActive,
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Ready when you are',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: kWeeklyRecapInk,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 200),
            child: Text(
              rhythmLine,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kWeeklyRecapInk.withValues(alpha: 0.55),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MoneyLeakSlide extends StatelessWidget {
  const _MoneyLeakSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final th = formatAmountWithComma(
      data.smallPurchaseThresholdUsed,
      decimalDigits: 0,
    );
    final tot = formatAmountWithComma(
      data.smallPurchaseTotal,
      decimalDigits: 2,
    );
    final share =
        data.totalSpent > 0
            ? (data.smallPurchaseTotal / data.totalSpent * 100).toStringAsFixed(
              0,
            )
            : '0';
    return WeeklyReviewSlideScaffold(
      backgroundColor: backgroundColor,
      seed: 3,
      decorativeText: '·',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RecapReveal(
            isActive: isActive,
            child: Text(
              'SMALL BUYS',
              textAlign: TextAlign.center,
              style: recapKickerStyle(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 12),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 80),
            child: MoneyLeakDotCluster(
              purchaseCount: data.smallPurchaseCount,
            ),
          ),
          const SizedBox(height: 16),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 100),
            child: Text(
              data.hasActivity ? '฿$tot' : '฿0',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kWeeklyRecapInk,
                fontSize: 48,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 200),
            child: Text(
              data.hasActivity
                  ? '${data.smallPurchaseCount} small buys under ฿$th each · $share% of your week'
                  : 'Small buys add up — log a few to see the pattern',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kWeeklyRecapInk.withValues(alpha: 0.62),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryShiftSlide extends StatelessWidget {
  const _CategoryShiftSlide({
    required this.shift,
    required this.backgroundColor,
    required this.isActive,
  });

  final CategoryShiftInsight shift;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return WeeklyReviewSlideScaffold(
      backgroundColor: backgroundColor,
      seed: 4,
      decorativeText: '§',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecapReveal(
            isActive: isActive,
            child: Text(
              'WHAT CHANGED',
              textAlign: TextAlign.center,
              style: recapKickerStyle(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 20),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 100),
            child: Text(
              shift.categoryName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: kWeeklyRecapInk,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 200),
            child: Text(
              'More than your usual by ฿${formatAmountWithComma(shift.differenceFromBaseline, decimalDigits: 2)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kWeeklyRecapInk.withValues(alpha: 0.65),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),
          RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 280),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CategoryShiftComparisonBars(
                baseline: shift.baselineCategoryAverage,
                thisWeek: shift.thisWeekAmount,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BiggestDecisionSlide extends StatelessWidget {
  const _BiggestDecisionSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final log = data.biggestExpense;
    final title =
        log == null
            ? null
            : (log.category.isNotEmpty ? log.category : log.timeLabel);
    final amount =
        log != null
            ? formatAmountWithComma(log.amount.abs(), decimalDigits: 2)
            : null;
    final pct = (data.biggestExpenseShare * 100).toStringAsFixed(0);
    return WeeklyReviewSlideScaffold(
      backgroundColor: backgroundColor,
      seed: 5,
      decorativeText: '฿',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          RecapReveal(
            isActive: isActive,
            child: Text(
              'YOUR BIGGEST BUY',
              textAlign: TextAlign.center,
              style: recapKickerStyle(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 20),
          if (log != null && title != null) ...[
            RecapReveal(
              isActive: isActive,
              delay: const Duration(milliseconds: 100),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  WeekShareDonut(share: data.biggestExpenseShare),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: kWeeklyRecapInk,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '฿$amount',
                          style: const TextStyle(
                            color: kWeeklyRecapInk,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          data.totalSpent > 0 ? '$pct% of your week' : '',
                          style: TextStyle(
                            color: kWeeklyRecapInk.withValues(alpha: 0.6),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else
            RecapReveal(
              isActive: isActive,
              delay: const Duration(milliseconds: 100),
              child: Text(
                'Nothing big stood out this week',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: kWeeklyRecapInk.withValues(alpha: 0.7),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _NextMoveSlide extends StatelessWidget {
  const _NextMoveSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final m = data.nextMove;
    return WeeklyReviewSlideScaffold(
      backgroundColor: backgroundColor,
      seed: 7,
      decorativeText: '✓',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RecapReveal(
            isActive: isActive,
            child: Text(
              'Nice work',
              textAlign: TextAlign.center,
              style: recapKickerStyle(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          NextMoveActionCard(
            nextMove: m,
            isActive: isActive,
          ),
        ],
      ),
    );
  }
}
