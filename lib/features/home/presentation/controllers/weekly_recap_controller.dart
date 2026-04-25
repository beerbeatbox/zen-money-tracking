import 'package:anti/features/home/domain/entities/weekly_recap_data.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
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
    final incomeLogs = weekLogs.where((l) => l.amount >= 0).toList();

    final totalSpent = expenses.fold<double>(
      0,
      (sum, l) => sum + l.amount.abs(),
    );
    final totalIncome = incomeLogs.fold<double>(
      0,
      (sum, l) => sum + l.amount,
    );

    final byCategory = <String, double>{};
    for (final l in expenses) {
      byCategory[l.category] =
          (byCategory[l.category] ?? 0) + l.amount.abs();
    }
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

    return WeeklyRecapData(
      weekStart: weekStart,
      weekEnd: weekEnd,
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      transactionCount: weekLogs.length,
      biggestExpense: biggestExpense,
      logs: weekLogs,
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
