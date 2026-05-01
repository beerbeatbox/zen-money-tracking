import 'package:baht/core/router/app_router.dart';
import 'package:baht/features/home/domain/entities/scheduled_transaction.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_doodle_divider.dart';
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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          top: -48,
          right: -52,
          child: IgnorePointer(child: _DueNowTopCorner()),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'DUE NOW',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Color(0xFFCC5533),
                  ),
                ),
                const Spacer(),
                const DashboardDoodleDivider.swirl(color: Color(0xFFE08B78)),
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
                        '${AppRouter.scheduledTransactionDetail.path.replaceFirst(':id', item.id)}?dueNow=1',
                        extra: item,
                      ),
                  showStatusLabel: true,
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

/// Soft blob + dots kept in the card’s top-right — dots sit beside the blob
/// toward the inner card (matching design reference).
class _DueNowTopCorner extends StatelessWidget {
  const _DueNowTopCorner();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 78),
      painter: _DueNowTopCornerPainter(),
    );
  }
}

class _DueNowTopCornerPainter extends CustomPainter {
  static const _blob = Color(0xFFFFD5C8);
  static const _dot = Color(0xFFE8A090);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final blobPaint =
        Paint()
          ..color = _blob
          ..style = PaintingStyle.fill;

    // Organic lump hugging top + right edges of this paint rect
    final blob =
        Path()
          ..moveTo(w * 0.72, -h * 0.06)
          ..cubicTo(w * 1.06, -h * 0.12, w * 1.18, h * 0.22, w * 1.02, h * 0.58)
          ..cubicTo(w * 0.88, h * 0.88, w * 0.52, h * 0.95, w * 0.32, h * 0.62)
          ..cubicTo(w * 0.18, h * 0.38, w * 0.28, h * 0.08, w * 0.58, -h * 0.02)
          ..cubicTo(
            w * 0.66,
            -h * 0.05,
            w * 0.68,
            -h * 0.06,
            w * 0.72,
            -h * 0.06,
          )
          ..close();
    canvas.drawPath(blob, blobPaint);

    final dotPaint =
        Paint()
          ..color = _dot.withValues(alpha: 0.72)
          ..style = PaintingStyle.fill;

    // Near top-right (“inner” side of blob, still upper area)
    canvas.drawCircle(Offset(w * 0.62, h * 0.20), 3.8, dotPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.32), 3.2, dotPaint);
  }

  @override
  bool shouldRepaint(_DueNowTopCornerPainter oldDelegate) => false;
}

