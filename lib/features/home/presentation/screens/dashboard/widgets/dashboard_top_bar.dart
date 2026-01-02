import 'package:flutter/material.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.monthYearLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onTapMonthLabel,
  });

  final String monthYearLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function()? onTapMonthLabel;

  @override
  Widget build(BuildContext context) {
    final isMonthLabelTappable = onTapMonthLabel != null;

    return Row(
      children: [
        IconButton(
          onPressed: onPreviousMonth,
          icon: const Icon(Icons.chevron_left, color: Colors.black),
          tooltip: 'Previous month',
        ),
        Expanded(
          child: Center(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: isMonthLabelTappable ? () => onTapMonthLabel!.call() : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    monthYearLabel,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Colors.black,
                    ),
                  ),
                  if (isMonthLabelTappable) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.expand_more,
                      size: 20,
                      color: Colors.black.withValues(alpha: 0.8),
                    ),
                  ],
                ],
              ),
            ),
          ),
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


