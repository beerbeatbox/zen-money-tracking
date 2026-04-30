import 'package:baht/features/home/data/models/balance_snapshot_model.dart';
import 'package:baht/features/home/domain/entities/balance_snapshot.dart';
import 'package:baht/features/home/domain/entities/expense_log.dart';
import 'package:baht/features/home/domain/utils/dashboard_net_balance.dart';
import 'package:flutter_test/flutter_test.dart';

ExpenseLog _log({
  required String id,
  required double amount,
  required DateTime createdAt,
}) {
  return ExpenseLog(
    id: id,
    timeLabel: '10:00',
    category: 'test',
    amount: amount,
    createdAt: createdAt,
  );
}

void main() {
  group('pickLatestSnapshot', () {
    test('returns null for empty list', () {
      expect(pickLatestSnapshot([]), isNull);
    });

    test('returns snapshot with latest effectiveAt', () {
      final a = BalanceSnapshot(
        id: 'a',
        amount: 1,
        effectiveAt: DateTime(2024, 1, 1),
      );
      final b = BalanceSnapshot(
        id: 'b',
        amount: 2,
        effectiveAt: DateTime(2024, 6, 1),
      );
      expect(pickLatestSnapshot([a, b])?.id, 'b');
      expect(pickLatestSnapshot([b, a])?.id, 'b');
    });
  });

  group('dashboardNetBalance', () {
    test('without snapshot: scoped net plus carry from previous month', () {
      final scoped = [
        _log(id: '1', amount: 100, createdAt: DateTime(2024, 3, 5)),
        _log(id: '2', amount: -30, createdAt: DateTime(2024, 3, 6)),
      ];
      final previous = [
        _log(id: '3', amount: 10, createdAt: DateTime(2024, 2, 1)),
      ];
      final balance = dashboardNetBalance(
        latestSnapshot: null,
        allLogs: [...scoped, ...previous],
        scopedLogs: scoped,
        previousMonthLogs: previous,
        carryEnabled: true,
        canCarry: true,
      );
      expect(balance, 80.0);
    });

    test('without snapshot: carry disabled', () {
      final scoped = [
        _log(id: '1', amount: 50, createdAt: DateTime(2024, 3, 5)),
      ];
      final previous = [
        _log(id: '2', amount: 200, createdAt: DateTime(2024, 2, 1)),
      ];
      final balance = dashboardNetBalance(
        latestSnapshot: null,
        allLogs: [...scoped, ...previous],
        scopedLogs: scoped,
        previousMonthLogs: previous,
        carryEnabled: false,
        canCarry: true,
      );
      expect(balance, 50.0);
    });

    test('with snapshot: baseline plus only logs after snapshot time', () {
      final snapTime = DateTime(2024, 6, 1, 12, 0, 0);
      final snap = BalanceSnapshot(
        id: 's',
        amount: 1000,
        effectiveAt: snapTime,
      );
      final before = _log(
        id: 'old',
        amount: -999,
        createdAt: DateTime(2024, 5, 1),
      );
      final after = _log(
        id: 'new',
        amount: 50,
        createdAt: DateTime(2024, 6, 2),
      );
      final balance = dashboardNetBalance(
        latestSnapshot: snap,
        allLogs: [before, after],
        scopedLogs: [after],
        previousMonthLogs: [before],
        carryEnabled: true,
        canCarry: true,
      );
      expect(balance, 1050.0);
    });

  });

  group('BalanceSnapshotModel', () {
    test('toJson and fromJson roundtrip', () {
      final original = BalanceSnapshotModel(
        id: 'id1',
        amount: 123.45,
        effectiveAt: DateTime.utc(2024, 3, 15, 8, 30),
        note: 'note',
      );
      final decoded = BalanceSnapshotModel.fromJson(original.toJson());
      expect(decoded.id, original.id);
      expect(decoded.amount, original.amount);
      expect(decoded.effectiveAt, original.effectiveAt);
      expect(decoded.note, original.note);
    });
  });
}
