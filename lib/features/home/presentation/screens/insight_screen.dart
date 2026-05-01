import 'package:baht/core/constants/app_sizes.dart';
import 'package:baht/features/settings/domain/entities/bottom_nav_style.dart';
import 'package:baht/features/settings/presentation/controllers/bottom_nav_style_setting_controller.dart';
import 'package:baht/core/utils/date_time_formatter.dart';
import 'package:baht/core/widgets/section_card.dart';
import 'package:baht/features/home/domain/entities/expense_log.dart';
import 'package:baht/features/home/presentation/controllers/dashboard_selected_month_controller.dart';
import 'package:baht/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:baht/features/home/presentation/controllers/weekly_recap_controller.dart';
import 'package:baht/features/home/presentation/controllers/insight_month_controller.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_month_pager.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_top_bar.dart';
import 'package:baht/features/home/presentation/widgets/category_ranking_section.dart';
import 'package:baht/features/home/presentation/widgets/month_picker_dialog.dart';
import 'package:baht/features/home/presentation/widgets/monthly_category_line_chart.dart';
import 'package:baht/features/home/presentation/widgets/weekly_recap_card.dart';
import 'package:baht/features/home/presentation/widgets/monthly_income_spent_line_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InsightScreen extends ConsumerWidget {
  const InsightScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedMonth = ref.watch(dashboardSelectedMonthProvider);
    final vmAsync = ref.watch(insightMonthControllerProvider(selectedMonth));
    final fallbackMonthYearLabel = formatMonthYearLabel(selectedMonth);

    Future<void> refreshLogs() async {
      ref.invalidate(expenseLogsProvider);
      await ref.read(expenseLogsProvider.future);
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        bottom: false,
        child: vmAsync.when(
          data: (vm) {
            return DashboardMonthPager(
              selectedMonth: selectedMonth,
              onRefresh: refreshLogs,
              header: _HeaderSection(
                selectedMonth: selectedMonth,
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
                onPickMonth: (picked) {
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
              monthContent: _MonthContent(
                selectedMonth: vm.selectedMonth,
                logs: vm.logs,
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
              () => _InsightStateWrapper(
                selectedMonth: selectedMonth,
                monthYearLabel: fallbackMonthYearLabel,
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
                onPickMonth: (picked) {
                  ref
                      .read(dashboardSelectedMonthProvider.notifier)
                      .setMonth(picked);
                },
                onLongPressMonthLabel: () {
                  ref
                      .read(dashboardSelectedMonthProvider.notifier)
                      .setMonth(DateTime.now());
                },
                onRefresh: refreshLogs,
                child: const _LoadingState(),
              ),
          error:
              (_, __) => _InsightStateWrapper(
                selectedMonth: selectedMonth,
                monthYearLabel: fallbackMonthYearLabel,
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
                onPickMonth: (picked) {
                  ref
                      .read(dashboardSelectedMonthProvider.notifier)
                      .setMonth(picked);
                },
                onLongPressMonthLabel: () {
                  ref
                      .read(dashboardSelectedMonthProvider.notifier)
                      .setMonth(DateTime.now());
                },
                onRefresh: refreshLogs,
                child: const _ErrorState(),
              ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.selectedMonth,
    required this.monthYearLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onPickMonth,
    required this.onLongPressMonthLabel,
  });

  final DateTime selectedMonth;
  final String monthYearLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onPickMonth;
  final VoidCallback onLongPressMonthLabel;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Insight',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        DashboardTopBar(
          monthYearLabel: monthYearLabel,
          isCurrentMonth: isCurrentMonth,
          onPreviousMonth: onPreviousMonth,
          onNextMonth: onNextMonth,
          onTapMonthLabel: () async {
            final picked = await showMonthPickerDialog(
              context,
              initialMonth: selectedMonth,
            );
            if (picked == null) return;
            onPickMonth(picked);
          },
          onLongPressMonthLabel: onLongPressMonthLabel,
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _MonthContent extends StatelessWidget {
  const _MonthContent({required this.selectedMonth, required this.logs});

  final DateTime selectedMonth;
  final List<ExpenseLog> logs;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: ValueKey('${selectedMonth.year}-${selectedMonth.month}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _WeeklyRecapSection(),
        const SizedBox(height: 16),
        SectionCard(
          child: MonthlyIncomeSpentLineChart(
            selectedMonth: selectedMonth,
            logs: logs,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: MonthlyCategoryLineChart(
            selectedMonth: selectedMonth,
            logs: logs,
          ),
        ),
        const SizedBox(height: 16),
        SectionCard(
          child: CategoryRankingSection(
            selectedMonth: selectedMonth,
            logs: logs,
          ),
        ),
      ],
    );
  }
}

class _InsightStateWrapper extends ConsumerStatefulWidget {
  const _InsightStateWrapper({
    required this.selectedMonth,
    required this.monthYearLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onPickMonth,
    required this.onLongPressMonthLabel,
    required this.onRefresh,
    required this.child,
  });

  final DateTime selectedMonth;
  final String monthYearLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onPickMonth;
  final VoidCallback onLongPressMonthLabel;
  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  ConsumerState<_InsightStateWrapper> createState() => _InsightStateWrapperState();
}

class _InsightStateWrapperState extends ConsumerState<_InsightStateWrapper> {
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
            _HeaderSection(
              selectedMonth: widget.selectedMonth,
              monthYearLabel: widget.monthYearLabel,
              onPreviousMonth: widget.onPreviousMonth,
              onNextMonth: widget.onNextMonth,
              onPickMonth: widget.onPickMonth,
              onLongPressMonthLabel: widget.onLongPressMonthLabel,
            ),
            widget.child,
          ],
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
        padding: EdgeInsets.symmetric(vertical: 32),
        child: CircularProgressIndicator(color: Colors.black),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        "Something went wrong. Pull to refresh and try again.",
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[700],
        ),
      ),
    );
  }
}

class _WeeklyRecapSection extends ConsumerWidget {
  const _WeeklyRecapSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncLogs = ref.watch(expenseLogsProvider);
    return asyncLogs.when(
      data: (logs) {
        final summaries = summarizeLastWeeksWithActivity(logs, 6);
        if (summaries.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Weekly Money Review',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 168,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: summaries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder:
                    (context, i) => WeeklyRecapCard(summary: summaries[i]),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
