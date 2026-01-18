import 'package:anti/core/router/app_router.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/widgets/scheduled_transaction_tile.dart';
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

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final total = _calculateTotal(widget.items);
    final totalLabel = formatCurrencySigned(total);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.isExpandable
            ? InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _toggleExpanded,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          totalLabel,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                  ],
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
        const SizedBox(height: 8),
        const Divider(thickness: 2, color: Colors.black),
        ClipRect(
          clipBehavior: Clip.none,
          child: widget.isExpandable
              ? AnimatedSize(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeInOut,
                  alignment: Alignment.topCenter,
                  child: _isExpanded
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            ...List.generate(widget.items.length, (index) {
                              final item = widget.items[index];
                              return Padding(
                                padding: EdgeInsets.only(
                                  bottom: index == widget.items.length - 1
                                      ? 0
                                      : 12,
                                ),
                                child: ScheduledTransactionTile(
                                  item: item,
                                  onEdit: () => context.push(
                                    AppRouter.scheduledTransactionDetail.path
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
                          bottom: index == widget.items.length - 1 ? 0 : 12,
                        ),
                        child: ScheduledTransactionTile(
                          item: item,
                          onEdit: () => context.push(
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
