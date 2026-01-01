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
        ),
      ),
      ...defaultIncomeLabels.map(
        (label) => Category(
          id: '${CategoryType.income.name}-$label-${now.microsecondsSinceEpoch}',
          type: CategoryType.income,
          label: label,
          createdAt: now,
        ),
      ),
    ];
    return seeded;
  }

  Future<List<Category>> getCategories() async {
    final categories = await _repository.getCategories();
    if (categories.isNotEmpty) return categories;

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

    final now = DateTime.now();
    final newItem = Category(
      id: '${type.name}-$trimmed-${now.microsecondsSinceEpoch}',
      type: type,
      label: trimmed,
      createdAt: now,
    );
    await setCategories([...categories, newItem]);
  }

  Future<void> deleteCategory(String id) async {
    final categories = await getCategories();
    final updated = categories.where((c) => c.id != id).toList();
    if (updated.length == categories.length) return;
    await setCategories(updated);
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
                      )
                      : c,
            )
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


