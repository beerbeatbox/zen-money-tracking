import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';

DateTime nextDueDate({
  required DateTime from,
  required PaymentFrequency frequency,
}) {
  switch (frequency) {
    case PaymentFrequency.oneTime:
      return from;
    case PaymentFrequency.monthly:
      return _addMonthsClamped(from, 1);
    case PaymentFrequency.yearly:
      return _addYearsClamped(from, 1);
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


