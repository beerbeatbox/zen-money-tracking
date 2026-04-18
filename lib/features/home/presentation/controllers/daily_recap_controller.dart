import 'package:anti/features/home/domain/entities/daily_recap_data.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'daily_recap_controller.g.dart';

/// Normalizes to local calendar date (year-month-day only).
DateTime normalizeToLocalDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

@riverpod
class DailyRecapController extends _$DailyRecapController {
  @override
  FutureOr<DailyRecapData> build(DateTime date) async {
    final day = normalizeToLocalDate(date);
    ref.watch(expenseLogsProvider);
    final allLogs = await ref.read(expenseLogsProvider.future);
    final dayLogs = [...filterLogsByDay(allLogs, day)]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final expenses = dayLogs.where((l) => l.amount < 0).toList();
    final incomeLogs = dayLogs.where((l) => l.amount >= 0).toList();

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

    return DailyRecapData(
      date: day,
      totalSpent: totalSpent,
      totalIncome: totalIncome,
      topCategory: topCategory,
      topCategoryAmount: topCategoryAmount,
      transactionCount: dayLogs.length,
      biggestExpense: biggestExpense,
      logs: dayLogs,
    );
  }
}

/// Sync summary for Insight cards without async churn (uses same rules as [DailyRecapController]).
@immutable
class DailyRecapDaySummary {
  const DailyRecapDaySummary({
    required this.date,
    required this.totalSpent,
    required this.transactionCount,
  });

  final DateTime date;
  final double totalSpent;
  final int transactionCount;
}

List<DailyRecapDaySummary> summarizeLastDaysWithActivity(
  List<ExpenseLog> allLogs,
  int dayCount,
) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final summaries = <DailyRecapDaySummary>[];

  for (var i = 0; i < dayCount; i++) {
    final day = today.subtract(Duration(days: i));
    final logs = filterLogsByDay(allLogs, day);
    if (logs.isEmpty) continue;

    final expenses = logs.where((l) => l.amount < 0);
    final totalSpent = expenses.fold<double>(
      0,
      (sum, l) => sum + l.amount.abs(),
    );
    summaries.add(
      DailyRecapDaySummary(
        date: day,
        totalSpent: totalSpent,
        transactionCount: logs.length,
      ),
    );
  }
  return summaries;
}
