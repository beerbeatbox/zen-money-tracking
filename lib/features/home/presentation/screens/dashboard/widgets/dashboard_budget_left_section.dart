import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/extensions/widget_extension.dart';
import 'package:baht/core/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardBudgetLeftSection extends ConsumerStatefulWidget {
  const DashboardBudgetLeftSection({
    super.key,
    this.todayBudgetRemaining,
    this.todaySpending,
    this.recommendedDailyBudgetWithBuffer,
  });

  final double? todayBudgetRemaining;
  final double? todaySpending;
  final double? recommendedDailyBudgetWithBuffer;

  @override
  ConsumerState<DashboardBudgetLeftSection> createState() =>
      _DashboardBudgetLeftSectionState();
}

class _DashboardBudgetLeftSectionState
    extends ConsumerState<DashboardBudgetLeftSection> {
  final GlobalKey _infoIconKey = GlobalKey();

  void _showCalculationDialog() {
    if (widget.recommendedDailyBudgetWithBuffer == null ||
        widget.todaySpending == null) {
      return;
    }
    final isMasked = ref.read(amountMaskControllerProvider);

    final RenderBox? renderBox =
        _infoIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final Offset position = renderBox.localToGlobal(Offset.zero);
    final Size size = renderBox.size;

    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx + size.width + 8,
        position.dy,
        position.dx + size.width + 8 + 200,
        position.dy + size.height,
      ),
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      items: [
        PopupMenuItem(
          enabled: false,
          padding: EdgeInsets.zero,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CalculationRow(
                  label: 'Conservative budget',
                  value: widget.recommendedDailyBudgetWithBuffer!,
                  isMasked: isMasked,
                ),
                const SizedBox(height: 12),
                _CalculationRow(
                  label: 'Today\'s spending',
                  value: widget.todaySpending!,
                  isMasked: isMasked,
                ),
                const SizedBox(height: 12),
                _CalculationRow(
                  label: 'Remaining',
                  value: widget.todayBudgetRemaining ?? 0.0,
                  isMasked: isMasked,
                  isBold: true,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.todayBudgetRemaining == null) {
      return const SizedBox.shrink();
    }
    final isMasked = ref.watch(amountMaskControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Budget left today',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey[600],
              key: _infoIconKey,
            ),
          ],
        ).onTap(onTap: _showCalculationDialog),
        const SizedBox(height: 8),
        Text(
          formatNetBalanceMasked(
            widget.todayBudgetRemaining!,
            isMasked: isMasked,
          ),
          style: const TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _CalculationRow extends StatelessWidget {
  const _CalculationRow({
    required this.label,
    required this.value,
    required this.isMasked,
    this.isBold = false,
  });

  final String label;
  final double value;
  final bool isMasked;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            letterSpacing: 0.2,
            color: Colors.grey[700],
          ),
        ),
        Text(
          formatNetBalanceMasked(value, isMasked: isMasked),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}
