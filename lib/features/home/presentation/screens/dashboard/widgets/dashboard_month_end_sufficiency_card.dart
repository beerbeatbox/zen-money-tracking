import 'package:anti/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class DashboardMonthEndSufficiencyCard extends StatelessWidget {
  const DashboardMonthEndSufficiencyCard({
    super.key,
    required this.isSufficient,
    required this.monthEndBalance,
  });

  final bool isSufficient;
  final double? monthEndBalance;

  @override
  Widget build(BuildContext context) {
    if (monthEndBalance == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isSufficient
            ? const Color(0xFFE8F5E9) // Light green
            : const Color(0xFFFFEBEE), // Light red
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSufficient
              ? const Color(0xFF4CAF50)
              : const Color(0xFFF44336),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isSufficient ? Icons.sentiment_very_satisfied : Icons.sentiment_dissatisfied,
            color: isSufficient
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
                  isSufficient
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
                  isSufficient
                      ? 'You\'ll have ${formatNetBalance(monthEndBalance!.abs())} left'
                      : 'You\'ll need ${formatNetBalance(monthEndBalance!.abs())} more',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
