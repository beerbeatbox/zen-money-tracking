import 'dart:async';

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:baht/core/services/notification_service.dart';
import 'package:baht/features/settings/domain/usecases/settings_service.dart';

part 'expense_reminder_controller.g.dart';

@Riverpod(keepAlive: true)
class ExpenseReminderController extends _$ExpenseReminderController {
  final _notificationService = NotificationService();

  @override
  FutureOr<List<TimeOfDay>> build() async {
    final service = ref.watch(settingsServiceProvider);
    return service.getExpenseReminders();
  }

  Future<void> addReminder(TimeOfDay time) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(settingsServiceProvider);
      final currentReminders = await service.getExpenseReminders();

      // Check if reminder already exists
      if (currentReminders.any(
        (t) => t.hour == time.hour && t.minute == time.minute,
      )) {
        return currentReminders;
      }

      // Add new reminder
      final updatedReminders = [...currentReminders, time];
      await service.setExpenseReminders(updatedReminders);

      // Schedule notification
      await _notificationService.scheduleDailyReminder(time);

      return updatedReminders;
    });
  }

  Future<void> removeReminder(TimeOfDay time) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(settingsServiceProvider);
      final currentReminders = await service.getExpenseReminders();

      // Remove reminder
      final updatedReminders = currentReminders
          .where((t) => !(t.hour == time.hour && t.minute == time.minute))
          .toList();
      await service.setExpenseReminders(updatedReminders);

      // Cancel notification
      await _notificationService.cancelReminder(time);

      return updatedReminders;
    });
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final service = ref.read(settingsServiceProvider);
      return service.getExpenseReminders();
    });
  }
}
