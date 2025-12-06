import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti/features/home/domain/usecases/expense_log_service.dart';
import 'package:anti/features/home/presentation/controllers/expense_logs_controller.dart';

final deleteExpenseLogsProvider = FutureProvider<void>((ref) async {
  final service = ref.read(expenseLogServiceProvider);
  await service.deleteExpenseLogFile();
  ref.invalidate(expenseLogsProvider);
  await ref.read(expenseLogsProvider.future);
});

