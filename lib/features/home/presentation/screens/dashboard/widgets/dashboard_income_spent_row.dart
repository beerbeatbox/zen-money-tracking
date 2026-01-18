import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti/core/controllers/amount_mask_controller.dart';
import 'package:anti/core/utils/formatters.dart';

class DashboardIncomeSpentRow extends ConsumerWidget {
  const DashboardIncomeSpentRow({
    super.key,
    required this.income,
    required this.spent,
  });

  final double income;
  final double spent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMasked = ref.watch(amountMaskControllerProvider);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Income',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrencySignedMasked(income, isMasked: isMasked),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Spent',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatCurrencySignedMasked(spent, isMasked: isMasked),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


