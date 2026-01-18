import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/router/app_router.dart';
import 'package:anti/core/widgets/section_card.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:anti/features/home/presentation/utils/scheduled_payment_validation.dart';
import 'package:anti/features/home/presentation/widgets/number_keyboard_bottom_sheet.dart';
import 'package:anti/features/home/presentation/widgets/scheduled_transaction_search_box.dart';
import 'package:anti/features/home/presentation/widgets/scheduled_transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

enum _ScheduledPaymentsFilter { all, oneTime, days, weeks, months, years }

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
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(onAdd: () => _openScheduleSheet(context, ref)),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              SectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ScheduledTransactionSearchBox(
                      onTap:
                          () => context.push(
                            AppRouter.scheduledTransactionsSearch.path,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _FilterChips(
                      value: filter,
                      onChanged:
                          (next) => setState(() {
                            _filter = next;
                          }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: itemsAsync.when(
                  data: (items) {
                    final filtered = _applyFilter(items, filter);
                    return _Content(
                      filter: filter,
                      items: filtered,
                      onEdit:
                          (item) => context.push(
                            AppRouter.scheduledTransactionDetail.path
                                .replaceFirst(':id', item.id),
                            extra: item,
                          ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openScheduleSheet(
    BuildContext context,
    WidgetRef ref, {
    ScheduledTransaction? initial,
  }) async {
    var frequency = initial?.frequency ?? PaymentFrequency.oneTime;
    var intervalCount = initial?.intervalCount;
    var intervalUnit = initial?.intervalUnit;
    var isDynamicAmount = initial?.isDynamicAmount ?? false;
    var budgetAmount = initial?.budgetAmount;

    await showNumberKeyboardBottomSheet(
      context,
      initialIsExpense: true,
      initialValue:
          initial == null
              ? null
              : _formatInitialAmount(
                (isDynamicAmount && budgetAmount != null)
                    ? budgetAmount.abs()
                    : initial.amount.abs(),
              ),
      initialLogDateTime: initial?.scheduledDate,
      initialCategory: initial?.category,
      showFrequencyChips: true,
      initialFrequency: frequency,
      initialIntervalCount: intervalCount,
      initialIntervalUnit: intervalUnit,
      initialIsDynamicAmount: isDynamicAmount,
      initialBudgetAmount: budgetAmount,
      onFrequencyChanged: (next) => frequency = next,
      onIntervalChanged: (interval) {
        intervalCount = interval.$1;
        intervalUnit = interval.$2;
      },
      onDynamicAmountChanged: (value) => isDynamicAmount = value,
      onBudgetAmountChanged: (value) => budgetAmount = value,
      onSubmit: (
        sheetContext,
        rawValue,
        isExpense,
        logDateTime,
        category,
        freq,
        count,
        unit,
        isDynamicAmount,
        budgetAmount,
      ) async {
        final result = parseAndValidateScheduledPayment(
          rawValue: rawValue,
          isExpense: isExpense,
          scheduledDateTime: logDateTime,
          // Allow creating due/overdue scheduled items (past or current time).
          requireFutureDate: false,
        );
        if (result.error != null) {
          _showSnack(sheetContext, result.error!);
          return false;
        }

        final amount = -result.amount!.abs();
        final now = DateTime.now();
        final item = ScheduledTransaction(
          id: initial?.id ?? now.microsecondsSinceEpoch.toString(),
          title: initial?.title ?? category,
          category: category,
          amount: amount,
          scheduledDate: logDateTime,
          createdAt: initial?.createdAt ?? now,
          frequency: freq,
          intervalCount: count,
          intervalUnit: unit,
          isActive: initial?.isActive ?? true,
          remindDaysBefore: initial?.remindDaysBefore ?? 0,
          isDynamicAmount: isDynamicAmount,
          budgetAmount: budgetAmount,
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
    case _ScheduledPaymentsFilter.oneTime:
      return items
          .where((e) => e.frequency == PaymentFrequency.oneTime)
          .toList(growable: false);
    case _ScheduledPaymentsFilter.days:
      return items
          .where(
            (e) =>
                e.frequency == PaymentFrequency.interval &&
                e.intervalUnit == IntervalUnit.days,
          )
          .toList(growable: false);
    case _ScheduledPaymentsFilter.weeks:
      return items
          .where(
            (e) =>
                e.frequency == PaymentFrequency.interval &&
                e.intervalUnit == IntervalUnit.weeks,
          )
          .toList(growable: false);
    case _ScheduledPaymentsFilter.months:
      return items
          .where(
            (e) =>
                e.frequency == PaymentFrequency.interval &&
                e.intervalUnit == IntervalUnit.months,
          )
          .toList(growable: false);
    case _ScheduledPaymentsFilter.years:
      return items
          .where(
            (e) =>
                e.frequency == PaymentFrequency.interval &&
                e.intervalUnit == IntervalUnit.years,
          )
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
              'Scheduled payments',
              style: TextStyle(
                fontSize: 24,
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
    required this.onEdit,
  });

  final _ScheduledPaymentsFilter filter;
  final List<ScheduledTransaction> items;
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
          padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
          child: ScheduledTransactionTile(
            item: item,
            onEdit: () => onEdit(item),
            showRecurrenceBadges: true,
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
      _ScheduledPaymentsFilter.all => 'Start planning your payments.',
      _ScheduledPaymentsFilter.oneTime =>
        'Schedule a payment to plan ahead with confidence.',
      _ScheduledPaymentsFilter.days =>
        'Add a daily recurring payment to track regular expenses.',
      _ScheduledPaymentsFilter.weeks =>
        'Add a weekly recurring payment to keep your bills on track.',
      _ScheduledPaymentsFilter.months =>
        'Add a monthly recurring payment to plan ahead with confidence.',
      _ScheduledPaymentsFilter.years =>
        'Schedule a yearly recurring payment to plan ahead with confidence.',
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
          label: 'One-time',
          selected: value == _ScheduledPaymentsFilter.oneTime,
          onTap: () => onChanged(_ScheduledPaymentsFilter.oneTime),
        ),
        _FilterChip(
          label: 'Days',
          selected: value == _ScheduledPaymentsFilter.days,
          onTap: () => onChanged(_ScheduledPaymentsFilter.days),
        ),
        _FilterChip(
          label: 'Weeks',
          selected: value == _ScheduledPaymentsFilter.weeks,
          onTap: () => onChanged(_ScheduledPaymentsFilter.weeks),
        ),
        _FilterChip(
          label: 'Months',
          selected: value == _ScheduledPaymentsFilter.months,
          onTap: () => onChanged(_ScheduledPaymentsFilter.months),
        ),
        _FilterChip(
          label: 'Years',
          selected: value == _ScheduledPaymentsFilter.years,
          onTap: () => onChanged(_ScheduledPaymentsFilter.years),
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
