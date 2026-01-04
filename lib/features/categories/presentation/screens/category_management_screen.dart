import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/presentation/controllers/categories_controller.dart';
import 'package:anti/features/categories/presentation/widgets/category_name_with_emoji.dart';
import 'package:anti/features/home/presentation/widgets/expense_type_toggle.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:anti/features/settings/presentation/widgets/outlined_confirmation_dialog.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  bool _isExpense = true;
  List<Category> _expenseMainsWorking = const [];
  List<Category> _incomeMainsWorking = const [];
  Map<String, List<Category>> _expenseSubsWorkingByParent = {};
  Map<String, List<Category>> _incomeSubsWorkingByParent = {};
  final Set<String> _expandedMainIds = <String>{};

  CategoryType get _selectedType =>
      _isExpense ? CategoryType.expense : CategoryType.income;

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: categoriesAsync.when(
          loading: () => const _LoadingState().paddingAll(24),
          error:
              (_, __) => _ErrorState(
                onRetry: () => ref.invalidate(categoriesControllerProvider),
              ).paddingAll(24),
          data: (categories) {
            _syncWorkingLists(categories);
            final mains =
                _selectedType == CategoryType.expense
                    ? _expenseMainsWorking
                    : _incomeMainsWorking;
            final visibleItems = _buildVisibleItems(_selectedType);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TopBar(onBack: () => context.pop()),
                const SizedBox(height: 16),
                const Divider(thickness: 2, color: Colors.black),
                const SizedBox(height: 24),
                Center(
                  child: ExpenseTypeToggle(
                    isExpense: _isExpense,
                    onChanged: (value) => setState(() => _isExpense = value),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isExpense
                                ? 'Expense categories'
                                : 'Income categories',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Press and hold, then drag to sort.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                    OutlinedSurface(
                      padding: const EdgeInsets.all(10),
                      borderRadius: BorderRadius.circular(12),
                      child: const Icon(Icons.add, color: Colors.black),
                    ).onTap(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onAddCategoryTap(context, categories),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child:
                      mains.isEmpty
                          ? _EmptyState(
                            isExpense: _isExpense,
                            onAdd: () => _onAddCategoryTap(context, categories),
                          )
                          : _CategoryTreeList(
                            items: visibleItems,
                            expandedMainIds: _expandedMainIds,
                            hasChildrenByMainId: _hasChildrenByMainId(
                              _selectedType,
                            ),
                            onReorder:
                                (oldIndex, newIndex) =>
                                    _onReorderVisible(oldIndex, newIndex),
                            onToggleExpanded: (id) => _toggleExpanded(id),
                            onAddSub:
                                (main) => _onAddSubCategoryTap(
                                  context,
                                  allCategories: categories,
                                  parent: main,
                                ),
                            onRename:
                                (item) => _onRenameCategoryTap(
                                  context,
                                  allCategories: categories,
                                  item: item,
                                ),
                            onDelete:
                                (item) => _confirmAndDelete(
                                  context,
                                  allCategories: categories,
                                  item: item,
                                ),
                          ),
                ),
              ],
            ).paddingAll(24);
          },
        ),
      ),
    );
  }

  void _syncWorkingLists(List<Category> categories) {
    final expenseMains =
        categories
            .where((c) => c.type == CategoryType.expense && c.parentId == null)
            .toList()
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final incomeMains =
        categories
            .where((c) => c.type == CategoryType.income && c.parentId == null)
            .toList()
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    final expenseSubs = _groupSubsByParent(categories, CategoryType.expense);
    final incomeSubs = _groupSubsByParent(categories, CategoryType.income);

    // Only overwrite working lists when they materially differ (e.g., add/delete
    // or provider refresh), so reorder feels instant.
    if (!_sameSignature(_expenseMainsWorking, expenseMains)) {
      _expenseMainsWorking = expenseMains;
    }
    if (!_sameSignature(_incomeMainsWorking, incomeMains)) {
      _incomeMainsWorking = incomeMains;
    }
    if (!_sameSubsSignature(_expenseSubsWorkingByParent, expenseSubs)) {
      _expenseSubsWorkingByParent = expenseSubs;
    }
    if (!_sameSubsSignature(_incomeSubsWorkingByParent, incomeSubs)) {
      _incomeSubsWorkingByParent = incomeSubs;
    }
  }

  Map<String, List<Category>> _groupSubsByParent(
    List<Category> categories,
    CategoryType type,
  ) {
    final map = <String, List<Category>>{};
    for (final c in categories) {
      if (c.type != type) continue;
      final parentId = c.parentId;
      if (parentId == null) continue;
      (map[parentId] ??= <Category>[]).add(c);
    }
    for (final entry in map.entries) {
      entry.value.sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    }
    return map;
  }

  bool _sameSignature(List<Category> a, List<Category> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
      if (a[i].label != b[i].label) return false;
      if ((a[i].emoji ?? '').trim() != (b[i].emoji ?? '').trim()) return false;
      if ((a[i].parentId ?? '').trim() != (b[i].parentId ?? '').trim()) {
        return false;
      }
    }
    return true;
  }

  bool _sameSubsSignature(
    Map<String, List<Category>> a,
    Map<String, List<Category>> b,
  ) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      final listA = a[key];
      final listB = b[key];
      if (listA == null || listB == null) return false;
      if (!_sameSignature(listA, listB)) return false;
    }
    return true;
  }

  Map<String, bool> _hasChildrenByMainId(CategoryType type) {
    final subsMap =
        type == CategoryType.expense
            ? _expenseSubsWorkingByParent
            : _incomeSubsWorkingByParent;
    return {
      for (final entry in subsMap.entries) entry.key: entry.value.isNotEmpty,
    };
  }

  List<_CategoryTreeItem> _buildVisibleItems(CategoryType type) {
    final mains =
        type == CategoryType.expense
            ? _expenseMainsWorking
            : _incomeMainsWorking;
    final subsMap =
        type == CategoryType.expense
            ? _expenseSubsWorkingByParent
            : _incomeSubsWorkingByParent;

    final items = <_CategoryTreeItem>[];
    for (final main in mains) {
      final children = subsMap[main.id] ?? const <Category>[];
      items.add(
        _CategoryTreeItem.main(
          main,
          isExpanded: _expandedMainIds.contains(main.id),
          hasChildren: children.isNotEmpty,
        ),
      );
      if (!_expandedMainIds.contains(main.id)) continue;
      for (final sub in children) {
        items.add(_CategoryTreeItem.sub(sub, parentId: main.id));
      }
    }
    return items;
  }

  void _toggleExpanded(String mainId) {
    setState(() {
      if (_expandedMainIds.contains(mainId)) {
        _expandedMainIds.remove(mainId);
      } else {
        // Accordion behavior: only one main category can be expanded at a time.
        _expandedMainIds
          ..clear()
          ..add(mainId);
      }
    });
  }

  Future<void> _onReorderVisible(int oldIndex, int newIndex) async {
    final visible = _buildVisibleItems(_selectedType);
    if (oldIndex < 0 || oldIndex >= visible.length) return;

    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (adjustedNewIndex < 0 || adjustedNewIndex > visible.length - 1) return;

    final moved = visible[oldIndex];

    if (moved.isMain) {
      final mains =
          _selectedType == CategoryType.expense
              ? _expenseMainsWorking
              : _incomeMainsWorking;

      final temp = [...visible]..removeAt(oldIndex);
      final newMainPos =
          temp.take(adjustedNewIndex).where((i) => i.isMain).length;

      final oldMainPos = mains.indexWhere((c) => c.id == moved.category.id);
      if (oldMainPos < 0) return;

      setState(() {
        final item = mains.removeAt(oldMainPos);
        mains.insert(newMainPos, item);
      });

      final orderedIds = mains.map((c) => c.id).toList(growable: false);
      await ref
          .read(categoriesControllerProvider.notifier)
          .reorderCategoryType(type: _selectedType, orderedIds: orderedIds);
      return;
    }

    final parentId = moved.parentId;
    if (parentId == null) return;
    final subsMap =
        _selectedType == CategoryType.expense
            ? _expenseSubsWorkingByParent
            : _incomeSubsWorkingByParent;
    final siblings = subsMap[parentId];
    if (siblings == null) return;
    final oldSubPos = siblings.indexWhere((c) => c.id == moved.category.id);
    if (oldSubPos < 0) return;

    final temp = [...visible]..removeAt(oldIndex);
    final siblingIndices = <int>[
      for (var i = 0; i < temp.length; i++)
        if (!temp[i].isMain && temp[i].parentId == parentId) i,
    ];
    if (siblingIndices.isEmpty) return;

    final minIdx = siblingIndices.first;
    final maxIdx = siblingIndices.last;
    final isInsideGroup =
        adjustedNewIndex >= minIdx && adjustedNewIndex <= (maxIdx + 1);
    if (!isInsideGroup) {
      setState(() {});
      return;
    }

    final newSubPos =
        temp
            .take(adjustedNewIndex)
            .where((i) => !i.isMain && i.parentId == parentId)
            .length;

    setState(() {
      final item = siblings.removeAt(oldSubPos);
      siblings.insert(newSubPos, item);
    });

    final orderedIds = siblings.map((c) => c.id).toList(growable: false);
    await ref
        .read(categoriesControllerProvider.notifier)
        .reorderSubCategories(
          type: _selectedType,
          parentId: parentId,
          orderedIds: orderedIds,
        );
  }

  Future<void> _onAddCategoryTap(
    BuildContext context,
    List<Category> allCategories,
  ) async {
    final result = await _showUpsertCategoryDialog(
      context,
      title: 'Add a category',
      description: 'Pick a short name you’ll recognize instantly.',
      primaryLabel: 'Add',
      initialLabel: '',
      initialEmoji: null,
    );
    if (!context.mounted || result == null) return;

    final trimmed = result.label.trim();
    if (trimmed.isEmpty) {
      _showSnack(context, 'Add a category name to continue.');
      return;
    }
    if (trimmed.contains(' - ')) {
      _showSnack(context, 'Use a simple name without “ - ”.');
      return;
    }

    final exists = allCategories.any(
      (c) =>
          c.type == _selectedType &&
          c.parentId == null &&
          c.label.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      _showSnack(context, 'That category already exists.');
      return;
    }

    await ref
        .read(categoriesControllerProvider.notifier)
        .addCategory(type: _selectedType, label: trimmed, emoji: result.emoji);
  }

  Future<void> _onAddSubCategoryTap(
    BuildContext context, {
    required List<Category> allCategories,
    required Category parent,
  }) async {
    final result = await _showUpsertCategoryDialog(
      context,
      title: 'Add a sub-category',
      description: 'Add a detail under “${parent.label}”.',
      primaryLabel: 'Add',
      initialLabel: '',
      initialEmoji: null,
    );
    if (!context.mounted || result == null) return;

    final trimmed = result.label.trim();
    if (trimmed.isEmpty) {
      _showSnack(context, 'Add a sub-category name to continue.');
      return;
    }
    if (trimmed.contains(' - ')) {
      _showSnack(context, 'Use a simple name without “ - ”.');
      return;
    }

    final exists = allCategories.any(
      (c) =>
          c.type == parent.type &&
          c.parentId == parent.id &&
          c.label.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      _showSnack(context, 'That sub-category already exists.');
      return;
    }

    await ref
        .read(categoriesControllerProvider.notifier)
        .addSubCategory(
          type: parent.type,
          parentId: parent.id,
          label: trimmed,
          emoji: result.emoji,
        );
    setState(() {
      _expandedMainIds
        ..clear()
        ..add(parent.id);
    });
  }

  Future<void> _confirmAndDelete(
    BuildContext context, {
    required List<Category> allCategories,
    required Category item,
  }) async {
    final isMain = item.parentId == null;
    final hasSubs = isMain && allCategories.any((c) => c.parentId == item.id);
    final description =
        isMain
            ? (hasSubs
                ? 'This removes it and its sub-categories from future selections. Past logs keep their saved labels.'
                : 'This removes it from future selections. Past logs keep their saved labels.')
            : 'This removes it from future selections. Past logs keep their saved labels.';

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return OutlinedConfirmationDialog(
          title: 'Delete this category?',
          description: description,
          primaryLabel: 'Delete category',
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
          secondaryLabel: 'Keep it',
          onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );

    if (shouldDelete != true) return;
    if (!context.mounted) return;

    await ref
        .read(categoriesControllerProvider.notifier)
        .deleteCategory(item.id);
  }

  Future<void> _onRenameCategoryTap(
    BuildContext context, {
    required List<Category> allCategories,
    required Category item,
  }) async {
    final result = await _showUpsertCategoryDialog(
      context,
      title: 'Edit category',
      description: 'Update the name and icon you’ll recognize instantly.',
      primaryLabel: 'Save',
      initialLabel: item.label,
      initialEmoji: item.emoji,
    );
    if (!context.mounted || result == null) return;

    final trimmed = result.label.trim();
    if (trimmed.isEmpty) {
      _showSnack(context, 'Add a category name to continue.');
      return;
    }
    if (trimmed.contains(' - ')) {
      _showSnack(context, 'Use a simple name without “ - ”.');
      return;
    }

    final exists = allCategories.any(
      (c) =>
          c.id != item.id &&
          c.type == item.type &&
          c.parentId == item.parentId &&
          c.label.trim().toLowerCase() == trimmed.toLowerCase(),
    );
    if (exists) {
      _showSnack(context, 'That category already exists.');
      return;
    }

    await ref
        .read(categoriesControllerProvider.notifier)
        .updateCategory(id: item.id, label: trimmed, emoji: result.emoji);
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CATEGORIES',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Add, remove, and personalize your lists',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTreeList extends StatelessWidget {
  const _CategoryTreeList({
    required this.items,
    required this.expandedMainIds,
    required this.hasChildrenByMainId,
    required this.onReorder,
    required this.onToggleExpanded,
    required this.onAddSub,
    required this.onRename,
    required this.onDelete,
  });

  final List<_CategoryTreeItem> items;
  final Set<String> expandedMainIds;
  final Map<String, bool> hasChildrenByMainId;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<String> onToggleExpanded;
  final ValueChanged<Category> onAddSub;
  final ValueChanged<Category> onRename;
  final ValueChanged<Category> onDelete;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.only(right: 6, bottom: 6),
      onReorder: onReorder,
      itemCount: items.length,
      proxyDecorator:
          (child, _, __) => Material(color: Colors.transparent, child: child),
      itemBuilder: (context, index) {
        final treeItem = items[index];
        final category = treeItem.category;

        if (treeItem.isMain) {
          final isExpanded = expandedMainIds.contains(category.id);
          final hasChildren = hasChildrenByMainId[category.id] == true;

          return ReorderableDelayedDragStartListener(
            key: ValueKey(category.id),
            index: index,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedSurface(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                borderRadius: BorderRadius.circular(12),
                child: Row(
                  children: [
                    Expanded(
                      child: CategoryNameWithEmoji(
                        label: category.label,
                        emoji: category.emoji,
                        spacing: 8,
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => onAddSub(category),
                      icon: const Icon(Icons.add, color: Colors.black),
                      tooltip: 'Add sub-category',
                    ),
                    if (hasChildren)
                      IconButton(
                        onPressed: () => onToggleExpanded(category.id),
                        icon: Icon(
                          isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: Colors.black,
                        ),
                        tooltip: isExpanded ? 'Collapse' : 'Expand',
                      ),
                    IconButton(
                      onPressed: () => onRename(category),
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.black,
                      ),
                      tooltip: 'Edit',
                    ),
                    IconButton(
                      onPressed: () => onDelete(category),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return ReorderableDelayedDragStartListener(
          key: ValueKey(category.id),
          index: index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    width: 28,
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: OutlinedSurface(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: CategoryNameWithEmoji(
                              label: category.label,
                              emoji: category.emoji,
                              spacing: 8,
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => onRename(category),
                            icon: const Icon(
                              Icons.edit_outlined,
                              color: Colors.black,
                            ),
                            tooltip: 'Edit',
                          ),
                          IconButton(
                            onPressed: () => onDelete(category),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'Delete',
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryTreeItem {
  final Category category;
  final bool isMain;
  final String? parentId;

  const _CategoryTreeItem._(
    this.category, {
    required this.isMain,
    this.parentId,
  });

  factory _CategoryTreeItem.main(
    Category category, {
    required bool isExpanded,
    required bool hasChildren,
  }) {
    return _CategoryTreeItem._(category, isMain: true);
  }

  factory _CategoryTreeItem.sub(Category category, {required String parentId}) {
    return _CategoryTreeItem._(category, isMain: false, parentId: parentId);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isExpense, required this.onAdd});

  final bool isExpense;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final title =
        isExpense
            ? 'Ready to personalize your expense list?'
            : 'Ready to personalize your income list?';
    final subtitle =
        isExpense
            ? 'Add a category to make logging faster.'
            : 'Add a category to keep your income organized.';

    return OutlinedSurface(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          OutlinedActionButton(
            label: 'Add category',
            onPressed: onAdd,
            textColor: Colors.black,
            borderColor: Colors.black,
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(color: Colors.black));
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Something went wrong. Let's try again.",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedActionButton(
            label: 'Retry',
            onPressed: onRetry,
            textColor: Colors.black,
            borderColor: Colors.black,
            backgroundColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _CategoryEditResult {
  final String label;
  final String? emoji;

  const _CategoryEditResult({required this.label, required this.emoji});
}

Future<_CategoryEditResult?> _showUpsertCategoryDialog(
  BuildContext context, {
  required String title,
  required String description,
  required String primaryLabel,
  required String initialLabel,
  required String? initialEmoji,
}) {
  final labelController = TextEditingController(text: initialLabel);
  final emojiController = TextEditingController(text: initialEmoji ?? '');

  return showDialog<_CategoryEditResult>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: OutlinedSurface(
          padding: const EdgeInsets.all(20),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _EmojiField(controller: emojiController),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CategoryNameField(controller: labelController),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedActionButton(
                      label: 'Cancel',
                      onPressed: () => Navigator.of(dialogContext).pop(null),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedActionButton(
                      label: primaryLabel,
                      onPressed: () {
                        final label = labelController.text;
                        final emoji = emojiController.text.trim();
                        Navigator.of(dialogContext).pop(
                          _CategoryEditResult(
                            label: label,
                            emoji: emoji.isEmpty ? null : emoji,
                          ),
                        );
                      },
                      textColor: Colors.white,
                      borderColor: Colors.black,
                      backgroundColor: Colors.black,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  ).whenComplete(() {
    labelController.dispose();
    emojiController.dispose();
  });
}

class _CategoryNameField extends StatelessWidget {
  const _CategoryNameField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        hintText: 'e.g., Coffee',
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey[500],
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
      ),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    );
  }
}

class _EmojiField extends StatelessWidget {
  const _EmojiField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 52,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, value, __) {
          final emoji = value.text.trim();
          final hasEmoji = emoji.isNotEmpty;

          return OutlinedSurface(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            borderRadius: BorderRadius.circular(12),
            child: Center(
              child:
                  hasEmoji
                      ? Text(
                        emoji,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      )
                      : const Icon(
                        Icons.emoji_emotions_outlined,
                        color: Colors.black,
                        size: 18,
                      ),
            ),
          ).onTap(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              final picked = await _showEmojiPickerBottomSheet(context);
              if (picked == null) return;
              controller.text = picked.trim();
            },
          );
        },
      ),
    );
  }
}

Future<String?> _showEmojiPickerBottomSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final mediaQuery = MediaQuery.of(sheetContext);
      final bottomPadding = mediaQuery.padding.bottom;
      final height = mediaQuery.size.height * 0.6;

      return SafeArea(
        top: false,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: OutlinedSurface(
            height: height,
            padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomPadding),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(28),
              topRight: Radius.circular(28),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Pick an icon',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    OutlinedActionButton(
                      label: 'Clear',
                      onPressed: () => Navigator.of(sheetContext).pop(''),
                      textColor: Colors.black,
                      borderColor: Colors.black,
                      backgroundColor: Colors.white,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: EmojiPicker(
                    onEmojiSelected: (_, emoji) {
                      Navigator.of(sheetContext).pop(emoji.emoji);
                    },
                    config: const Config(
                      height: null,
                      checkPlatformCompatibility: true,
                      emojiViewConfig: EmojiViewConfig(emojiSizeMax: 28),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
