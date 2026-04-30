import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:baht/core/services/notification_service.dart';
import 'package:baht/features/home/domain/usecases/scheduled_transaction_service.dart';
import 'package:baht/features/settings/domain/usecases/settings_service.dart';

part 'notification_settings_controller.g.dart';

@Riverpod(keepAlive: true)
class NotificationSettingsController extends _$NotificationSettingsController {
  final _notificationService = NotificationService();

  @override
  FutureOr<bool> build() async {
    final service = ref.watch(settingsServiceProvider);
    return service.getScheduledNotificationsEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(settingsServiceProvider);
      await service.setScheduledNotificationsEnabled(enabled);

      if (enabled) {
        // Schedule notifications for all due scheduled transactions
        final scheduledService = ref.read(scheduledTransactionServiceProvider);
        final scheduledTransactions = await scheduledService.getScheduledTransactions();
        await _notificationService.rescheduleAllScheduledTransactionNotifications(
          scheduledTransactions,
        );
      } else {
        // Cancel all scheduled transaction notifications
        final scheduledService = ref.read(scheduledTransactionServiceProvider);
        final scheduledTransactions = await scheduledService.getScheduledTransactions();
        for (final scheduled in scheduledTransactions) {
          await _notificationService.cancelScheduledTransactionNotification(scheduled.id);
        }
      }

      return enabled;
    });
  }
}
