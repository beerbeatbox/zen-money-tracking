import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/router/app_router.dart';
import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/dashboard_selected_month_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard_events.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScreen extends ConsumerStatefulWidget with DashboardEvents {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with DashboardEvents, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  double _dragOffset = 0.0;
  int _lastSwipeDirection = 0; // -1 = next, 1 = previous
  Animation<double>? _currentAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
  }

  @override
  void dispose() {
    if (_currentAnimation != null) {
      _currentAnimation!.removeListener(_animationListener);
      _currentAnimation = null;
    }
    _animationController.dispose();
    super.dispose();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    // Cancel any ongoing animation and remove listener to prevent interference
    if (_currentAnimation != null) {
      _currentAnimation!.removeListener(_animationListener);
      _currentAnimation = null;
    }
    _animationController.stop();
    _animationController.reset();

    setState(() {
      final delta = details.primaryDelta ?? 0;
      _dragOffset += delta;
      // Clamp to screen width
      final screenWidth = MediaQuery.of(context).size.width;
      _dragOffset = _dragOffset.clamp(-screenWidth, screenWidth);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.25;
    final velocity = details.primaryVelocity ?? 0;

    if (_dragOffset.abs() > threshold || velocity.abs() > 500) {
      // Capture direction before animation
      final isSwipeLeft = _dragOffset < 0 || velocity < 0;

      // Animate current content fully off-screen first, then change month
      final targetOffset =
          isSwipeLeft
              ? -screenWidth // Swipe left = animate to left (off-screen)
              : screenWidth; // Swipe right = animate to right (off-screen)

      _animateToOffset(targetOffset, () {
        // After animation completes, change month
        if (mounted) {
          if (isSwipeLeft) {
            setState(() {
              _lastSwipeDirection = -1; // Next month (slide from right)
            });
            ref.read(dashboardSelectedMonthProvider.notifier).goToNextMonth();
          } else {
            setState(() {
              _lastSwipeDirection = 1; // Previous month (slide from left)
            });
            ref
                .read(dashboardSelectedMonthProvider.notifier)
                .goToPreviousMonth();
          }
          // Reset drag offset - new content will animate in via AnimatedSwitcher
          setState(() {
            _dragOffset = 0.0;
          });
        }
      });
    } else {
      // Animate back to center
      _animateBackToCenter();
    }
  }

  void _onHorizontalDragCancel() {
    _animateBackToCenter();
  }

  void _animateBackToCenter() {
    _animateToOffset(0.0, () {
      if (mounted) {
        _animationController.reset();
      }
    });
  }

  void _animationListener() {
    if (mounted && _currentAnimation != null) {
      setState(() {
        _dragOffset = _currentAnimation!.value;
      });
    }
  }

  void _animateToOffset(double targetOffset, VoidCallback? onComplete) {
    final startOffset = _dragOffset;

    // Remove previous animation listener if exists
    if (_currentAnimation != null) {
      _currentAnimation!.removeListener(_animationListener);
    }

    _currentAnimation = Tween<double>(
      begin: startOffset,
      end: targetOffset,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _currentAnimation!.addListener(_animationListener);

    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        if (_currentAnimation != null) {
          _currentAnimation!.removeListener(_animationListener);
          _currentAnimation = null;
        }
        _animationController.reset();
        onComplete?.call();
      }
    });
  }

  Widget _buildMonthContent({
    required double netBalance,
    required double income,
    required double spent,
    required List<ExpenseLog> scopedLogs,
    required String itemsLabel,
    required String monthYearLabel,
    required DateTime selectedMonth,
  }) {
    return Column(
      key: ValueKey('${selectedMonth.year}-${selectedMonth.month}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NetBalanceSection(netBalance: netBalance),
        const SizedBox(height: 16),
        _IncomeSpentRow(income: income, spent: spent),
        const SizedBox(height: 16),
        // WeeklyStreak(logs: scopedLogs, dailyBudgetLimit: 500),
        const SizedBox(height: 32),
        _RecentLogsSection(
          logs: scopedLogs,
          itemsLabel: itemsLabel,
          monthYearLabel: monthYearLabel,
          onRetry: () => refreshExpenseLogs(ref),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(dashboardSelectedMonthProvider);
    final monthYearLabel = formatMonthYearLabel(selectedMonth);
    final dateLabel = 'Swipe left or right to change month';
    final logsAsync = watchExpenseLogs(ref);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: logsAsync.when(
          data: (logs) {
            final scopedLogs = _filterLogsByMonth(logs, selectedMonth);
            final netBalance = calculateNetBalance(scopedLogs);
            final income = calculateIncome(scopedLogs);
            final spent = calculateSpent(scopedLogs);
            final itemsLabel = logsCountLabel(scopedLogs.length);

            return LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onHorizontalDragUpdate: _onHorizontalDragUpdate,
                  onHorizontalDragEnd: _onHorizontalDragEnd,
                  onHorizontalDragCancel: _onHorizontalDragCancel,
                  child: SizedBox(
                    height: constraints.maxHeight,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _TopBar(
                            monthYearLabel: monthYearLabel,
                            dateLabel: dateLabel,
                            onPreviousMonth:
                                () =>
                                    ref
                                        .read(
                                          dashboardSelectedMonthProvider
                                              .notifier,
                                        )
                                        .goToPreviousMonth(),
                            onNextMonth:
                                () =>
                                    ref
                                        .read(
                                          dashboardSelectedMonthProvider
                                              .notifier,
                                        )
                                        .goToNextMonth(),
                          ),
                          const SizedBox(height: 16),
                          const Divider(thickness: 2, color: Colors.black),
                          const SizedBox(height: 24),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, animation) {
                              // Use PageRoute-style transition
                              final slideOffset =
                                  _lastSwipeDirection == 0
                                      ? const Offset(0.2, 0)
                                      : Offset(_lastSwipeDirection * 0.2, 0);

                              final tween = Tween<Offset>(
                                begin: slideOffset,
                                end: Offset.zero,
                              ).chain(CurveTween(curve: Curves.easeOutCubic));

                              final offsetAnimation = animation.drive(tween);

                              return SlideTransition(
                                position: offsetAnimation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: Transform.translate(
                              offset: Offset(_dragOffset, 0),
                              child: _buildMonthContent(
                                netBalance: netBalance,
                                income: income,
                                spent: spent,
                                scopedLogs: scopedLogs,
                                itemsLabel: itemsLabel,
                                monthYearLabel: monthYearLabel,
                                selectedMonth: selectedMonth,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
          loading:
              () => _DashboardStateWrapper(
                monthYearLabel: monthYearLabel,
                dateLabel: dateLabel,
                onPreviousMonth:
                    () =>
                        ref
                            .read(dashboardSelectedMonthProvider.notifier)
                            .goToPreviousMonth(),
                onNextMonth:
                    () =>
                        ref
                            .read(dashboardSelectedMonthProvider.notifier)
                            .goToNextMonth(),
                child: const _LogsLoading(),
              ),
          error:
              (_, __) => _DashboardStateWrapper(
                monthYearLabel: monthYearLabel,
                dateLabel: dateLabel,
                onPreviousMonth:
                    () =>
                        ref
                            .read(dashboardSelectedMonthProvider.notifier)
                            .goToPreviousMonth(),
                onNextMonth:
                    () =>
                        ref
                            .read(dashboardSelectedMonthProvider.notifier)
                            .goToNextMonth(),
                child: _LogsError(onRetry: () => refreshExpenseLogs(ref)),
              ),
        ),
      ),
    );
  }
}

List<ExpenseLog> _filterLogsByMonth(List<ExpenseLog> logs, DateTime month) {
  return logs
      .where(
        (log) =>
            log.createdAt.year == month.year &&
            log.createdAt.month == month.month,
      )
      .toList();
}

class _DashboardStateWrapper extends StatelessWidget {
  const _DashboardStateWrapper({
    required this.monthYearLabel,
    required this.dateLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.child,
  });

  final String monthYearLabel;
  final String dateLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TopBar(
            monthYearLabel: monthYearLabel,
            dateLabel: dateLabel,
            onPreviousMonth: onPreviousMonth,
            onNextMonth: onNextMonth,
          ),
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
  const _TopBar({
    required this.monthYearLabel,
    required this.dateLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String monthYearLabel;
  final String dateLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPreviousMonth,
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          tooltip: 'Previous month',
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              monthYearLabel,
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
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        IconButton(
          onPressed: onNextMonth,
          icon: const Icon(Icons.chevron_right, color: Colors.black),
          tooltip: 'Next month',
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
          'Balance',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Income',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrencySigned(income),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spent',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrencySigned(spent),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentLogsSection extends StatelessWidget {
  const _RecentLogsSection({
    required this.logs,
    required this.itemsLabel,
    required this.monthYearLabel,
    required this.onRetry,
  });

  final List<ExpenseLog> logs;
  final String itemsLabel;
  final String monthYearLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return _EmptyLogs(monthYearLabel: monthYearLabel);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activity',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                  Text(
                    _calculateDayTotal(group.logs),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                      color: Colors.black,
                    ),
                  ),
                ],
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

  String _calculateDayTotal(List<ExpenseLog> logs) {
    final total = logs.fold<double>(0.0, (sum, log) => sum + log.amount);
    return formatCurrencySigned(total);
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
  const _EmptyLogs({required this.monthYearLabel});

  final String monthYearLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(
          'Add your first log for $monthYearLabel.',
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
