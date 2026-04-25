import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/domain/utils/dashboard_net_balance.dart';
import 'package:anti/features/home/domain/utils/recurrence.dart';
import 'package:anti/features/home/presentation/controllers/balance_snapshot_controller.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
import 'package:anti/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:anti/features/settings/presentation/controllers/budget_setting_controller.dart';
import 'package:anti/features/settings/presentation/controllers/carry_balance_setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_controller.g.dart';

enum DailyBudgetComparison { under, onTrack, over }

@immutable
class MonthEndSufficiencyBreakdown {
  const MonthEndSufficiencyBreakdown({
    required this.currentBalance,
    required this.averageDailySpending,
    required this.daysPassed,
    required this.daysRemaining,
    required this.remainingScheduledTotal,
    required this.dueNowScheduledTotal,
    required this.projectedDailySpending,
    required this.monthEndBalance,
    required this.isSufficient,
    required this.recommendedDailyBudget,
    required this.recommendedDailyBudgetWithBuffer,
    required this.currentVsRecommended,
  });

  final double currentBalance;
  final double averageDailySpending;
  final int daysPassed;
  final int daysRemaining;
  final double remainingScheduledTotal;
  final double dueNowScheduledTotal;
  final double projectedDailySpending;
  final double monthEndBalance;
  final bool isSufficient;
  final double recommendedDailyBudget;
  final double recommendedDailyBudgetWithBuffer;
  final DailyBudgetComparison currentVsRecommended;
}

@immutable
class DashboardMonth {
  const DashboardMonth({
    required this.selectedMonth,
    required this.monthYearLabel,
    required this.logs,
    required this.itemsLabel,
    required this.netBalance,
    required this.projectedBalance,
    required this.showProjected,
    required this.income,
    required this.spent,
    required this.scheduledThisMonth,
    required this.dueNow,
    required this.isSufficientUntilMonthEnd,
    this.monthEndBalance,
    this.sufficiencyBreakdown,
    this.todayBudgetRemaining,
    this.todaySpending,
  });

  final DateTime selectedMonth;
  final String monthYearLabel;
  final List<ExpenseLog> logs;
  final String itemsLabel;
  final double netBalance;
  final double projectedBalance;
  final bool showProjected;
  final double income;
  final double spent;
  final List<ScheduledTransaction> scheduledThisMonth;
  final List<ScheduledTransaction> dueNow;
  final bool isSufficientUntilMonthEnd;
  final double? monthEndBalance;
  final MonthEndSufficiencyBreakdown? sufficiencyBreakdown;
  final double? todayBudgetRemaining;
  final double? todaySpending;
}

