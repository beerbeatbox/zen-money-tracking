import 'dart:async';

import 'package:anti/features/home/domain/entities/balance_snapshot.dart';
import 'package:anti/features/home/domain/usecases/balance_snapshot_service.dart';
import 'package:anti/features/home/domain/utils/dashboard_net_balance.dart'
    show pickLatestSnapshot;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'balance_snapshot_controller.g.dart';

@Riverpod(keepAlive: true)
class BalanceSnapshotListController extends _$BalanceSnapshotListController {
  @override
  FutureOr<List<BalanceSnapshot>> build() async {
    final service = ref.watch(balanceSnapshotServiceProvider);
    return service.getSnapshots();
  }

  Future<void> setCurrentBalance({required double amount, String? note}) async {
    final service = ref.read(balanceSnapshotServiceProvider);
    final snapshot = BalanceSnapshot(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      amount: amount,
      effectiveAt: DateTime.now(),
      note: note,
    );
    await service.addSnapshot(snapshot);
    if (!ref.mounted) return;
    ref.invalidateSelf();
    await future;
  }

  Future<void> clearAll() async {
    final service = ref.read(balanceSnapshotServiceProvider);
    await service.deleteAllSnapshots();
    if (!ref.mounted) return;
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
Future<BalanceSnapshot?> latestBalanceSnapshot(Ref ref) async {
  final list = await ref.watch(balanceSnapshotListControllerProvider.future);
  return pickLatestSnapshot(list);
}

@riverpod
Future<void> deleteAllBalanceSnapshots(Ref ref) async {
  await ref.read(balanceSnapshotListControllerProvider.notifier).clearAll();
}
