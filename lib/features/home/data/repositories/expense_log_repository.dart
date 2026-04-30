import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:baht/features/home/data/datasources/expense_log_local_datasource.dart';
import 'package:baht/features/home/data/models/expense_log_model.dart';
import 'package:baht/features/home/domain/entities/expense_log.dart';

part 'expense_log_repository.g.dart';

class ExpenseLogRepository {
  final ExpenseLogLocalDatasource _datasource;

  const ExpenseLogRepository(this._datasource);

  Future<List<ExpenseLog>> getExpenseLogs() async {
    final models = await _datasource.readAll();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> addExpenseLog(ExpenseLog log) async {
    final model = ExpenseLogModel.fromEntity(log);
    await _datasource.append(model);
  }

  Future<void> setExpenseLogs(List<ExpenseLog> logs) async {
    final models = logs.map(ExpenseLogModel.fromEntity).toList();
    await _datasource.overwrite(models);
  }

  Future<void> deleteExpenseLogFile() => _datasource.deleteFile();
}

@riverpod
ExpenseLogRepository expenseLogRepository(Ref ref) {
  final datasource = ref.watch(expenseLogLocalDatasourceProvider);
  return ExpenseLogRepository(datasource);
}
