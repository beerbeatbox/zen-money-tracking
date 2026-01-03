import 'package:anti/features/categories/domain/entities/category.dart';

class CategoryModel {
  final String id;
  final String type; // 'expense' | 'income'
  final String label;
  final String emoji; // optional, can be empty
  final String createdAtIso;
  final String sortIndex; // int as string

  const CategoryModel({
    required this.id,
    required this.type,
    required this.label,
    required this.emoji,
    required this.createdAtIso,
    required this.sortIndex,
  });

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      type: entity.type.name,
      label: entity.label,
      emoji: entity.emoji ?? '',
      createdAtIso: entity.createdAt.toIso8601String(),
      sortIndex: entity.sortIndex.toString(),
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      type: CategoryType.values.byName(type),
      label: label,
      emoji: emoji.trim().isEmpty ? null : emoji,
      createdAt: DateTime.tryParse(createdAtIso) ?? DateTime.now(),
      sortIndex: int.tryParse(sortIndex) ?? -1,
    );
  }

  static CategoryModel fromCsvRow(List<dynamic> row) {
    // id,type,label,createdAt,sortIndex,emoji
    final id = row.isNotEmpty ? row[0].toString() : '';
    final type = row.length > 1 ? row[1].toString() : CategoryType.expense.name;
    final label = row.length > 2 ? row[2].toString() : '';
    final createdAt = row.length > 3 ? row[3].toString() : '';
    final sortIndex = row.length > 4 ? row[4].toString() : '-1';
    final emoji = row.length > 5 ? row[5].toString() : '';
    return CategoryModel(
      id: id,
      type: type,
      label: label,
      emoji: emoji,
      createdAtIso: createdAt,
      sortIndex: sortIndex,
    );
  }

  List<String> toCsvRow() => [id, type, label, createdAtIso, sortIndex, emoji];
}


