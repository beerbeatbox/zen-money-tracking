enum CategoryType { expense, income }

class Category {
  final String id;
  final CategoryType type;
  final String label;
  final String? emoji;
  final DateTime createdAt;
  final int sortIndex;

  const Category({
    required this.id,
    required this.type,
    required this.label,
    this.emoji,
    required this.createdAt,
    required this.sortIndex,
  });
}
