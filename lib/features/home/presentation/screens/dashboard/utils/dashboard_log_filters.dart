import 'package:anti/features/home/domain/entities/expense_log.dart';

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


