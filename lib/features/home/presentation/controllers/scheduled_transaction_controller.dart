import 'dart:async';

import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/domain/usecases/expense_log_service.dart';
import 'package:anti/features/home/domain/usecases/scheduled_transaction_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  @override
  FutureOr<void> build() {}

  Future<void> add(ScheduledTransaction item) async {
    final service = ref.read(scheduledTransactionServiceProvider);
    await service.addScheduledTransaction(item);

    if (!ref.mounted) return;
    ref.invalidate(scheduledTransactionsProvider);
    await ref.read(scheduledTransactionsProvider.future);
  }

  Future<void> updateItem(ScheduledTransaction item) async {
    final service = ref.read(scheduledTransactionServiceProvider);
    await service.updateScheduledTransaction(item);

    if (!ref.mounted) return;
    ref.invalidate(scheduledTransactionsProvider);
    await ref.read(scheduledTransactionsProvider.future);
  }

  Future<void> delete(String id) async {
    final service = ref.read(scheduledTransactionServiceProvider);
    await service.deleteScheduledTransaction(id);

    if (!ref.mounted) return;
    ref.invalidate(scheduledTransactionsProvider);
    await ref.read(scheduledTransactionsProvider.future);
  }

  Future<void> convertToLog(ScheduledTransaction item) async {
    final scheduledService = ref.read(scheduledTransactionServiceProvider);
    final expenseLogService = ref.read(expenseLogServiceProvider);
    await scheduledService.convertToExpenseLog(
      scheduled: item,
      expenseLogService: expenseLogService,
    );

    if (!ref.mounted) return;
    ref.invalidate(scheduledTransactionsProvider);
    await ref.read(scheduledTransactionsProvider.future);
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


