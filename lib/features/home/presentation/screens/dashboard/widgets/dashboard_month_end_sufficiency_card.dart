import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:flutter/material.dart';

class DashboardMonthEndSufficiencyCard extends StatefulWidget {
  const DashboardMonthEndSufficiencyCard({
    super.key,
    this.sufficiencyBreakdown,
  });

  final MonthEndSufficiencyBreakdown? sufficiencyBreakdown;

  @override
  State<DashboardMonthEndSufficiencyCard> createState() =>
      _DashboardMonthEndSufficiencyCardState();
}

class _DashboardMonthEndSufficiencyCardState
    extends State<DashboardMonthEndSufficiencyCard>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  bool get _canExpand => widget.sufficiencyBreakdown != null;

  void _toggleExpanded() {
    if (!_canExpand) return;
    setState(() => _isExpanded = !_isExpanded);
  }

  @override
  Widget build(BuildContext context) {
    final breakdown = widget.sufficiencyBreakdown;
    if (breakdown == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: breakdown.isSufficient
            ? const Color(0xFFE8F5E9) // Light green
            : const Color(0xFFFFEBEE), // Light red
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: breakdown.isSufficient
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF44336),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _toggleExpanded,
            child: Row(
              children: [
                Icon(
                  breakdown.isSufficient
                      ? Icons.sentiment_very_satisfied
                      : Icons.sentiment_dissatisfied,
                  color: breakdown.isSufficient
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFF44336),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        breakdown.isSufficient
                            ? 'You\'re on track until month end'
                            : 'Watch your spending to stay on track',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        breakdown.isSufficient
                            ? 'You\'ll have ${formatNetBalance(breakdown.monthEndBalance.abs())} left'
                            : 'You\'ll need ${formatNetBalance(breakdown.monthEndBalance.abs())} more',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeInOut,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    size: 20,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
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
                  axisAlignment: -1,
                  child: FadeTransition(opacity: animation, child: child),
                ),
              );
            },
            child: _isExpanded
                ? SizedBox(
                    key: const ValueKey('breakdown_expanded'),
                    width: double.infinity,
                    child: _BreakdownSection(breakdown: breakdown),
                  )
                : const SizedBox(
                    key: ValueKey('breakdown_collapsed'),
                  ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownSection extends StatelessWidget {
  const _BreakdownSection({
    required this.breakdown,
  });

  final MonthEndSufficiencyBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Divider(thickness: 1, color: Colors.black12),
        const SizedBox(height: 16),
        _BreakdownRow(
          label: 'Your current balance',
          value: formatNetBalance(breakdown.currentBalance),
          icon: Icons.account_balance_wallet,
        ),
        const SizedBox(height: 12),
        _BreakdownRow(
          label: 'Average daily spending',
          value: formatNetBalance(breakdown.averageDailySpending),
          icon: Icons.trending_down,
        ),
        const SizedBox(height: 12),
        _BreakdownRow(
          label: 'Days remaining',
          value: '${breakdown.daysRemaining} days',
          icon: Icons.calendar_today,
        ),
        const SizedBox(height: 12),
        _BreakdownRow(
          label: 'Remaining scheduled',
          value: formatNetBalance(breakdown.remainingScheduledTotal),
          icon: Icons.schedule,
        ),
        const SizedBox(height: 12),
        _BreakdownRow(
          label: 'Due now scheduled',
          value: formatNetBalance(breakdown.dueNowScheduledTotal),
          icon: Icons.pending_actions,
        ),
        const SizedBox(height: 12),
        _BreakdownRow(
          label: 'Projected spending',
          value: formatNetBalance(breakdown.projectedDailySpending),
          icon: Icons.auto_graph,
        ),
        const SizedBox(height: 16),
        const Divider(thickness: 1, color: Colors.black12),
        const SizedBox(height: 16),
        _CalculationBreakdown(breakdown: breakdown),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: breakdown.isSufficient
                ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                : const Color(0xFFF44336).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                breakdown.isSufficient
                    ? Icons.check_circle
                    : Icons.warning_amber_rounded,
                color: breakdown.isSufficient
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFF44336),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Month-end balance: ${formatNetBalance(breakdown.monthEndBalance)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: breakdown.isSufficient
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFF44336),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: Colors.grey[700],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _CalculationBreakdown extends StatelessWidget {
  const _CalculationBreakdown({
    required this.breakdown,
  });

  final MonthEndSufficiencyBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Calculation',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        _CalculationLine(
          label: 'Current balance',
          value: formatNetBalance(breakdown.currentBalance),
          isPositive: true,
        ),
        _CalculationLine(
          label: 'Remaining scheduled',
          value: formatNetBalance(breakdown.remainingScheduledTotal),
          isPositive: true,
        ),
        _CalculationLine(
          label: 'Due now scheduled',
          value: formatNetBalance(breakdown.dueNowScheduledTotal),
          isPositive: true,
        ),
        _CalculationLine(
          label: 'Projected spending',
          value: formatNetBalance(breakdown.projectedDailySpending),
          isPositive: false,
        ),
        const SizedBox(height: 4),
        const Divider(thickness: 1, color: Colors.black26),
        const SizedBox(height: 4),
        _CalculationLine(
          label: 'Month-end balance',
          value: formatNetBalance(breakdown.monthEndBalance),
          isPositive: breakdown.monthEndBalance >= 0,
          isBold: true,
        ),
      ],
    );
  }
}

class _CalculationLine extends StatelessWidget {
  const _CalculationLine({
    required this.label,
    required this.value,
    required this.isPositive,
    this.isBold = false,
  });

  final String label;
  final String value;
  final bool isPositive;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(
                isPositive ? '+ ' : '- ',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
