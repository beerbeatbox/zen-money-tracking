import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
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
    required this.scheduleReminders,
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
  final List<ScheduledTransaction> scheduleReminders;
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
    final scheduleReminders = _buildScheduleReminders(
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
      selectedMonth: selectedMonth,
      scheduledTransactions: scheduledTransactions,
    );

    final from = DateTime(selectedMonth.year, selectedMonth.month);
    final showProjected = scheduledTransactions.any(
      (t) => !t.scheduledDate.isBefore(from),
    );

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
      scheduleReminders: scheduleReminders,
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
  required DateTime selectedMonth,
  required List<ScheduledTransaction> scheduledTransactions,
}) {
  final from = DateTime(selectedMonth.year, selectedMonth.month);
  final scheduledSum = scheduledTransactions
      .where((t) => !t.scheduledDate.isBefore(from))
      .fold<double>(0.0, (sum, t) => sum + t.amount);
  return balanceWithCarry + scheduledSum;
}

String _logsCountLabel(int count) => '$count Items';

List<ScheduledTransaction> _buildScheduleReminders({
  required DateTime selectedMonth,
  required List<ScheduledTransaction> scheduledTransactions,
}) {
  final now = DateTime.now();
  final startOfMonth = DateTime(selectedMonth.year, selectedMonth.month);
  final endOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0);

  final reminders =
      scheduledTransactions.where((t) {
        final dateOnly = DateUtils.dateOnly(t.scheduledDate);
        final isOverdueOrDue = !t.scheduledDate.isAfter(now);

        final isInSelectedMonth =
            !dateOnly.isBefore(startOfMonth) && !dateOnly.isAfter(endOfMonth);
        final isOverdueCarry =
            isOverdueOrDue && dateOnly.isBefore(startOfMonth);

        final remindWindowDays =
            t.remindDaysBefore > 0 ? t.remindDaysBefore : 7;
        final daysUntil =
            DateUtils.dateOnly(
              t.scheduledDate,
            ).difference(DateUtils.dateOnly(now)).inDays;
        final isDueSoon = daysUntil > 0 && daysUntil <= remindWindowDays;

        return (isInSelectedMonth && (isOverdueOrDue || isDueSoon)) ||
            isOverdueCarry;
      }).toList();

  int urgencyRank(ScheduledTransaction t) {
    final dateOnly = DateUtils.dateOnly(t.scheduledDate);
    final today = DateUtils.dateOnly(now);
    if (!t.scheduledDate.isAfter(now) && dateOnly.isBefore(today))
      return 0; // overdue
    if (dateOnly == today) return 1; // due today
    return 2; // due soon
  }

  reminders.sort((a, b) {
    final byRank = urgencyRank(a).compareTo(urgencyRank(b));
    if (byRank != 0) return byRank;
    return a.scheduledDate.compareTo(b.scheduledDate);
  });

  return reminders;
}
