import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/router/app_router.dart';
import 'package:baht/core/utils/formatters.dart';
import 'package:baht/features/home/domain/entities/scheduled_transaction.dart';
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
    final header =
        widget.isExpandable
            ? InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _toggleExpanded,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Upcoming',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                      color: Colors.black,
                    ),
                  ),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            )
            : const Text(
              'Upcoming',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.black,
              ),
            );

    if (widget.items.isEmpty) {
      return Column(
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
                        padding: const EdgeInsets.only(top: 12),
                        child: _emptyHint(),
                      )
                      : const SizedBox.shrink(),
            )
          else ...[
            const SizedBox(height: 12),
            _emptyHint(),
          ],
        ],
      );
    }

    final total = _calculateTotal(widget.items);
    final isMasked = ref.watch(amountMaskControllerProvider);
    final totalLabel = formatCurrencySignedMasked(total, isMasked: isMasked);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        header,
        const SizedBox(height: 16),
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
                                ...List.generate(widget.items.length, (index) {
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
    );
  }
}
