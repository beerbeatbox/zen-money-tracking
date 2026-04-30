import 'dart:math' as math;

import 'package:baht/core/utils/local_week.dart';
import 'package:baht/features/home/domain/entities/expense_log.dart';
import 'package:baht/features/home/domain/entities/weekly_recap_data.dart';

/// Total spent (expenses only) in the local week starting [weekStartMonday].
double totalSpentInWeek(
  List<ExpenseLog> allLogs,
  DateTime weekStartMonday,
) {
  return filterLogsInLocalWeek(allLogs, weekStartMonday)
      .where((l) => l.amount < 0)
      .fold<double>(0, (s, l) => s + l.amount.abs());
}

List<double> dailyExpenseTotalsForWeek(
  List<ExpenseLog> weekExpenses,
  DateTime weekStartMonday,
) {
  final start = startOfLocalWeekMonday(weekStartMonday);
  final out = List<double>.filled(7, 0);
  for (final l in weekExpenses) {
    if (l.amount >= 0) continue;
    final d = DateTime(l.createdAt.year, l.createdAt.month, l.createdAt.day);
    final monday = startOfLocalWeekMonday(d);
    if (monday != start) continue;
    final index = d.weekday - DateTime.monday;
    if (index >= 0 && index < 7) {
      out[index] += l.amount.abs();
    }
  }
  return out;
}

int busiestDayIndex(List<double> daily) {
  if (daily.isEmpty) return 0;
  var best = 0;
  for (var i = 1; i < daily.length; i++) {
    if (daily[i] > daily[best]) best = i;
  }
  return best;
}

/// Per Mon–Sun: sum per category for that day, then top category vs the rest.
List<DailyCategorySpend> computeDailyCategorySpending(
  List<ExpenseLog> weekExpenses,
  DateTime weekStartMonday,
) {
  final start = startOfLocalWeekMonday(weekStartMonday);
  final byDay = List.generate(7, (_) => <String, double>{});
  for (final l in weekExpenses) {
    if (l.amount >= 0) continue;
    final d = DateTime(l.createdAt.year, l.createdAt.month, l.createdAt.day);
    if (startOfLocalWeekMonday(d) != start) continue;
    final index = d.weekday - DateTime.monday;
    if (index < 0 || index >= 7) continue;
    final k = l.category.isEmpty ? '—' : l.category;
    byDay[index][k] = (byDay[index][k] ?? 0) + l.amount.abs();
  }
  return List.generate(7, (i) {
    final m = byDay[i];
    final total = m.values.fold(0.0, (a, b) => a + b);
    if (total <= 0) {
      return DailyCategorySpend(
        weekdayIndex: i,
        totalAmount: 0,
        topCategory: null,
        topCategoryAmount: 0,
        otherAmount: 0,
        distinctCategoryCount: 0,
      );
    }
    var maxV = 0.0;
    for (final e in m.entries) {
      if (e.value > maxV) maxV = e.value;
    }
    String? topKey;
    for (final e in m.entries) {
      if ((e.value - maxV).abs() < 1e-9) {
        if (topKey == null || e.key.compareTo(topKey) < 0) {
          topKey = e.key;
        }
      }
    }
    final topAmt = topKey != null ? m[topKey]! : 0.0;
    final nCats = m.entries.where((e) => e.value > 0).length;
    return DailyCategorySpend(
      weekdayIndex: i,
      totalAmount: total,
      topCategory: topKey,
      topCategoryAmount: topAmt,
      otherAmount: (total - topAmt).clamp(0.0, double.infinity),
      distinctCategoryCount: nCats,
    );
  });
}

/// One-line subcopy for Spending Rhythm (busiest day + category).
String spendingRhythmBusiestLine({
  required List<DailyCategorySpend> daily,
  required int busiestIndex,
  required List<String> weekdayShort,
}) {
  if (busiestIndex < 0 || busiestIndex > 6 || daily.length != 7) {
    return 'Log spending to see your rhythm here.';
  }
  final d = daily[busiestIndex];
  final day = weekdayShort[busiestIndex];
  if (d.totalAmount <= 0) {
    return 'Add logs to see your spending rhythm for this week.';
  }
  if (d.distinctCategoryCount == 1 && d.topCategory != null) {
    return '$day was your busiest day, mostly in ${d.topCategory!}.';
  }
  if (d.topCategoryShare >= 0.5 && d.topCategory != null) {
    return '$day led the week. ${d.topCategory!} was most of that day, with the rest spread out.';
  }
  return '$day led the week, with a mix of categories that day.';
}

