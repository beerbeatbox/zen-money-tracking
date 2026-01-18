import 'package:anti/core/utils/formatters.dart';
import 'package:flutter/material.dart';

class DashboardSpendingSection extends StatelessWidget {
  const DashboardSpendingSection({
    super.key,
    required this.todaySpending,
    required this.netBalance,
  });

  final double todaySpending;
  final double netBalance;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row: Label + Spending (vertical)
        Text(
          'Spent today',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          formatCurrencySigned(-todaySpending),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        // Second row: Label + Balance (horizontal)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
            Text(
              formatNetBalance(netBalance),
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
    );
  }
}
