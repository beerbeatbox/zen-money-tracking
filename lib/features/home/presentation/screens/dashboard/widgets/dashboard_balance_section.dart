import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/screens/dashboard/widgets/dashboard_schedule_section.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:flutter/material.dart';

class DashboardNetBalanceSection extends StatefulWidget {
  const DashboardNetBalanceSection({
    super.key,
    required this.netBalance,
    required this.projectedBalance,
    required this.showProjected,
    required this.selectedMonth,
    required this.scheduledThisMonth,
    this.todayBudgetRemaining,
    this.todaySpending,
    this.recommendedDailyBudgetWithBuffer,
  });

  final double netBalance;
  final double projectedBalance;
  final bool showProjected;
  final DateTime selectedMonth;
  final List<ScheduledTransaction> scheduledThisMonth;
  final double? todayBudgetRemaining;
  final double? todaySpending;
  final double? recommendedDailyBudgetWithBuffer;

  @override
  State<DashboardNetBalanceSection> createState() =>
      _DashboardNetBalanceSectionState();
}

class _DashboardNetBalanceSectionState extends State<DashboardNetBalanceSection>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  final GlobalKey _infoIconKey = GlobalKey();

  bool get _canExpand => widget.scheduledThisMonth.isNotEmpty;

  void _toggleExpanded() {
    if (!_canExpand) return;
    setState(() => _isExpanded = !_isExpanded);
  }

  void _showCalculationDialog() {
    if (widget.recommendedDailyBudgetWithBuffer == null ||
        widget.todaySpending == null) {
      return;
    }

    final RenderBox? renderBox =
        _infoIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + size.width + 8,
        position.dy,
        position.dx + size.width + 8 + 200,
        position.dy + size.height,
      ),
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: OutlinedSurface(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalculationRow(
                  label: 'Conservative budget',
                  value: widget.recommendedDailyBudgetWithBuffer!,
                ),
                const SizedBox(height: 12),
                _CalculationRow(
                  label: 'Today\'s spending',
                  value: widget.todaySpending!,
                ),
                const SizedBox(height: 12),
                _CalculationRow(
                  label: 'Remaining',
                  value: widget.todayBudgetRemaining ?? 0.0,
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.todayBudgetRemaining != null) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Budget left today',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                Icons.info_outline,
                size: 16,
                color: Colors.grey[600],
                key: _infoIconKey,
              ),
            ],
          ).onTap(onTap: _showCalculationDialog),
          const SizedBox(height: 8),
          Text(
            formatNetBalance(widget.todayBudgetRemaining!),
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 24),
        ],
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
        Text(
          formatNetBalance(widget.netBalance),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        if (widget.showProjected) ...[
          const SizedBox(height: 12),
          _ProjectedBalanceRow(
            isExpanded: _isExpanded,
            canExpand: _canExpand,
            projectedBalance: widget.projectedBalance,
            onToggleExpanded: _toggleExpanded,
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (child, animation) {
              return ClipRect(
                clipBehavior: Clip.none,
                child: SizeTransition(
                  sizeFactor: animation,
                  axis: Axis.vertical,
                  axisAlignment: -1, // grow down from the top (row position)
                  child: FadeTransition(opacity: animation, child: child),
                ),
              );
            },
            child:
                _isExpanded
                    ? SizedBox(
                      key: const ValueKey('projected_schedule_expanded'),
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 16),
                          _AvailableAfterScheduledRow(
                            netBalance: widget.netBalance,
                            scheduledTotal: widget.scheduledThisMonth
                                .fold<double>(0.0, (sum, t) => sum + t.amount),
                          ),
                          const SizedBox(height: 12),
                          DashboardScheduleSection(
                            items: widget.scheduledThisMonth,
                            selectedMonth: widget.selectedMonth,
                            maxPreviewCount: null,
                          ),
                        ],
                      ),
                    )
                    : const SizedBox(
                      key: ValueKey('projected_schedule_collapsed'),
                    ),
          ),
        ],
      ],
    );
  }
}

class _ProjectedBalanceRow extends StatelessWidget {
  const _ProjectedBalanceRow({
    required this.isExpanded,
    required this.canExpand,
    required this.projectedBalance,
    required this.onToggleExpanded,
  });

  final bool isExpanded;
  final bool canExpand;
  final double projectedBalance;
  final VoidCallback onToggleExpanded;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: canExpand ? onToggleExpanded : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                if (canExpand)
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.black,
                    ),
                  )
                else
                  const SizedBox(width: 20),
                const SizedBox(width: 6),
                Text(
                  'Scheduled this month',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
            Text(
              formatNetBalance(projectedBalance),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableAfterScheduledRow extends StatelessWidget {
  const _AvailableAfterScheduledRow({
    required this.netBalance,
    required this.scheduledTotal,
  });

  final double netBalance;
  final double scheduledTotal;

  @override
  Widget build(BuildContext context) {
    final availableBalance = netBalance + scheduledTotal;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Available after scheduled',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: Colors.grey[700],
          ),
        ),
        Text(
          formatNetBalance(availableBalance),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _CalculationRow extends StatelessWidget {
  const _CalculationRow({
    required this.label,
    required this.value,
    this.isBold = false,
  });

  final String label;
  final double value;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.2,
            color: Colors.grey[700],
          ),
        ),
        Text(
          formatNetBalance(value),
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