/// Derived dashboard values for the given month.
///
/// Loading/error states are driven solely by `expenseLogsProvider` (same as the
/// previous implementation in `DashboardScreen`). Scheduled transactions and
/// carry-balance setting are treated as optional values while loading.
@riverpod
class DashboardController extends _$DashboardController {
  @override
  FutureOr<DashboardMonth> build(DateTime selectedMonth) async {
    ref.watch(expenseLogsProvider);
    ref.watch(balanceSnapshotListControllerProvider);
    final scheduledAsync = ref.watch(scheduledTransactionsProvider);
    final carryAsync = ref.watch(carryBalanceSettingControllerProvider);
    final budgetAsync = ref.watch(budgetSettingControllerProvider);

    final allLogs = await ref.read(expenseLogsProvider.future);
    final balanceSnapshots = await ref.read(
      balanceSnapshotListControllerProvider.future,
    );
    final latestSnapshot = pickLatestSnapshot(balanceSnapshots);
    final scheduledTransactions =
        scheduledAsync.value ?? const <ScheduledTransaction>[];
    final carryEnabled = carryAsync.value ?? false;
    final budgetSetting = budgetAsync.value;

    final sortedLogs = [...allLogs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final monthYearLabel = formatMonthYearLabel(selectedMonth);
    final scopedLogs = filterLogsByMonth(sortedLogs, selectedMonth);
    final scheduledThisMonth = _scheduledInMonth(
      selectedMonth: selectedMonth,
      scheduledTransactions: scheduledTransactions,
    );

    final previousMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final previousLogs = filterLogsByMonth(sortedLogs, previousMonth);

    final canCarry =
        !DateTime(
          previousMonth.year,
          previousMonth.month + 1,
          0,
        ).isAfter(DateUtils.dateOnly(DateTime.now()));

    final netBalance = dashboardNetBalance(
      latestSnapshot: latestSnapshot,
      allLogs: sortedLogs,
      scopedLogs: scopedLogs,
      previousMonthLogs: previousLogs,
      carryEnabled: carryEnabled,
      canCarry: canCarry,
    );
    final income = _calculateIncome(scopedLogs);
    final spent = _calculateSpent(scopedLogs);
    final itemsLabel = _logsCountLabel(scopedLogs.length);

    final projectedBalance = _calculateProjectedBalance(
      balanceWithCarry: netBalance,
      scheduledThisMonth: scheduledThisMonth,
    );

    final showProjected = scheduledThisMonth.isNotEmpty;

    final now = DateTime.now();
    final dueNow = _dueNowItems(
      scheduledTransactions: scheduledTransactions,
      now: now,
    );

    final sufficiencyBreakdown = _calculateMonthEndSufficiency(
      selectedMonth: selectedMonth,
      netBalance: netBalance,
      spent: spent,
      scheduledThisMonth: scheduledThisMonth,
      now: now,
    );

    final todaySpending = _calculateTodaySpending(scopedLogs, now);
    final todayBudgetRemaining = _calculateTodayBudgetRemaining(
      budgetSource: budgetSetting?.source ?? BudgetSource.autoConservative,
      customBudgetAmount: budgetSetting?.customAmount,
      recommendedDailyBudget: sufficiencyBreakdown?.recommendedDailyBudget,
      recommendedDailyBudgetWithBuffer:
          sufficiencyBreakdown?.recommendedDailyBudgetWithBuffer,
      todaySpending: todaySpending,
    );

    return DashboardMonth(
      selectedMonth: selectedMonth,
      monthYearLabel: monthYearLabel,
      logs: scopedLogs,
      itemsLabel: itemsLabel,
      netBalance: netBalance,
      projectedBalance: projectedBalance,
      showProjected: showProjected,
      income: income,
      spent: spent,
      scheduledThisMonth: scheduledThisMonth,
      dueNow: dueNow,
      isSufficientUntilMonthEnd: sufficiencyBreakdown?.isSufficient ?? false,
      monthEndBalance: sufficiencyBreakdown?.monthEndBalance,
      sufficiencyBreakdown: sufficiencyBreakdown,
      todayBudgetRemaining: todayBudgetRemaining,
      todaySpending: todaySpending,
    );
  }
}

double _calculateIncome(List<ExpenseLog> logs) => logs
    .where((log) => log.amount > 0)
    .fold<double>(0.0, (total, log) => total + log.amount);

double _calculateSpent(List<ExpenseLog> logs) => logs
    .where((log) => log.amount < 0)
    .fold<double>(0.0, (total, log) => total + log.amount);

double _calculateTodaySpending(List<ExpenseLog> logs, DateTime now) {
  final today = DateUtils.dateOnly(now);
  return logs
      .where((log) {
        final logDate = DateUtils.dateOnly(log.createdAt);
        return logDate.isAtSameMomentAs(today) && log.amount < 0;
      })
      .fold<double>(0.0, (total, log) => total + log.amount.abs());
}

double? _calculateTodayBudgetRemaining({
  required BudgetSource budgetSource,
  double? customBudgetAmount,
  double? recommendedDailyBudget,
  double? recommendedDailyBudgetWithBuffer,
  required double todaySpending,
}) {
  double? dailyBudget;

  switch (budgetSource) {
    case BudgetSource.custom:
      dailyBudget = customBudgetAmount;
      break;
    case BudgetSource.autoConservative:
      dailyBudget = recommendedDailyBudgetWithBuffer;
      break;
    case BudgetSource.autoExactly:
      dailyBudget = recommendedDailyBudget;
      break;
  }

  if (dailyBudget == null) {
    return null;
  }

  return dailyBudget - todaySpending;
}

double _calculateProjectedBalance({
  required double balanceWithCarry,
  required List<ScheduledTransaction> scheduledThisMonth,
}) {
  final scheduledSum = scheduledThisMonth.fold<double>(0.0, (sum, t) {
    // Use budgetAmount for dynamic scheduled transactions, amount for fixed
    // budgetAmount should be negated since it's an expense
    final amountToUse =
        t.isDynamicAmount ? -(t.budgetAmount ?? t.amount.abs()) : t.amount;
    return sum + amountToUse;
  });
  return scheduledSum;
}

String _logsCountLabel(int count) => '$count Items';

List<ScheduledTransaction> _scheduledInMonth({
  required DateTime selectedMonth,
  required List<ScheduledTransaction> scheduledTransactions,
}) {
  final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month);
  final endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

  final items = <ScheduledTransaction>[];

  for (final schedule in scheduledTransactions) {
    final occurrences = occurrencesInMonth(
      schedule: schedule,
      startOfMonth: startOfMonth,
      endOfMonth: endOfMonth,
    );

    for (final occurrenceDate in occurrences) {
      // Create a virtual scheduled transaction for this occurrence
      // Keep the original ID so edit/delete actions work correctly
      items.add(schedule.copyWith(scheduledDate: occurrenceDate));
    }
  }

