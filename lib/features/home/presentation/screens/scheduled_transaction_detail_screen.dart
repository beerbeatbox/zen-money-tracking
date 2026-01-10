import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/presentation/controllers/categories_controller.dart';
import 'package:anti/features/categories/presentation/widgets/category_name_with_emoji.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:anti/features/home/presentation/utils/scheduled_payment_validation.dart';
import 'package:anti/features/home/presentation/widgets/number_keyboard_bottom_sheet.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:anti/features/settings/presentation/widgets/outlined_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ScheduledTransactionDetailScreen extends ConsumerWidget {
  const ScheduledTransactionDetailScreen({
    super.key,
    required this.scheduledId,
    this.item,
  });

  final String scheduledId;
  final ScheduledTransaction? item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(scheduledTransactionsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 64,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            padding: EdgeInsets.zero,
            splashRadius: 20,
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
        ),
        title: const Text(
          'Scheduled payment',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: itemsAsync.when(
          data: (items) {
            final resolved = _resolveItem(items);
            if (resolved == null) {
              return _MissingItemState(
                onBack: () => context.pop(),
                onRetry: () => ref.invalidate(scheduledTransactionsProvider),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ScheduledDetailCard(item: resolved),
                  const SizedBox(height: 16),
                  _ScheduledActionsRow(item: resolved),
                ],
              ),
            );
          },
          loading: () => const _LoadingState(),
          error:
              (_, __) => _ErrorState(
                onBack: () => context.pop(),
                onRetry: () => ref.invalidate(scheduledTransactionsProvider),
              ),
        ),
      ),
    );
  }

  ScheduledTransaction? _resolveItem(List<ScheduledTransaction> items) {
    for (final it in items) {
      if (it.id == scheduledId) return it;
    }
    return item;
  }
}

class _ScheduledDetailCard extends ConsumerWidget {
  const _ScheduledDetailCard({required this.item});

  final ScheduledTransaction item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountLabel = formatCurrencySigned(item.amount);
    final dateLabel = formatDateLabel(item.scheduledDate);
    final timeLabel = formatTimeHm(item.scheduledDate);
    final frequencyLabel = _frequencyLabel(
      item.frequency,
      item.intervalCount,
      item.intervalUnit,
    );
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

    return OutlinedSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryNameWithEmoji(
            label: item.category,
            emoji: emoji,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            amountLabel,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          _MetaRow(
            label: 'Category',
            value: item.category,
            valueWidget: CategoryNameWithEmoji(
              label: item.category,
              emoji: emoji,
              spacing: 6,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
                color: Colors.black,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MetaRow(label: 'When', value: '$timeLabel • $dateLabel'),
          const SizedBox(height: 12),
          _MetaRow(label: 'Frequency', value: frequencyLabel),
          const SizedBox(height: 12),
          _MetaRow(label: 'Status', value: item.isActive ? 'Active' : 'Paused'),
          const SizedBox(height: 12),
          _MetaRow(label: 'Schedule ID', value: item.id),
        ],
      ),
    );
  }

  String _frequencyLabel(
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
          return 'Recurring';
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
}

class _ScheduledActionsRow extends ConsumerWidget {
  const _ScheduledActionsRow({required this.item});

  final ScheduledTransaction item;

  String _formatInitialAmount(double value) {
    final asInt = value.toInt();
    if (value == asInt) return asInt.toString();
    return value.toStringAsFixed(2);
  }

