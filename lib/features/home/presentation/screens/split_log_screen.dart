import 'package:anti/core/utils/formatters.dart';
import 'package:anti/core/widgets/section_card.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/domain/usecases/category_service.dart';
import 'package:anti/features/categories/presentation/controllers/categories_controller.dart';
import 'package:anti/features/categories/presentation/widgets/category_name_with_emoji.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/home/presentation/screens/expense_log_detail_events.dart';
import 'package:anti/features/home/presentation/widgets/outlined_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

class SplitLogScreen extends ConsumerStatefulWidget {
  const SplitLogScreen({super.key, required this.logId, this.log});

  final String logId;
  final ExpenseLog? log;

  @override
  ConsumerState<SplitLogScreen> createState() => _SplitLogScreenState();
}

class _SplitRow {
  _SplitRow({required this.category, required this.amountController});

  String category;
  final TextEditingController amountController;
}

class _SplitLogScreenState extends ConsumerState<SplitLogScreen>
    with ExpenseLogDetailEvents {
  final List<_SplitRow> _rows = [];
  bool _rowsInitialized = false;

  ExpenseLog? _resolveLog(List<ExpenseLog> logs) {
    for (final item in logs) {
      if (item.id == widget.logId) return item;
    }
    return widget.log;
  }

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  String _formatAmountField(double value) {
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.000001) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }

  void _ensureRowsInitialized(ExpenseLog log) {
    if (_rowsInitialized) return;
    _rowsInitialized = true;
    final totalAbs = log.amount.abs();
    final satang = (totalAbs * 100).round();
    final firstSatang = satang ~/ 2;
    final secondSatang = satang - firstSatang;
    final c1 = TextEditingController(
      text: _formatAmountField(firstSatang / 100),
    );
    final c2 = TextEditingController(
      text: _formatAmountField(secondSatang / 100),
    );
    void notify() {
      if (mounted) setState(() {});
    }

    c1.addListener(notify);
    c2.addListener(notify);
    _rows.add(_SplitRow(category: log.category, amountController: c1));
    _rows.add(_SplitRow(category: log.category, amountController: c2));
  }

  @override
  void dispose() {
    for (final r in _rows) {
      r.amountController.dispose();
    }
    super.dispose();
  }

  double _splitSum() {
    var sum = 0.0;
    for (final r in _rows) {
      sum += double.tryParse(r.amountController.text.trim()) ?? 0;
    }
    return sum;
  }

  double _remaining(double totalAbs) => totalAbs - _splitSum();

  bool _canConfirm(double totalAbs) {
    if (_rows.length < 2) return false;
    if (_remaining(totalAbs).abs() >= 0.009) return false;
    for (final r in _rows) {
      if (r.category.trim().isEmpty) return false;
      final parsed = double.tryParse(r.amountController.text.trim());
      if (parsed == null || parsed <= 0) return false;
    }
    return true;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  List<String> _expenseCategoryOptions(List<Category> all) {
    final expense =
        all.where((c) => c.type == CategoryType.expense).toList()
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    if (expense.isEmpty) {
      return List<String>.from(CategoryService.defaultExpenseLabels);
    }
    final mains =
        expense.where((c) => c.parentId == null).toList()
          ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
    final out = <String>[];
    for (final main in mains) {
      out.add(main.label);
      final subs =
          expense.where((c) => c.parentId == main.id).toList()
            ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
      for (final sub in subs) {
        out.add(
          '${main.label}${CategoryService.labelSeparator}${sub.label}',
        );
      }
    }
    return out;
  }

  Future<void> _pickCategory(_SplitRow row, List<String> options) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final height = MediaQuery.sizeOf(context).height * 0.5;
        return SafeArea(
          child: SizedBox(
            height: height,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, index) {
                      final label = options[index];
                      return ListTile(
                        title: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        onTap: () => Navigator.of(ctx).pop(label),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null && mounted) {
      setState(() => row.category = picked);
    }
  }

  void _addRow(String defaultCategory) {
    final c = TextEditingController();
    c.addListener(() {
      if (mounted) setState(() {});
    });
    setState(() {
      _rows.add(_SplitRow(category: defaultCategory, amountController: c));
    });
  }

  void _removeAt(int index) {
    if (_rows.length <= 2) return;
    setState(() {
      final removed = _rows.removeAt(index);
      removed.amountController.dispose();
    });
  }

  Future<void> _onConfirm(ExpenseLog original) async {
    if (!_canConfirm(original.amount.abs())) return;

    final base = DateTime.now().microsecondsSinceEpoch;
    final timeLabel = _formatTimeLabel(original.createdAt);
    final newLogs = <ExpenseLog>[];
    for (var i = 0; i < _rows.length; i++) {
      final r = _rows[i];
      final parsed = double.tryParse(r.amountController.text.trim())!;
      newLogs.add(
        ExpenseLog(
          id: '$base-$i',
          timeLabel: timeLabel,
          category: r.category.trim(),
          amount: -parsed.abs(),
          createdAt: original.createdAt,
        ),
      );
    }

    final router = GoRouter.of(context);
    try {
      await splitLog(ref, original.id, newLogs);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Log split into ${_rows.length} entries.'),
        ),
      );
      router.pop();
      router.pop();
    } catch (_) {
      if (!mounted) return;
      _showSnack("Let's try that again.");
    }
  }

  String? _resolveEmoji(String label, List<Category>? categories) {
    if (categories == null) return null;
    return resolveCategoryEmoji(
      label: label,
      categories: categories,
      type: CategoryType.expense,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(expenseLogsProvider);
    final categoriesAsync = ref.watch(categoriesControllerProvider);
    final categories = categoriesAsync.maybeWhen(
      data: (value) => value,
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leadingWidth: 64,
        titleSpacing: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            padding: EdgeInsets.zero,
            splashRadius: 20,
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back, color: Colors.black),
          ),
        ),
        title: const Text(
          'Split log',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: logsAsync.when(
          data: (logs) {
            final resolved = _resolveLog(logs);
            if (resolved == null) {
              return _ErrorBody(
                message: "We couldn't find that log right now.",
                onRetry: () => ref.invalidate(expenseLogsProvider),
              );
            }
            if (resolved.amount >= 0) {
              return _ErrorBody(
                message: 'Only expense logs can be split.',
                onRetry: null,
              );
            }

            _ensureRowsInitialized(resolved);
            final totalAbs = resolved.amount.abs();
            final remaining = _remaining(totalAbs);
            final balanced = remaining.abs() < 0.009;
            final categoryOptions = categories == null
                ? List<String>.from(CategoryService.defaultExpenseLabels)
                : _expenseCategoryOptions(categories);
            final defaultCat =
                categoryOptions.isNotEmpty
                    ? categoryOptions.first
                    : CategoryService.defaultExpenseLabels.first;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total to split',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatCurrencySigned(-totalAbs),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < _rows.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Item ${i + 1}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Material(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      child: InkWell(
                                        onTap:
                                            () => _pickCategory(
                                              _rows[i],
                                              categoryOptions,
                                            ),
                                        borderRadius: BorderRadius.circular(12),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.grey[300]!,
                                            ),
                                          ),
                                          child: CategoryNameWithEmoji(
                                            label: _rows[i].category,
                                            emoji: _resolveEmoji(
                                              _rows[i].category,
                                              categories,
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _rows[i].amountController,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: 'Amount',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        isDense: true,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_rows.length > 2) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _removeAt(i),
                                  icon: HeroIcon(
                                    HeroIcons.trash,
                                    size: 22,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                        const SizedBox(height: 16),
                        OutlinedActionButton(
                          label: 'Add item',
                          onPressed: () => _addRow(defaultCat),
                          textColor: Colors.black,
                          borderColor: Colors.black,
                          backgroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SectionCard(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Remaining',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          '฿${formatAmountWithComma(remaining.abs(), decimalDigits: 2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: balanced ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                      onPressed:
                          _canConfirm(totalAbs)
                              ? () => _onConfirm(resolved)
                              : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Confirm split',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error:
              (_, __) => _ErrorBody(
                message: "Let's try that again.",
                onRetry: () => ref.invalidate(expenseLogsProvider),
              ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                child: const Text(
                  'Reload',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
