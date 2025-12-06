import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/usecases/expense_log_service.dart';
import 'package:anti/features/home/presentation/controllers/expense_logs_controller.dart';

import 'number_keyboard_bottom_sheet.dart';

class CustomBottomBar extends ConsumerStatefulWidget {
  const CustomBottomBar({super.key});

  @override
  ConsumerState<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends ConsumerState<CustomBottomBar> {
  bool _ctaPressed = false;

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

  Future<void> _openKeyboard(BuildContext context) async {
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

  void _setCtaPressed(bool value) {
    if (_ctaPressed == value) return;
    setState(() => _ctaPressed = value);
  }

  Future<void> _releaseCtaWithPause() async {
    await Future.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    _setCtaPressed(false);
  }

  @override
  Widget build(BuildContext context) {
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
          height: 72,
          child: Center(
            child: GestureDetector(
              onTapDown: (_) => _setCtaPressed(true),
              onTapUp: (_) => _releaseCtaWithPause(),
              onTapCancel: () => _releaseCtaWithPause(),
              onTap: () => _openKeyboard(context),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 80),
                curve: Curves.easeOut,
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _ctaPressed ? const Color(0xFFF7F7F7) : Colors.white,
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black,
                      offset:
                          _ctaPressed ? const Offset(1, 1) : const Offset(3, 3),
                      blurRadius: 0,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: const Icon(Icons.add, color: Colors.black, size: 28),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