  items.sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  return items;
}

List<ScheduledTransaction> _dueNowItems({
  required List<ScheduledTransaction> scheduledTransactions,
  required DateTime now,
}) {
  final today = DateUtils.dateOnly(now);
  final dueItems =
      scheduledTransactions.where((item) {
          if (!item.isActive) return false;
          final scheduledDay = DateUtils.dateOnly(item.scheduledDate);
          return scheduledDay.isBefore(today) ||
              scheduledDay.isAtSameMomentAs(today);
        }).toList()
        ..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
  return dueItems;
}

MonthEndSufficiencyBreakdown? _calculateMonthEndSufficiency({
  required DateTime selectedMonth,
  required double netBalance,
  required double spent,
  required List<ScheduledTransaction> scheduledThisMonth,
  required DateTime now,
}) {
  // Only calculate for current month
  final isCurrentMonth =
      selectedMonth.year == now.year && selectedMonth.month == now.month;
  if (!isCurrentMonth) {
    return null;
  }

  final today = DateUtils.dateOnly(now);
  final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month);
  final endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

  // Calculate days passed and remaining
  final daysPassed = today.difference(startOfMonth).inDays + 1;
  final daysRemaining = endOfMonth.difference(today).inDays + 1;

  // Calculate average daily spending
  final averageDailySpending = daysPassed > 0 ? spent.abs() / daysPassed : 0.0;

  // Calculate remaining scheduled transactions (not yet due)
  final remainingScheduled = scheduledThisMonth
      .where((t) {
        final scheduledDay = DateUtils.dateOnly(t.scheduledDate);
        return scheduledDay.isAfter(today);
      })
      .fold<double>(0.0, (sum, t) {
        // Use budgetAmount for dynamic scheduled transactions, amount for fixed
        // budgetAmount should be negated since it's an expense
        final amountToUse =
            t.isDynamicAmount ? -(t.budgetAmount ?? t.amount.abs()) : t.amount;
        return sum + amountToUse;
      });

  // Calculate due now scheduled transactions (due today or before, not yet paid)
  final dueNowScheduled = scheduledThisMonth
      .where((t) {
        final scheduledDay = DateUtils.dateOnly(t.scheduledDate);
        return scheduledDay.isBefore(today) ||
            scheduledDay.isAtSameMomentAs(today);
      })
      .fold<double>(0.0, (sum, t) {
        // Use budgetAmount for dynamic scheduled transactions, amount for fixed
        // budgetAmount should be negated since it's an expense
        final amountToUse =
            t.isDynamicAmount ? -(t.budgetAmount ?? t.amount.abs()) : t.amount;
        return sum + amountToUse;
      });

  // Calculate projected daily spending for remaining days
  final projectedDailySpending = averageDailySpending * daysRemaining;

  // Calculate month-end balance
  final monthEndBalance =
      netBalance +
      remainingScheduled +
      dueNowScheduled -
      projectedDailySpending;

  // Check if sufficient
  final isSufficient = monthEndBalance >= 0;

  // Calculate available balance after scheduled transactions
  final availableBalance = netBalance + remainingScheduled + dueNowScheduled;

  // Calculate recommended daily budget (balanced approach)
  final recommendedDailyBudget =
      daysRemaining > 0 ? availableBalance / daysRemaining : 0.0;

  // Conservative approach with 10% buffer
  final recommendedDailyBudgetWithBuffer = recommendedDailyBudget * 0.9;

  // Compare current average spending with recommended budget
  // Use ±10% tolerance for "on track"
  final tolerance = recommendedDailyBudget * 0.1;
  final DailyBudgetComparison currentVsRecommended;
  if (averageDailySpending < recommendedDailyBudget - tolerance) {
    currentVsRecommended = DailyBudgetComparison.under;
  } else if (averageDailySpending <= recommendedDailyBudget + tolerance) {
    currentVsRecommended = DailyBudgetComparison.onTrack;
  } else {
    currentVsRecommended = DailyBudgetComparison.over;
  }

  return MonthEndSufficiencyBreakdown(
    currentBalance: netBalance,
    averageDailySpending: averageDailySpending,
    daysPassed: daysPassed,
    daysRemaining: daysRemaining,
    remainingScheduledTotal: remainingScheduled,
    dueNowScheduledTotal: dueNowScheduled,
    projectedDailySpending: projectedDailySpending,
    monthEndBalance: monthEndBalance,
    isSufficient: isSufficient,
    recommendedDailyBudget: recommendedDailyBudget,
    recommendedDailyBudgetWithBuffer: recommendedDailyBudgetWithBuffer,
    currentVsRecommended: currentVsRecommended,
  );
}
