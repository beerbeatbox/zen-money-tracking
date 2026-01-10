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
    this.maxPreviewCount = 3,
  });

  final List<ScheduledTransaction> items;
  final DateTime selectedMonth;
  final int? maxPreviewCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) return const SizedBox.shrink();

    final countLabel = '${items.length} Scheduled';
    final preview =
        maxPreviewCount == null ? items : items.take(maxPreviewCount!).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 0, right: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Schedule',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.black,
                ),
              ),
              Row(
                children: [
                  Text(
                    countLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TextButton(
                    onPressed:
                        () => context.go(AppRouter.scheduledTransactions.path),
                    child: const Text(
                      'View all',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(thickness: 2, color: Colors.black),
          const SizedBox(height: 12),
          ...List.generate(preview.length, (index) {
            final item = preview[index];
            return Padding(
              padding: EdgeInsets.only(bottom: index == preview.length - 1 ? 0 : 12),
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
