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
}

@riverpod
ExpenseLogService expenseLogService(Ref ref) {
  final repository = ref.watch(expenseLogRepositoryProvider);
  return ExpenseLogService(repository);
}
