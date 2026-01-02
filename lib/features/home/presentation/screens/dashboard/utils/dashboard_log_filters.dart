import 'package:anti/features/home/domain/entities/expense_log.dart';

List<ExpenseLog> filterLogsByMonth(List<ExpenseLog> logs, DateTime month) {
  return logs
      .where(
        (log) => log.createdAt.year == month.year && log.createdAt.month == month.month,
      )
      .toList(growable: false);
}


