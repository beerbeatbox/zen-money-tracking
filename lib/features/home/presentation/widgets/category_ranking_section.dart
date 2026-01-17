import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/domain/usecases/category_service.dart';
import 'package:anti/features/categories/presentation/controllers/categories_controller.dart';
import 'package:anti/features/categories/presentation/widgets/category_name_with_emoji.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryRankingSection extends ConsumerWidget {
  const CategoryRankingSection({
    super.key,
    required this.selectedMonth,
    required this.logs,
  });

  final DateTime selectedMonth;
  final List<ExpenseLog> logs;

  String _extractMainCategory(String categoryLabel) {
    final parts = categoryLabel.split(CategoryService.labelSeparator);
    return parts.first.trim();
  }

  Map<String, double> _calculateCategoryTotals() {
    final categoryTotals = <String, double>{};

    for (final log in logs) {
      final mainCategory = _extractMainCategory(log.category);
      if (mainCategory.isEmpty) continue;

      categoryTotals[mainCategory] =
          (categoryTotals[mainCategory] ?? 0) + log.amount.abs();
    }

    return categoryTotals;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryTotals = _calculateCategoryTotals();

    if (categoryTotals.isEmpty) {
      return OutlinedSurface(
        padding: const EdgeInsets.all(16),
        child: const _EmptyState(),
      );
    }

    // Sort by total amount descending
    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final categoriesAsync = ref.watch(categoriesControllerProvider);

    return categoriesAsync.when(
      data: (categories) {
        // Build category emoji map
        final categoryEmojiMap = <String, String?>{};
        for (final categoryName in categoryTotals.keys) {
          Category? category;
          try {
            category = categories.firstWhere(
              (c) =>
                  c.parentId == null &&
                  c.label.trim().toLowerCase() == categoryName.toLowerCase(),
            );
          } catch (_) {
            try {
              category = categories.firstWhere(
                (c) => c.label.trim().toLowerCase() == categoryName.toLowerCase(),
              );
            } catch (_) {
              category = null;
            }
          }
          final emoji = category?.emoji?.trim();
          categoryEmojiMap[categoryName] = emoji?.isNotEmpty == true ? emoji : null;
        }

        return OutlinedSurface(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Header(),
              const SizedBox(height: 8),
              const Divider(thickness: 2, color: Colors.black),
              const SizedBox(height: 12),
              ...sortedEntries.asMap().entries.map((entry) {
                final index = entry.key;
                final categoryEntry = entry.value;
                return _RankingItem(
                  rank: index + 1,
                  categoryName: categoryEntry.key,
                  totalAmount: categoryEntry.value,
                  emoji: categoryEmojiMap[categoryEntry.key],
                );
              }),
            ],
          ),
        );
      },
      loading: () => OutlinedSurface(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: CircularProgressIndicator(color: Colors.black),
          ),
        ),
      ),
      error: (_, __) => OutlinedSurface(
        padding: const EdgeInsets.all(16),
        child: const _EmptyState(),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Ranking',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: Colors.black,
      ),
    );
  }
}

class _RankingItem extends StatelessWidget {
  const _RankingItem({
    required this.rank,
    required this.categoryName,
    required this.totalAmount,
    required this.emoji,
  });

  final int rank;
  final String categoryName;
  final double totalAmount;
  final String? emoji;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  '$rank.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CategoryNameWithEmoji(
                    label: categoryName,
                    emoji: emoji,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    spacing: 6,
                  ),
                ),
              ],
            ),
          ),
          Text(
            formatNetBalance(totalAmount),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ranking',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Start tracking your expenses to see category rankings.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}
