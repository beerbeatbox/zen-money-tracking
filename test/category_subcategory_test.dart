import 'package:anti/features/categories/data/models/category_model.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/presentation/widgets/category_name_with_emoji.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryModel CSV migration', () {
    test('old CSV row (no parentId) maps to parentId == null', () {
      final row = [
        'id-1',
        CategoryType.expense.name,
        'Subscription',
        '2026-01-01T00:00:00.000Z',
        '0',
        '💳',
      ];

      final model = CategoryModel.fromCsvRow(row);
      final entity = model.toEntity();

      expect(entity.parentId, isNull);
      expect(entity.label, 'Subscription');
      expect(entity.emoji, '💳');
    });

    test('new CSV row (with parentId) maps to parentId', () {
      final row = [
        'id-2',
        CategoryType.expense.name,
        'YouTube',
        '2026-01-01T00:00:00.000Z',
        '0',
        '▶️',
        'main-1',
      ];

      final model = CategoryModel.fromCsvRow(row);
      final entity = model.toEntity();

      expect(entity.parentId, 'main-1');
      expect(entity.label, 'YouTube');
      expect(entity.emoji, '▶️');
    });
  });

  group('resolveCategoryEmoji (Main - Sub)', () {
    test('prefers sub-category emoji when present', () {
      final categories = [
        Category(
          id: 'm1',
          type: CategoryType.expense,
          label: 'Subscription',
          emoji: '💳',
          parentId: null,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          sortIndex: 0,
        ),
        Category(
          id: 's1',
          type: CategoryType.expense,
          label: 'YouTube',
          emoji: '▶️',
          parentId: 'm1',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          sortIndex: 0,
        ),
      ];

      final emoji = resolveCategoryEmoji(
        label: 'Subscription - YouTube',
        categories: categories,
        type: CategoryType.expense,
      );
      expect(emoji, '▶️');
    });

    test('falls back to main emoji when sub has no emoji', () {
      final categories = [
        Category(
          id: 'm1',
          type: CategoryType.expense,
          label: 'Subscription',
          emoji: '💳',
          parentId: null,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          sortIndex: 0,
        ),
        Category(
          id: 's1',
          type: CategoryType.expense,
          label: 'YouTube',
          emoji: null,
          parentId: 'm1',
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          sortIndex: 0,
        ),
      ];

      final emoji = resolveCategoryEmoji(
        label: 'Subscription - YouTube',
        categories: categories,
        type: CategoryType.expense,
      );
      expect(emoji, '💳');
    });
  });
}


