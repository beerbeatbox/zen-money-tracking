import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:flutter/material.dart';

DateTime nextDueDate({
  required DateTime from,
  required PaymentFrequency frequency,
  int? intervalCount,
  IntervalUnit? intervalUnit,
}) {
  switch (frequency) {
    case PaymentFrequency.oneTime:
      return from;
    case PaymentFrequency.monthly:
      return _addMonthsClamped(from, 1);
    case PaymentFrequency.yearly:
      return _addYearsClamped(from, 1);
    case PaymentFrequency.interval:
      if (intervalCount == null || intervalUnit == null) {
        return from;
      }
      return _addInterval(from, intervalCount, intervalUnit);
  }
}

DateTime _addInterval(
  DateTime from,
  int count,
  IntervalUnit unit,
) {
  switch (unit) {
    case IntervalUnit.days:
      return from.add(Duration(days: count));
    case IntervalUnit.weeks:
      return from.add(Duration(days: count * 7));
    case IntervalUnit.months:
      return _addMonthsClamped(from, count);
    case IntervalUnit.years:
      return _addYearsClamped(from, count);
  }
}

DateTime _addMonthsClamped(DateTime from, int monthsToAdd) {
  final totalMonths = (from.year * 12) + (from.month - 1) + monthsToAdd;
  final year = totalMonths ~/ 12;
  final month = (totalMonths % 12) + 1;
  final day = _clampDay(year: year, month: month, day: from.day);

  return DateTime(
    year,
    month,
    day,
    from.hour,
    from.minute,
    from.second,
    from.millisecond,
    from.microsecond,
  );
}

DateTime _addYearsClamped(DateTime from, int yearsToAdd) {
  final year = from.year + yearsToAdd;
  final month = from.month;
  final day = _clampDay(year: year, month: month, day: from.day);

  return DateTime(
    year,
    month,
    day,
    from.hour,
    from.minute,
    from.second,
    from.millisecond,
    from.microsecond,
  );
}

int _clampDay({required int year, required int month, required int day}) {
  final lastDayOfMonth = DateTime(year, month + 1, 0).day;
  if (day <= lastDayOfMonth) return day;
  return lastDayOfMonth;
}

/// Generates all occurrences of an interval schedule within a given month.
///
/// Returns a list of DateTime occurrences that fall within [startOfMonth, endOfMonth].
/// For one-time schedules, returns empty list if not in the month, or single item if it is.
/// For interval schedules, generates all occurrences starting from the schedule's
/// scheduledDate and continuing until endOfMonth.
List<DateTime> occurrencesInMonth({
  required ScheduledTransaction schedule,
  required DateTime startOfMonth,
  required DateTime endOfMonth,
}) {
  if (schedule.frequency == PaymentFrequency.oneTime) {
    final dateOnly = DateUtils.dateOnly(schedule.scheduledDate);
    final startOnly = DateUtils.dateOnly(startOfMonth);
    final endOnly = DateUtils.dateOnly(endOfMonth);
    if (!dateOnly.isBefore(startOnly) && !dateOnly.isAfter(endOnly)) {
      return [schedule.scheduledDate];
    }
    return [];
  }

  if (schedule.frequency == PaymentFrequency.interval) {
    if (schedule.intervalCount == null || schedule.intervalUnit == null) {
      return [];
    }

    final occurrences = <DateTime>[];
    var current = schedule.scheduledDate;

    // Start from the first occurrence that is >= startOfMonth
    while (current.isBefore(startOfMonth)) {
      current = nextDueDate(
        from: current,
        frequency: PaymentFrequency.interval,
        intervalCount: schedule.intervalCount,
        intervalUnit: schedule.intervalUnit,
      );
    }

    // Generate all occurrences within the month
    while (!current.isAfter(endOfMonth)) {
      occurrences.add(current);
      current = nextDueDate(
        from: current,
        frequency: PaymentFrequency.interval,
        intervalCount: schedule.intervalCount,
        intervalUnit: schedule.intervalUnit,
      );
    }

    return occurrences;
  }

  // Legacy monthly/yearly - generate occurrences for the month
  if (schedule.frequency == PaymentFrequency.monthly ||
      schedule.frequency == PaymentFrequency.yearly) {
    final occurrences = <DateTime>[];
    var current = schedule.scheduledDate;

    // Start from the first occurrence that is >= startOfMonth
    while (current.isBefore(startOfMonth)) {
      current = nextDueDate(
        from: current,
        frequency: schedule.frequency,
      );
    }

    // Generate all occurrences within the month
    while (!current.isAfter(endOfMonth)) {
      occurrences.add(current);
      current = nextDueDate(
        from: current,
        frequency: schedule.frequency,
      );
    }

    return occurrences;
  }

  return [];
}


