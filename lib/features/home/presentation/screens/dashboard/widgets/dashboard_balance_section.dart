import 'package:anti/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class DashboardNetBalanceSection extends StatelessWidget {
  const DashboardNetBalanceSection({
    super.key,
    required this.netBalance,
    required this.projectedBalance,
    required this.showProjected,
  });

  final double netBalance;
  final double projectedBalance;
  final bool showProjected;

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
        if (showProjected) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Projected balance',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: Colors.grey[700],
                ),
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
        ],
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


