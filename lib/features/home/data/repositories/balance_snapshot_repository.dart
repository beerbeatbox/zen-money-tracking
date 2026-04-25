import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/data/datasources/balance_snapshot_local_datasource.dart';
import 'package:anti/features/home/data/models/balance_snapshot_model.dart';
import 'package:anti/features/home/domain/entities/balance_snapshot.dart';

part 'balance_snapshot_repository.g.dart';

class BalanceSnapshotRepository {
  const BalanceSnapshotRepository(this._datasource);

  final BalanceSnapshotLocalDatasource _datasource;

  Future<List<BalanceSnapshot>> getAll() async {
    final models = await _datasource.readAll();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> add(BalanceSnapshot snapshot) async {
    final model = BalanceSnapshotModel.fromEntity(snapshot);
    await _datasource.append(model);
  }

  Future<void> deleteAll() => _datasource.deleteFile();
}

@riverpod
BalanceSnapshotRepository balanceSnapshotRepository(Ref ref) {
  final datasource = ref.watch(balanceSnapshotLocalDatasourceProvider);
  return BalanceSnapshotRepository(datasource);
}
