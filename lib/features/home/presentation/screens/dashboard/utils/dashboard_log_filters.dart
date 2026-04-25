import 'package:anti/features/home/domain/entities/expense_log.dart';

/// Local calendar Monday 00:00:00 of the week containing [d] (same convention as [DateTime.monday]).
DateTime startOfLocalWeekMonday(DateTime d) {
  final day = DateTime(d.year, d.month, d.day);
  return day.subtract(Duration(days: day.weekday - DateTime.monday));
}

/// Local date (date-only) for the Sunday that ends the week that starts on [anyDayInWeek]'s Monday.
DateTime endOfLocalWeekSunday(DateTime anyDayInWeek) {
  return startOfLocalWeekMonday(anyDayInWeek).add(const Duration(days: 6));
}

/// Inclusive of Monday 00:00, exclusive of next Monday 00:00.
List<ExpenseLog> filterLogsInLocalWeek(
  List<ExpenseLog> logs,
  DateTime anyDayInWeek,
) {
  final start = startOfLocalWeekMonday(anyDayInWeek);
  final endExclusive = start.add(const Duration(days: 7));
  return logs
      .where(
        (log) => !log.createdAt.isBefore(start) && log.createdAt.isBefore(endExclusive),
      )
      .toList(growable: false);
}

List<ExpenseLog> filterLogsByMonth(List<ExpenseLog> logs, DateTime month) {
  return logs
      .where(
        (log) => log.createdAt.year == month.year && log.createdAt.month == month.month,
      )
      .toList(growable: false);
}

List<ExpenseLog> filterLogsByDay(List<ExpenseLog> logs, DateTime day) {
  return logs
      .where(
        (log) =>
            log.createdAt.year == day.year &&
            log.createdAt.month == day.month &&
            log.createdAt.day == day.day,
      )
      .toList(growable: false);
}


