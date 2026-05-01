import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/router/app_router.dart';
import 'package:baht/core/utils/formatters.dart';
import 'package:baht/features/home/domain/entities/scheduled_transaction.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_doodle_divider.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_section_header_styles.dart';
import 'package:baht/features/home/presentation/widgets/scheduled_transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class DashboardScheduleSection extends ConsumerStatefulWidget {
  const DashboardScheduleSection({
    super.key,
    required this.items,
    required this.selectedMonth,
    this.isExpandable = false,
  });

  final List<ScheduledTransaction> items;
  final DateTime selectedMonth;
  final bool isExpandable;

  @override
  ConsumerState<DashboardScheduleSection> createState() =>
      _DashboardScheduleSectionState();
}

class _DashboardScheduleSectionState
    extends ConsumerState<DashboardScheduleSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.isExpandable;
  }

  void _toggleExpanded() {
    setState(() => _isExpanded = !_isExpanded);
  }

  double _calculateTotal(List<ScheduledTransaction> items) {
    return items.fold<double>(0.0, (sum, t) {
      final amountToUse =
          t.isDynamicAmount ? -(t.budgetAmount ?? t.amount.abs()) : t.amount;
      return sum + amountToUse;
    });
  }

  static const _upcomingAccentBlue = Color(0xFF6A9FD4);

  Widget _wrapWithDecoration(Widget child) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          top: -48,
          right: -52,
          child: IgnorePointer(child: _UpcomingTopCorner()),
        ),
        child,
      ],
    );
  }

  Widget _buildHeaderTitleRow() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Row(
          children: [
            Text(
              'Upcoming',
              style: DashboardSectionHeaderStyles.titleStyle(
                color: DashboardSectionHeaderStyles.upcomingTitleColor,
              ),
            ),
            const Spacer(),
          ],
        ),
        const Positioned(
          right: 0,
          top: 0,
          child: DashboardDoodleDivider.wave(color: _upcomingAccentBlue),
        ),
      ],
    );
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
                    'Upcoming',
                    style: DashboardSectionHeaderStyles.titleStyle(
                      color: DashboardSectionHeaderStyles.upcomingTitleColor,
                    ),
                  ),
                  const Positioned(
                    right: 28,
                    top: 0,
                    child: DashboardDoodleDivider.wave(
                      color: _upcomingAccentBlue,
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
                color: DashboardSectionHeaderStyles.upcomingTitleColor,
              ),
            ),
          ],
        ),
      );
    }
    return _buildHeaderTitleRow();
  }

  Widget _emptyHint() {
    return Text(
      'Open Scheduled to add payments you want to track each month.',
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
    final header = _buildHeader();

    if (widget.items.isEmpty) {
      return _wrapWithDecoration(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header,
            if (widget.isExpandable)
              AnimatedSize(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child:
                    _isExpanded
                        ? Padding(
                          padding: const EdgeInsets.only(
                            top:
                                DashboardSectionHeaderStyles.spacingBelowTitle,
                          ),
                          child: _emptyHint(),
                        )
                        : const SizedBox.shrink(),
              )
            else ...[
              const SizedBox(
                height: DashboardSectionHeaderStyles.spacingBelowTitle,
              ),
              _emptyHint(),
            ],
          ],
        ),
      );
    }

    final total = _calculateTotal(widget.items);
    final isMasked = ref.watch(amountMaskControllerProvider);
    final totalLabel = formatCurrencySignedMasked(total, isMasked: isMasked);

    return _wrapWithDecoration(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header,
          const SizedBox(
            height: DashboardSectionHeaderStyles.spacingBelowTitle + 4,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                totalLabel,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: Colors.black,
                ),
              ),
            ],
          ),
            ClipRect(
            clipBehavior: Clip.none,
            child:
                widget.isExpandable
                    ? AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      alignment: Alignment.topCenter,
                      child:
                          _isExpanded
                              ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 12),
                                  ...List.generate(widget.items.length, (
                                    index,
                                  ) {
                                    final item = widget.items[index];
                                    return Padding(
                                      padding: EdgeInsets.only(
                                        bottom:
                                            index == widget.items.length - 1
                                                ? 0
                                                : 32,
                                      ),
                                      child: ScheduledTransactionTile(
                                        item: item,
                                        onEdit:
                                            () => context.push(
                                              AppRouter
                                                  .scheduledTransactionDetail
                                                  .path
                                                  .replaceFirst(':id', item.id),
                                              extra: item,
                                            ),
                                        showStatusLabel: true,
                                      ),
                                    );
                                  }),
                                ],
                              )
                              : const SizedBox.shrink(),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        ...List.generate(widget.items.length, (index) {
                          final item = widget.items[index];
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == widget.items.length - 1 ? 0 : 32,
                            ),
                            child: ScheduledTransactionTile(
                              item: item,
                              onEdit:
                                  () => context.push(
                                    AppRouter.scheduledTransactionDetail.path
                                        .replaceFirst(':id', item.id),
                                    extra: item,
                                  ),
                              showStatusLabel: true,
                            ),
                          );
                        }),
                      ],
                    ),
          ),
      ],
    ),
    );
  }
}

/// Soft blob + dots in the card’s top-right — blue palette for Upcoming.
class _UpcomingTopCorner extends StatelessWidget {
  const _UpcomingTopCorner();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(100, 78),
      painter: _UpcomingTopCornerPainter(),
    );
  }
}

class _UpcomingTopCornerPainter extends CustomPainter {
  static const _blob = Color(0xFFCCDEFF);
  static const _dot = Color(0xFF8CB4E8);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final blobPaint =
        Paint()
          ..color = _blob
          ..style = PaintingStyle.fill;

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

    canvas.drawCircle(Offset(w * 0.62, h * 0.20), 3.8, dotPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.32), 3.2, dotPaint);
  }

  @override
  bool shouldRepaint(_UpcomingTopCornerPainter oldDelegate) => false;
}
