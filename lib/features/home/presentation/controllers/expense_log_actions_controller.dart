import 'dart:async';

import 'package:baht/features/home/domain/entities/expense_log.dart';
import 'package:baht/features/home/domain/usecases/expense_log_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'expense_log_actions_controller.g.dart';

@Riverpod(keepAlive: true)
Future<List<ExpenseLog>> expenseLogs(Ref ref) async {
  final service = ref.watch(expenseLogServiceProvider);
  final logs = await service.getExpenseLogs();
  // Sync widget asynchronously to avoid circular dependency with dashboard controller
  _syncTodaySpendingWithWidget(ref, logs).catchError((_) {
    // Ignore errors in widget sync - it's non-critical
  });
  return logs;
}

@Riverpod(keepAlive: true)
class ExpenseLogActionsController extends _$ExpenseLogActionsController {
  @override
  FutureOr<void> build() {}

  Future<void> addExpenseLog(ExpenseLog log) async {
    final service = ref.read(expenseLogServiceProvider);
    await service.addExpenseLog(log);

    if (!ref.mounted) return;
    ref.invalidate(expenseLogsProvider);
    await ref.read(expenseLogsProvider.future);
  }

  Future<void> deleteExpenseLog(String logId) async {
    final service = ref.read(expenseLogServiceProvider);
    await service.deleteExpenseLog(logId);

    if (!ref.mounted) return;
    ref.invalidate(expenseLogsProvider);
    await ref.read(expenseLogsProvider.future);
  }

  Future<void> updateExpenseLog(ExpenseLog updatedLog) async {
    final service = ref.read(expenseLogServiceProvider);
    await service.updateExpenseLog(updatedLog);

    if (!ref.mounted) return;
    ref.invalidate(expenseLogsProvider);
    await ref.read(expenseLogsProvider.future);
  }

  Future<void> deleteExpenseLogs() async {
    final service = ref.read(expenseLogServiceProvider);
    await service.deleteExpenseLogFile();

    if (!ref.mounted) return;
    ref.invalidate(expenseLogsProvider);
    await ref.read(expenseLogsProvider.future);
  }
}

@riverpod
Future<void> deleteAllExpenseLogs(Ref ref) async {
  final controller = ref.read(expenseLogActionsControllerProvider.notifier);
  await controller.deleteExpenseLogs();
}

@riverpod
Future<void> addExpenseLogAction(Ref ref, ExpenseLog log) async {
  final controller = ref.read(expenseLogActionsControllerProvider.notifier);
  await controller.addExpenseLog(log);
}

@riverpod
Future<void> deleteExpenseLogAction(Ref ref, String logId) async {
  final controller = ref.read(expenseLogActionsControllerProvider.notifier);
  await controller.deleteExpenseLog(logId);
}

@riverpod
Future<void> updateExpenseLogAction(Ref ref, ExpenseLog log) async {
  final controller = ref.read(expenseLogActionsControllerProvider.notifier);
  await controller.updateExpenseLog(log);
}

const _widgetChannel = MethodChannel('com.dopaminelab.thumby/widget');

Future<void> _syncTodaySpendingWithWidget(Ref ref, List<ExpenseLog> logs) async {
  if (!_isRunningOnIOS()) return;

  final now = DateTime.now();
  final spentToday =
      logs
          .where(
            (log) =>
                log.amount < 0 &&
                _isSameDay(log.createdAt.toLocal(), now.toLocal()),
          )
          .fold<double>(0, (total, log) => total + log.amount)
          .abs();

  try {
    await _widgetChannel.invokeMethod<void>(
      'updateTodaySpending',
      <String, dynamic>{'amount': spentToday},
    );
  } on PlatformException {
    // Widget bridge not available (e.g., running on non-iOS simulator target).
  } on MissingPluginException {
    // Widget bridge not available (e.g., running on non-iOS simulator target).
  }
}

/// Syncs budget data to iOS widget. Can be called from dashboard screen
/// after budget is calculated to avoid circular dependency.
Future<void> syncBudgetToWidget(double? todayBudgetRemaining) async {
  if (!_isRunningOnIOS()) return;
  if (todayBudgetRemaining == null) return;

  try {
    await _widgetChannel.invokeMethod<void>(
      'updateTodaySpending',
      <String, dynamic>{'budgetRemaining': todayBudgetRemaining},
    );
  } on PlatformException {
    // Widget bridge not available (e.g., running on non-iOS simulator target).
  } on MissingPluginException {
    // Widget bridge not available (e.g., running on non-iOS simulator target).
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isRunningOnIOS() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
