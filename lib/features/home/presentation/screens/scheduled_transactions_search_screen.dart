import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/router/app_router.dart';
import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';
import 'package:anti/features/home/presentation/controllers/scheduled_transaction_controller.dart';
import 'package:anti/features/home/presentation/widgets/scheduled_transaction_search_box.dart';
import 'package:anti/features/home/presentation/widgets/scheduled_transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

enum _ScheduledPaymentsFilter { all, oneTime, days, weeks, months, years }

class ScheduledTransactionsSearchScreen extends ConsumerStatefulWidget {
  const ScheduledTransactionsSearchScreen({super.key});

  @override
  ConsumerState<ScheduledTransactionsSearchScreen> createState() =>
      _ScheduledTransactionsSearchScreenState();
}

class _ScheduledTransactionsSearchScreenState
    extends ConsumerState<ScheduledTransactionsSearchScreen> {
  final _searchController = TextEditingController();
  var _filter = _ScheduledPaymentsFilter.all;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(scheduledTransactionsProvider);
    final searchQuery = _searchController.text.trim();
    final filter = _filter;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const HeroIcon(
                      HeroIcons.arrowLeft,
                      style: HeroIconStyle.outline,
                      color: Colors.black,
                      size: 22,
                    ),
                    tooltip: 'Back',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ScheduledTransactionSearchBox(
                      controller: _searchController,
                      autofocus: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _FilterChips(
                value: filter,
                onChanged: (next) => setState(() => _filter = next),
              ),
              const SizedBox(height: 16),
              itemsAsync.when(
                data: (items) {
                  final filtered = _applySearchAndFilters(
                    items,
                    searchQuery: searchQuery,
                    filter: filter,
                  );
                  return _Content(
                    filter: filter,
                    items: filtered,
                    hasSearchQuery: searchQuery.isNotEmpty,
                    onEdit:
                        (item) => context.push(
                          AppRouter.scheduledTransactionDetail.path
                              .replaceFirst(':id', item.id),
                          extra: item,
                        ),
                  );
                },
                loading:
                    () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.black,
                        ),
                      ),
                    ),
                error:
                    (_, __) => _ErrorState(
                      onRetry:
                          () => ref.invalidate(scheduledTransactionsProvider),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Checks if all characters in the query appear in order in the target string.
  /// This allows fuzzy matching like "ytb" matching "Youtube".
  bool _fuzzyMatch(String query, String target) {
    if (query.isEmpty) return true;
    if (target.isEmpty) return false;

    final normalizedQuery = query.toLowerCase();
    final normalizedTarget = target.toLowerCase();

    int queryIndex = 0;
    for (
      int i = 0;
      i < normalizedTarget.length && queryIndex < normalizedQuery.length;
      i++
    ) {
      if (normalizedTarget[i] == normalizedQuery[queryIndex]) {
        queryIndex++;
      }
    }

    return queryIndex == normalizedQuery.length;
  }

  List<ScheduledTransaction> _applySearchAndFilters(
    List<ScheduledTransaction> items, {
    required String searchQuery,
    required _ScheduledPaymentsFilter filter,
  }) {
    var result = items;

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final normalizedQuery = searchQuery.toLowerCase();
      result = result
          .where((item) {
            final normalizedTitle = item.title.toLowerCase();
            final normalizedCategory = item.category.toLowerCase();

            // Try substring matching first (fast path)
            final titleSubstringMatch = normalizedTitle.contains(
              normalizedQuery,
            );
            final categorySubstringMatch = normalizedCategory.contains(
              normalizedQuery,
            );
            final amountMatch = item.amount.abs().toString().contains(
              searchQuery,
            );

            // If substring match found, return early
            if (titleSubstringMatch || categorySubstringMatch || amountMatch) {
              return true;
            }

            // Fallback to fuzzy matching for title and category
            final titleFuzzyMatch = _fuzzyMatch(
              normalizedQuery,
              normalizedTitle,
            );
            final categoryFuzzyMatch = _fuzzyMatch(
              normalizedQuery,
              normalizedCategory,
            );

            return titleFuzzyMatch || categoryFuzzyMatch;
          })
          .toList(growable: false);
    }

    // Apply frequency filter
    result = _applyFilter(result, filter);

    return result;
  }

  List<ScheduledTransaction> _applyFilter(
    List<ScheduledTransaction> items,
    _ScheduledPaymentsFilter filter,
  ) {
    switch (filter) {
      case _ScheduledPaymentsFilter.all:
        return items;
      case _ScheduledPaymentsFilter.oneTime:
        return items
            .where((e) => e.frequency == PaymentFrequency.oneTime)
            .toList(growable: false);
      case _ScheduledPaymentsFilter.days:
        return items
            .where(
              (e) =>
                  e.frequency == PaymentFrequency.interval &&
                  e.intervalUnit == IntervalUnit.days,
            )
            .toList(growable: false);
      case _ScheduledPaymentsFilter.weeks:
        return items
            .where(
              (e) =>
                  e.frequency == PaymentFrequency.interval &&
                  e.intervalUnit == IntervalUnit.weeks,
            )
            .toList(growable: false);
      case _ScheduledPaymentsFilter.months:
        return items
            .where(
              (e) =>
                  e.frequency == PaymentFrequency.interval &&
                  e.intervalUnit == IntervalUnit.months,
            )
            .toList(growable: false);
      case _ScheduledPaymentsFilter.years:
        return items
            .where(
              (e) =>
                  e.frequency == PaymentFrequency.interval &&
                  e.intervalUnit == IntervalUnit.years,
            )
            .toList(growable: false);
    }
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.value, required this.onChanged});

  final _ScheduledPaymentsFilter value;
  final ValueChanged<_ScheduledPaymentsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _FilterChip(
          label: 'All',
          selected: value == _ScheduledPaymentsFilter.all,
          onTap: () => onChanged(_ScheduledPaymentsFilter.all),
        ),
        _FilterChip(
          label: 'One-time',
          selected: value == _ScheduledPaymentsFilter.oneTime,
          onTap: () => onChanged(_ScheduledPaymentsFilter.oneTime),
        ),
        _FilterChip(
          label: 'Days',
          selected: value == _ScheduledPaymentsFilter.days,
          onTap: () => onChanged(_ScheduledPaymentsFilter.days),
        ),
        _FilterChip(
          label: 'Weeks',
          selected: value == _ScheduledPaymentsFilter.weeks,
          onTap: () => onChanged(_ScheduledPaymentsFilter.weeks),
        ),
        _FilterChip(
          label: 'Months',
          selected: value == _ScheduledPaymentsFilter.months,
          onTap: () => onChanged(_ScheduledPaymentsFilter.months),
        ),
        _FilterChip(
          label: 'Years',
          selected: value == _ScheduledPaymentsFilter.years,
          onTap: () => onChanged(_ScheduledPaymentsFilter.years),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = selected ? Colors.black : Colors.white;
    final fg = selected ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(
        label,
        style: TextStyle(
          color: fg,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.2,
        ),
      ),
    ).onTap(onTap: onTap);
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.filter,
    required this.items,
    required this.hasSearchQuery,
    required this.onEdit,
  });

  final _ScheduledPaymentsFilter filter;
  final List<ScheduledTransaction> items;
  final bool hasSearchQuery;
  final Future<void> Function(ScheduledTransaction item) onEdit;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return _EmptyState(filter: filter, hasSearchQuery: hasSearchQuery);
    }

    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        return Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 32),
          child: ScheduledTransactionTile(
            item: item,
            onEdit: () => onEdit(item),
            showRecurrenceBadges: true,
          ),
        );
      }),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.filter, required this.hasSearchQuery});

  final _ScheduledPaymentsFilter filter;
  final bool hasSearchQuery;

  @override
  Widget build(BuildContext context) {
    String message;
    if (hasSearchQuery) {
      message = 'No payments found. Try adjusting your search or filters.';
    } else {
      message = switch (filter) {
        _ScheduledPaymentsFilter.all => 'Start planning your payments.',
        _ScheduledPaymentsFilter.oneTime =>
          'Schedule a payment to plan ahead with confidence.',
        _ScheduledPaymentsFilter.days =>
          'Add a daily recurring payment to track regular expenses.',
        _ScheduledPaymentsFilter.weeks =>
          'Add a weekly recurring payment to keep your bills on track.',
        _ScheduledPaymentsFilter.months =>
          'Add a monthly recurring payment to plan ahead with confidence.',
        _ScheduledPaymentsFilter.years =>
          'Schedule a yearly recurring payment to plan ahead with confidence.',
      };
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Let's try that again.",
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: onRetry,
          child: const Text(
            'Reload scheduled payments',
            style: TextStyle(fontWeight: FontWeight.w700, color: Colors.black),
          ),
        ),
      ],
    );
  }
}
