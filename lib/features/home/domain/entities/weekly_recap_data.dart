import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:flutter/foundation.dart';

/// How spending behaved relative to the user’s own patterns.
enum WeeklyReviewPatternType {
  /// Sat–Sun account for a large share of the week.
  weekendSpender,

  /// Many small expenses vs total.
  frequentSmallSpender,

  /// One purchase dominated the week.
  oneBigPurchaseWeek,

  /// Food (or food-like category) is the top share.
  foodHeavyWeek,

  /// Week-over-week change is small.
  steadyWeek,

  /// Default when no clear pattern.
  mixedWeek,
}

/// One actionable line for the final slide.
@immutable
class WeeklyReviewNextMove {
  const WeeklyReviewNextMove({
    required this.title,
    required this.body,
    this.actionLabel,
  });

  final String title;
  final String body;

  /// Optional short CTA label (e.g. “Add a log”).
  final String? actionLabel;
}

/// One local day in the review week: top category vs the rest, for stacked bars.
@immutable
class DailyCategorySpend {
  const DailyCategorySpend({
    required this.weekdayIndex,
    required this.totalAmount,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.otherAmount,
    required this.distinctCategoryCount,
  });

  /// 0=Mon .. 6=Sun
  final int weekdayIndex;
  final double totalAmount;
  final String? topCategory;
  final double topCategoryAmount;
  final double otherAmount;
  final int distinctCategoryCount;

  double get topCategoryShare =>
      totalAmount > 0 ? topCategoryAmount / totalAmount : 0.0;

  /// For under-bar label: "—" | category | "Mixed"
  String get barLabel {
    if (totalAmount <= 0) return '—';
    if (distinctCategoryCount == 1 && topCategory != null) {
      return topCategory!.length > 7 ? '${topCategory!.substring(0, 6)}…' : topCategory!;
    }
    if (topCategoryShare >= 0.5 && topCategory != null) {
      return topCategory!.length > 7 ? '${topCategory!.substring(0, 6)}…' : topCategory!;
    }
    return 'Mixed';
  }
}

/// Category with the largest change vs a short personal baseline.
@immutable
class CategoryShiftInsight {
  const CategoryShiftInsight({
    required this.categoryName,
    required this.thisWeekAmount,
    required this.baselineCategoryAverage,
    required this.differenceFromBaseline,
  });

  final String categoryName;
  final double thisWeekAmount;

  /// Average amount this category had per week in the prior 4 weeks.
  final double baselineCategoryAverage;

  /// Positive = above usual for this category.
  final double differenceFromBaseline;
}

@immutable
class WeeklyRecapData {
  const WeeklyRecapData({
    required this.weekStart,
    required this.weekEnd,
    required this.totalSpent,
    required this.totalIncome,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.transactionCount,
    required this.expenseCount,
    required this.incomeCount,
    required this.biggestExpense,
    required this.logs,
    required this.previousWeekTotalSpent,
    required this.baselineAverageSpent,
    required this.hasBaselineForAverage,
    required this.spentChangeVsPreviousAmount,
    required this.spentChangeVsPreviousPercent,
    required this.dailySpendingTotals,
    required this.dailyCategorySpending,
    required this.busiestSpendingDayIndex,
    required this.categoryBreakdownSorted,
    required this.topCategoryShare,
    required this.categoryShift,
    required this.biggestExpenseShare,
    required this.smallPurchaseTotal,
    required this.smallPurchaseCount,
    required this.smallPurchaseThresholdUsed,
    required this.monthSpentInCalendarMonth,
    required this.monthProjectionDaysUsed,
    required this.monthDaysInMonth,
    required this.monthlyProjectedSpent,
    required this.reviewPattern,
    required this.nextMove,
  });

  /// Monday of the week (local, date-only).
  final DateTime weekStart;

  /// Sunday of the week (local, date-only).
  final DateTime weekEnd;
  final double totalSpent;
  final double totalIncome;
  final String? topCategory;
  final double topCategoryAmount;

  /// All logs in the week (income + expense). Prefer [expenseCount] in copy.
  final int transactionCount;
  final int expenseCount;
  final int incomeCount;
  final ExpenseLog? biggestExpense;
  final List<ExpenseLog> logs;

  final double previousWeekTotalSpent;

  /// Average total spent in the 4 full weeks before [weekStart] (0 if an empty week).
  final double baselineAverageSpent;

  /// True when at least 4 prior weeks were available to average.
  final bool hasBaselineForAverage;
  final double spentChangeVsPreviousAmount;

  /// Null when the previous week had 0 spend (avoid divide-by-zero).
  final double? spentChangeVsPreviousPercent;

  /// Mon=index 0 … Sun=6, expense totals only.
  final List<double> dailySpendingTotals;

  /// Mon=0…Sun=6, top category vs other per day.
  final List<DailyCategorySpend> dailyCategorySpending;

  /// 0–6, Mon–Sun; arg max of [dailySpendingTotals], or 0 if all zero.
  final int busiestSpendingDayIndex;

  /// Descending by amount, category → sum for the week.
  final List<({String category, double amount})> categoryBreakdownSorted;
  final double topCategoryShare;
  final CategoryShiftInsight? categoryShift;
  final double biggestExpenseShare;

  /// Expenses with amount under [smallPurchaseThresholdUsed].
  final double smallPurchaseTotal;
  final int smallPurchaseCount;
  final double smallPurchaseThresholdUsed;

  /// Sum of expenses in the calendar month of [weekStart] from day 1 through [weekEnd] (inclusive of local days in range).
  final double monthSpentInCalendarMonth;

  /// Number of local days in that month spanned for the month-to-date amount (>=1 when projection is valid).
  final int monthProjectionDaysUsed;
  final int monthDaysInMonth;
  final double? monthlyProjectedSpent;
  final WeeklyReviewPatternType reviewPattern;
  final WeeklyReviewNextMove nextMove;

  bool get hasActivity => logs.isNotEmpty;
}
