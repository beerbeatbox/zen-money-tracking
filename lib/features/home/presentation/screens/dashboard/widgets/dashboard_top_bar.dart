import 'package:flutter/material.dart';

class DashboardTopBar extends StatelessWidget {
  const DashboardTopBar({
    super.key,
    required this.monthYearLabel,
    required this.onPreviousMonth,
    required this.onNextMonth,
  });

  final String monthYearLabel;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

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
            child: Text(
              monthYearLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.black,
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