/// Month-to-date through [weekEnd] for the same calendar month as [weekStart].
({double monthToDate, int daysUsed, int daysInMonth}) monthSpentToDateForWeek(
  List<ExpenseLog> allLogs,
  DateTime weekStart,
  DateTime weekEnd,
) {
  final startOfMonth = DateTime(weekStart.year, weekStart.month, 1);
  final endOfMonth = DateTime(weekStart.year, weekStart.month + 1, 0);
  final lastDayInRange = weekEnd.isAfter(endOfMonth) ? endOfMonth : weekEnd;
  var sum = 0.0;
  for (final l in allLogs) {
    if (l.amount >= 0) continue;
    final d = DateTime(l.createdAt.year, l.createdAt.month, l.createdAt.day);
    if (d.month != weekStart.month || d.year != weekStart.year) continue;
    if (d.isBefore(startOfMonth) || d.isAfter(lastDayInRange)) continue;
    sum += l.amount.abs();
  }
  var daysUsed = 0;
  for (var day = 1; day <= lastDayInRange.day; day++) {
    final x = DateTime(weekStart.year, weekStart.month, day);
    if (!x.isAfter(lastDayInRange) && !x.isBefore(startOfMonth)) {
      daysUsed++;
    }
  }
  if (daysUsed < 1) daysUsed = 1;
  return (
    monthToDate: sum,
    daysUsed: daysUsed,
    daysInMonth: endOfMonth.day,
  );
}

double? projectMonthEndFromPace(
  double monthToDate,
  int daysUsed,
  int daysInMonth,
) {
  if (daysUsed < 1 || daysInMonth < 1) return null;
  if (monthToDate <= 0) return 0.0;
  return (monthToDate / daysUsed) * daysInMonth;
}

Map<String, double> categoryAmounts(
  List<ExpenseLog> expenses,
) {
  final map = <String, double>{};
  for (final l in expenses) {
    if (l.amount >= 0) continue;
    final key = l.category.isEmpty ? '—' : l.category;
    map[key] = (map[key] ?? 0) + l.amount.abs();
  }
  return map;
}

List<({String category, double amount})> sortedCategoryList(
  Map<String, double> map, {
  int maxEntries = 10,
}) {
  final list =
      map.entries
          .map((e) => (category: e.key, amount: e.value))
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
  if (list.length > maxEntries) {
    return list.sublist(0, maxEntries);
  }
  return list;
}

Map<String, double> categoryTotalForWeek(
  List<ExpenseLog> allLogs,
  DateTime weekStartMonday,
) {
  final w = filterLogsInLocalWeek(allLogs, weekStartMonday);
  return categoryAmounts(w.where((l) => l.amount < 0).toList());
}

/// Per-category average per week over [weekMondays].
Map<String, double> averageCategoryPerWeekOverWeeks(
  List<ExpenseLog> allLogs,
  List<DateTime> weekMondays,
) {
  if (weekMondays.isEmpty) {
    return {};
  }
  final acc = <String, double>{};
  for (final m in weekMondays) {
    final by = categoryTotalForWeek(allLogs, m);
    for (final e in by.entries) {
      acc[e.key] = (acc[e.key] ?? 0) + e.value;
    }
  }
  final n = weekMondays.length;
  for (final k in acc.keys.toList()) {
    acc[k] = acc[k]! / n;
  }
  return acc;
}

/// Category with the largest positive jump vs 4-week average.
CategoryShiftInsight? computeCategoryShift(
  List<ExpenseLog> allLogs,
  DateTime currentWeekStart,
  Map<String, double> thisWeekByCategory,
) {
  if (thisWeekByCategory.isEmpty) return null;
  final priorMondays = <DateTime>[
    for (var i = 1; i <= 4; i++)
      currentWeekStart.subtract(Duration(days: 7 * i)),
  ];
  final baseline = averageCategoryPerWeekOverWeeks(allLogs, priorMondays);
  CategoryShiftInsight? best;
  var bestDiff = 0.0;
  for (final e in thisWeekByCategory.entries) {
    final base = baseline[e.key] ?? 0;
    final diff = e.value - base;
    if (diff > bestDiff) {
      bestDiff = diff;
      best = CategoryShiftInsight(
        categoryName: e.key,
        thisWeekAmount: e.value,
        baselineCategoryAverage: base,
        differenceFromBaseline: diff,
      );
    }
  }
  if (best == null || best.differenceFromBaseline <= 0) {
    return null;
  }
  return best;
}

bool _isFoodish(String category) {
  final c = category.toLowerCase();
  return c.contains('food') ||
      c.contains('eat') ||
      c.contains('meal') ||
      c.contains('อาหาร') ||
      c.contains('café') ||
      c.contains('cafe');
}

