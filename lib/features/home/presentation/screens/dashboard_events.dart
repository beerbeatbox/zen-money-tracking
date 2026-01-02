import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin DashboardEvents {
  AsyncValue<List<ExpenseLog>> watchExpenseLogs(WidgetRef ref) => ref
      .watch(expenseLogsProvider)
      .whenData(
        (logs) => [...logs]..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
      );

  void refreshExpenseLogs(WidgetRef ref) => ref.invalidate(expenseLogsProvider);

  String dashboardDateLabel(DateTime now) => formatDateLabel(now);

  double calculateNetBalance(List<ExpenseLog> logs) =>
      logs.fold<double>(0, (total, log) => total + log.amount);

  double calculateBalanceWithCarry({
    required List<ExpenseLog> allLogs,
    required DateTime selectedMonth,
    required bool carryEnabled,
  }) {
    final currentLogs = filterLogsByMonth(allLogs, selectedMonth);
    final currentBalance = calculateNetBalance(currentLogs);

    if (!carryEnabled) return currentBalance;

    final previousMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    if (!_isMonthEnded(previousMonth, DateTime.now())) return currentBalance;

    final previousLogs = filterLogsByMonth(allLogs, previousMonth);
    final carryBalance = calculateNetBalance(previousLogs);
    return currentBalance + carryBalance;
  }

  double calculateProjectedBalance({
    required double balanceWithCarry,
    required DateTime selectedMonth,
    required List<ScheduledTransaction> scheduledTransactions,
  }) {
    final from = DateTime(selectedMonth.year, selectedMonth.month);
    final scheduledSum = scheduledTransactions
        .where((t) => !t.scheduledDate.isBefore(from))
        .fold<double>(0, (sum, t) => sum + t.amount);
    return balanceWithCarry + scheduledSum;
  }

  double calculateIncome(List<ExpenseLog> logs) => logs
      .where((log) => log.amount > 0)
      .fold<double>(0, (total, log) => total + log.amount);

  double calculateSpent(List<ExpenseLog> logs) => logs
      .where((log) => log.amount < 0)
      .fold<double>(0, (total, log) => total + log.amount);

  String logsCountLabel(int count) => '$count Items';
}

bool _isMonthEnded(DateTime month, DateTime now) {
  // Last day of month: using day 0 of next month trick.
  final lastDay = DateTime(month.year, month.month + 1, 0);
  final today = DateUtils.dateOnly(now);
  final monthEnd = DateUtils.dateOnly(lastDay);
  return today.isAfter(monthEnd) || today.isAtSameMomentAs(monthEnd);
}
