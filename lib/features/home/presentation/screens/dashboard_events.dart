import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_logs_controller.dart';

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

  double calculateIncome(List<ExpenseLog> logs) => logs
      .where((log) => log.amount > 0)
      .fold<double>(0, (total, log) => total + log.amount);

  double calculateSpent(List<ExpenseLog> logs) => logs
      .where((log) => log.amount < 0)
      .fold<double>(0, (total, log) => total + log.amount);

  String logsCountLabel(int count) => '$count ITEMS';
}
