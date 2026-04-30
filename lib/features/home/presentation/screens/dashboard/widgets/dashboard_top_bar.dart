import 'package:flutter/material.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.monthYearLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onTapMonthLabel,
    this.onLongPressMonthLabel,
  });

  final String monthYearLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final Future<void> Function()? onTapMonthLabel;
  final VoidCallback? onLongPressMonthLabel;

  @override
  Widget build(BuildContext context) {
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
              onTap: onTapMonthLabel != null
                  ? () => onTapMonthLabel!.call()
                  : null,
              onLongPress: onLongPressMonthLabel,
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
                  if (onTapMonthLabel != null) ...[
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


