enum CategoryType { expense, income }

class Category {
  final String id;
  final CategoryType type;
  final String label;
  final String? emoji;
  /// Null means this is a main category. Non-null means this is a sub-category
  /// under the category with the given id.
  final String? parentId;
  final DateTime createdAt;
  final int sortIndex;

  const Category({
    required this.id,
    required this.type,
    required this.label,
    this.emoji,
    this.parentId,
    required this.createdAt,
    required this.sortIndex,
  });
}
