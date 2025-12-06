import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/usecases/expense_log_service.dart';
import 'package:anti/features/home/presentation/controllers/expense_logs_controller.dart';

import 'number_keyboard_bottom_sheet.dart';

class CustomBottomBar extends ConsumerWidget {
  const CustomBottomBar({super.key});

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openKeyboard(BuildContext context, WidgetRef ref) async {
    final rawValue = await showNumberKeyboardBottomSheet(context);
    if (rawValue == null) return;

    final parsed = double.tryParse(rawValue);
    if (parsed == null) {
      _showSnack(context, 'Please enter a valid number.');
      return;
    }

    final now = DateTime.now();
    final log = ExpenseLog(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'Quick entry',
      timeLabel: _formatTimeLabel(now),
      category: 'General',
      amount: -parsed.abs(),
      createdAt: now,
    );

    try {
      final service = ref.read(expenseLogServiceProvider);
      await service.addExpenseLog(log);
      ref.invalidate(expenseLogsProvider);
      await ref.read(expenseLogsProvider.future);
      _showSnack(context, 'Great job! Expense saved.');
    } catch (_) {
      _showSnack(context, 'Something went wrong. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.transparent)),
        ),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => _openKeyboard(context, ref),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Add amount',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ),
    );
  }
}
