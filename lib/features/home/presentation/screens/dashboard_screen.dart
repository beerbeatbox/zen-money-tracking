import 'package:baht/core/constants/app_sizes.dart';
import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/utils/date_time_formatter.dart';
import 'package:baht/core/widgets/section_card.dart';
import 'package:baht/features/home/domain/entities/dashboard_sections.dart';
import 'package:baht/features/home/domain/entities/expense_log.dart';
import 'package:baht/features/home/domain/entities/scheduled_transaction.dart';
import 'package:baht/features/home/domain/usecases/expense_log_service.dart';
import 'package:baht/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:baht/features/home/presentation/controllers/dashboard_selected_month_controller.dart';
import 'package:baht/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:baht/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:baht/features/home/presentation/screens/dashboard/dashboard_quick_add_handler.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_due_now_section.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_logs_states.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_month_pager.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_recent_logs_section.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_schedule_section.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_spending_section.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_top_bar.dart';
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
  static const _postQuickLogSheetCloseDelay = Duration(milliseconds: 280);

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
    var addedExpenseLog = false;

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
          await ref.read(expenseLogServiceProvider).addExpenseLog(log);
          addedExpenseLog = true;
          return true;
        } catch (_) {
          if (!sheetContext.mounted) return false;
          _showSnack(sheetContext, "Let's try that again.");
          return false;
        }
      },
    );

    if (!mounted || !addedExpenseLog) return;

    await Future<void>.delayed(_postQuickLogSheetCloseDelay);
    if (!mounted) return;

    ref.invalidate(expenseLogsProvider);
    await ref.read(expenseLogsProvider.future);
  }

  Widget _buildMonthContent({
    required double netBalance,
    required List<ExpenseLog> scopedLogs,
    required DateTime selectedMonth,
    required String itemsLabel,
    required String monthYearLabel,
    required List<ScheduledTransaction> scheduledThisMonth,
    required List<ScheduledTransaction> dueNow,
    double? todaySpending,
    double? todayBudgetRemaining,
  }) {
    final sections = <DashboardSectionId>[];
    final widgets = <Widget>[];

    for (final section in kDashboardSectionOrder) {
      switch (section) {
        case DashboardSectionId.spentToday:
          sections.add(section);
          widgets.add(
            DashboardSpendingSection(
              key: const ValueKey('spending-section'),
              todaySpending: todaySpending ?? 0.0,
              netBalance: netBalance,
              todayBudgetRemaining: todayBudgetRemaining,
            ),
          );
        case DashboardSectionId.dueNow:
          if (dueNow.isNotEmpty) {
            sections.add(section);
            widgets.add(DashboardDueNowSection(items: dueNow));
          }
        case DashboardSectionId.upcoming:
          sections.add(section);
          widgets.add(
            DashboardScheduleSection(
              items: scheduledThisMonth,
              selectedMonth: selectedMonth,
              isExpandable: true,
            ),
          );
        case DashboardSectionId.transactions:
          sections.add(section);
          widgets.add(
            DashboardRecentLogsSection(
              logs: scopedLogs,
              itemsLabel: itemsLabel,
              monthYearLabel: monthYearLabel,
              onRetry: () => refreshExpenseLogs(ref),
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
      final bg = switch (sections[index]) {
        DashboardSectionId.spentToday => const Color(0xFF1A5C52),
        DashboardSectionId.dueNow => const Color(0xFFFFF0EC),
        DashboardSectionId.upcoming => const Color(0xFFEFF6FF),
        _ => Colors.white,
      };
      final needsClip =
          sections[index] == DashboardSectionId.dueNow ||
          sections[index] == DashboardSectionId.upcoming;
      final card = SectionCard(backgroundColor: bg, child: widgets[index]);
      spaced.add(
        needsClip
            ? ClipRRect(borderRadius: BorderRadius.circular(24), child: card)
            : card,
      );
      if (index == widgets.length - 1) continue;
      spaced.add(SizedBox(height: _spacingAfterSection(sections[index])));
    }

    return spaced;
  }

  double _spacingAfterSection(DashboardSectionId section) =>
      section == DashboardSectionId.spentToday ? 24 : 16;

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(dashboardSelectedMonthProvider);
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;
    final monthYearLabel = formatMonthYearLabel(selectedMonth);
    final vmAsync = ref.watch(dashboardControllerProvider(selectedMonth));
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFEEF2F1), Color(0xFFE5E9E8)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: vmAsync.when(
            // Dependency invalidation (e.g. new expense log) reloads this async
            // provider; keep showing the last dashboard so section state (spending
            // counter animation) is not torn down and replaced by the loading UI.
            skipLoadingOnReload: true,
            data: (vm) {
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
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.black,
                          ),
                        ),
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
                            color: const Color(0xFF1A5C52),
                          ),
                          tooltip: isMasked ? 'Show amounts' : 'Hide amounts',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DashboardTopBar(
                      monthYearLabel: vm.monthYearLabel,
                      isCurrentMonth: isCurrentMonth,
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
                      onLongPressMonthLabel: () {
                        ref
                            .read(dashboardSelectedMonthProvider.notifier)
                            .setMonth(DateTime.now());
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
                monthContent: _buildMonthContent(
                  netBalance: vm.netBalance,
                  scopedLogs: vm.logs,
                  selectedMonth: vm.selectedMonth,
                  itemsLabel: vm.itemsLabel,
                  monthYearLabel: vm.monthYearLabel,
                  scheduledThisMonth: vm.scheduledThisMonth,
                  dueNow: vm.dueNow,
                  todaySpending: vm.todaySpending,
                  todayBudgetRemaining: vm.todayBudgetRemaining,
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
                  isCurrentMonth: isCurrentMonth,
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
                  onLongPressMonthLabel: () {
                    ref
                        .read(dashboardSelectedMonthProvider.notifier)
                        .setMonth(DateTime.now());
                  },
                  child: const DashboardLogsLoading(),
                ),
            error:
                (_, __) => _DashboardStateWrapper(
                  monthYearLabel: monthYearLabel,
                  isCurrentMonth: isCurrentMonth,
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
                  onLongPressMonthLabel: () {
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
      ),
    );
  }
}

class _DashboardStateWrapper extends ConsumerStatefulWidget {
  const _DashboardStateWrapper({
    required this.monthYearLabel,
    required this.isCurrentMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onTapMonthLabel,
    required this.onLongPressMonthLabel,
    required this.isMasked,
    required this.onToggleMask,
    required this.onRefresh,
    required this.child,
  });

  final String monthYearLabel;
  final bool isCurrentMonth;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function()? onTapMonthLabel;
  final VoidCallback onLongPressMonthLabel;
  final bool isMasked;
  final VoidCallback onToggleMask;
  final Future<void> Function() onRefresh;
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
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  onPressed: widget.onToggleMask,
                  icon: HeroIcon(
                    widget.isMasked ? HeroIcons.eyeSlash : HeroIcons.eye,
                    style: HeroIconStyle.outline,
                    color: const Color(0xFF1A5C52),
                  ),
                  tooltip: widget.isMasked ? 'Show amounts' : 'Hide amounts',
                ),
              ],
            ),
            const SizedBox(height: 12),
            DashboardTopBar(
              monthYearLabel: widget.monthYearLabel,
              isCurrentMonth: widget.isCurrentMonth,
              onPreviousMonth: widget.onPreviousMonth,
              onNextMonth: widget.onNextMonth,
              onTapMonthLabel: widget.onTapMonthLabel,
              onLongPressMonthLabel: widget.onLongPressMonthLabel,
            ),
            const SizedBox(height: 16),
            widget.child,
          ],
        ),
      ),
    );
  }
}
