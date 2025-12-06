import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/controllers/expense_logs_controller.dart';

mixin ExpenseLogDetailEvents {
  Future<void> deleteLog(WidgetRef ref, String logId) async {
    await ref.read(deleteExpenseLogProvider(logId).future);
    ref.invalidate(expenseLogsProvider);
    await ref.read(expenseLogsProvider.future);
  }
}
