import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/router/app_router.dart';
import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/screens/dashboard/widgets/dashboard_logs_states.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardRecentLogsSection extends StatelessWidget {
  const DashboardRecentLogsSection({
    super.key,
    required this.logs,
    required this.itemsLabel,
    required this.monthYearLabel,
    required this.onRetry,
  });

  final List<ExpenseLog> logs;
  final String itemsLabel;
  final String monthYearLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return DashboardEmptyLogs(monthYearLabel: monthYearLabel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.black,
              ),
            ),
            Text(
              itemsLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(thickness: 2, color: Colors.black),
        const SizedBox(height: 12),
        _DatedLogsList(logs: logs),
      ],
    );
  }
}

class _DatedLogsList extends StatelessWidget {
  const _DatedLogsList({required this.logs});

  final List<ExpenseLog> logs;

  @override
  Widget build(BuildContext context) {
    final groupedLogs = _groupLogsByDate(logs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(groupedLogs.length, (groupIndex) {
        final group = groupedLogs[groupIndex];
        final isLastGroup = groupIndex == groupedLogs.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLastGroup ? 0 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _dateLabel(group.date),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: Colors.black,
                    ),
                  ),
                  Text(
                    _calculateDayTotal(group.logs),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...List.generate(group.logs.length, (logIndex) {
                final log = group.logs[logIndex];
                final isLastLog = logIndex == group.logs.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLastLog ? 0 : 10),
                  child: _LogTile(log: log),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  List<_LogGroup> _groupLogsByDate(List<ExpenseLog> logs) {
    final map = <DateTime, List<ExpenseLog>>{};

    for (final log in logs) {
      final dateKey = DateUtils.dateOnly(log.createdAt);
      map.putIfAbsent(dateKey, () => []).add(log);
    }

    final groups =
        map.entries
            .map((entry) => _LogGroup(date: entry.key, logs: entry.value))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return groups;
  }

  String _dateLabel(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final baseLabel = formatDateWithWeekday(date);
    final isToday = date.isAtSameMomentAs(today);
    return isToday ? '$baseLabel (Today)' : baseLabel;
  }

  String _calculateDayTotal(List<ExpenseLog> logs) {
    final total = logs.fold<double>(0.0, (sum, log) => sum + log.amount);
    return formatCurrencySigned(total);
  }
}

class _LogGroup {
  const _LogGroup({required this.date, required this.logs});

  final DateTime date;
  final List<ExpenseLog> logs;
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final ExpenseLog log;

  @override
  Widget build(BuildContext context) {
    final amountLabel = formatCurrencySigned(log.amount);

    return OutlinedSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.category,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                _LogMetaRow(log: log),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountLabel,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: Colors.black,
            ),
          ),
        ],
      ),
    ).onTap(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openLogDetail(context),
    );
  }

  void _openLogDetail(BuildContext context) {
    context.pushNamed(
      AppRouter.expenseLogDetail.name,
      pathParameters: {'id': log.id},
      extra: log,
    );
  }
}

class _LogMetaRow extends StatelessWidget {
  const _LogMetaRow({required this.log});

  final ExpenseLog log;

  @override
  Widget build(BuildContext context) {
    return Text(
      log.timeLabel,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
      ),
    );
  }
}
