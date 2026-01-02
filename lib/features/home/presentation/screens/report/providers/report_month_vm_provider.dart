import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class ReportMonthVm {
  const ReportMonthVm({
    required this.selectedMonth,
    required this.monthYearLabel,
    required this.logs,
  });

  final DateTime selectedMonth;
  final String monthYearLabel;
  final List<ExpenseLog> logs;
}

final reportMonthVmProvider = Provider.family<AsyncValue<ReportMonthVm>, DateTime>(
  (ref, selectedMonth) {
    final logsAsync = ref.watch(expenseLogsProvider).whenData((logs) {
      return [...logs]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });

    return logsAsync.whenData((allLogs) {
      final monthYearLabel = formatMonthYearLabel(selectedMonth);
      final scopedLogs = filterLogsByMonth(allLogs, selectedMonth);

      return ReportMonthVm(
        selectedMonth: selectedMonth,
        monthYearLabel: monthYearLabel,
        logs: scopedLogs,
      );
    });
  },
);


