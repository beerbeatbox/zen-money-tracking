import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/router/app_router.dart';
import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/screens/dashboard_events.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerWidget with DashboardEvents {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateLabel = dashboardDateLabel(DateTime.now());
    final logsAsync = watchExpenseLogs(ref);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: logsAsync.when(
          data: (logs) {
            final netBalance = calculateNetBalance(logs);
            final income = calculateIncome(logs);
            final spent = calculateSpent(logs);
            final itemsLabel = logsCountLabel(logs.length);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TopBar(dateLabel: dateLabel),
                  const SizedBox(height: 16),
                  const Divider(thickness: 2, color: Colors.black),
                  const SizedBox(height: 24),
                  _NetBalanceSection(netBalance: netBalance),
                  const SizedBox(height: 16),
                  _IncomeSpentRow(income: income, spent: spent),
                  const SizedBox(height: 32),
                  _RecentLogsSection(
                    logs: logs,
                    itemsLabel: itemsLabel,
                    onRetry: () => refreshExpenseLogs(ref),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
          loading:
              () => _DashboardStateWrapper(
                dateLabel: dateLabel,
                child: const _LogsLoading(),
              ),
          error:
              (_, __) => _DashboardStateWrapper(
                dateLabel: dateLabel,
                child: _LogsError(onRetry: () => refreshExpenseLogs(ref)),
              ),
        ),
      ),
    );
  }
}

class _DashboardStateWrapper extends StatelessWidget {
  const _DashboardStateWrapper({required this.dateLabel, required this.child});

  final String dateLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(dateLabel: dateLabel),
          const SizedBox(height: 16),
          const Divider(thickness: 2, color: Colors.black),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.dateLabel});

  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'EXPENSE_LOG',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dateLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _NetBalanceSection extends StatelessWidget {
  const _NetBalanceSection({required this.netBalance});

  final double netBalance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NET_BALANCE',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        _AnimatedBalanceText(
          value: netBalance,
          textStyle: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _AnimatedBalanceText extends ImplicitlyAnimatedWidget {
  const _AnimatedBalanceText({
    required this.value,
    required this.textStyle,
    super.duration = const Duration(milliseconds: 600),
  });

  final double value;
  final TextStyle textStyle;

  @override
  AnimatedWidgetBaseState<_AnimatedBalanceText> createState() =>
      _AnimatedBalanceTextState();
}

class _AnimatedBalanceTextState
    extends AnimatedWidgetBaseState<_AnimatedBalanceText> {
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

    return Text(formatNetBalance(animatedValue), style: widget.textStyle);
  }
}

class _IncomeSpentRow extends StatelessWidget {
  const _IncomeSpentRow({required this.income, required this.spent});

  final double income;
  final double spent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            title: 'Income',
            amount: income,
            icon: Icons.north_east,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _SummaryCard(
            title: 'Spent',
            amount: spent,
            icon: Icons.north_west,
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.amount,
    required this.icon,
  });

  final String title;
  final double amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x11000000),
            offset: Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.black),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            formatCurrencySigned(amount),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentLogsSection extends StatelessWidget {
  const _RecentLogsSection({
    required this.logs,
    required this.itemsLabel,
    required this.onRetry,
  });

  final List<ExpenseLog> logs;
  final String itemsLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const _EmptyLogs();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'RECENT_LOGS',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.black,
              ),
            ),
            Text(
              itemsLabel,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(thickness: 2, color: Colors.black),
        const SizedBox(height: 12),
        _DatedLogsList(logs: logs),
      ],
    );
  }
}

class _DatedLogsList extends StatelessWidget {
  const _DatedLogsList({required this.logs});

  final List<ExpenseLog> logs;

  @override
  Widget build(BuildContext context) {
    final groupedLogs = _groupLogsByDate(logs);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(groupedLogs.length, (groupIndex) {
        final group = groupedLogs[groupIndex];
        final isLastGroup = groupIndex == groupedLogs.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLastGroup ? 0 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _dateLabel(group.date),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),
              ...List.generate(group.logs.length, (logIndex) {
                final log = group.logs[logIndex];
                final isLastLog = logIndex == group.logs.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLastLog ? 0 : 10),
                  child: _LogTile(log: log),
                );
              }),
            ],
          ),
        );
      }),
    );
  }

  List<_LogGroup> _groupLogsByDate(List<ExpenseLog> logs) {
    final map = <DateTime, List<ExpenseLog>>{};

    for (final log in logs) {
      final dateKey = DateUtils.dateOnly(log.createdAt);
      map.putIfAbsent(dateKey, () => []).add(log);
    }

    final groups =
        map.entries
            .map((entry) => _LogGroup(date: entry.key, logs: entry.value))
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));

    return groups;
  }

  String _dateLabel(DateTime date) {
    final today = DateUtils.dateOnly(DateTime.now());
    final baseLabel = formatDateWithWeekday(date);
    final isToday = date.isAtSameMomentAs(today);
    return isToday ? 'Today $baseLabel' : baseLabel;
  }
}

class _LogGroup {
  const _LogGroup({required this.date, required this.logs});

  final DateTime date;
  final List<ExpenseLog> logs;
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.log});

  final ExpenseLog log;

  @override
  Widget build(BuildContext context) {
    final amountLabel = formatCurrencySigned(log.amount);

    return OutlinedSurface(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.black, width: 2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  log.category.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 6),
                _LogMetaRow(log: log),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountLabel,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
              color: Colors.black,
            ),
          ),
        ],
      ),
    ).onTap(
      behavior: HitTestBehavior.opaque,
      onTap: () => _openLogDetail(context),
    );
  }

  void _openLogDetail(BuildContext context) {
    context.pushNamed(
      AppRouter.expenseLogDetail.name,
      pathParameters: {'id': log.id},
      extra: log,
    );
  }
}

class _LogMetaRow extends StatelessWidget {
  const _LogMetaRow({required this.log});

  final ExpenseLog log;

  @override
  Widget build(BuildContext context) {
    return Text(
      log.timeLabel,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Colors.grey[600],
      ),
    );
  }
}

class _EmptyLogs extends StatelessWidget {
  const _EmptyLogs();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          'Ready to track your spending? Add your first log.',
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

class _LogsLoading extends StatelessWidget {
  const _LogsLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.black),
      ),
    );
  }
}

class _LogsError extends StatelessWidget {
  const _LogsError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          'Let\'s try that again.',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Reload logs',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
