import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/data/repositories/expense_log_repository.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';

part 'expense_log_service.g.dart';

class ExpenseLogService {
  const ExpenseLogService(this._repository);

  final ExpenseLogRepository _repository;

  Future<List<ExpenseLog>> getExpenseLogs() => _repository.getExpenseLogs();

  Future<void> addExpenseLog(ExpenseLog log) => _repository.addExpenseLog(log);

  Future<void> setExpenseLogs(List<ExpenseLog> logs) =>
      _repository.setExpenseLogs(logs);

  Future<void> deleteExpenseLog(String id) async {
    final logs = await getExpenseLogs();
    final updatedLogs = logs.where((log) => log.id != id).toList();
    if (updatedLogs.length == logs.length) return;
    await setExpenseLogs(updatedLogs);
  }

  Future<void> deleteExpenseLogFile() => _repository.deleteExpenseLogFile();
}

@riverpod
ExpenseLogService expenseLogService(Ref ref) {
  final repository = ref.watch(expenseLogRepositoryProvider);
  return ExpenseLogService(repository);
}