  Future<void> _openEditSheet(BuildContext context, WidgetRef ref) async {
    var frequency = item.frequency;
    var intervalCount = item.intervalCount;
    var intervalUnit = item.intervalUnit;

    await showNumberKeyboardBottomSheet(
      context,
      initialIsExpense: true,
      initialValue: _formatInitialAmount(item.amount.abs()),
      initialLogDateTime: item.scheduledDate,
      initialCategory: item.category,
      showFrequencyChips: true,
      initialFrequency: frequency,
      initialIntervalCount: intervalCount,
      initialIntervalUnit: intervalUnit,
      onFrequencyChanged: (next) => frequency = next,
      onIntervalChanged: (interval) {
        intervalCount = interval.$1;
        intervalUnit = interval.$2;
      },
      onSubmit: (
        sheetContext,
        rawValue,
        isExpense,
        logDateTime,
        category,
        freq,
        count,
        unit,
      ) async {
        final result = parseAndValidateScheduledPayment(
          rawValue: rawValue,
          isExpense: isExpense,
          scheduledDateTime: logDateTime,
          // Detail edit should allow editing overdue/due items.
          requireFutureDate: false,
        );
        if (result.error != null) {
          _showSnack(sheetContext, result.error!);
          return false;
        }

        final updated = item.copyWith(
          amount: -result.amount!.abs(),
          category: category,
          scheduledDate: logDateTime,
          frequency: freq,
          intervalCount: count,
          intervalUnit: unit,
        );

        try {
          await ref.read(
            updateScheduledTransactionActionProvider(updated).future,
          );
          return true;
        } catch (_) {
          if (!sheetContext.mounted) return false;
          _showSnack(sheetContext, "Let's try that again.");
          return false;
        }
      },
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => OutlinedConfirmationDialog(
            title: 'Remove this scheduled payment?',
            description: 'You can schedule it again anytime.',
            primaryLabel: 'Remove payment',
            onPrimaryPressed: () => Navigator.of(ctx).pop(true),
            secondaryLabel: 'Keep it',
            onSecondaryPressed: () => Navigator.of(ctx).pop(false),
          ),
    );

    if (shouldDelete != true) return;

    try {
      await ref.read(deleteScheduledTransactionActionProvider(item.id).future);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Scheduled payment removed.'),
        ),
      );
      context.pop();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Let's try that again."),
        ),
      );
    }
  }

  String _getDueDateStatusMessage(DateTime scheduledDate, DateTime now) {
    final today = DateUtils.dateOnly(now);
    final scheduledDay = DateUtils.dateOnly(scheduledDate);

    if (scheduledDay.isBefore(today)) {
      return 'This payment is overdue. Mark it as paid?';
    } else if (scheduledDay == today) {
      return 'Mark this payment as paid?';
    } else {
      final dateLabel = formatDateLabel(scheduledDate);
      return 'This payment is scheduled for $dateLabel. Mark it as paid now?';
    }
  }

  Future<void> _showMarkAsPaidConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final now = DateTime.now();
    final description = _getDueDateStatusMessage(item.scheduledDate, now);

    final shouldMarkAsPaid = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => OutlinedConfirmationDialog(
        title: 'Mark as paid?',
        description: description,
        primaryLabel: 'Mark as paid',
        onPrimaryPressed: () => Navigator.of(ctx).pop(true),
        secondaryLabel: 'Cancel',
        onSecondaryPressed: () => Navigator.of(ctx).pop(false),
      ),
    );

    if (shouldMarkAsPaid != true) return;

    await _handleMarkAsPaid(context, ref);
  }

  Future<void> _handleMarkAsPaid(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(
        convertScheduledTransactionToLogActionProvider(item).future,
      );
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Added to your logs.'),
          duration: Duration(seconds: 2),
        ),
      );
      // For one-time payments the item is deleted after conversion,
      // so navigate back; recurring items stay and refresh automatically.
      if (!context.mounted) return;
      if (item.frequency == PaymentFrequency.oneTime) {
        context.pop();
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Let's try that again."),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final markAsPaidLabel = !item.isActive ? 'Paused' : 'Mark as paid';

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedActionButton(
                label: markAsPaidLabel,
                onPressed: !item.isActive
                    ? null
                    : () => _showMarkAsPaidConfirmation(context, ref),
                textColor: Colors.white,
                borderColor: Colors.black,
                backgroundColor: Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedActionButton(
                label: 'Edit',
                onPressed: () => _openEditSheet(context, ref),
                textColor: Colors.black,
                borderColor: Colors.black,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedActionButton(
                label: 'Delete',
                onPressed: () => _handleDelete(context, ref),
                textColor: Colors.white,
                borderColor: Colors.black,
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value, this.valueWidget});

  final String label;
  final String value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.black,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: Alignment.centerRight,
            child:
                valueWidget ??
                Text(
                  value,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Colors.black,
                  ),
                ),
          ),
        ),
      ],
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onBack, required this.onRetry});

  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Let's try that again.",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Reload scheduled payments',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onBack,
              child: const Text(
                'Back to dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissingItemState extends StatelessWidget {
  const _MissingItemState({required this.onBack, required this.onRetry});

  final VoidCallback onBack;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "We couldn't find that scheduled payment right now.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Refresh to load your latest schedule.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Reload scheduled payments',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onBack,
              child: const Text(
                'Back to dashboard',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
