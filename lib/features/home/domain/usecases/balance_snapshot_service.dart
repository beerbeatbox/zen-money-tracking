import 'package:anti/features/home/data/repositories/balance_snapshot_repository.dart';
import 'package:anti/features/home/domain/entities/balance_snapshot.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'balance_snapshot_service.g.dart';

class BalanceSnapshotService {
  const BalanceSnapshotService(this._repository);

  final BalanceSnapshotRepository _repository;

  Future<List<BalanceSnapshot>> getSnapshots() => _repository.getAll();

  Future<void> addSnapshot(BalanceSnapshot snapshot) => _repository.add(snapshot);

  Future<void> deleteAllSnapshots() => _repository.deleteAll();
}

@riverpod
BalanceSnapshotService balanceSnapshotService(Ref ref) {
  final repository = ref.watch(balanceSnapshotRepositoryProvider);
  return BalanceSnapshotService(repository);
}
