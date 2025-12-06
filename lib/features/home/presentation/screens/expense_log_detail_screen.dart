import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_logs_controller.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';

class ExpenseLogDetailScreen extends ConsumerWidget {
  const ExpenseLogDetailScreen({
    super.key,
    required this.logId,
    this.log,
  });

  final String logId;
  final ExpenseLog? log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(expenseLogsProvider);

    return Scaffold(
      backgroundColor: Colors.white,
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
                  _Header(onBack: () => context.pop()),
                  const SizedBox(height: 24),
                  _TitleSection(log: resolvedLog),
                  const SizedBox(height: 16),
                  _AmountCard(log: resolvedLog),
                  const SizedBox(height: 16),
                  _MetaCard(log: resolvedLog),
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
    if (log != null) return log;
    for (final item in logs) {
      if (item.id == logId) return item;
    }
    return null;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
        ),
        const SizedBox(width: 12),
        const Text(
          'Your activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _TitleSection extends StatelessWidget {
  const _TitleSection({required this.log});

  final ExpenseLog log;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          log.title.toUpperCase(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Logged on ${formatDateLabel(log.createdAt)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.log});

  final ExpenseLog log;

  @override
  Widget build(BuildContext context) {
    final amountLabel = formatCurrencySigned(log.amount);
    final isIncome = log.amount >= 0;
    final amountColor = isIncome ? Colors.green[700] : Colors.red[700];

    return OutlinedSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Amount',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            amountLabel,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: amountColor ?? Colors.black,
            ),
          ),
          const SizedBox(height: 10),
          _Tag(label: isIncome ? 'Income' : 'Spent'),
        ],
      ),
    );
  }
}

class _MetaCard extends StatelessWidget {
  const _MetaCard({required this.log});

  final ExpenseLog log;

  @override
  Widget build(BuildContext context) {
    return OutlinedSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _MetaRow(label: 'Category', value: log.category.toUpperCase()),
          const SizedBox(height: 12),
          _MetaRow(label: 'Time', value: log.timeLabel),
          const SizedBox(height: 12),
          _MetaRow(label: 'Log ID', value: log.id),
        ],
      ),
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
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: Colors.black,
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
        label.toUpperCase(),
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
        child: CircularProgressIndicator(
          color: Colors.black,
          strokeWidth: 2.5,
        ),
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

