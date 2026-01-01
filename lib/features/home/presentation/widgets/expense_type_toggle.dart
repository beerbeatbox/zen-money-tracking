import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:flutter/material.dart';

class ExpenseTypeToggle extends StatelessWidget {
  const ExpenseTypeToggle({
    super.key,
    required this.isExpense,
    required this.onChanged,
  });

  final bool isExpense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypeChip(
            label: 'Expense',
            selected: isExpense,
            onTap: () => onChanged(true),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.black,
          ).paddingSymmetric(horizontal: 10),
          _TypeChip(
            label: 'Income',
            selected: !isExpense,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      isPressed: false,
      color: Colors.white,
      pressedColor: Colors.white,
      border: const Border.fromBorderSide(
        BorderSide(color: Colors.transparent, width: 0),
      ),
      unpressedShadowOffset: Offset.zero,
      pressedShadowOffset: Offset.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: 0.6,
              color: selected ? Colors.black : Colors.grey[600],
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: 34,
            color: selected ? Colors.black : Colors.transparent,
          ),
        ],
      ),
    ).onTap(onTap: onTap, behavior: HitTestBehavior.opaque);
  }
}


