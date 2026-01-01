import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/features/home/data/repositories/scheduled_transaction_repository.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/domain/usecases/expense_log_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'scheduled_transaction_service.g.dart';

class ScheduledTransactionService {
  const ScheduledTransactionService(this._repo);

  final ScheduledTransactionRepository _repo;

  Future<List<ScheduledTransaction>> getScheduledTransactions() =>
      _repo.getAll();

  Future<void> addScheduledTransaction(ScheduledTransaction item) =>
      _repo.add(item);

  Future<void> setScheduledTransactions(List<ScheduledTransaction> items) =>
      _repo.setAll(items);

  Future<void> updateScheduledTransaction(ScheduledTransaction updated) async {
    final items = await getScheduledTransactions();
    final index = items.indexWhere((e) => e.id == updated.id);
    if (index == -1) return;
    final next = [...items];
    next[index] = updated;
    await setScheduledTransactions(next);
  }

  Future<void> deleteScheduledTransaction(String id) => _repo.deleteById(id);

  Future<void> deleteScheduledTransactionFile() => _repo.deleteFile();

  Future<void> convertToExpenseLog({
    required ScheduledTransaction scheduled,
    required ExpenseLogService expenseLogService,
  }) async {
    final createdAt = scheduled.scheduledDate;
    final log = ExpenseLog(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      timeLabel: formatTimeHm(createdAt),
      category: scheduled.category,
      amount: scheduled.amount,
      createdAt: createdAt,
    );

    await expenseLogService.addExpenseLog(log);
    await deleteScheduledTransaction(scheduled.id);
  }
}

@riverpod
ScheduledTransactionService scheduledTransactionService(Ref ref) {
  final repo = ref.watch(scheduledTransactionRepositoryProvider);
  return ScheduledTransactionService(repo);
}


