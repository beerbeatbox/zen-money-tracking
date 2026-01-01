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
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

class ScheduledTransactionsScreen extends ConsumerWidget {
  const ScheduledTransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(scheduledTransactionsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                onBack: () => context.pop(),
                onAdd: () => _openScheduleSheet(context, ref),
              ),
              const SizedBox(height: 16),
              const Divider(thickness: 2, color: Colors.black),
              const SizedBox(height: 24),
              itemsAsync.when(
                data:
                    (items) => _Content(
                      items: items,
                      onConvert: (item) => _convert(context, ref, item),
                      onDelete: (item) => _confirmAndDelete(context, ref, item),
                      onEdit:
                          (item) =>
                              _openScheduleSheet(context, ref, initial: item),
                    ),
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
    await showNumberKeyboardBottomSheet(
      context,
      initialIsExpense: (initial?.amount ?? -1) < 0,
      initialValue:
          initial == null ? null : _formatInitialAmount(initial.amount.abs()),
      initialLogDateTime: initial?.scheduledDate,
      initialCategory: initial?.category,
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack, required this.onAdd});

  final VoidCallback onBack;
  final VoidCallback onAdd;

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
    required this.items,
    required this.onConvert,
    required this.onDelete,
    required this.onEdit,
  });

  final List<ScheduledTransaction> items;
  final Future<void> Function(ScheduledTransaction item) onConvert;
  final Future<void> Function(ScheduledTransaction item) onDelete;
  final Future<void> Function(ScheduledTransaction item) onEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyState();
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
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          'Start planning your future payments.',
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
    final dateLabel = formatDateLabel(item.scheduledDate);
    final timeLabel = formatTimeHm(item.scheduledDate);
    final amountLabel = formatCurrencySigned(item.amount);

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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedActionButton(
                  label: isDue ? 'Add to logs' : 'Available on schedule',
                  onPressed: isDue ? onConvert : null,
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
