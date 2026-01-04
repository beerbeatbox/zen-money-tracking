import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/domain/utils/recurrence.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
import 'package:anti/features/settings/presentation/controllers/carry_balance_setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class DashboardMonthVm {
  const DashboardMonthVm({
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
}

/// Derived dashboard values for the given month.
///
/// Loading/error states are driven solely by `expenseLogsProvider` (same as the
/// previous implementation in `DashboardScreen`). Scheduled transactions and
/// carry-balance setting are treated as optional values while loading.
final dashboardMonthVmProvider = Provider.family<
  AsyncValue<DashboardMonthVm>,
  DateTime
>((ref, selectedMonth) {
  final logsAsync = ref.watch(expenseLogsProvider).whenData((logs) {
    return [...logs]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  });

  final scheduledAsync = ref.watch(scheduledTransactionsProvider);
  final carryAsync = ref.watch(carryBalanceSettingControllerProvider);
  final scheduledTransactions =
      scheduledAsync.value ?? const <ScheduledTransaction>[];
  final carryEnabled = carryAsync.value ?? false;

  return logsAsync.whenData((allLogs) {
    final monthYearLabel = formatMonthYearLabel(selectedMonth);

    final scopedLogs = filterLogsByMonth(allLogs, selectedMonth);
    final scheduledThisMonth = _scheduledInMonth(
      selectedMonth: selectedMonth,
      scheduledTransactions: scheduledTransactions,
    );

    final previousMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final previousLogs = filterLogsByMonth(allLogs, previousMonth);

    final canCarry =
        !DateTime(
          previousMonth.year,
          previousMonth.month + 1,
          0,
        ).isAfter(DateUtils.dateOnly(DateTime.now()));

    final carryBalance =
        (carryEnabled && canCarry) ? _calculateNetBalance(previousLogs) : 0.0;

    final netBalance = _calculateNetBalance(scopedLogs) + carryBalance;
    final income = _calculateIncome(scopedLogs);
    final spent = _calculateSpent(scopedLogs);
    final itemsLabel = _logsCountLabel(scopedLogs.length);

    final projectedBalance = _calculateProjectedBalance(
      balanceWithCarry: netBalance,
      scheduledThisMonth: scheduledThisMonth,
    );

    final showProjected = scheduledThisMonth.isNotEmpty;

    return DashboardMonthVm(
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
    );
  });
});

double _calculateNetBalance(List<ExpenseLog> logs) =>
    logs.fold<double>(0.0, (total, log) => total + log.amount);

double _calculateIncome(List<ExpenseLog> logs) => logs
    .where((log) => log.amount > 0)
    .fold<double>(0.0, (total, log) => total + log.amount);

double _calculateSpent(List<ExpenseLog> logs) => logs
    .where((log) => log.amount < 0)
    .fold<double>(0.0, (total, log) => total + log.amount);

double _calculateProjectedBalance({
  required double balanceWithCarry,
  required List<ScheduledTransaction> scheduledThisMonth,
}) {
  final scheduledSum = scheduledThisMonth.fold<double>(
    0.0,
    (sum, t) => sum + t.amount,
  );
  return balanceWithCarry + scheduledSum;
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
