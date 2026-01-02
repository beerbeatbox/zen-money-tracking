import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/widgets/number_keyboard_bottom_sheet.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:anti/features/settings/presentation/widgets/outlined_confirmation_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'expense_log_detail_events.dart';

class ExpenseLogDetailScreen extends ConsumerWidget {
  const ExpenseLogDetailScreen({super.key, required this.logId, this.log});

  final String logId;
  final ExpenseLog? log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(expenseLogsProvider);

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
          'Your activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: logsAsync.when(
          data: (logs) {
            final resolvedLog = _resolveLog(logs);
            if (resolvedLog == null) {
              return _MissingLogState(
                onBack: () => context.pop(),
                onRetry: () => ref.invalidate(expenseLogsProvider),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LogDetailCard(log: resolvedLog),
                  const SizedBox(height: 16),
                  _LogActionsRow(log: resolvedLog),
                ],
              ),
            );
          },
          loading: () => const _LoadingState(),
          error:
              (_, __) => _ErrorState(
                onBack: () => context.pop(),
                onRetry: () => ref.invalidate(expenseLogsProvider),
              ),
        ),
      ),
    );
  }

  ExpenseLog? _resolveLog(List<ExpenseLog> logs) {
    for (final item in logs) {
      if (item.id == logId) return item;
    }
    return log;
  }
}

class _LogDetailCard extends StatelessWidget {
  const _LogDetailCard({required this.log});

  final ExpenseLog log;

  @override
  Widget build(BuildContext context) {
    final isIncome = log.amount >= 0;
    final amountColor = isIncome ? Colors.green[700] : Colors.red[700];

    return OutlinedSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            log.category,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _AnimatedLogAmountText(
                  value: log.amount,
                  textStyle: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: amountColor ?? Colors.black,
                  ),
                ),
              ),
              _Tag(label: isIncome ? 'Income' : 'Spent'),
            ],
          ),
          const SizedBox(height: 16),
          _MetaRow(label: 'Category', value: log.category),
          const SizedBox(height: 12),
          _MetaRow(
            label: 'Time',
            value: '${log.timeLabel} • ${formatDateLabel(log.createdAt)}',
          ),
          const SizedBox(height: 12),
          _MetaRow(label: 'Log ID', value: log.id),
        ],
      ),
    );
  }
}

class _AnimatedLogAmountText extends ImplicitlyAnimatedWidget {
  const _AnimatedLogAmountText({
    required this.value,
    required this.textStyle,
    super.duration = const Duration(milliseconds: 600),
  });

  final double value;
  final TextStyle textStyle;

  @override
  AnimatedWidgetBaseState<_AnimatedLogAmountText> createState() =>
      _AnimatedLogAmountTextState();
}

class _AnimatedLogAmountTextState
    extends AnimatedWidgetBaseState<_AnimatedLogAmountText> {
  Tween<double>? _valueTween;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _valueTween =
        visitor(
              _valueTween,
              widget.value,
              (dynamic value) =>
                  Tween<double>(begin: value as double, end: widget.value),
            )
            as Tween<double>?;
  }

  @override
  Widget build(BuildContext context) {
    final animatedValue = _valueTween?.evaluate(animation) ?? widget.value;
    return Text(formatCurrencySigned(animatedValue), style: widget.textStyle);
  }
}

class _LogActionsRow extends ConsumerWidget with ExpenseLogDetailEvents {
  const _LogActionsRow({required this.log});

  final ExpenseLog log;

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatInitialAmount(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toString();
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder:
          (ctx) => OutlinedConfirmationDialog(
            title: 'Delete this log?',
            description: 'This removes it from your activity.',
            primaryLabel: 'Delete log',
            onPrimaryPressed: () => Navigator.of(ctx).pop(true),
            secondaryLabel: 'Keep this log',
            onSecondaryPressed: () => Navigator.of(ctx).pop(false),
          ),
    );

    if (shouldDelete != true) return;

    try {
      await deleteLog(ref, log.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Log removed from your activity.'),
        ),
      );
      context.pop();
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text("Let's try that again. Please try once more."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        Expanded(
          child: OutlinedActionButton(
            label: 'Edit',
            onPressed: () async {
              await showNumberKeyboardBottomSheet(
                context,
                initialIsExpense: log.amount < 0,
                initialValue: _formatInitialAmount(log.amount.abs()),
                initialLogDateTime: log.createdAt,
                initialCategory: log.category,
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
                      'Add an amount above zero to save changes.',
                    );
                    return false;
                  }

                  final updated = ExpenseLog(
                    id: log.id,
                    timeLabel: _formatTimeLabel(logDateTime),
                    category: category,
                    amount: isExpense ? -parsed.abs() : parsed.abs(),
                    createdAt: logDateTime,
                  );

                  try {
                    await updateLog(ref, updated);
                    return true;
                  } catch (_) {
                    if (!sheetContext.mounted) return false;
                    _showSnack(sheetContext, "Let's try that again.");
                    return false;
                  }
                },
              );
            },
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
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.label, required this.value});

  final String label;
  final String value;

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
            child: Text(
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

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
          color: Colors.white,
        ),
      ),
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
                'Reload log',
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

class _MissingLogState extends StatelessWidget {
  const _MissingLogState({required this.onBack, required this.onRetry});

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
              "We couldn't find that log right now.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Refresh to load your latest activity.',
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
                'Reload logs',
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
