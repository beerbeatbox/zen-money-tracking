import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:anti/features/home/presentation/widgets/number_keyboard_bottom_sheet.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:anti/features/settings/presentation/widgets/outlined_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';

enum _ScheduledPaymentsFilter { all, monthly, yearly, oneTime }

class ScheduledTransactionsScreen extends ConsumerStatefulWidget {
  const ScheduledTransactionsScreen({super.key});

  @override
  ConsumerState<ScheduledTransactionsScreen> createState() =>
      _ScheduledTransactionsScreenState();
}

class _ScheduledTransactionsScreenState
    extends ConsumerState<ScheduledTransactionsScreen> {
  var _filter = _ScheduledPaymentsFilter.all;

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(scheduledTransactionsProvider);
    final filter = _filter;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onAdd: () => _openScheduleSheet(context, ref)),
              const SizedBox(height: 16),
              const Divider(thickness: 2, color: Colors.black),
              const SizedBox(height: 24),
              _FilterChips(
                value: filter,
                onChanged:
                    (next) => setState(() {
                      _filter = next;
                    }),
              ),
              const SizedBox(height: 16),
              itemsAsync.when(
                data: (items) {
                  final filtered = _applyFilter(items, filter);
                  return _Content(
                    filter: filter,
                    items: filtered,
                    onConvert: (item) => _convert(context, ref, item),
                    onDelete: (item) => _confirmAndDelete(context, ref, item),
                    onEdit:
                        (item) =>
                            _openScheduleSheet(context, ref, initial: item),
                  );
                },
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      ),
                    ),
                error:
                    (_, __) => _ErrorState(
                      onRetry:
                          () => ref.invalidate(scheduledTransactionsProvider),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    ScheduledTransaction item,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return OutlinedConfirmationDialog(
          title: 'Remove this scheduled payment?',
          description: 'You can schedule it again anytime.',
          primaryLabel: 'Remove payment',
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
          secondaryLabel: 'Keep it',
          onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );

    if (shouldDelete != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(deleteScheduledTransactionActionProvider(item.id).future);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Scheduled payment removed.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Let's try that again."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _convert(
    BuildContext context,
    WidgetRef ref,
    ScheduledTransaction item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await ref.read(
        convertScheduledTransactionToLogActionProvider(item).future,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Added to your logs.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Let's try that again."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _openScheduleSheet(
    BuildContext context,
    WidgetRef ref, {
    ScheduledTransaction? initial,
  }) async {
    var frequency = initial?.frequency ?? PaymentFrequency.oneTime;

    await showNumberKeyboardBottomSheet(
      context,
      initialIsExpense: true,
      initialValue:
          initial == null ? null : _formatInitialAmount(initial.amount.abs()),
      initialLogDateTime: initial?.scheduledDate,
      initialCategory: initial?.category,
      showFrequencyChips: true,
      initialFrequency: frequency,
      onFrequencyChanged: (next) => frequency = next,
      onSubmit: (
        sheetContext,
        rawValue,
        isExpense,
        logDateTime,
        category,
      ) async {
        final parsed = double.tryParse(rawValue);
        if (parsed == null) {
          _showSnack(sheetContext, 'Please enter a valid number.');
          return false;
        }
        if (parsed <= 0) {
          _showSnack(
            sheetContext,
            'Add an amount above zero to schedule a payment.',
          );
          return false;
        }
        if (!logDateTime.isAfter(DateTime.now())) {
          _showSnack(
            sheetContext,
            'Pick a future date to schedule this payment.',
          );
          return false;
        }
        if (!isExpense) {
          _showSnack(
            sheetContext,
            'Scheduled payments are expenses. Switch to Expense to continue.',
          );
          return false;
        }

        final amount = -parsed.abs();
        final now = DateTime.now();
        final item = ScheduledTransaction(
          id: initial?.id ?? now.microsecondsSinceEpoch.toString(),
          title: initial?.title ?? category,
          category: category,
          amount: amount,
          scheduledDate: logDateTime,
          createdAt: initial?.createdAt ?? now,
          frequency: frequency,
          isActive: initial?.isActive ?? true,
          remindDaysBefore: initial?.remindDaysBefore ?? 0,
        );

        try {
          if (initial == null) {
            await ref.read(addScheduledTransactionActionProvider(item).future);
          } else {
            await ref.read(
              updateScheduledTransactionActionProvider(item).future,
            );
          }
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatInitialAmount(double value) {
    final asInt = value.toInt();
    if (value == asInt) return asInt.toString();
    return value.toStringAsFixed(2);
  }
}

List<ScheduledTransaction> _applyFilter(
  List<ScheduledTransaction> items,
  _ScheduledPaymentsFilter filter,
) {
  switch (filter) {
    case _ScheduledPaymentsFilter.all:
      return items;
    case _ScheduledPaymentsFilter.monthly:
      return items
          .where((e) => e.frequency == PaymentFrequency.monthly)
          .toList(growable: false);
    case _ScheduledPaymentsFilter.yearly:
      return items
          .where((e) => e.frequency == PaymentFrequency.yearly)
          .toList(growable: false);
    case _ScheduledPaymentsFilter.oneTime:
      return items
          .where((e) => e.frequency == PaymentFrequency.oneTime)
          .toList(growable: false);
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SCHEDULED PAYMENTS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Plan upcoming payments in advance',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onAdd,
          icon: const HeroIcon(
            HeroIcons.plus,
            style: HeroIconStyle.outline,
            color: Colors.black,
            size: 22,
          ),
          tooltip: 'Add payment',
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.filter,
    required this.items,
    required this.onConvert,
    required this.onDelete,
    required this.onEdit,
  });

  final _ScheduledPaymentsFilter filter;
  final List<ScheduledTransaction> items;
  final Future<void> Function(ScheduledTransaction item) onConvert;
  final Future<void> Function(ScheduledTransaction item) onDelete;
  final Future<void> Function(ScheduledTransaction item) onEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(filter: filter);
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
          child: _ScheduledTransactionTile(
            item: item,
            onConvert: () => onConvert(item),
            onDelete: () => onDelete(item),
            onEdit: () => onEdit(item),
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter});

  final _ScheduledPaymentsFilter filter;

  @override
  Widget build(BuildContext context) {
    final message = switch (filter) {
      _ScheduledPaymentsFilter.all => 'Start planning your future payments.',
      _ScheduledPaymentsFilter.monthly =>
        'Add a monthly payment to keep your bills on track.',
      _ScheduledPaymentsFilter.yearly =>
        'Schedule a yearly payment to plan ahead with confidence.',
      _ScheduledPaymentsFilter.oneTime =>
        'Schedule a payment to plan ahead with confidence.',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Let's try that again.",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Reload scheduled payments',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
      ],
    );
  }
}

class _ScheduledTransactionTile extends StatelessWidget {
  const _ScheduledTransactionTile({
    required this.item,
    required this.onConvert,
    required this.onDelete,
    required this.onEdit,
  });

  final ScheduledTransaction item;
  final VoidCallback onConvert;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isDue = !item.scheduledDate.isAfter(now);
    final canConvert = isDue && item.isActive;
    final dateLabel = formatDateLabel(item.scheduledDate);
    final timeLabel = formatTimeHm(item.scheduledDate);
    final amountLabel = formatCurrencySigned(item.amount);
    final recurrenceLabel = _recurrenceLabel(item.frequency);
    final showRecurrence = item.frequency != PaymentFrequency.oneTime;

    return OutlinedSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: Colors.black,
                  ),
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
            '$dateLabel • $timeLabel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          if (showRecurrence || !item.isActive) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (showRecurrence) _Badge(label: recurrenceLabel),
                if (!item.isActive)
                  const _Badge(
                    label: 'Paused',
                    backgroundColor: Color(0xFFF4F4F4),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedActionButton(
                  label:
                      canConvert
                          ? (item.isSubscription
                              ? 'Mark as paid'
                              : 'Add to logs')
                          : (!item.isActive
                              ? 'Paused'
                              : 'Available on schedule'),
                  onPressed: canConvert ? onConvert : null,
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
      ),
    ).onTap(onTap: onEdit);
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});

  final _ScheduledPaymentsFilter value;
  final ValueChanged<_ScheduledPaymentsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'All',
          selected: value == _ScheduledPaymentsFilter.all,
          onTap: () => onChanged(_ScheduledPaymentsFilter.all),
        ),
        _FilterChip(
          label: 'Monthly',
          selected: value == _ScheduledPaymentsFilter.monthly,
          onTap: () => onChanged(_ScheduledPaymentsFilter.monthly),
        ),
        _FilterChip(
          label: 'Yearly',
          selected: value == _ScheduledPaymentsFilter.yearly,
          onTap: () => onChanged(_ScheduledPaymentsFilter.yearly),
        ),
        _FilterChip(
          label: 'One-time',
          selected: value == _ScheduledPaymentsFilter.oneTime,
          onTap: () => onChanged(_ScheduledPaymentsFilter.oneTime),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.black : Colors.white;
    final fg = selected ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    ).onTap(onTap: onTap);
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

String _recurrenceLabel(PaymentFrequency frequency) {
  switch (frequency) {
    case PaymentFrequency.oneTime:
      return 'One-time';
    case PaymentFrequency.monthly:
      return 'Monthly';
    case PaymentFrequency.yearly:
      return 'Yearly';
  }
}
