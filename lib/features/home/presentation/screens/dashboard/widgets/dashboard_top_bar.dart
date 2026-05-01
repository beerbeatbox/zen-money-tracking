import 'package:flutter/material.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.monthYearLabel,
    required this.isCurrentMonth,
    required this.onPreviousMonth,
    required this.onNextMonth,
    this.onTapMonthLabel,
    this.onLongPressMonthLabel,
  });

  final String monthYearLabel;
  final bool isCurrentMonth;
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
          icon: const Icon(Icons.chevron_left, color: Color(0xFF1A5C52)),
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
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
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
                        color: Color(0xFF1A5C52),
                      ),
                    ),
                    if (isCurrentMonth) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A5C52),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Now',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ],
                    if (onTapMonthLabel != null) ...[
                      const SizedBox(width: 4),
                      Icon(
                        Icons.expand_more,
                        size: 20,
                        color: const Color(0xFF1A5C52).withValues(alpha: 0.8),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        IconButton(
          onPressed: onNextMonth,
          icon: const Icon(Icons.chevron_right, color: Color(0xFF1A5C52)),
          tooltip: 'Next month',
        ),
      ],
    );
  }
}


