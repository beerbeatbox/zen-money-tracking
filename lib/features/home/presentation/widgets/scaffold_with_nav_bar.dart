import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'custom_bottom_nav.dart';
import 'number_keyboard_bottom_sheet.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  const ScaffoldWithNavBar({required this.child, super.key});

  final Widget child;

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openKeyboard(BuildContext context, WidgetRef ref) async {
    await showNumberKeyboardBottomSheet(
      context,
      onSubmit: (sheetContext, rawValue, isExpense) async {
        final parsed = double.tryParse(rawValue);
        if (parsed == null) {
          _showSnack(sheetContext, 'Please enter a valid number.');
          return false;
        }
        if (parsed <= 0) {
          _showSnack(
            sheetContext,
            'Add an amount above zero to log your spending.',
          );
          return false;
        }

        final now = DateTime.now();
        final amount = isExpense ? -parsed.abs() : parsed.abs();
        final log = ExpenseLog(
          id: now.microsecondsSinceEpoch.toString(),
          title: 'Quick entry',
          timeLabel: _formatTimeLabel(now),
          category: 'General',
          amount: amount,
          createdAt: now,
        );

        try {
          await ref.read(addExpenseLogActionProvider(log).future);
          return true;
        } catch (_) {
          _showSnack(sheetContext, "Let's try that again.");
          return false;
        }
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openKeyboard(context, ref),
        backgroundColor: Colors.white,
        shape: const CircleBorder(
          side: BorderSide(color: Colors.black, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: const Icon(Icons.add, color: Colors.black),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNav(),
    );
  }
}
