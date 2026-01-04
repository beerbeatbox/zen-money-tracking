import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/domain/usecases/category_service.dart';

part 'categories_controller.g.dart';

@Riverpod(keepAlive: true)
class CategoriesController extends _$CategoriesController {
  @override
  FutureOr<List<Category>> build() async {
    final service = ref.watch(categoryServiceProvider);
    return service.getCategories();
  }

  Future<void> addCategory({
    required CategoryType type,
    required String label,
    String? emoji,
  }) async {
    final service = ref.read(categoryServiceProvider);
    await service.addCategory(type: type, label: label, emoji: emoji);
    ref.invalidateSelf();
    await future;
  }

  Future<void> addSubCategory({
    required CategoryType type,
    required String parentId,
    required String label,
    String? emoji,
  }) async {
    final service = ref.read(categoryServiceProvider);
    await service.addSubCategory(
      type: type,
      parentId: parentId,
      label: label,
      emoji: emoji,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> deleteCategory(String id) async {
    final service = ref.read(categoryServiceProvider);
    await service.deleteCategory(id);
    ref.invalidateSelf();
    await future;
  }

  Future<void> renameCategory({
    required String id,
    required String label,
  }) async {
    final service = ref.read(categoryServiceProvider);
    await service.renameCategory(id: id, label: label);
    ref.invalidateSelf();
    await future;
  }

  Future<void> updateCategory({
    required String id,
    required String label,
    required String? emoji,
  }) async {
    final service = ref.read(categoryServiceProvider);
    await service.updateCategory(id: id, label: label, emoji: emoji);
    ref.invalidateSelf();
    await future;
  }

  Future<void> reorderCategoryType({
    required CategoryType type,
    required List<String> orderedIds,
  }) async {
    final service = ref.read(categoryServiceProvider);
    await service.reorderCategoryType(type: type, orderedIds: orderedIds);
    ref.invalidateSelf();
    await future;
  }

  Future<void> reorderSubCategories({
    required CategoryType type,
    required String parentId,
    required List<String> orderedIds,
  }) async {
    final service = ref.read(categoryServiceProvider);
    await service.reorderSubCategories(
      type: type,
      parentId: parentId,
      orderedIds: orderedIds,
    );
    ref.invalidateSelf();
    await future;
  }
}


