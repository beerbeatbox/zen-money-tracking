import 'package:baht/core/constants/app_sizes.dart';
import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/utils/date_time_formatter.dart';
import 'package:baht/core/widgets/section_card.dart';
import 'package:baht/features/home/domain/entities/dashboard_layout.dart';
import 'package:baht/features/home/domain/entities/expense_log.dart';
import 'package:baht/features/home/domain/entities/scheduled_transaction.dart';
import 'package:baht/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:baht/features/home/presentation/controllers/dashboard_layout_controller.dart';
import 'package:baht/features/home/presentation/controllers/dashboard_selected_month_controller.dart';
import 'package:baht/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:baht/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:baht/features/home/presentation/screens/dashboard/dashboard_quick_add_handler.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_balance_section.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_budget_left_section.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_due_now_section.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_income_spent_row.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_logs_states.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_month_end_sufficiency_card.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_month_pager.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_recent_logs_section.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_schedule_section.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_spending_section.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_top_bar.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/edit_dashboard_drawer.dart';
import 'package:baht/features/home/presentation/screens/dashboard_events.dart';
import 'package:baht/features/home/presentation/widgets/month_picker_dialog.dart';
import 'package:baht/features/home/presentation/widgets/number_keyboard_bottom_sheet.dart';
import 'package:baht/features/settings/domain/entities/bottom_nav_style.dart';
import 'package:baht/features/settings/presentation/controllers/bottom_nav_style_setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:heroicons/heroicons.dart';

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
        frequency,
        intervalCount,
        intervalUnit,
        isDynamicAmount,
        budgetAmount,
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
    required DashboardLayout layout,
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
    required List<ScheduledTransaction> dueNow,
    required MonthEndSufficiencyBreakdown? sufficiencyBreakdown,
    double? todayBudgetRemaining,
    double? todaySpending,
    double? recommendedDailyBudgetWithBuffer,
  }) {
    final sections = <DashboardSectionId>[];
    final widgets = <Widget>[];

    for (final section in layout.active) {
      switch (section) {
        case DashboardSectionId.budgetLeftToday:
          if (todayBudgetRemaining == null) continue;
          sections.add(section);
          widgets.add(
            DashboardBudgetLeftSection(
              todayBudgetRemaining: todayBudgetRemaining,
              todaySpending: todaySpending,
              recommendedDailyBudgetWithBuffer:
                  recommendedDailyBudgetWithBuffer,
            ),
          );
        case DashboardSectionId.balance:
          sections.add(section);
          widgets.add(
            DashboardBalanceSection(
              netBalance: netBalance,
              projectedBalance: projectedBalance,
              showProjected: showProjected,
            ),
          );
        case DashboardSectionId.incomeSpent:
          sections.add(section);
          widgets.add(DashboardIncomeSpentRow(income: income, spent: spent));
        case DashboardSectionId.monthEndSufficiency:
          if (sufficiencyBreakdown == null) continue;
          sections.add(section);
          widgets.add(
            DashboardMonthEndSufficiencyCard(
              sufficiencyBreakdown: sufficiencyBreakdown,
            ),
          );
        case DashboardSectionId.scheduledThisMonth:
          if (scheduledThisMonth.isEmpty) continue;
          sections.add(section);
          widgets.add(
            DashboardScheduleSection(
              items: scheduledThisMonth,
              selectedMonth: selectedMonth,
            ),
          );
        case DashboardSectionId.dueNow:
          if (dueNow.isEmpty) continue;
          sections.add(section);
          widgets.add(DashboardDueNowSection(items: dueNow));
        case DashboardSectionId.recentActivity:
          sections.add(section);
          widgets.add(
            DashboardRecentLogsSection(
              logs: scopedLogs,
              itemsLabel: itemsLabel,
              monthYearLabel: monthYearLabel,
              onRetry: () => refreshExpenseLogs(ref),
            ),
          );
        case DashboardSectionId.spending:
          sections.add(section);
          widgets.add(
            DashboardSpendingSection(
              todaySpending: todaySpending ?? 0.0,
              netBalance: netBalance,
            ),
          );
      }
    }

    return Column(
      key: ValueKey('${selectedMonth.year}-${selectedMonth.month}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _applySectionSpacing(sections, widgets),
    );
  }

  List<Widget> _applySectionSpacing(
    List<DashboardSectionId> sections,
    List<Widget> widgets,
  ) {
    final spaced = <Widget>[];

    for (var index = 0; index < widgets.length; index++) {
      spaced.add(SectionCard(child: widgets[index]));
      if (index == widgets.length - 1) continue;
      spaced.add(SizedBox(height: _spacingAfterSection(sections[index])));
    }

    return spaced;
  }

  double _spacingAfterSection(DashboardSectionId _) => 16;

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(dashboardSelectedMonthProvider);
    final monthYearLabel = formatMonthYearLabel(selectedMonth);
    final vmAsync = ref.watch(dashboardControllerProvider(selectedMonth));
    final layoutAsync = ref.watch(dashboardLayoutControllerProvider);
    final isMasked = ref.watch(amountMaskControllerProvider);

    // Sync budget to widget when dashboard data is ready
    ref.listen(dashboardControllerProvider(selectedMonth), (previous, next) {
      next.whenData((vm) {
        if (vm.todayBudgetRemaining != null) {
          syncBudgetToWidget(vm.todayBudgetRemaining);
        }
      });
    });

    return Scaffold(
      backgroundColor: Colors.grey[200],
      endDrawer: const EditDashboardDrawer(),
      body: SafeArea(
        bottom: false,
        child: vmAsync.when(
          data: (vm) {
            final layout = layoutAsync.value ?? DashboardLayout.defaults();
            return DashboardMonthPager(
              selectedMonth: selectedMonth,
              onRefresh: _refreshDashboard,
              header: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed:
                                () =>
                                    ref
                                        .read(
                                          amountMaskControllerProvider.notifier,
                                        )
                                        .toggle(),
                            icon: HeroIcon(
                              isMasked ? HeroIcons.eyeSlash : HeroIcons.eye,
                              style: HeroIconStyle.outline,
                              color: Colors.black,
                            ),
                            tooltip: isMasked ? 'Show amounts' : 'Hide amounts',
                          ),
                          Builder(
                            builder: (context) {
                              return IconButton(
                                onPressed:
                                    () => Scaffold.of(context).openEndDrawer(),
                                icon: const HeroIcon(
                                  HeroIcons.pencil,
                                  style: HeroIconStyle.outline,
                                  color: Colors.black,
                                ),
                                tooltip: 'Edit dashboard',
                              );
                            },
                          ),
                          IconButton(
                            onPressed: () {
                              ref
                                  .read(dashboardSelectedMonthProvider.notifier)
                                  .setMonth(DateTime.now());
                            },
                            icon: const HeroIcon(
                              HeroIcons.arrowPath,
                              style: HeroIconStyle.outline,
                              color: Colors.black,
                            ),
                            tooltip: 'Reset to current month',
                          ),
                        ],
                      ),
                    ],
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
                  const SizedBox(height: 24),
                ],
              ),
              monthContent: _buildMonthContent(
                layout: layout,
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
                dueNow: vm.dueNow,
                sufficiencyBreakdown: vm.sufficiencyBreakdown,
                todayBudgetRemaining: vm.todayBudgetRemaining,
                todaySpending: vm.todaySpending,
                recommendedDailyBudgetWithBuffer:
                    vm.sufficiencyBreakdown?.recommendedDailyBudgetWithBuffer,
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
                isMasked: isMasked,
                onToggleMask:
                    () =>
                        ref
                            .read(amountMaskControllerProvider.notifier)
                            .toggle(),
                onRefresh: _refreshDashboard,
                onResetMonth: () {
                  ref
                      .read(dashboardSelectedMonthProvider.notifier)
                      .setMonth(DateTime.now());
                },
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
                isMasked: isMasked,
                onToggleMask:
                    () =>
                        ref
                            .read(amountMaskControllerProvider.notifier)
                            .toggle(),
                onRefresh: _refreshDashboard,
                onResetMonth: () {
                  ref
                      .read(dashboardSelectedMonthProvider.notifier)
                      .setMonth(DateTime.now());
                },
                child: DashboardLogsError(
                  onRetry: () => refreshExpenseLogs(ref),
                ),
              ),
        ),
      ),
    );
  }
}

