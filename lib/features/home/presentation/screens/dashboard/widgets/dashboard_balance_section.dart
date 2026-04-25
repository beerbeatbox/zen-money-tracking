import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti/core/controllers/amount_mask_controller.dart';
import 'package:anti/core/utils/formatters.dart';

class DashboardBalanceSection extends ConsumerWidget {
  const DashboardBalanceSection({
    super.key,
    required this.netBalance,
    required this.projectedBalance,
    required this.showProjected,
    required this.onUpdateBalance,
  });

  final double netBalance;
  final double projectedBalance;
  final bool showProjected;
  final VoidCallback onUpdateBalance;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMasked = ref.watch(amountMaskControllerProvider);
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
        Text(
          formatNetBalanceMasked(netBalance, isMasked: isMasked),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        if (showProjected) ...[
          const SizedBox(height: 12),
          _ProjectedBalanceRow(
            projectedBalance: projectedBalance,
            isMasked: isMasked,
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onUpdateBalance,
            style: TextButton.styleFrom(
              foregroundColor: Colors.blue,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            child: const Text('Update your balance'),
          ),
        ),
      ],
    );
  }
}

class _ProjectedBalanceRow extends StatelessWidget {
  const _ProjectedBalanceRow({
    required this.projectedBalance,
    required this.isMasked,
  });

  final double projectedBalance;
  final bool isMasked;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
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
            formatNetBalanceMasked(projectedBalance, isMasked: isMasked),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
