import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/router/app_router.dart';
import 'package:baht/core/utils/date_time_formatter.dart';
import 'package:baht/core/utils/formatters.dart';
import 'package:baht/features/categories/domain/entities/category.dart';
import 'package:baht/features/categories/presentation/controllers/categories_controller.dart';
import 'package:baht/features/categories/presentation/widgets/category_name_with_emoji.dart';
import 'package:baht/features/home/domain/entities/expense_log.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_doodle_divider.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_section_header_styles.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_logs_states.dart';
import 'package:baht/features/home/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardRecentLogsSection extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    if (logs.isEmpty) {
      return DashboardEmptyLogs(monthYearLabel: monthYearLabel);
    }
    final isMasked = ref.watch(amountMaskControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Transactions',
              style: DashboardSectionHeaderStyles.titleStyle(color: Colors.black),
            ),
            Text(
              itemsLabel,
              style: DashboardSectionHeaderStyles.subtitleStyle(),
            ),
          ],
        ),
        const SizedBox(height: DashboardSectionHeaderStyles.spacingBelowTitle),
        _DatedLogsList(logs: logs, isMasked: isMasked),
      ],
    );
  }
}

class _DatedLogsList extends StatelessWidget {
  const _DatedLogsList({required this.logs, required this.isMasked});

  final List<ExpenseLog> logs;
  final bool isMasked;

  @override
  Widget build(BuildContext context) {
    final groupedLogs = _groupLogsByDate(logs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(groupedLogs.length, (groupIndex) {
        final group = groupedLogs[groupIndex];
        final isLastGroup = groupIndex == groupedLogs.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLastGroup ? 0 : 40),
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
                    _calculateDayTotal(group.logs, isMasked: isMasked),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const DashboardDoodleDivider.zigzag(color: Colors.black26),
              const SizedBox(height: 10),
              ...List.generate(group.logs.length, (logIndex) {
                final log = group.logs[logIndex];
                final isLastLog = logIndex == group.logs.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLastLog ? 0 : 32),
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

  String _calculateDayTotal(List<ExpenseLog> logs, {required bool isMasked}) {
    final total = logs.fold<double>(0.0, (sum, log) => sum + log.amount);
    return formatCurrencySignedMasked(total, isMasked: isMasked);
  }
}

class _LogGroup {
  const _LogGroup({required this.date, required this.logs});

  final DateTime date;
  final List<ExpenseLog> logs;
}

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.log});

  final ExpenseLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref
        .watch(categoriesControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final type = log.amount >= 0 ? CategoryType.income : CategoryType.expense;
    final emoji =
        categories == null
            ? null
            : resolveCategoryEmoji(
              label: log.category,
              categories: categories,
              type: type,
            );

    return TransactionListItem(
      title: log.category,
      subtitle: log.timeLabel,
      amount: log.amount,
      emoji: emoji,
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
