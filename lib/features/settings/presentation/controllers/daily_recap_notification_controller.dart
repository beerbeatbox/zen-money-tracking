import 'dart:async';

import 'package:anti/core/services/notification_service.dart';
import 'package:anti/features/settings/domain/usecases/settings_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'daily_recap_notification_controller.g.dart';

@Riverpod(keepAlive: true)
class DailyRecapNotificationController extends _$DailyRecapNotificationController {
  final _notificationService = NotificationService();

  @override
  FutureOr<bool> build() async {
    final service = ref.watch(settingsServiceProvider);
    return service.getDailyRecapNotificationEnabled();
  }

  Future<void> setEnabled(bool enabled) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(settingsServiceProvider);
      await service.setDailyRecapNotificationEnabled(enabled);
      if (enabled) {
        await _notificationService.scheduleDailyRecapNotification();
      } else {
        await _notificationService.cancelDailyRecapNotification();
      }
      return enabled;
    });
  }
}
