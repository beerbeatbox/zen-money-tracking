import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/screens/dashboard/widgets/dashboard_schedule_section.dart';
import 'package:flutter/material.dart';

class DashboardNetBalanceSection extends StatefulWidget {
  const DashboardNetBalanceSection({
    super.key,
    required this.netBalance,
    required this.projectedBalance,
    required this.showProjected,
    required this.selectedMonth,
    required this.scheduledThisMonth,
  });

  final double netBalance;
  final double projectedBalance;
  final bool showProjected;
  final DateTime selectedMonth;
  final List<ScheduledTransaction> scheduledThisMonth;

  @override
  State<DashboardNetBalanceSection> createState() =>
      _DashboardNetBalanceSectionState();
}

class _DashboardNetBalanceSectionState extends State<DashboardNetBalanceSection>
    with TickerProviderStateMixin {
  bool _isExpanded = false;

  bool get _canExpand => widget.scheduledThisMonth.isNotEmpty;

  void _toggleExpanded() {
    if (!_canExpand) return;
    setState(() => _isExpanded = !_isExpanded);
  }

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
          value: widget.netBalance,
          textStyle: const TextStyle(
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
              return SizeTransition(
                sizeFactor: animation,
                axis: Axis.vertical,
                axisAlignment: -1, // grow down from the top (row position)
                child: FadeTransition(opacity: animation, child: child),
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
                          _ScheduledTotalRow(
                            total: widget.scheduledThisMonth.fold<double>(
                              0.0,
                              (sum, t) => sum + t.amount,
                            ),
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

class _ScheduledTotalRow extends StatelessWidget {
  const _ScheduledTotalRow({required this.total});

  final double total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Scheduled total',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: Colors.grey[700],
          ),
        ),
        Text(
          formatNetBalance(total),
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
                  'Projected balance',
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
