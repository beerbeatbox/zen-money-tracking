import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'insight_month_controller.g.dart';

@immutable
class InsightMonth {
  const InsightMonth({
    required this.selectedMonth,
    required this.monthYearLabel,
    required this.logs,
  });

  final DateTime selectedMonth;
  final String monthYearLabel;
  final List<ExpenseLog> logs;
}

@riverpod
class InsightMonthController extends _$InsightMonthController {
  @override
  FutureOr<InsightMonth> build(DateTime selectedMonth) async {
    ref.watch(expenseLogsProvider);
    final allLogs = await ref.read(expenseLogsProvider.future);

    final sortedLogs = [...allLogs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final monthYearLabel = formatMonthYearLabel(selectedMonth);
    final scopedLogs = filterLogsByMonth(sortedLogs, selectedMonth);

    return InsightMonth(
      selectedMonth: selectedMonth,
      monthYearLabel: monthYearLabel,
      logs: scopedLogs,
    );
  }
}
