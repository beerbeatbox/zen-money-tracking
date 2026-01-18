import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/widgets/section_card.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:anti/features/home/presentation/utils/scheduled_payment_validation.dart';
import 'package:anti/features/home/presentation/widgets/number_keyboard_bottom_sheet.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddScheduledTransactionScreen extends ConsumerStatefulWidget {
  const AddScheduledTransactionScreen({super.key, this.initial});

  final ScheduledTransaction? initial;

  @override
  ConsumerState<AddScheduledTransactionScreen> createState() =>
      _AddScheduledTransactionScreenState();
}

class _AddScheduledTransactionScreenState
    extends ConsumerState<AddScheduledTransactionScreen> {
  late PaymentFrequency _frequency;
  late bool _isActive;
  bool _isDynamicAmount = false;
  double? _budgetAmount;

  ScheduledTransaction? get _initial => widget.initial;

  bool get _isEditing => _initial != null;

  @override
  void initState() {
    super.initState();
    _frequency = _initial?.frequency ?? PaymentFrequency.oneTime;
    _isActive = _initial?.isActive ?? true;
    _isDynamicAmount = _initial?.isDynamicAmount ?? false;
    _budgetAmount = _initial?.budgetAmount;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = _isEditing;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(
              title: isEditing ? 'EDIT SCHEDULED PAYMENT' : 'SCHEDULE A PAYMENT',
              subtitle:
                  isEditing
                      ? 'Update amount, time, or category'
                      : 'Pick an amount, a type, and a date',
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 2, color: Colors.black),
            const SizedBox(height: 24),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set a one-time payment or a subscription, then save it in seconds.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _FrequencySection(
                    value: _frequency,
                    onChanged: (next) => setState(() => _frequency = next),
                  ),
                  if (isEditing && _frequency != PaymentFrequency.oneTime) ...[
                    const SizedBox(height: 16),
                    _ActiveSubscriptionToggle(
                      value: _isActive,
                      onChanged: (value) => setState(() => _isActive = value),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedActionButton(
              label: isEditing ? 'Edit payment' : 'Schedule payment',
              onPressed: () => _openSheet(context),
              textColor: Colors.black,
              borderColor: Colors.black,
              backgroundColor: Colors.white,
            ),
            const Spacer(),
            OutlinedActionButton(
              label: isEditing ? 'Save changes' : 'Done',
              onPressed: () => _onDone(context),
              textColor: Colors.black,
              borderColor: Colors.black,
              backgroundColor: Colors.white,
            ),
          ],
        ).paddingAll(24.0),
      ),
    );
  }

  Future<void> _onDone(BuildContext context) async {
    final initial = _initial;
    if (initial == null) {
      context.pop();
      return;
    }

    final didChangeFrequency = _frequency != initial.frequency;
    final didChangeActive = _isActive != initial.isActive;
    if (!didChangeFrequency && !didChangeActive) {
      context.pop();
      return;
    }

    try {
      final updated = initial.copyWith(
        frequency: _frequency,
        isActive: _isActive,
      );
      await ref.read(updateScheduledTransactionActionProvider(updated).future);
      if (!context.mounted) return;
      context.pop();
    } catch (_) {
      if (!context.mounted) return;
      _showSnack(context, "Let's try that again.");
    }
  }

  Future<void> _openSheet(BuildContext context) async {
    var didSave = false;
    final initial = _initial;

    await showNumberKeyboardBottomSheet(
      context,
      initialIsExpense: true,
      initialValue:
          initial == null
              ? null
              : _formatInitialAmount(
                  (_isDynamicAmount && _budgetAmount != null)
                      ? _budgetAmount!.abs()
                      : initial.amount.abs(),
                ),
      initialLogDateTime: initial?.scheduledDate,
      initialCategory: initial?.category,
      showFrequencyChips: true,
      initialFrequency: _frequency,
      initialIntervalCount: initial?.intervalCount,
      initialIntervalUnit: initial?.intervalUnit,
      initialIsDynamicAmount: _isDynamicAmount,
      initialBudgetAmount: _budgetAmount,
      onDynamicAmountChanged: (value) {
        setState(() {
          _isDynamicAmount = value;
        });
      },
      onBudgetAmountChanged: (value) {
        setState(() {
          _budgetAmount = value;
        });
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
          isActive: initial?.isActive ?? _isActive,
          remindDaysBefore: initial?.remindDaysBefore ?? 0,
          isDynamicAmount: isDynamicAmount,
          budgetAmount: budgetAmount,
        );

        try {
          if (initial == null) {
            await ref.read(addScheduledTransactionActionProvider(item).future);
          } else {
            await ref.read(updateScheduledTransactionActionProvider(item).future);
          }
          didSave = true;
          return true;
        } catch (_) {
          if (!sheetContext.mounted) return false;
          _showSnack(sheetContext, "Let's try that again.");
          return false;
        }
      },
    );

    if (!context.mounted) return;
    if (didSave) context.pop();
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          tooltip: 'Back',
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FrequencySection extends StatelessWidget {
  const _FrequencySection({required this.value, required this.onChanged});

  final PaymentFrequency value;
  final ValueChanged<PaymentFrequency> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ChoiceChip(
              label: 'One-time',
              selected: value == PaymentFrequency.oneTime,
              onTap: () => onChanged(PaymentFrequency.oneTime),
            ),
            _ChoiceChip(
              label: 'Monthly',
              selected: value == PaymentFrequency.monthly,
              onTap: () => onChanged(PaymentFrequency.monthly),
            ),
            _ChoiceChip(
              label: 'Yearly',
              selected: value == PaymentFrequency.yearly,
              onTap: () => onChanged(PaymentFrequency.yearly),
            ),
          ],
        ),
      ],
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
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

class _ActiveSubscriptionToggle extends StatelessWidget {
  const _ActiveSubscriptionToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.10)),
        color: const Color(0xFFF8F8F8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Subscription',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value
                      ? 'Keep it active so it’s ready when it’s due.'
                      : 'Pause it for now. You can turn it back on anytime.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.black,
            inactiveTrackColor: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}


