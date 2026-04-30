import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:baht/features/home/presentation/controllers/balance_snapshot_controller.dart';
import 'package:baht/features/home/presentation/controllers/expense_log_actions_controller.dart';

mixin SettingsEvents {
  Future<void> deleteAllData(WidgetRef ref) async {
    await Future.wait([
      ref.read(deleteAllBalanceSnapshotsProvider.future),
      ref.read(deleteAllExpenseLogsProvider.future),
    ]);
  }
}
