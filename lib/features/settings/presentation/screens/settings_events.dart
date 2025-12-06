import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';

mixin SettingsEvents {
  Future<void> deleteAllData(WidgetRef ref) =>
      ref.read(deleteExpenseLogsProvider.future);
}
