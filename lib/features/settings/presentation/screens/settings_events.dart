import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';

mixin SettingsEvents {
  Future<void> deleteAllData(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(deleteExpenseLogsProvider.future);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('All data cleared. Ready for a fresh start.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Could not clear data. Please try again.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

