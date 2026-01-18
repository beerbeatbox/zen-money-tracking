import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/presentation/widgets/number_keyboard_bottom_sheet.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:flutter/material.dart';

Future<double?> showDynamicAmountPaidDialog(
  BuildContext context, {
  required String category,
  required double budgetAmount,
  double? previousAmount,
}) async {
  return showDialog<double>(
    context: context,
    barrierDismissible: true,
    builder:
        (context) => _DynamicAmountPaidDialog(
          category: category,
          budgetAmount: budgetAmount,
          previousAmount: previousAmount,
        ),
  );
}

class _DynamicAmountPaidDialog extends StatefulWidget {
  const _DynamicAmountPaidDialog({
    required this.category,
    required this.budgetAmount,
    this.previousAmount,
  });

  final String category;
  final double budgetAmount;
  final double? previousAmount;

  @override
  State<_DynamicAmountPaidDialog> createState() =>
      _DynamicAmountPaidDialogState();
}

class _DynamicAmountPaidDialogState extends State<_DynamicAmountPaidDialog> {
  String _value = '';
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.previousAmount != null) {
      _value = widget.previousAmount!.toStringAsFixed(2);
      _controller.text = _value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String get _displayValue => _value.isEmpty ? '0' : _value;

  void _handleConfirm() {
    final amount = double.tryParse(_displayValue);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount above zero.'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    Navigator.of(context).pop(amount);
  }

  void _handleCancel() {
    Navigator.of(context).pop();
  }

  Future<void> _openNumberKeyboard() async {
    await showNumberKeyboardBottomSheet(
      context,
      initialIsExpense: true,
      initialValue: _value.isEmpty ? null : _value,
      showFrequencyChips: false,
      onSubmit: (
        sheetContext,
        rawValue,
        isExpense,
        logDateTime,
        category,
        freq,
        count,
        unit,
        isDynamicAmount,
        budgetAmount,
      ) async {
        setState(() {
          _value = rawValue;
          _controller.text = rawValue;
        });
        return true;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter actual amount',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.category,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Budget: ${formatNetBalance(widget.budgetAmount)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      _value.isEmpty
                          ? 'Tap to enter amount'
                          : formatNetBalance(
                            double.tryParse(_displayValue) ?? 0,
                          ),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _value.isEmpty ? Colors.grey[500] : Colors.black,
                      ),
                    ),
                  ),
                  Icon(Icons.keyboard, color: Colors.grey[600], size: 20),
                ],
              ),
            ).onTap(onTap: _openNumberKeyboard),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedActionButton(
                    label: 'Cancel',
                    onPressed: _handleCancel,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedActionButton(
                    label: 'Confirm',
                    onPressed: _handleConfirm,
                    textColor: Colors.white,
                    borderColor: Colors.black,
                    backgroundColor: Colors.black,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
