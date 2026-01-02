import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/domain/utils/recurrence.dart';
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
  });
}
