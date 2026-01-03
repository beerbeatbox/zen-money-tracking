import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/presentation/controllers/categories_controller.dart';
import 'package:anti/features/home/presentation/widgets/expense_type_toggle.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:anti/features/settings/presentation/widgets/outlined_confirmation_dialog.dart';
import 'package:anti/features/categories/presentation/widgets/category_name_with_emoji.dart';
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
  List<Category> _expenseWorking = const [];
  List<Category> _incomeWorking = const [];

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
            final filtered =
                _selectedType == CategoryType.expense
                    ? _expenseWorking
                    : _incomeWorking;

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
                      child: Text(
                        _isExpense ? 'Expense categories' : 'Income categories',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.black,
                        ),
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
                      filtered.isEmpty
                          ? _EmptyState(
                            isExpense: _isExpense,
                            onAdd: () => _onAddCategoryTap(context, categories),
                          )
                          : _CategoryList(
                            items: filtered,
                            onReorder:
                                (oldIndex, newIndex) => _onReorder(
                                  context,
                                  oldIndex: oldIndex,
                                  newIndex: newIndex,
                                ),
                            onRename:
                                (item) => _onRenameCategoryTap(
                                  context,
                                  allCategories: categories,
                                  item: item,
                                ),
                            onDelete: (id) => _confirmAndDelete(context, id),
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
    final expense =
        categories.where((c) => c.type == CategoryType.expense).toList()
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final income =
        categories.where((c) => c.type == CategoryType.income).toList()
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    // Only overwrite working lists when they materially differ (e.g., add/delete
    // or provider refresh), so reorder feels instant.
    if (!_sameSignature(_expenseWorking, expense)) _expenseWorking = expense;
    if (!_sameSignature(_incomeWorking, income)) _incomeWorking = income;
  }

  bool _sameSignature(List<Category> a, List<Category> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
      if (a[i].label != b[i].label) return false;
      if ((a[i].emoji ?? '').trim() != (b[i].emoji ?? '').trim()) return false;
    }
    return true;
  }

  Future<void> _onReorder(
    BuildContext context, {
    required int oldIndex,
    required int newIndex,
  }) async {
    // ReorderableListView gives newIndex after removal; adjust accordingly.
    final list =
        _selectedType == CategoryType.expense
            ? _expenseWorking
            : _incomeWorking;
    final adjustedNewIndex = newIndex > oldIndex ? newIndex - 1 : newIndex;

    setState(() {
      final item = list.removeAt(oldIndex);
      list.insert(adjustedNewIndex, item);
    });

    final orderedIds = list.map((c) => c.id).toList(growable: false);
    await ref
        .read(categoriesControllerProvider.notifier)
        .reorderCategoryType(type: _selectedType, orderedIds: orderedIds);
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

    final exists = allCategories.any(
      (c) =>
          c.type == _selectedType &&
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

  Future<void> _confirmAndDelete(BuildContext context, String id) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return OutlinedConfirmationDialog(
          title: 'Delete this category?',
          description:
              'This removes it from future selections. Past logs keep their current label.',
          primaryLabel: 'Delete category',
          onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
          secondaryLabel: 'Keep it',
          onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
        );
      },
    );

    if (shouldDelete != true) return;
    if (!context.mounted) return;

    await ref.read(categoriesControllerProvider.notifier).deleteCategory(id);
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

    final exists = allCategories.any(
      (c) =>
          c.id != item.id &&
          c.type == item.type &&
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

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.items,
    required this.onReorder,
    required this.onRename,
    required this.onDelete,
  });

  final List<Category> items;
  final void Function(int oldIndex, int newIndex) onReorder;
  final ValueChanged<Category> onRename;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      onReorder: onReorder,
      itemCount: items.length,
      proxyDecorator:
          (child, _, __) => Material(color: Colors.transparent, child: child),
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.only(bottom: 10),
          child: OutlinedSurface(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(Icons.drag_handle, color: Colors.black),
                  ),
                ),
                Expanded(
                  child: CategoryNameWithEmoji(
                    label: item.label,
                    emoji: item.emoji,
                    spacing: 8,
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => onRename(item),
                  icon: const Icon(Icons.edit_outlined, color: Colors.black),
                  tooltip: 'Rename',
                ),
                IconButton(
                  onPressed: () => onDelete(item.id),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                ),
              ],
            ),
          ),
        );
      },
    );
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
                      emojiViewConfig: EmojiViewConfig(
                        emojiSizeMax: 28,
                      ),
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
