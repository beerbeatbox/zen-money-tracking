import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/router/app_router.dart';
import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/presentation/controllers/categories_controller.dart';
import 'package:anti/features/categories/presentation/widgets/category_name_with_emoji.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/screens/dashboard/widgets/dashboard_logs_states.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.log});

  final ExpenseLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountLabel = formatCurrencySigned(log.amount);
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

    return OutlinedSurface(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: _CategoryLabelWithEmojiBaseline(
                        label: log.category,
                        emoji: emoji,
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
                const SizedBox(height: 6),
                _LogMetaRow(log: log),
              ],
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

class _CategoryLabelWithEmojiBaseline extends StatelessWidget {
  const _CategoryLabelWithEmojiBaseline({
    required this.label,
    required this.emoji,
  });

  final String label;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    final normalizedEmoji = (emoji ?? '').trim();
    const labelStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: Colors.black,
      letterSpacing: 0.2,
    );

    if (normalizedEmoji.isEmpty) {
      return Text(
        label,
        style: labelStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

    // Use Text.rich so the widget participates in baseline alignment within the Row.
    final emojiFontSize = (labelStyle.fontSize! + 6).clamp(18, 28).toDouble();
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: normalizedEmoji,
            style: labelStyle.copyWith(fontSize: emojiFontSize),
          ),
          const WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: SizedBox(width: 8),
          ),
          TextSpan(text: label, style: labelStyle),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
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