WeeklyReviewPatternType detectPattern({
  required double totalSpent,
  required List<double> daily,
  required int expenseCount,
  required int smallPurchaseCount,
  required double biggestShare,
  required double? pctVsPrevious,
  required String? topCategory,
}) {
  if (totalSpent <= 0) return WeeklyReviewPatternType.mixedWeek;
  if (expenseCount > 0 && daily.length == 7) {
    final wEnd = (daily[5] + daily[6]) / totalSpent;
    if (wEnd > 0.45) return WeeklyReviewPatternType.weekendSpender;
  }
  if (expenseCount >= 5 && smallPurchaseCount / expenseCount > 0.5) {
    return WeeklyReviewPatternType.frequentSmallSpender;
  }
  if (biggestShare > 0.35) {
    return WeeklyReviewPatternType.oneBigPurchaseWeek;
  }
  if (topCategory != null && _isFoodish(topCategory)) {
    return WeeklyReviewPatternType.foodHeavyWeek;
  }
  if (pctVsPrevious != null && pctVsPrevious.abs() < 7) {
    return WeeklyReviewPatternType.steadyWeek;
  }
  return WeeklyReviewPatternType.mixedWeek;
}

double smallPurchaseThreshold(double totalSpent) {
  if (totalSpent <= 0) return 100;
  return (totalSpent * 0.08).clamp(80.0, 320.0);
}

({double total, int count}) smallPurchases(
  List<ExpenseLog> expenses,
  double threshold,
) {
  var total = 0.0;
  var n = 0;
  for (final l in expenses) {
    if (l.amount >= 0) continue;
    final a = l.amount.abs();
    if (a > 0 && a < threshold) {
      total += a;
      n++;
    }
  }
  return (total: total, count: n);
}

/// Whether to show the Small Buys slide (meaningful small-purchase share).
bool shouldShowWeeklyReviewMoneyLeaksSlide({
  required double totalSpent,
  required int smallPurchaseCount,
  required double smallPurchaseTotal,
}) {
  if (totalSpent <= 0) return false;
  if (smallPurchaseCount < 3) return false;
  return (smallPurchaseTotal / totalSpent) >= 0.15;
}

/// Whether category spend jumped enough vs the user’s usual to warrant a slide.
bool shouldShowWeeklyReviewCategoryShiftSlide(CategoryShiftInsight? shift) {
  if (shift == null) return false;
  if (shift.thisWeekAmount <= 0) return false;
  final threshold = math.max(150.0, shift.baselineCategoryAverage * 0.35);
  return shift.differenceFromBaseline >= threshold;
}

/// Slide count for the weekly money review story (intro, this week, where it went,
/// optional insights, biggest purchase, next move).
int weeklyReviewSlideCount(WeeklyRecapData data) {
  var n = 5;
  if (shouldShowWeeklyReviewMoneyLeaksSlide(
        totalSpent: data.totalSpent,
        smallPurchaseCount: data.smallPurchaseCount,
        smallPurchaseTotal: data.smallPurchaseTotal,
      )) {
    n++;
  }
  if (shouldShowWeeklyReviewCategoryShiftSlide(data.categoryShift)) {
    n++;
  }
  return n;
}

WeeklyReviewNextMove computeNextMove({
  required double totalSpent,
  required CategoryShiftInsight? shift,
  required WeeklyReviewPatternType pattern,
  required double? monthlyProjected,
  required double? spentChangePercent,
  required double smallPurchaseTotal,
  required int smallPurchaseCount,
}) {
  if (totalSpent <= 0) {
    return const WeeklyReviewNextMove(
      title: 'Start your review',
      body: 'Add a log next week to unlock patterns tailored to you.',
    );
  }
  if (shift != null && shouldShowWeeklyReviewCategoryShiftSlide(shift)) {
    return WeeklyReviewNextMove(
      title: 'Shape next week',
      body:
          '“${shift.categoryName}” ran above your usual. Try one small cap there next week.',
    );
  }
  if (pattern == WeeklyReviewPatternType.weekendSpender) {
    return const WeeklyReviewNextMove(
      title: 'Plan the weekend first',
      body: 'Set a simple weekend total before Friday so Saturday stays on track.',
    );
  }
  if (pattern == WeeklyReviewPatternType.frequentSmallSpender &&
      smallPurchaseCount >= 3) {
    return const WeeklyReviewNextMove(
      title: 'Group the little buys',
      body: 'Batch errands into one trip to keep small spends from stacking up.',
    );
  }
  if (monthlyProjected != null &&
      monthlyProjected > 0 &&
      spentChangePercent != null) {
    if (spentChangePercent > 12) {
      return const WeeklyReviewNextMove(
        title: 'Gentle reset',
        body: 'This week was higher than last. A lighter week ahead keeps the month calmer.',
      );
    }
  }
  return const WeeklyReviewNextMove(
    title: 'Keep the rhythm',
    body: 'Log through next week to sharpen your view and your habits.',
  );
}
