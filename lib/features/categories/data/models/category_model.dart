import 'package:anti/features/categories/domain/entities/category.dart';

class CategoryModel {
  final String id;
  final String type; // 'expense' | 'income'
  final String label;
  final String createdAtIso;
  final String sortIndex; // int as string

  const CategoryModel({
    required this.id,
    required this.type,
    required this.label,
    required this.createdAtIso,
    required this.sortIndex,
  });

  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      type: entity.type.name,
      label: entity.label,
      createdAtIso: entity.createdAt.toIso8601String(),
      sortIndex: entity.sortIndex.toString(),
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      type: CategoryType.values.byName(type),
      label: label,
      createdAt: DateTime.tryParse(createdAtIso) ?? DateTime.now(),
      sortIndex: int.tryParse(sortIndex) ?? -1,
    );
  }

  static CategoryModel fromCsvRow(List<dynamic> row) {
    // id,type,label,createdAt,sortIndex
    final id = row.isNotEmpty ? row[0].toString() : '';
    final type = row.length > 1 ? row[1].toString() : CategoryType.expense.name;
    final label = row.length > 2 ? row[2].toString() : '';
    final createdAt = row.length > 3 ? row[3].toString() : '';
    final sortIndex = row.length > 4 ? row[4].toString() : '-1';
    return CategoryModel(
      id: id,
      type: type,
      label: label,
      createdAtIso: createdAt,
      sortIndex: sortIndex,
    );
  }

  List<String> toCsvRow() => [id, type, label, createdAtIso, sortIndex];
}


