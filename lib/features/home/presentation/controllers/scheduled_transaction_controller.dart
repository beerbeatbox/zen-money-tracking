import 'dart:async';

import 'package:anti/core/services/notification_service.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/domain/usecases/expense_log_service.dart';
import 'package:anti/features/home/domain/usecases/scheduled_transaction_service.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/settings/domain/usecases/settings_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scheduled_transaction_controller.g.dart';

@Riverpod(keepAlive: true)
Future<List<ScheduledTransaction>> scheduledTransactions(Ref ref) async {
  final service = ref.watch(scheduledTransactionServiceProvider);
  final items = await service.getScheduledTransactions();
  return [...items]..sort((a, b) => a.scheduledDate.compareTo(b.scheduledDate));
}

@Riverpod(keepAlive: true)
class ScheduledTransactionController extends _$ScheduledTransactionController {
  final _notificationService = NotificationService();

  @override
  FutureOr<void> build() {}

  Future<void> _handleNotificationForTransaction(
    ScheduledTransaction item,
    bool shouldSchedule,
  ) async {
    final settingsService = ref.read(settingsServiceProvider);
    final notificationsEnabled =
        await settingsService.getScheduledNotificationsEnabled();

    if (!notificationsEnabled) return;

    if (shouldSchedule) {
      await _notificationService.scheduleScheduledTransactionNotification(item);
    } else {
      await _notificationService.cancelScheduledTransactionNotification(item.id);
    }
  }

  Future<void> add(ScheduledTransaction item) async {
    final service = ref.read(scheduledTransactionServiceProvider);
    await service.addScheduledTransaction(item);

    // Schedule notification if enabled and transaction is due
    await _handleNotificationForTransaction(item, true);

    if (!ref.mounted) return;
    ref.invalidate(scheduledTransactionsProvider);
    await ref.read(scheduledTransactionsProvider.future);
  }

  Future<void> updateItem(ScheduledTransaction item) async {
    final service = ref.read(scheduledTransactionServiceProvider);
    await service.updateScheduledTransaction(item);

    // Reschedule notification if enabled and transaction is due
    await _handleNotificationForTransaction(item, true);

    if (!ref.mounted) return;
    ref.invalidate(scheduledTransactionsProvider);
    await ref.read(scheduledTransactionsProvider.future);
  }

  Future<void> delete(String id) async {
    final service = ref.read(scheduledTransactionServiceProvider);
    await service.deleteScheduledTransaction(id);

    // Cancel notification for deleted transaction
    await _notificationService.cancelScheduledTransactionNotification(id);

    if (!ref.mounted) return;
    ref.invalidate(scheduledTransactionsProvider);
    await ref.read(scheduledTransactionsProvider.future);
  }

  Future<void> convertToLog(
    ScheduledTransaction item, {
    double? actualAmount,
  }) async {
    final scheduledService = ref.read(scheduledTransactionServiceProvider);
    final expenseLogService = ref.read(expenseLogServiceProvider);
    await scheduledService.convertToExpenseLog(
      scheduled: item,
      expenseLogService: expenseLogService,
      actualAmount: actualAmount,
    );

    // Cancel notification for this transaction (it's been marked as paid)
    // If recurring, the next occurrence will be scheduled when it becomes due
    await _notificationService.cancelScheduledTransactionNotification(item.id);

    if (!ref.mounted) return;
    ref.invalidate(expenseLogsProvider);
    ref.invalidate(scheduledTransactionsProvider);
    final updatedTransactions = await ref.read(scheduledTransactionsProvider.future);
    await ref.read(expenseLogsProvider.future);

    // If recurring, schedule notification for next occurrence if it's due
    final updatedItem = updatedTransactions.firstWhere(
      (t) => t.id == item.id,
      orElse: () => item,
    );
    if (updatedItem.id == item.id && item.frequency != PaymentFrequency.oneTime) {
      // Check if next occurrence is due
      final today = DateTime.now();
      final scheduledDay = DateTime(
        updatedItem.scheduledDate.year,
        updatedItem.scheduledDate.month,
        updatedItem.scheduledDate.day,
      );
      final todayOnly = DateTime(today.year, today.month, today.day);
      if (updatedItem.isActive && !scheduledDay.isAfter(todayOnly)) {
        await _handleNotificationForTransaction(updatedItem, true);
      }
    }
  }
}

@riverpod
Future<void> addScheduledTransactionAction(Ref ref, ScheduledTransaction item) async {
  final controller = ref.read(scheduledTransactionControllerProvider.notifier);
  await controller.add(item);
}

@riverpod
Future<void> updateScheduledTransactionAction(
  Ref ref,
  ScheduledTransaction item,
) async {
  final controller = ref.read(scheduledTransactionControllerProvider.notifier);
  await controller.updateItem(item);
}

@riverpod
Future<void> deleteScheduledTransactionAction(Ref ref, String id) async {
  final controller = ref.read(scheduledTransactionControllerProvider.notifier);
  await controller.delete(id);
}

@riverpod
Future<void> convertScheduledTransactionToLogAction(
  Ref ref,
  ScheduledTransaction item,
) async {
  final controller = ref.read(scheduledTransactionControllerProvider.notifier);
  await controller.convertToLog(item);
}


