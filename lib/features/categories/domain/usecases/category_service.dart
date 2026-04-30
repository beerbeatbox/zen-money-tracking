import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:baht/features/categories/data/repositories/category_repository.dart';
import 'package:baht/features/categories/domain/entities/category.dart';

part 'category_service.g.dart';

class CategoryService {
  const CategoryService(this._repository);

  final CategoryRepository _repository;
  static const labelSeparator = ' - ';

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
          emoji: null,
          parentId: null,
          createdAt: now,
          sortIndex: defaultExpenseLabels.indexOf(label),
        ),
      ),
      ...defaultIncomeLabels.map(
        (label) => Category(
          id: '${CategoryType.income.name}-$label-${now.microsecondsSinceEpoch}',
          type: CategoryType.income,
          label: label,
          emoji: null,
          parentId: null,
          createdAt: now,
          sortIndex: defaultIncomeLabels.indexOf(label),
        ),
      ),
    ];
    return seeded;
  }

  String _groupKey(Category c) => '${c.type.name}:${c.parentId ?? ''}';

  bool _isMain(Category c) => c.parentId == null;

  List<Category> _reindexGroups(List<Category> categories) {
    final groups = <String, List<Category>>{};
    for (final c in categories) {
      (groups[_groupKey(c)] ??= <Category>[]).add(c);
    }

    final updatedById = <String, Category>{};
    for (final entry in groups.entries) {
      final items = [...entry.value]..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
      for (var i = 0; i < items.length; i++) {
        final c = items[i];
        updatedById[c.id] = Category(
          id: c.id,
          type: c.type,
          label: c.label,
          emoji: c.emoji,
          parentId: c.parentId,
          createdAt: c.createdAt,
          sortIndex: i,
        );
      }
    }

    return categories.map((c) => updatedById[c.id] ?? c).toList(growable: false);
  }

  List<Category> _normalizeSortIndexIfNeeded(List<Category> categories) {
    // If sortIndex is missing/invalid/duplicated, re-index per (type + parentId)
    // while preserving the current grouping.
    bool needsNormalize = false;
    final seenByGroup = <String, Set<int>>{};

    for (final c in categories) {
      if (c.sortIndex < 0) {
        needsNormalize = true;
        break;
      }
      final key = _groupKey(c);
      final set = seenByGroup.putIfAbsent(key, () => <int>{});
      if (set.contains(c.sortIndex)) {
        needsNormalize = true;
        break;
      }
      set.add(c.sortIndex);
    }

    if (!needsNormalize) return categories;

    return _reindexGroups(categories);
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
    String? emoji,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.contains(labelSeparator)) return;

    final normalizedEmoji = (emoji ?? '').trim();
    final emojiOrNull = normalizedEmoji.isEmpty ? null : normalizedEmoji;

    final categories = await getCategories();
    final exists =
        categories.any(
          (c) =>
              c.type == type &&
              c.parentId == null &&
              c.label.trim().toLowerCase() == trimmed.toLowerCase(),
        );
    if (exists) return;

    final currentType =
        categories
            .where((c) => c.type == type && c.parentId == null)
            .toList(growable: false);
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
      emoji: emojiOrNull,
      parentId: null,
      createdAt: now,
      sortIndex: nextIndex,
    );
    await setCategories([...categories, newItem]);
  }

  Future<void> addSubCategory({
    required CategoryType type,
    required String parentId,
    required String label,
    String? emoji,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.contains(labelSeparator)) return;

    final normalizedEmoji = (emoji ?? '').trim();
    final emojiOrNull = normalizedEmoji.isEmpty ? null : normalizedEmoji;

    final categories = await getCategories();
    final parent =
        categories.where((c) => c.id == parentId && c.type == type).toList();
    if (parent.isEmpty) return;

    final exists =
        categories.any(
          (c) =>
              c.type == type &&
              c.parentId == parentId &&
              c.label.trim().toLowerCase() == trimmed.toLowerCase(),
        );
    if (exists) return;

    final siblings =
        categories.where((c) => c.type == type && c.parentId == parentId).toList();
    final nextIndex =
        siblings.isEmpty
            ? 0
            : (siblings.map((c) => c.sortIndex).reduce((a, b) => a > b ? a : b) +
                1);

    final now = DateTime.now();
    final newItem = Category(
      id: '${type.name}-sub-$parentId-$trimmed-${now.microsecondsSinceEpoch}',
      type: type,
      label: trimmed,
      emoji: emojiOrNull,
      parentId: parentId,
      createdAt: now,
      sortIndex: nextIndex,
    );
    await setCategories([...categories, newItem]);
  }

  Future<void> deleteCategory(String id) async {
    final categories = await getCategories();
    final target = categories.where((c) => c.id == id).toList();
    if (target.isEmpty) return;

    final isMain = _isMain(target.first);
    final updated =
        categories
            .where(
              (c) => c.id != id && (!isMain || c.parentId != id),
            )
            .toList();

    await setCategories(_reindexGroups(updated));
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

    await updateCategory(id: id, label: trimmed, emoji: current.emoji);
  }

  Future<void> updateCategory({
    required String id,
    required String label,
    required String? emoji,
  }) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.contains(labelSeparator)) return;

    final normalizedEmoji = (emoji ?? '').trim();
    final emojiOrNull = normalizedEmoji.isEmpty ? null : normalizedEmoji;

    final categories = await getCategories();
    final existing = categories.where((c) => c.id == id).toList();
    if (existing.isEmpty) return;
    final current = existing.first;

    final exists =
        categories.any(
          (c) =>
              c.id != id &&
              c.type == current.type &&
              c.parentId == current.parentId &&
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
                        emoji: emojiOrNull,
                        parentId: c.parentId,
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
        categories
            .where((c) => c.type == type && c.parentId == null)
            .toList(growable: false)
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    // Keep only ids belonging to this type + main group, preserving the incoming order.
    final filteredIds =
        orderedIds
            .where((id) => byId[id]?.type == type && byId[id]?.parentId == null)
            .toList(growable: false);

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
          emoji: byId[finalOrder[i]]!.emoji,
          parentId: byId[finalOrder[i]]!.parentId,
          createdAt: byId[finalOrder[i]]!.createdAt,
          sortIndex: i,
        ),
    ];

    final updatedById = {for (final c in updatedType) c.id: c};
    final updated =
        categories
            .map((c) => updatedById[c.id] ?? c)
            .toList(growable: false);
    await setCategories(updated);
  }

  Future<void> reorderSubCategories({
    required CategoryType type,
    required String parentId,
    required List<String> orderedIds,
  }) async {
    final categories = await getCategories();
    final byId = {for (final c in categories) c.id: c};

    final currentGroup =
        categories
            .where((c) => c.type == type && c.parentId == parentId)
            .toList(growable: false)
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    final filteredIds =
        orderedIds
            .where(
              (id) =>
                  byId[id]?.type == type && byId[id]?.parentId == parentId,
            )
            .toList(growable: false);

    final missing =
        currentGroup
            .map((c) => c.id)
            .where((id) => !filteredIds.contains(id))
            .toList(growable: false);
    final finalOrder = [...filteredIds, ...missing];

    final updatedGroup = <Category>[
      for (var i = 0; i < finalOrder.length; i++)
        Category(
          id: byId[finalOrder[i]]!.id,
          type: byId[finalOrder[i]]!.type,
          label: byId[finalOrder[i]]!.label,
          emoji: byId[finalOrder[i]]!.emoji,
          parentId: byId[finalOrder[i]]!.parentId,
          createdAt: byId[finalOrder[i]]!.createdAt,
          sortIndex: i,
        ),
    ];

    final updatedById = {for (final c in updatedGroup) c.id: c};
    final updated =
        categories
            .map((c) => updatedById[c.id] ?? c)
            .toList(growable: false);
    await setCategories(updated);
  }

  Future<void> deleteCategoryFile() => _repository.deleteCategoryFile();
}

@riverpod
CategoryService categoryService(Ref ref) {
  final repository = ref.watch(categoryRepositoryProvider);
  return CategoryService(repository);
}


