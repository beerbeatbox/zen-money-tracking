import 'package:anti/features/home/domain/entities/balance_snapshot.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';

/// Returns the most recent snapshot by [BalanceSnapshot.effectiveAt], or null.
BalanceSnapshot? pickLatestSnapshot(List<BalanceSnapshot> snapshots) {
  if (snapshots.isEmpty) return null;
  final sorted = [...snapshots]..sort(
        (a, b) => a.effectiveAt.compareTo(b.effectiveAt),
      );
  return sorted.last;
}

/// Dashboard “Balance” number: either snapshot-based (real wallet) or month logs + carry.
double dashboardNetBalance({
  required BalanceSnapshot? latestSnapshot,
  required List<ExpenseLog> allLogs,
  required List<ExpenseLog> scopedLogs,
  required List<ExpenseLog> previousMonthLogs,
  required bool carryEnabled,
  required bool canCarry,
}) {
  if (latestSnapshot != null) {
    var delta = 0.0;
    for (final log in allLogs) {
      if (log.createdAt.isAfter(latestSnapshot.effectiveAt)) {
        delta += log.amount;
      }
    }
    return latestSnapshot.amount + delta;
  }
  final carry =
      (carryEnabled && canCarry) ? _netFromLogs(previousMonthLogs) : 0.0;
  return _netFromLogs(scopedLogs) + carry;
}

double _netFromLogs(List<ExpenseLog> logs) =>
    logs.fold<double>(0.0, (sum, log) => sum + log.amount);
