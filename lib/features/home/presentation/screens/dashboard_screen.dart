import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/controllers/dashboard_selected_month_controller.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard/dashboard_quick_add_handler.dart';
import 'package:anti/features/home/presentation/screens/dashboard/providers/dashboard_month_vm_provider.dart';
import 'package:anti/features/home/presentation/screens/dashboard/widgets/dashboard_balance_section.dart';
import 'package:anti/features/home/presentation/screens/dashboard/widgets/dashboard_income_spent_row.dart';
import 'package:anti/features/home/presentation/screens/dashboard/widgets/dashboard_logs_states.dart';
import 'package:anti/features/home/presentation/screens/dashboard/widgets/dashboard_month_pager.dart';
import 'package:anti/features/home/presentation/screens/dashboard/widgets/dashboard_recent_logs_section.dart';
import 'package:anti/features/home/presentation/screens/dashboard/widgets/dashboard_top_bar.dart';
import 'package:anti/features/home/presentation/screens/dashboard_events.dart';
import 'package:anti/features/home/presentation/widgets/month_picker_dialog.dart';
import 'package:anti/features/home/presentation/widgets/number_keyboard_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardScreen extends ConsumerStatefulWidget with DashboardEvents {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with DashboardEvents {
  final _quickAddHandler = DashboardQuickAddHandler();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _quickAddHandler.handle(
      context: context,
      openQuickLogKeyboard:
          ({required bool initialIsExpense}) =>
              _openQuickLogKeyboard(initialIsExpense: initialIsExpense),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _refreshDashboard() async {
    ref.invalidate(expenseLogsProvider);
    ref.invalidate(scheduledTransactionsProvider);
    await Future.wait([
      ref.read(expenseLogsProvider.future),
      ref.read(scheduledTransactionsProvider.future),
    ]);
  }

  Future<void> _openQuickLogKeyboard({required bool initialIsExpense}) async {
    await showNumberKeyboardBottomSheet(
      context,
      initialIsExpense: initialIsExpense,
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
            'Add an amount above zero to log your spending.',
          );
          return false;
        }

        final now = DateTime.now();
        final amount = isExpense ? -parsed.abs() : parsed.abs();
        final entryDateTime = logDateTime;
        final log = ExpenseLog(
          id: now.microsecondsSinceEpoch.toString(),
          timeLabel: _formatTimeLabel(entryDateTime),
          category: category,
          amount: amount,
          createdAt: entryDateTime,
        );

        try {
          await ref.read(addExpenseLogActionProvider(log).future);
          return true;
        } catch (_) {
          if (!sheetContext.mounted) return false;
          _showSnack(sheetContext, "Let's try that again.");
          return false;
        }
      },
    );
  }

  Widget _buildMonthContent({
    required double netBalance,
    required double projectedBalance,
    required bool showProjected,
    required double income,
    required double spent,
    required List<ExpenseLog> scopedLogs,
    required DateTime selectedMonth,
    required String itemsLabel,
    required String monthYearLabel,
    required List<ScheduledTransaction> scheduledThisMonth,
  }) {
    return Column(
      key: ValueKey('${selectedMonth.year}-${selectedMonth.month}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DashboardNetBalanceSection(
          netBalance: netBalance,
          projectedBalance: projectedBalance,
          showProjected: showProjected,
          selectedMonth: selectedMonth,
          scheduledThisMonth: scheduledThisMonth,
        ),
        const SizedBox(height: 16),
        DashboardIncomeSpentRow(income: income, spent: spent),
        const SizedBox(height: 32),
        DashboardRecentLogsSection(
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
    final vmAsync = ref.watch(dashboardMonthVmProvider(selectedMonth));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: vmAsync.when(
          data: (vm) {
            return DashboardMonthPager(
              selectedMonth: selectedMonth,
              onRefresh: _refreshDashboard,
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DashboardTopBar(
                    monthYearLabel: vm.monthYearLabel,
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
                    onTapMonthLabel: () async {
                      final picked = await showMonthPickerDialog(
                        context,
                        initialMonth: selectedMonth,
                      );
                      if (picked == null) return;
                      ref
                          .read(dashboardSelectedMonthProvider.notifier)
                          .setMonth(picked);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Divider(thickness: 2, color: Colors.black),
                  const SizedBox(height: 24),
                ],
              ),
              monthContent: _buildMonthContent(
                netBalance: vm.netBalance,
                projectedBalance: vm.projectedBalance,
                showProjected: vm.showProjected,
                income: vm.income,
                spent: vm.spent,
                scopedLogs: vm.logs,
                selectedMonth: vm.selectedMonth,
                itemsLabel: vm.itemsLabel,
                monthYearLabel: vm.monthYearLabel,
                scheduledThisMonth: vm.scheduledThisMonth,
              ),
              onSwipeToPreviousMonth:
                  () =>
                      ref
                          .read(dashboardSelectedMonthProvider.notifier)
                          .goToPreviousMonth(),
              onSwipeToNextMonth:
                  () =>
                      ref
                          .read(dashboardSelectedMonthProvider.notifier)
                          .goToNextMonth(),
            );
          },
          loading:
              () => _DashboardStateWrapper(
                monthYearLabel: monthYearLabel,
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
                onTapMonthLabel: () async {
                  final picked = await showMonthPickerDialog(
                    context,
                    initialMonth: selectedMonth,
                  );
                  if (picked == null) return;
                  ref
                      .read(dashboardSelectedMonthProvider.notifier)
                      .setMonth(picked);
                },
                onRefresh: _refreshDashboard,
                child: const DashboardLogsLoading(),
              ),
          error:
              (_, __) => _DashboardStateWrapper(
                monthYearLabel: monthYearLabel,
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
                onTapMonthLabel: () async {
                  final picked = await showMonthPickerDialog(
                    context,
                    initialMonth: selectedMonth,
                  );
                  if (picked == null) return;
                  ref
                      .read(dashboardSelectedMonthProvider.notifier)
                      .setMonth(picked);
                },
                onRefresh: _refreshDashboard,
                child: DashboardLogsError(
                  onRetry: () => refreshExpenseLogs(ref),
                ),
              ),
        ),
      ),
    );
  }
}

class _DashboardStateWrapper extends StatefulWidget {
  const _DashboardStateWrapper({
    required this.monthYearLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onTapMonthLabel,
    required this.onRefresh,
    required this.child,
  });

  final String monthYearLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function()? onTapMonthLabel;
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  State<_DashboardStateWrapper> createState() => _DashboardStateWrapperState();
}

class _DashboardStateWrapperState extends State<_DashboardStateWrapper> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _snapToTop() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 0) {
      _scrollController.jumpTo(0);
      return;
    }

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 1),
      curve: Curves.linear,
    );
  }

  Future<void> _handleRefresh() async {
    await _snapToTop();
    await widget.onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.black,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            DashboardTopBar(
              monthYearLabel: widget.monthYearLabel,
              onPreviousMonth: widget.onPreviousMonth,
              onNextMonth: widget.onNextMonth,
              onTapMonthLabel: widget.onTapMonthLabel,
            ),
            const SizedBox(height: 16),
            const Divider(thickness: 2, color: Colors.black),
            const SizedBox(height: 24),
            widget.child,
          ],
        ),
      ),
    );
  }
}
