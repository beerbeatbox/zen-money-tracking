import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/usecases/expense_log_service.dart';

part 'expense_log_actions_controller.g.dart';

@Riverpod(keepAlive: true)
Future<List<ExpenseLog>> expenseLogs(Ref ref) async {
  final service = ref.watch(expenseLogServiceProvider);
  return service.getExpenseLogs();
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
