import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/categories/data/repositories/category_repository.dart';
import 'package:anti/features/categories/domain/entities/category.dart';

part 'category_service.g.dart';

class CategoryService {
  const CategoryService(this._repository);

  final CategoryRepository _repository;

  static const defaultExpenseLabels = <String>[
    'Food',
    'Bill',
    'Shopping',
    'Subscription',
    'Investment',
    'Family',
    'Essential',
    'Others',
  ];

  static const defaultIncomeLabels = <String>[
    'Salary',
    'Bonus',
    'Business',
    'Gift',
    'Interest',
    'Refund',
    'Investment Return',
    'Others',
  ];

  List<Category> _seedDefaults() {
    final now = DateTime.now();
    final seeded = <Category>[
      ...defaultExpenseLabels.map(
        (label) => Category(
          id: '${CategoryType.expense.name}-$label-${now.microsecondsSinceEpoch}',
          type: CategoryType.expense,
          label: label,
          createdAt: now,
          sortIndex: defaultExpenseLabels.indexOf(label),
        ),
      ),
      ...defaultIncomeLabels.map(
        (label) => Category(
          id: '${CategoryType.income.name}-$label-${now.microsecondsSinceEpoch}',
          type: CategoryType.income,
          label: label,
          createdAt: now,
          sortIndex: defaultIncomeLabels.indexOf(label),
        ),
      ),
    ];
    return seeded;
  }

  List<Category> _normalizeSortIndexIfNeeded(List<Category> categories) {
    // If sortIndex is missing/invalid/duplicated, re-index per type while
    // preserving current file order (the repository returns rows in file order).
    bool needsNormalize = false;
    final seenExpense = <int>{};
    final seenIncome = <int>{};

    for (final c in categories) {
      if (c.sortIndex < 0) {
        needsNormalize = true;
        break;
      }
      final set = c.type == CategoryType.expense ? seenExpense : seenIncome;
      if (set.contains(c.sortIndex)) {
        needsNormalize = true;
        break;
      }
      set.add(c.sortIndex);
    }

    if (!needsNormalize) return categories;

    final expense = <Category>[];
    final income = <Category>[];
    for (final c in categories) {
      (c.type == CategoryType.expense ? expense : income).add(c);
    }

    final normalized = <Category>[
      for (var i = 0; i < expense.length; i++)
        Category(
          id: expense[i].id,
          type: expense[i].type,
          label: expense[i].label,
          createdAt: expense[i].createdAt,
          sortIndex: i,
        ),
      for (var i = 0; i < income.length; i++)
        Category(
          id: income[i].id,
          type: income[i].type,
          label: income[i].label,
          createdAt: income[i].createdAt,
          sortIndex: i,
        ),
    ];

    return normalized;
  }

  Future<List<Category>> getCategories() async {
    final categories = await _repository.getCategories();
    if (categories.isNotEmpty) {
      final normalized = _normalizeSortIndexIfNeeded(categories);
      if (normalized != categories) {
        await _repository.setCategories(normalized);
      }
      return normalized;
    }

    final seeded = _seedDefaults();
    await _repository.setCategories(seeded);
    return seeded;
  }

  Future<void> setCategories(List<Category> categories) =>
      _repository.setCategories(categories);

  Future<void> addCategory({
    required CategoryType type,
    required String label,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;

    final categories = await getCategories();
    final exists =
        categories.any(
          (c) =>
              c.type == type &&
              c.label.trim().toLowerCase() == trimmed.toLowerCase(),
        );
    if (exists) return;

    final currentType =
        categories.where((c) => c.type == type).toList(growable: false);
    final nextIndex =
        currentType.isEmpty
            ? 0
            : (currentType.map((c) => c.sortIndex).reduce((a, b) => a > b ? a : b) +
                1);

    final now = DateTime.now();
    final newItem = Category(
      id: '${type.name}-$trimmed-${now.microsecondsSinceEpoch}',
      type: type,
      label: trimmed,
      createdAt: now,
      sortIndex: nextIndex,
    );
    await setCategories([...categories, newItem]);
  }

  Future<void> deleteCategory(String id) async {
    final categories = await getCategories();
    final updated = categories.where((c) => c.id != id).toList();
    if (updated.length == categories.length) return;

    // Reindex per type to keep order stable and indices compact.
    final expense =
        updated.where((c) => c.type == CategoryType.expense).toList()
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final income =
        updated.where((c) => c.type == CategoryType.income).toList()
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    final reindexed = <Category>[
      for (var i = 0; i < expense.length; i++)
        Category(
          id: expense[i].id,
          type: expense[i].type,
          label: expense[i].label,
          createdAt: expense[i].createdAt,
          sortIndex: i,
        ),
      for (var i = 0; i < income.length; i++)
        Category(
          id: income[i].id,
          type: income[i].type,
          label: income[i].label,
          createdAt: income[i].createdAt,
          sortIndex: i,
        ),
    ];

    await setCategories(reindexed);
  }

  Future<void> renameCategory({
    required String id,
    required String label,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;

    final categories = await getCategories();
    final existing = categories.where((c) => c.id == id).toList();
    if (existing.isEmpty) return;
    final current = existing.first;

    final exists =
        categories.any(
          (c) =>
              c.id != id &&
              c.type == current.type &&
              c.label.trim().toLowerCase() == trimmed.toLowerCase(),
        );
    if (exists) return;

    final updated =
        categories
            .map(
              (c) =>
                  c.id == id
                      ? Category(
                        id: c.id,
                        type: c.type,
                        label: trimmed,
                        createdAt: c.createdAt,
                        sortIndex: c.sortIndex,
                      )
                      : c,
            )
            .toList(growable: false);
    await setCategories(updated);
  }

  Future<void> reorderCategoryType({
    required CategoryType type,
    required List<String> orderedIds,
  }) async {
    final categories = await getCategories();

    final byId = {for (final c in categories) c.id: c};
    final currentType =
        categories.where((c) => c.type == type).toList(growable: false)
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    // Keep only ids belonging to this type, preserving the incoming order.
    final filteredIds =
        orderedIds.where((id) => byId[id]?.type == type).toList(growable: false);

    // Append any missing ids (safety for partial/old lists).
    final missing =
        currentType
            .map((c) => c.id)
            .where((id) => !filteredIds.contains(id))
            .toList(growable: false);
    final finalOrder = [...filteredIds, ...missing];

    final updatedType = <Category>[
      for (var i = 0; i < finalOrder.length; i++)
        Category(
          id: byId[finalOrder[i]]!.id,
          type: byId[finalOrder[i]]!.type,
          label: byId[finalOrder[i]]!.label,
          createdAt: byId[finalOrder[i]]!.createdAt,
          sortIndex: i,
        ),
    ];

    final otherType =
        categories.where((c) => c.type != type).toList(growable: false)
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    await setCategories([...updatedType, ...otherType]);
  }

  Future<void> deleteCategoryFile() => _repository.deleteCategoryFile();
}

@riverpod
CategoryService categoryService(Ref ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryService(repository);
}


