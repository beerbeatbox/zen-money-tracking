import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardSpendingSection extends ConsumerWidget {
  const DashboardSpendingSection({
    super.key,
    required this.todaySpending,
    required this.netBalance,
  });

  final double todaySpending;
  final double netBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMasked = ref.watch(amountMaskControllerProvider);
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
          formatCurrencySignedMasked(-todaySpending, isMasked: isMasked),
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
              formatNetBalanceMasked(netBalance, isMasked: isMasked),
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
