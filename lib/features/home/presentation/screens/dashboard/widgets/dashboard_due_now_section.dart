import 'package:baht/core/router/app_router.dart';
import 'package:baht/features/home/domain/entities/scheduled_transaction.dart';
import 'package:baht/features/home/presentation/widgets/scheduled_transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardDueNowSection extends ConsumerWidget {
  const DashboardDueNowSection({super.key, required this.items});

  final List<ScheduledTransaction> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DUE NOW',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: Colors.red[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mark these paid or update dates so your balance stays accurate.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(items.length, (index) {
          final item = items[index];
          final isLast = index == items.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
            child: ScheduledTransactionTile(
              item: item,
              onEdit:
                  () => context.push(
                    '${AppRouter.scheduledTransactionDetail.path.replaceFirst(
                      ':id',
                      item.id,
                    )}?dueNow=1',
                    extra: item,
                  ),
              showStatusLabel: true,
            ),
          );
        }),
      ],
    );
  }
}
