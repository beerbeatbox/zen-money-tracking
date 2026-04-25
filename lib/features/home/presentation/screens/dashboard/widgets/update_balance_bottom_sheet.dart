import 'package:anti/core/constants/app_sizes.dart';
import 'package:anti/features/home/presentation/controllers/balance_snapshot_controller.dart';
import 'package:anti/features/home/presentation/controllers/dashboard_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Lets the user set their real current balance as a [BalanceSnapshot] (not an expense log).
Future<void> showUpdateBalanceBottomSheet(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24.0,
          right: 24.0,
          top: 24.0,
          bottom: MediaQuery.viewInsetsOf(ctx).bottom + 24.0,
        ),
        child: const _UpdateBalanceForm(),
      );
    },
  );
}

class _UpdateBalanceForm extends ConsumerStatefulWidget {
  const _UpdateBalanceForm();

  @override
  ConsumerState<_UpdateBalanceForm> createState() => _UpdateBalanceFormState();
}

class _UpdateBalanceFormState extends ConsumerState<_UpdateBalanceForm> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  var _saving = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = _amountController.text.trim().replaceAll(',', '');
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      _showMessage('Add an amount to set your current balance.');
      return;
    }

    setState(() => _saving = true);
    try {
      final note = _noteController.text.trim();
      await ref
          .read(balanceSnapshotListControllerProvider.notifier)
          .setCurrentBalance(
            amount: parsed,
            note: note.isEmpty ? null : note,
          );
      ref.invalidate(dashboardControllerProvider);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      _showMessage("Let's try that again.");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Set your current balance',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: Sizes.kP8),
        Text(
          'Enter the amount you have now. Your activity stays focused on real income and spending.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
            height: 1.35,
          ),
        ),
        const SizedBox(height: Sizes.kP24),
        TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          textInputAction: TextInputAction.next,
          decoration: InputDecoration(
            labelText: 'Your balance',
            hintText: '0.00',
            prefixText: '฿',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: Sizes.kP16),
        TextField(
          controller: _noteController,
          maxLines: 2,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: 'Note (optional)',
            hintText: 'Why you are updating this',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        const SizedBox(height: Sizes.kP24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text(
                    'Save balance',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
          ),
        ),
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}
