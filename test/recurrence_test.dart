import 'package:baht/features/home/domain/entities/scheduled_transaction.dart';
import 'package:baht/features/home/domain/utils/recurrence.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('nextDueDate', () {
    test('monthly keeps day when possible', () {
      final from = DateTime(2025, 1, 15, 10, 30);
      final next = nextDueDate(from: from, frequency: PaymentFrequency.monthly);
      expect(next, DateTime(2025, 2, 15, 10, 30));
    });

    test('monthly clamps day to last day of month', () {
      final from = DateTime(2025, 1, 31, 9, 0);
      final next = nextDueDate(from: from, frequency: PaymentFrequency.monthly);
      expect(next, DateTime(2025, 2, 28, 9, 0));
    });

    test('monthly handles leap year (Jan 31 -> Feb 29 in leap year)', () {
      final from = DateTime(2024, 1, 31, 9, 0);
      final next = nextDueDate(from: from, frequency: PaymentFrequency.monthly);
      expect(next, DateTime(2024, 2, 29, 9, 0));
    });

    test('yearly clamps Feb 29 to Feb 28 on non-leap year', () {
      final from = DateTime(2024, 2, 29, 18, 45);
      final next = nextDueDate(from: from, frequency: PaymentFrequency.yearly);
      expect(next, DateTime(2025, 2, 28, 18, 45));
    });

    test('interval days adds correct number of days', () {
      final from = DateTime(2025, 1, 15, 10, 30);
      final next = nextDueDate(
        from: from,
        frequency: PaymentFrequency.interval,
        intervalCount: 7,
        intervalUnit: IntervalUnit.days,
      );
      expect(next, DateTime(2025, 1, 22, 10, 30));
    });

    test('interval weeks adds correct number of weeks', () {
      final from = DateTime(2025, 1, 15, 10, 30);
      final next = nextDueDate(
        from: from,
        frequency: PaymentFrequency.interval,
        intervalCount: 2,
        intervalUnit: IntervalUnit.weeks,
      );
      expect(next, DateTime(2025, 1, 29, 10, 30));
    });

    test('interval months clamps day correctly', () {
      final from = DateTime(2025, 1, 31, 9, 0);
      final next = nextDueDate(
        from: from,
        frequency: PaymentFrequency.interval,
        intervalCount: 1,
        intervalUnit: IntervalUnit.months,
      );
      expect(next, DateTime(2025, 2, 28, 9, 0));
    });

    test('interval years clamps Feb 29 correctly', () {
      final from = DateTime(2024, 2, 29, 18, 45);
      final next = nextDueDate(
        from: from,
        frequency: PaymentFrequency.interval,
        intervalCount: 1,
        intervalUnit: IntervalUnit.years,
      );
      expect(next, DateTime(2025, 2, 28, 18, 45));
    });
  });

  group('occurrencesInMonth', () {
    test('one-time returns single occurrence if in month', () {
      final schedule = ScheduledTransaction(
        id: '1',
        title: 'Test',
        category: 'Test',
        amount: 100,
        scheduledDate: DateTime(2025, 1, 15, 10, 0),
        createdAt: DateTime.now(),
        frequency: PaymentFrequency.oneTime,
      );
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 31, 23, 59, 59);

      final occurrences = occurrencesInMonth(
        schedule: schedule,
        startOfMonth: start,
        endOfMonth: end,
      );

      expect(occurrences.length, 1);
      expect(occurrences.first, DateTime(2025, 1, 15, 10, 0));
    });

    test('one-time returns empty if not in month', () {
      final schedule = ScheduledTransaction(
        id: '1',
        title: 'Test',
        category: 'Test',
        amount: 100,
        scheduledDate: DateTime(2025, 2, 15, 10, 0),
        createdAt: DateTime.now(),
        frequency: PaymentFrequency.oneTime,
      );
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 31, 23, 59, 59);

      final occurrences = occurrencesInMonth(
        schedule: schedule,
        startOfMonth: start,
        endOfMonth: end,
      );

      expect(occurrences.isEmpty, true);
    });

    test('interval days generates multiple occurrences', () {
      final schedule = ScheduledTransaction(
        id: '1',
        title: 'Test',
        category: 'Test',
        amount: 100,
        scheduledDate: DateTime(2025, 1, 5, 10, 0),
        createdAt: DateTime.now(),
        frequency: PaymentFrequency.interval,
        intervalCount: 7,
        intervalUnit: IntervalUnit.days,
      );
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 31, 23, 59, 59);

      final occurrences = occurrencesInMonth(
        schedule: schedule,
        startOfMonth: start,
        endOfMonth: end,
      );

      // Should have occurrences on Jan 5, 12, 19, 26
      expect(occurrences.length, 4);
      expect(occurrences[0], DateTime(2025, 1, 5, 10, 0));
      expect(occurrences[1], DateTime(2025, 1, 12, 10, 0));
      expect(occurrences[2], DateTime(2025, 1, 19, 10, 0));
      expect(occurrences[3], DateTime(2025, 1, 26, 10, 0));
    });

    test('interval months generates single occurrence per month', () {
      final schedule = ScheduledTransaction(
        id: '1',
        title: 'Test',
        category: 'Test',
        amount: 100,
        scheduledDate: DateTime(2025, 1, 15, 10, 0),
        createdAt: DateTime.now(),
        frequency: PaymentFrequency.interval,
        intervalCount: 1,
        intervalUnit: IntervalUnit.months,
      );
      final start = DateTime(2025, 1, 1);
      final end = DateTime(2025, 1, 31, 23, 59, 59);

      final occurrences = occurrencesInMonth(
        schedule: schedule,
        startOfMonth: start,
        endOfMonth: end,
      );

      expect(occurrences.length, 1);
      expect(occurrences.first, DateTime(2025, 1, 15, 10, 0));
    });
  });
}
