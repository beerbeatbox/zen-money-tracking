import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/domain/usecases/expense_log_service.dart';

part 'expense_log_actions_controller.g.dart';

@riverpod
Future<void> deleteExpenseLog(Ref ref, String logId) async {
  final service = ref.read(expenseLogServiceProvider);
  await service.deleteExpenseLog(logId);
}

@riverpod
Future<void> deleteExpenseLogs(Ref ref) async {
  final service = ref.read(expenseLogServiceProvider);
  await service.deleteExpenseLogFile();
}
