import 'package:baht/features/categories/data/datasources/category_local_datasource.dart';
import 'package:baht/features/categories/data/models/category_model.dart';
import 'package:baht/features/categories/domain/entities/category.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_repository.g.dart';

class CategoryRepository {
  final CategoryLocalDatasource _datasource;

  const CategoryRepository(this._datasource);

  Future<List<Category>> getCategories() async {
    final models = await _datasource.readAll();
    return models.map((m) => m.toEntity()).toList();
  }

  Future<void> setCategories(List<Category> categories) async {
    final models = categories.map(CategoryModel.fromEntity).toList();
    await _datasource.overwrite(models);
  }

  Future<void> deleteCategoryFile() => _datasource.deleteFile();
}

@riverpod
CategoryRepository categoryRepository(Ref ref) {
  final datasource = ref.watch(categoryLocalDatasourceProvider);
  return CategoryRepository(datasource);
}
