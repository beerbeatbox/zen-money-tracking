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
                      if (breakdown.daysRemaining > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _getComparisonColor(
                                  breakdown.currentVsRecommended,
                                ).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: _getComparisonColor(
                                    breakdown.currentVsRecommended,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getComparisonIcon(
                                      breakdown.currentVsRecommended,
                                    ),
                                    size: 14,
                                    color: _getComparisonColor(
                                      breakdown.currentVsRecommended,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Aim to spend around ${formatNetBalance(breakdown.recommendedDailyBudget)} per day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getComparisonColor(
                                        breakdown.currentVsRecommended,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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
        if (breakdown.daysRemaining > 0) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _getComparisonColor(breakdown.currentVsRecommended)
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getComparisonColor(breakdown.currentVsRecommended),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: _getComparisonColor(
                        breakdown.currentVsRecommended,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily budget recommendation',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[900],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _DailyBudgetRecommendationRow(
                  label: 'Balanced',
                  value: formatNetBalance(breakdown.recommendedDailyBudget),
                  description: 'To reach month end comfortably',
                  icon: Icons.balance,
                ),
                const SizedBox(height: 8),
                _DailyBudgetRecommendationRow(
                  label: 'Conservative',
                  value: formatNetBalance(
                    breakdown.recommendedDailyBudgetWithBuffer,
                  ),
                  description: 'With 10% safety buffer',
                  icon: Icons.shield,
                ),
                const SizedBox(height: 8),
                _ComparisonIndicator(breakdown: breakdown),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
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

Color _getComparisonColor(DailyBudgetComparison comparison) {
  switch (comparison) {
    case DailyBudgetComparison.under:
      return const Color(0xFF4CAF50); // Green
    case DailyBudgetComparison.onTrack:
      return const Color(0xFF2196F3); // Blue
    case DailyBudgetComparison.over:
      return const Color(0xFFFF9800); // Orange
  }
}

IconData _getComparisonIcon(DailyBudgetComparison comparison) {
  switch (comparison) {
    case DailyBudgetComparison.under:
      return Icons.trending_down;
    case DailyBudgetComparison.onTrack:
      return Icons.check_circle;
    case DailyBudgetComparison.over:
      return Icons.trending_up;
  }
}

class _DailyBudgetRecommendationRow extends StatelessWidget {
  const _DailyBudgetRecommendationRow({
    required this.label,
    required this.value,
    required this.description,
    required this.icon,
  });

  final String label;
  final String value;
  final String description;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.grey[700],
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[900],
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
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ComparisonIndicator extends StatelessWidget {
  const _ComparisonIndicator({
    required this.breakdown,
  });

  final MonthEndSufficiencyBreakdown breakdown;

  String _getComparisonMessage() {
    final diff = breakdown.averageDailySpending -
        breakdown.recommendedDailyBudget;

    switch (breakdown.currentVsRecommended) {
      case DailyBudgetComparison.under:
        return 'You\'re spending ${formatNetBalance(diff.abs())} less per day than recommended. Great job!';
      case DailyBudgetComparison.onTrack:
        return 'You\'re on track! Your spending aligns with the recommendation.';
      case DailyBudgetComparison.over:
        return 'You\'re spending ${formatNetBalance(diff.abs())} more per day than recommended. Consider reducing spending to stay on track.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getComparisonIcon(breakdown.currentVsRecommended),
            size: 16,
            color: _getComparisonColor(breakdown.currentVsRecommended),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getComparisonMessage(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
