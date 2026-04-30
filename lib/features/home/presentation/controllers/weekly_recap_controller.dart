import 'package:baht/features/home/domain/entities/expense_log.dart';
import 'package:baht/features/home/domain/entities/weekly_recap_data.dart';
import 'package:baht/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:baht/features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
import 'package:baht/features/home/presentation/utils/weekly_review_aggregation.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'weekly_recap_controller.g.dart';

/// Normalizes to local calendar date (year-month-day only).
DateTime normalizeToLocalDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

@riverpod
class WeeklyRecapController extends _$WeeklyRecapController {
  @override
  FutureOr<WeeklyRecapData> build(DateTime date) async {
    final weekStart = startOfLocalWeekMonday(normalizeToLocalDate(date));
    final weekEnd = endOfLocalWeekSunday(weekStart);
    ref.watch(expenseLogsProvider);
    final allLogs = await ref.read(expenseLogsProvider.future);
    final weekLogs = [...filterLogsInLocalWeek(allLogs, weekStart)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final expenses = weekLogs.where((l) => l.amount < 0).toList();
    final incomeLogs = weekLogs.where((l) => l.amount > 0).toList();

    final totalSpent = expenses.fold<double>(
      0,
      (sum, l) => sum + l.amount.abs(),
    );
    final totalIncome = incomeLogs.fold<double>(
      0,
      (sum, l) => sum + l.amount,
    );

    final byCategory = categoryAmounts(expenses);
    String? topCategory;
    var topCategoryAmount = 0.0;
    for (final e in byCategory.entries) {
      if (e.value > topCategoryAmount) {
        topCategoryAmount = e.value;
        topCategory = e.key;
      }
    }

    ExpenseLog? biggestExpense;
    for (final l in expenses) {
      if (biggestExpense == null ||
          l.amount.abs() > biggestExpense.amount.abs()) {
        biggestExpense = l;
      }
    }

    final previousMonday = weekStart.subtract(const Duration(days: 7));
    final previousWeekTotalSpent = totalSpentInWeek(allLogs, previousMonday);

    final fourPriorMondays = <DateTime>[
      for (var i = 1; i <= 4; i++) weekStart.subtract(Duration(days: 7 * i)),
    ];
    var baselineSum = 0.0;
    for (final m in fourPriorMondays) {
      baselineSum += totalSpentInWeek(allLogs, m);
    }
    final baselineAverageSpent = baselineSum / 4.0;
    const hasBaselineForAverage = true;

    final spentChangeVsPreviousAmount = totalSpent - previousWeekTotalSpent;
    final spentChangeVsPreviousPercent =
        previousWeekTotalSpent > 0
            ? (spentChangeVsPreviousAmount / previousWeekTotalSpent) * 100.0
            : null;

    final dailySpendingTotals = dailyExpenseTotalsForWeek(
      expenses,
      weekStart,
    );
    final dailyCategorySpending = computeDailyCategorySpending(
      expenses,
      weekStart,
    );
    final busiestSpendingDayIndex = busiestDayIndex(dailySpendingTotals);
    final categoryBreakdownSorted = sortedCategoryList(byCategory);
    final topCategoryShare =
        totalSpent > 0 ? topCategoryAmount / totalSpent : 0.0;
    final biggestExpenseShare =
        (biggestExpense != null && totalSpent > 0)
            ? biggestExpense.amount.abs() / totalSpent
            : 0.0;

    final smallPurchaseThresholdUsed = smallPurchaseThreshold(totalSpent);
    final sm = smallPurchases(expenses, smallPurchaseThresholdUsed);
    final categoryShift = computeCategoryShift(
      allLogs,
      weekStart,
      byCategory,
    );

    final monthInfo = monthSpentToDateForWeek(
      allLogs,
      weekStart,
      weekEnd,
    );
    final monthlyProjected = projectMonthEndFromPace(
      monthInfo.monthToDate,
      monthInfo.daysUsed,
      monthInfo.daysInMonth,
    );

    final pattern = detectPattern(
      totalSpent: totalSpent,
      daily: dailySpendingTotals,
      expenseCount: expenses.length,
      smallPurchaseCount: sm.count,
      biggestShare: biggestExpenseShare,
      pctVsPrevious: spentChangeVsPreviousPercent,
      topCategory: topCategory,
    );

    final nextMove = computeNextMove(
      totalSpent: totalSpent,
      shift: categoryShift,
      pattern: pattern,
      monthlyProjected: monthlyProjected,
      spentChangePercent: spentChangeVsPreviousPercent,
      smallPurchaseTotal: sm.total,
      smallPurchaseCount: sm.count,
    );

    return WeeklyRecapData(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      transactionCount: weekLogs.length,
      expenseCount: expenses.length,
      incomeCount: incomeLogs.length,
      biggestExpense: biggestExpense,
      logs: weekLogs,
      previousWeekTotalSpent: previousWeekTotalSpent,
      baselineAverageSpent: baselineAverageSpent,
      hasBaselineForAverage: hasBaselineForAverage,
      spentChangeVsPreviousAmount: spentChangeVsPreviousAmount,
      spentChangeVsPreviousPercent: spentChangeVsPreviousPercent,
      dailySpendingTotals: dailySpendingTotals,
      dailyCategorySpending: dailyCategorySpending,
      busiestSpendingDayIndex: busiestSpendingDayIndex,
      categoryBreakdownSorted: categoryBreakdownSorted,
      topCategoryShare: topCategoryShare,
      categoryShift: categoryShift,
      biggestExpenseShare: biggestExpenseShare,
      smallPurchaseTotal: sm.total,
      smallPurchaseCount: sm.count,
      smallPurchaseThresholdUsed: smallPurchaseThresholdUsed,
      monthSpentInCalendarMonth: monthInfo.monthToDate,
      monthProjectionDaysUsed: monthInfo.daysUsed,
      monthDaysInMonth: monthInfo.daysInMonth,
      monthlyProjectedSpent: monthlyProjected,
      reviewPattern: pattern,
      nextMove: nextMove,
    );
  }
}

/// Sync summary for Insight cards without async churn (uses same rules as [WeeklyRecapController]).
@immutable
class WeeklyRecapWeekSummary {
  const WeeklyRecapWeekSummary({
    required this.weekStart,
    required this.totalSpent,
    required this.transactionCount,
  });

  final DateTime weekStart;
  final double totalSpent;
  final int transactionCount;
}

List<WeeklyRecapWeekSummary> summarizeLastWeeksWithActivity(
  List<ExpenseLog> allLogs,
  int maxWeeks,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final thisMonday = startOfLocalWeekMonday(today);
  final summaries = <WeeklyRecapWeekSummary>[];

  for (var w = 0; w < maxWeeks; w++) {
    final weekStart = thisMonday.subtract(Duration(days: 7 * w));
    final logs = filterLogsInLocalWeek(allLogs, weekStart);
    if (logs.isEmpty) continue;

    final expenses = logs.where((l) => l.amount < 0);
    final totalSpent = expenses.fold<double>(
      0,
      (sum, l) => sum + l.amount.abs(),
    );
    summaries.add(
      WeeklyRecapWeekSummary(
        weekStart: weekStart,
        totalSpent: totalSpent,
        transactionCount: logs.length,
      ),
    );
  }
  return summaries;
}
