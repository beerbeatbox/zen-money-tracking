import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/usecases/expense_log_service.dart';

part 'expense_logs_controller.g.dart';

@riverpod
Future<List<ExpenseLog>> expenseLogs(Ref ref) async {
  final service = ref.watch(expenseLogServiceProvider);
  return service.getExpenseLogs();
}
