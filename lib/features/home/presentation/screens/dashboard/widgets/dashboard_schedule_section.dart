import 'package:anti/core/router/app_router.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/widgets/scheduled_transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScheduleSection extends ConsumerWidget {
  const DashboardScheduleSection({
    super.key,
    required this.items,
    required this.selectedMonth,
  });

  final List<ScheduledTransaction> items;
  final DateTime selectedMonth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scheduled',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 2, color: Colors.black),
          const SizedBox(height: 12),
          ...List.generate(items.length, (index) {
            final item = items[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : 12,
              ),
              child: ScheduledTransactionTile(
                item: item,
                onEdit:
                    () => context.push(
                      AppRouter.scheduledTransactionDetail.path.replaceFirst(
                        ':id',
                        item.id,
                      ),
                      extra: item,
                    ),
                showStatusLabel: true,
              ),
            );
          }),
        ],
      ),
    );
  }
}
