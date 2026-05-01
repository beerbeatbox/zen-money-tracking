import 'package:baht/core/router/app_router.dart';
import 'package:baht/features/home/domain/entities/scheduled_transaction.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_doodle_divider.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_section_header_styles.dart';
import 'package:baht/features/home/presentation/widgets/scheduled_transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardDueNowSection extends ConsumerStatefulWidget {
  const DashboardDueNowSection({
    super.key,
    required this.items,
    this.isExpandable = false,
  });

  final List<ScheduledTransaction> items;
  final bool isExpandable;

  @override
  ConsumerState<DashboardDueNowSection> createState() =>
      _DashboardDueNowSectionState();
}

class _DashboardDueNowSectionState
    extends ConsumerState<DashboardDueNowSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.items.isNotEmpty;
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  Widget _buildHeader() {
    if (widget.isExpandable) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: _toggleExpanded,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Text(
                    'Due now',
                    style: DashboardSectionHeaderStyles.titleStyle(
                      color: DashboardSectionHeaderStyles.dueNowTitleColor,
                    ),
                  ),
                  const Positioned(
                    right: 28,
                    top: 0,
                    child: DashboardDoodleDivider.swirl(
                      color: Color(0xFFE08B78),
                    ),
                  ),
                ],
              ),
            ),
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: Icon(
                Icons.keyboard_arrow_down,
                size: 20,
                color: DashboardSectionHeaderStyles.dueNowTitleColor,
              ),
            ),
          ],
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            Text(
              'Due now',
              style: DashboardSectionHeaderStyles.titleStyle(
                color: DashboardSectionHeaderStyles.dueNowTitleColor,
              ),
            ),
            const Spacer(),
          ],
        ),
        const Positioned(
          right: 0,
          top: 0,
          child: DashboardDoodleDivider.swirl(color: Color(0xFFE08B78)),
        ),
      ],
    );
  }

  Widget _emptyHint() {
    return Text(
      'You are all caught up — nothing needs attention today.',
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: Colors.grey[600],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
            _buildHeader(),
            if (widget.isExpandable)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child:
                    _isExpanded
                        ? Padding(
                          padding: const EdgeInsets.only(
                            top: DashboardSectionHeaderStyles.spacingBelowTitle,
                          ),
                          child:
                              widget.items.isEmpty
                                  ? _emptyHint()
                                  : _buildItems(context),
                        )
                        : const SizedBox.shrink(),
              )
            else ...[
              const SizedBox(
                height: DashboardSectionHeaderStyles.spacingBelowTitle,
              ),
              if (widget.items.isEmpty)
                _emptyHint()
              else
                _buildItems(context),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildItems(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(widget.items.length, (index) {
        final item = widget.items[index];
        final isLast = index == widget.items.length - 1;
        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
          child: ScheduledTransactionTile(
            item: item,
            iconBackgroundColor:
                DashboardSectionHeaderStyles.dueNowTitleColor.withValues(
                  alpha: 0.12,
                ),
            onEdit:
                () => context.push(
                  '${AppRouter.scheduledTransactionDetail.path.replaceFirst(':id', item.id)}?dueNow=1',
                  extra: item,
                ),
            showStatusLabel: true,
          ),
        );
      }),
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
  static const _blob = Color(0xFFFFBBA8);
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
          ..color = _dot.withValues(alpha: 0.90)
          ..style = PaintingStyle.fill;

    // Near top-right (“inner” side of blob, still upper area)
    canvas.drawCircle(Offset(w * 0.62, h * 0.20), 3.8, dotPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.32), 3.2, dotPaint);
  }

  @override
  bool shouldRepaint(_DueNowTopCornerPainter oldDelegate) => false;

}
