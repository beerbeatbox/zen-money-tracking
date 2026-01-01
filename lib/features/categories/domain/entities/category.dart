enum CategoryType { expense, income }

class Category {
  final String id;
  final CategoryType type;
  final String label;
  final DateTime createdAt;

  const Category({
    required this.id,
    required this.type,
    required this.label,
    required this.createdAt,
  });
}


