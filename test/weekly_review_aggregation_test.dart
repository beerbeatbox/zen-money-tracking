import 'package:anti/core/utils/local_week.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/entities/weekly_recap_data.dart';
import 'package:anti/features/home/presentation/utils/weekly_review_aggregation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('totalSpentInWeek', () {
    test('sums only negative amounts in the local week', () {
      final monday = DateTime(2025, 1, 6);
      final logs = <ExpenseLog>[
        ExpenseLog(
          id: '1',
          timeLabel: '10:00',
          category: 'A',
          amount: -100,
          createdAt: DateTime(2025, 1, 7, 10, 0),
        ),
        ExpenseLog(
          id: '2',
          timeLabel: '11:00',
          category: 'B',
          amount: 50,
          createdAt: DateTime(2025, 1, 8, 11, 0),
        ),
        ExpenseLog(
          id: '3',
          timeLabel: '12:00',
          category: 'C',
          amount: -25.5,
          createdAt: DateTime(2025, 1, 9, 12, 0),
        ),
      ];
      expect(totalSpentInWeek(logs, monday), 125.5);
    });
  });

  group('dailyExpenseTotalsForWeek', () {
    test('distributes Mon–Sun', () {
      final monday = DateTime(2025, 1, 6);
      final expenses = <ExpenseLog>[
        ExpenseLog(
          id: '1',
          timeLabel: '09:00',
          category: 'A',
          amount: -10,
          createdAt: DateTime(2025, 1, 6, 9, 0),
        ),
        ExpenseLog(
          id: '2',
          timeLabel: '09:00',
          category: 'B',
          amount: -20,
          createdAt: DateTime(2025, 1, 8, 9, 0),
        ),
      ];
      final d = dailyExpenseTotalsForWeek(expenses, monday);
      expect(d[0], 10);
      expect(d[1], 0);
      expect(d[2], 20);
    });
  });

  group('projectMonthEndFromPace', () {
    test('linearly scales month to date', () {
      expect(
        projectMonthEndFromPace(1000, 10, 30),
        3000.0,
      );
    });
  });

  group('smallPurchases', () {
    test('includes amounts strictly below threshold', () {
      final ex = <ExpenseLog>[
        ExpenseLog(
          id: '1',
          timeLabel: '09:00',
          category: 'A',
          amount: -50,
          createdAt: DateTime(2025, 1, 1),
        ),
        ExpenseLog(
          id: '2',
          timeLabel: '09:00',
          category: 'A',
          amount: -200,
          createdAt: DateTime(2025, 1, 1),
        ),
      ];
      final r = smallPurchases(ex, 100);
      expect(r.count, 1);
      expect(r.total, 50);
    });
  });

  test('parse query date round-trip via startOfLocalWeekMonday', () {
    final m = startOfLocalWeekMonday(DateTime(2025, 1, 8));
    expect(m.weekday, DateTime.monday);
  });

  group('computeDailyCategorySpending', () {
    test('splits top category vs other for a day', () {
      final monday = DateTime(2025, 1, 6);
      final expenses = <ExpenseLog>[
        ExpenseLog(
          id: '1',
          timeLabel: '09:00',
          category: 'Food',
          amount: -40,
          createdAt: DateTime(2025, 1, 6, 9, 0),
        ),
        ExpenseLog(
          id: '2',
          timeLabel: '10:00',
          category: 'Shop',
          amount: -60,
          createdAt: DateTime(2025, 1, 6, 10, 0),
        ),
        ExpenseLog(
          id: '3',
          timeLabel: '11:00',
          category: 'Food',
          amount: -30,
          createdAt: DateTime(2025, 1, 7, 11, 0),
        ),
      ];
      final list = computeDailyCategorySpending(expenses, monday);
      expect(list[0].totalAmount, 100);
      expect(list[0].topCategory, 'Shop');
      expect(list[0].topCategoryAmount, 60);
      expect(list[0].otherAmount, 40);
      expect(list[1].totalAmount, 30);
      expect(list[1].distinctCategoryCount, 1);
      expect(list[1].barLabel, 'Food');
    });
  });

  group('shouldShowWeeklyReviewMoneyLeaksSlide', () {
    test('true when count and share thresholds met', () {
      expect(
        shouldShowWeeklyReviewMoneyLeaksSlide(
          totalSpent: 1000,
          smallPurchaseCount: 3,
          smallPurchaseTotal: 150,
        ),
        true,
      );
    });

    test('false when too few small purchases', () {
      expect(
        shouldShowWeeklyReviewMoneyLeaksSlide(
          totalSpent: 1000,
          smallPurchaseCount: 2,
          smallPurchaseTotal: 200,
        ),
        false,
      );
    });

    test('false when share of week is below 15%', () {
      expect(
        shouldShowWeeklyReviewMoneyLeaksSlide(
          totalSpent: 1000,
          smallPurchaseCount: 5,
          smallPurchaseTotal: 100,
        ),
        false,
      );
    });
  });

  group('shouldShowWeeklyReviewCategoryShiftSlide', () {
    test('true when difference clears max(150, 35% of baseline)', () {
      expect(
        shouldShowWeeklyReviewCategoryShiftSlide(
          const CategoryShiftInsight(
            categoryName: 'Food',
            thisWeekAmount: 500,
            baselineCategoryAverage: 100,
            differenceFromBaseline: 200,
          ),
        ),
        true,
      );
    });

    test('false when difference below threshold', () {
      expect(
        shouldShowWeeklyReviewCategoryShiftSlide(
          const CategoryShiftInsight(
            categoryName: 'Food',
            thisWeekAmount: 500,
            baselineCategoryAverage: 10,
            differenceFromBaseline: 100,
          ),
        ),
        false,
      );
    });

    test('true when 35% of large baseline exceeds 150', () {
      expect(
        shouldShowWeeklyReviewCategoryShiftSlide(
          const CategoryShiftInsight(
            categoryName: 'Rent',
            thisWeekAmount: 2000,
            baselineCategoryAverage: 1000,
            differenceFromBaseline: 400,
          ),
        ),
        true,
      );
    });

    test('false for null', () {
      expect(shouldShowWeeklyReviewCategoryShiftSlide(null), false);
    });
  });

  group('spendingRhythmBusiestLine', () {
    test('returns a line for busiest day with spend', () {
      const wd = <String>['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      final daily = List<DailyCategorySpend>.generate(7, (i) {
        if (i == 2) {
          return DailyCategorySpend(
            weekdayIndex: i,
            totalAmount: 50,
            topCategory: 'A',
            topCategoryAmount: 50,
            otherAmount: 0,
            distinctCategoryCount: 1,
          );
        }
        return DailyCategorySpend(
          weekdayIndex: i,
          totalAmount: 0,
          topCategory: null,
          topCategoryAmount: 0,
          otherAmount: 0,
          distinctCategoryCount: 0,
        );
      });
      final line = spendingRhythmBusiestLine(
        daily: daily,
        busiestIndex: 2,
        weekdayShort: wd,
      );
      expect(line, contains('Wed'));
    });
  });
}
