import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/core/widgets/section_card.dart';
import 'package:anti/features/home/presentation/widgets/number_keyboard_bottom_sheet.dart';
import 'package:anti/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:anti/features/settings/presentation/controllers/budget_setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetSettingControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopBar(),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              budgetAsync.when(
                data: (budget) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionCard(
                      child: _BudgetSourceSection(
                        selectedSource: budget.source,
                        onSourceChanged: (source) {
                          ref
                              .read(budgetSettingControllerProvider.notifier)
                              .setBudgetSource(source);
                        },
                      ),
                    ),
                    if (budget.source == BudgetSource.custom) ...[
                      const SizedBox(height: 16),
                      SectionCard(
                        child: _CustomAmountSection(
                          currentAmount: budget.customAmount,
                          onAmountChanged: (amount) {
                            ref
                                .read(budgetSettingControllerProvider.notifier)
                                .setCustomBudgetAmount(amount);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Could not load budget settings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BUDGET',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose how your daily budget is calculated',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BudgetSourceSection extends StatelessWidget {
  const _BudgetSourceSection({
    required this.selectedSource,
    required this.onSourceChanged,
  });

  final BudgetSource selectedSource;
  final ValueChanged<BudgetSource> onSourceChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'BUDGET SOURCE',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        _BudgetSourceOption(
          source: BudgetSource.custom,
          title: 'Custom',
          description: 'Set your own daily budget amount',
          selected: selectedSource == BudgetSource.custom,
          onTap: () => onSourceChanged(BudgetSource.custom),
        ),
        Divider(color: Colors.grey[300], thickness: 1),
        _BudgetSourceOption(
          source: BudgetSource.autoConservative,
          title: 'Auto Conservative',
          description:
              'Automatically calculated with a 10% safety buffer for unexpected expenses',
          selected: selectedSource == BudgetSource.autoConservative,
          onTap: () => onSourceChanged(BudgetSource.autoConservative),
        ),
        Divider(color: Colors.grey[300], thickness: 1),
        _BudgetSourceOption(
          source: BudgetSource.autoExactly,
          title: 'Auto Exactly',
          description:
              'Automatically calculated based on your available balance and remaining days',
          selected: selectedSource == BudgetSource.autoExactly,
          onTap: () => onSourceChanged(BudgetSource.autoExactly),
        ),
      ],
    );
  }
}

class _BudgetSourceOption extends StatelessWidget {
  const _BudgetSourceOption({
    required this.source,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final BudgetSource source;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Radio<BudgetSource>(
              value: source,
              groupValue: selected ? source : null,
              onChanged: (_) => onTap(),
              activeColor: Colors.black,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).onTap(behavior: HitTestBehavior.opaque, onTap: onTap);
  }
}

class _CustomAmountSection extends StatelessWidget {
  const _CustomAmountSection({
    required this.currentAmount,
    required this.onAmountChanged,
  });

  final double? currentAmount;
  final ValueChanged<double?> onAmountChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'DAILY BUDGET AMOUNT',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentAmount != null
                          ? formatNetBalance(currentAmount!)
                          : 'Not set',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: currentAmount != null
                            ? Colors.black
                            : Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to set your daily budget',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const HeroIcon(
                HeroIcons.pencil,
                style: HeroIconStyle.outline,
                color: Colors.black,
                size: 20,
              ),
            ],
          ),
        ).onTap(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showAmountInput(context),
        ),
      ],
    );
  }

  Future<void> _showAmountInput(BuildContext context) async {
    await showNumberKeyboardBottomSheet(
      context,
      initialIsExpense: true,
      initialValue: currentAmount?.toStringAsFixed(2),
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
        final amount = double.tryParse(rawValue);
        if (amount != null && amount > 0) {
          onAmountChanged(amount);
          Navigator.of(sheetContext).pop();
          return true;
        } else {
          ScaffoldMessenger.of(sheetContext).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid amount above zero.'),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 2),
            ),
          );
          return false;
        }
      },
    );
  }
}
