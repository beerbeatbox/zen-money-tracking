import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/presentation/controllers/categories_controller.dart';
import 'package:anti/features/categories/presentation/widgets/category_name_with_emoji.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:anti/features/home/presentation/widgets/transaction_list_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ScheduledTransactionTile extends ConsumerWidget {
  const ScheduledTransactionTile({
    super.key,
    required this.item,
    required this.onEdit,
    this.onConvert,
    this.onDelete,
    this.showActionButtons = false,
    this.showStatusLabel = false,
    this.showRecurrenceBadges = false,
    this.now,
  });

  final ScheduledTransaction item;
  final VoidCallback? onConvert;
  final VoidCallback? onDelete;
  final VoidCallback onEdit;

  /// When true, shows "Mark as paid" and "Remove" buttons on the tile.
  final bool showActionButtons;

  /// When true, shows "Overdue/Due today/Due in X days" before date/time.
  final bool showStatusLabel;

  /// When true, shows frequency badges (and "Paused" badge if inactive).
  final bool showRecurrenceBadges;

  /// Optional injection point for testing.
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = this.now ?? DateTime.now();

    final dateLabel = formatDateLabel(item.scheduledDate);
    final timeLabel = formatTimeHm(item.scheduledDate);
    // Use budgetAmount for dynamic scheduled transactions, amount for fixed
    final amountToDisplay =
        item.isDynamicAmount
            ? (item.budgetAmount ?? item.amount.abs())
            : item.amount.abs();
    final amountValue = item.isDynamicAmount ? -amountToDisplay : item.amount;

    final subtitle =
        showStatusLabel
            ? '${_statusLabel(item.scheduledDate, now: now)} • ${item.category} • $dateLabel • $timeLabel'
            : '${item.category} • $dateLabel • $timeLabel';

    final primaryLabel = !item.isActive ? 'Paused' : 'Mark as paid';
    final categories = ref
        .watch(categoriesControllerProvider)
        .maybeWhen(data: (value) => value, orElse: () => null);
    final type = item.amount >= 0 ? CategoryType.income : CategoryType.expense;
    final emoji =
        categories == null
            ? null
            : resolveCategoryEmoji(
              label: item.category,
              categories: categories,
              type: type,
            );

    final shouldShowBadges = showRecurrenceBadges;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TransactionListItem(
          title: item.category,
          subtitle: subtitle,
          amount: amountValue,
          emoji: emoji,
          onTap: onEdit,
        ),
        if (shouldShowBadges) ...[
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Text(
              _buildBadgeText(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
        if (showActionButtons) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedActionButton(
                  label: primaryLabel,
                  onPressed: !item.isActive ? null : onConvert,
                  textColor: Colors.black,
                  borderColor: Colors.black,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedActionButton(
                  label: 'Remove',
                  onPressed: onDelete,
                  textColor: Colors.red,
                  borderColor: Colors.red,
                  backgroundColor: const Color(0xFFFDEBEB),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _statusLabel(DateTime scheduledDate, {required DateTime now}) {
    final today = DateUtils.dateOnly(now);
    final scheduledDay = DateUtils.dateOnly(scheduledDate);

    if (!scheduledDate.isAfter(now) && scheduledDay.isBefore(today))
      return 'Overdue';
    if (scheduledDay == today) return 'Due today';

    final daysUntil = scheduledDay.difference(today).inDays;
    if (daysUntil == 1) return 'Due in 1 day';
    return 'Due in $daysUntil days';
  }

  String _buildBadgeText() {
    final badges = <String>[];

    badges.add(
      _recurrenceLabel(item.frequency, item.intervalCount, item.intervalUnit),
    );

    if (item.isDynamicAmount) {
      badges.add('Dynamic');
    }

    if (!item.isActive) {
      badges.add('Paused');
    }

    return badges.join(' • ');
  }
}

String _recurrenceLabel(
  PaymentFrequency frequency,
  int? intervalCount,
  IntervalUnit? intervalUnit,
) {
  switch (frequency) {
    case PaymentFrequency.oneTime:
      return 'One-time';
    case PaymentFrequency.monthly:
      return 'Monthly';
    case PaymentFrequency.yearly:
      return 'Yearly';
    case PaymentFrequency.interval:
      if (intervalCount == null || intervalUnit == null) {
        // Some legacy/migrated schedules can end up with `interval` frequency
        // but no interval payload. Treat as one-time for display.
        return (intervalCount == null && intervalUnit == null)
            ? 'One-time'
            : 'Recurring';
      }
      final unitLabel = switch (intervalUnit) {
        IntervalUnit.days => intervalCount == 1 ? 'day' : 'days',
        IntervalUnit.weeks => intervalCount == 1 ? 'week' : 'weeks',
        IntervalUnit.months => intervalCount == 1 ? 'month' : 'months',
        IntervalUnit.years => intervalCount == 1 ? 'year' : 'years',
      };
      return 'Every $intervalCount $unitLabel';
  }
}
