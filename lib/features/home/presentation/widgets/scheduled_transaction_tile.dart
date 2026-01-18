import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/presentation/controllers/categories_controller.dart';
import 'package:anti/features/categories/presentation/widgets/category_name_with_emoji.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
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
    final amountLabel =
        item.isDynamicAmount
            ? formatCurrencySigned(-amountToDisplay)
            : formatCurrencySigned(item.amount);

    final subtitle =
        showStatusLabel
            ? '${_statusLabel(item.scheduledDate, now: now)} • $dateLabel • $timeLabel'
            : '$dateLabel • $timeLabel';

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

    return OutlinedSurface(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Expanded(
                child: _CategoryLabelWithEmojiBaseline(
                  label: item.category,
                  emoji: emoji,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                amountLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          if (shouldShowBadges) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _Badge(
                  label: _recurrenceLabel(
                    item.frequency,
                    item.intervalCount,
                    item.intervalUnit,
                  ),
                ),
                if (item.isDynamicAmount)
                  const _Badge(
                    label: 'Dynamic',
                    backgroundColor: Color(0xFFE8F4FD),
                  ),
                if (!item.isActive)
                  const _Badge(
                    label: 'Paused',
                    backgroundColor: Color(0xFFF4F4F4),
                  ),
              ],
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
      ),
    ).onTap(onTap: onEdit);
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
      letterSpacing: 0.2,
      color: Colors.black,
    );

    if (normalizedEmoji.isEmpty) {
      return Text(
        label,
        style: labelStyle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

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

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    this.backgroundColor = const Color(0xFFF2F2F2),
  });

  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
          color: Colors.black,
        ),
      ),
    );
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
