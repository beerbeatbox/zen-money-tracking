import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

mixin ExpenseLogDetailEvents {
  Future<void> deleteLog(WidgetRef ref, String logId) async {
    await ref.read(deleteExpenseLogActionProvider(logId).future);
  }

  Future<void> updateLog(WidgetRef ref, ExpenseLog updatedLog) async {
    await ref.read(updateExpenseLogActionProvider(updatedLog).future);
  }
}
