import 'package:anti/core/router/app_router.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:anti/features/home/presentation/widgets/scheduled_transaction_tile.dart';
import 'package:anti/features/settings/presentation/widgets/outlined_confirmation_dialog.dart';
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

    return Column(
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
          final isLast = index == preview.length - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
            child: ScheduledTransactionTile(
              item: item,
              onConvert: () => _convert(context, ref, item),
              onDelete: () => _confirmAndDelete(context, ref, item),
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
    );
  }

  Future<void> _confirmAndDelete(
    BuildContext context,
    WidgetRef ref,
    ScheduledTransaction item,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return OutlinedConfirmationDialog(
          title: 'Remove this scheduled payment?',
          description: 'You can schedule it again anytime.',
          primaryLabel: 'Remove payment',
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
          secondaryLabel: 'Keep it',
          onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );

    if (shouldDelete != true) return;
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(deleteScheduledTransactionActionProvider(item.id).future);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Scheduled payment removed.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Let's try that again."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _convert(
    BuildContext context,
    WidgetRef ref,
    ScheduledTransaction item,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(
        convertScheduledTransactionToLogActionProvider(item).future,
      );
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Added to your logs.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text("Let's try that again."),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
