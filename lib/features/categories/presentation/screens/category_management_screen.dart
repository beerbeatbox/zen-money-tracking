import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/presentation/controllers/categories_controller.dart';
import 'package:anti/features/home/presentation/widgets/expense_type_toggle.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:anti/features/settings/presentation/widgets/outlined_confirmation_dialog.dart';
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
                onRetry:
                    () => ref.invalidate(categoriesControllerProvider),
              ).paddingAll(24),
          data: (categories) {
            final filtered =
                categories
                    .where((c) => c.type == _selectedType)
                    .toList(growable: false)
                  ..sort((a, b) => a.label.compareTo(b.label));

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

  Future<void> _onAddCategoryTap(
    BuildContext context,
    List<Category> allCategories,
  ) async {
    final label = await _showAddCategoryDialog(context);
    if (!context.mounted || label == null) return;

    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      _showSnack(context, 'Add a category name to continue.');
      return;
    }

    final exists =
        allCategories.any(
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
        .addCategory(type: _selectedType, label: trimmed);
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
    final label = await _showRenameCategoryDialog(
      context,
      initialLabel: item.label,
    );
    if (!context.mounted || label == null) return;

    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      _showSnack(context, 'Add a category name to continue.');
      return;
    }

    final exists =
        allCategories.any(
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
        .renameCategory(id: item.id, label: trimmed);
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
    required this.onRename,
    required this.onDelete,
  });

  final List<Category> items;
  final ValueChanged<Category> onRename;
  final ValueChanged<String> onDelete;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return OutlinedSurface(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  style: const TextStyle(
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
    return const Center(
      child: CircularProgressIndicator(color: Colors.black),
    );
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

Future<String?> _showAddCategoryDialog(BuildContext context) {
  final controller = TextEditingController();

  return showDialog<String>(
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
              const Text(
                'Add a category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pick a short name you’ll recognize instantly.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
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
                onSubmitted: (_) {
                  Navigator.of(dialogContext).pop(controller.text);
                },
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
                      label: 'Add',
                      onPressed:
                          () => Navigator.of(dialogContext).pop(controller.text),
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
  ).whenComplete(controller.dispose);
}

Future<String?> _showRenameCategoryDialog(
  BuildContext context, {
  required String initialLabel,
}) {
  final controller = TextEditingController(text: initialLabel);

  return showDialog<String>(
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
              const Text(
                'Rename category',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Use a short name you’ll recognize instantly.',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
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
                onSubmitted: (_) {
                  Navigator.of(dialogContext).pop(controller.text);
                },
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
                      label: 'Save',
                      onPressed:
                          () => Navigator.of(dialogContext).pop(controller.text),
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
  ).whenComplete(controller.dispose);
}


