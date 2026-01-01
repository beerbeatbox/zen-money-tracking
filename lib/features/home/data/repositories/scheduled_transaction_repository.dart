import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/data/datasources/scheduled_transaction_local_datasource.dart';
import 'package:anti/features/home/data/models/scheduled_transaction_model.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';

part 'scheduled_transaction_repository.g.dart';

class ScheduledTransactionRepository {
  const ScheduledTransactionRepository(this._datasource);

  final ScheduledTransactionLocalDatasource _datasource;

  Future<List<ScheduledTransaction>> getAll() async {
    final models = await _datasource.readAll();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> add(ScheduledTransaction item) async {
    final model = ScheduledTransactionModel.fromEntity(item);
    await _datasource.append(model);
  }

  Future<void> setAll(List<ScheduledTransaction> items) async {
    final models = items.map(ScheduledTransactionModel.fromEntity).toList();
    await _datasource.overwrite(models);
  }

  Future<void> deleteById(String id) => _datasource.deleteById(id);

  Future<void> deleteFile() => _datasource.deleteFile();
}

@riverpod
ScheduledTransactionRepository scheduledTransactionRepository(Ref ref) {
  final datasource = ref.watch(scheduledTransactionLocalDatasourceProvider);
  return ScheduledTransactionRepository(datasource);
}


