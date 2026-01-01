import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:anti/features/home/presentation/widgets/number_keyboard_bottom_sheet.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AddScheduledTransactionScreen extends ConsumerWidget {
  const AddScheduledTransactionScreen({super.key, this.initial});

  final ScheduledTransaction? initial;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = initial != null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(
              title: isEditing ? 'EDIT SCHEDULED PAYMENT' : 'SCHEDULE A PAYMENT',
              subtitle:
                  isEditing
                      ? 'Update amount, time, or category'
                      : 'Pick an amount and a future date',
              onBack: () => context.pop(),
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 2, color: Colors.black),
            const SizedBox(height: 24),
            Text(
              'You can use the same quick add sheet you use for logs.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            OutlinedActionButton(
              label: isEditing ? 'Edit payment' : 'Schedule payment',
              onPressed: () => _openSheet(context, ref),
              textColor: Colors.black,
              borderColor: Colors.black,
              backgroundColor: Colors.white,
            ),
            const Spacer(),
            OutlinedActionButton(
              label: 'Done',
              onPressed: () => context.pop(),
              textColor: Colors.black,
              borderColor: Colors.black,
              backgroundColor: Colors.white,
            ),
          ],
        ).paddingAll(24.0),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context, WidgetRef ref) async {
    var didSave = false;

    await showNumberKeyboardBottomSheet(
      context,
      initialIsExpense: (initial?.amount ?? -1) < 0,
      initialValue: initial == null ? null : _formatInitialAmount(initial!.amount.abs()),
      initialLogDateTime: initial?.scheduledDate,
      initialCategory: initial?.category,
      onSubmit: (sheetContext, rawValue, isExpense, logDateTime, category) async {
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

        final amount = isExpense ? -parsed.abs() : parsed.abs();
        final now = DateTime.now();
        final item = ScheduledTransaction(
          id: initial?.id ?? now.microsecondsSinceEpoch.toString(),
          title: initial?.title ?? category,
          category: category,
          amount: amount,
          scheduledDate: logDateTime,
          createdAt: initial?.createdAt ?? now,
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