class _DashboardStateWrapper extends ConsumerStatefulWidget {
  const _DashboardStateWrapper({
    required this.monthYearLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onTapMonthLabel,
    required this.isMasked,
    required this.onToggleMask,
    required this.onRefresh,
    required this.onResetMonth,
    required this.child,
  });

  final String monthYearLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function()? onTapMonthLabel;
  final bool isMasked;
  final VoidCallback onToggleMask;
  final Future<void> Function() onRefresh;
  final VoidCallback onResetMonth;
  final Widget child;

  @override
  ConsumerState<_DashboardStateWrapper> createState() =>
      _DashboardStateWrapperState();
}

class _DashboardStateWrapperState
    extends ConsumerState<_DashboardStateWrapper> {
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
    final navStyle =
        ref.watch(bottomNavStyleSettingControllerProvider).value ??
        BottomNavStyle.floating;

    return RefreshIndicator(
      onRefresh: _handleRefresh,
      color: Colors.black,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          24 + Sizes.bottomNavInset(context, navStyle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: widget.onToggleMask,
                      icon: HeroIcon(
                        widget.isMasked ? HeroIcons.eyeSlash : HeroIcons.eye,
                        style: HeroIconStyle.outline,
                        color: Colors.black,
                      ),
                      tooltip:
                          widget.isMasked ? 'Show amounts' : 'Hide amounts',
                    ),
                    Builder(
                      builder: (context) {
                        return IconButton(
                          onPressed: () => Scaffold.of(context).openEndDrawer(),
                          icon: const Icon(Icons.edit, color: Colors.black),
                          tooltip: 'Edit dashboard',
                        );
                      },
                    ),
                    IconButton(
                      onPressed: widget.onResetMonth,
                      icon: const Icon(Icons.refresh, color: Colors.black),
                      tooltip: 'Reset to current month',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            DashboardTopBar(
              monthYearLabel: widget.monthYearLabel,
              onPreviousMonth: widget.onPreviousMonth,
              onNextMonth: widget.onNextMonth,
              onTapMonthLabel: widget.onTapMonthLabel,
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            widget.child,
          ],
        ),
      ),
    );
  }
}
