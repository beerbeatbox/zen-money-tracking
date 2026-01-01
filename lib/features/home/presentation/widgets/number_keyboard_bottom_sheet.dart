import 'dart:async';

import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/presentation/widgets/log_time_picker_dialog.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';

const _kExpenseCategories = <String>[
  'Food',
  'Bill',
  'Shopping',
  'Subscription',
  'Investment',
  'Family',
  'Essential',
  'Others',
];

const _kIncomeCategories = <String>[
  'Salary',
  'Bonus',
  'Business',
  'Gift',
  'Interest',
  'Refund',
  'Investment Return',
  'Others',
];

Future<void> showNumberKeyboardBottomSheet(
  BuildContext context, {
  required Future<bool> Function(
    BuildContext context,
    String value,
    bool isExpense,
    DateTime logDateTime,
    String category,
  )
  onSubmit,
  bool initialIsExpense = true,
  String? initialValue,
  DateTime? initialLogDateTime,
  String? initialCategory,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => NumberKeyboardBottomSheet(
          onSubmit: onSubmit,
          initialIsExpense: initialIsExpense,
          initialValue: initialValue,
          initialLogDateTime: initialLogDateTime,
          initialCategory: initialCategory,
        ),
  );
}

class NumberKeyboardBottomSheet extends StatefulWidget {
  const NumberKeyboardBottomSheet({
    super.key,
    required this.onSubmit,
    this.initialIsExpense = true,
    this.initialValue,
    this.initialLogDateTime,
    this.initialCategory,
  });

  final Future<bool> Function(
    BuildContext context,
    String value,
    bool isExpense,
    DateTime logDateTime,
    String category,
  )
  onSubmit;
  final bool initialIsExpense;
  final String? initialValue;
  final DateTime? initialLogDateTime;
  final String? initialCategory;

  @override
  State<NumberKeyboardBottomSheet> createState() =>
      _NumberKeyboardBottomSheetState();
}

class _NumberKeyboardBottomSheetState extends State<NumberKeyboardBottomSheet> {
  String _value = '';
  bool _ctaPressed = false;
  bool _closePressed = false;
  Timer? _backspaceHoldTimer;
  late bool _isExpense;
  late DateTime _logDateTime;
  late String _selectedCategory;

  String get _displayValue => _value.isEmpty ? '0' : _value;
  List<String> get _availableCategories =>
      _isExpense ? _kExpenseCategories : _kIncomeCategories;
  String get _logTimeLabel {
    final dateLabel = formatWithPattern(
      _logDateTime,
      SystemDateFormat.weekdayDayMonthYear,
    );
    final timeLabel = formatTimeWithPattern(
      _logDateTime,
      SystemTimeFormat.hm24,
    );
    return '$dateLabel • $timeLabel';
  }

  @override
  void initState() {
    super.initState();
    _isExpense = widget.initialIsExpense;
    _value = widget.initialValue ?? '';
    _logDateTime = widget.initialLogDateTime ?? DateTime.now();
    _selectedCategory = _resolveInitialCategory(
      widget.initialCategory,
      categories: _availableCategories,
    );
  }

  String _resolveInitialCategory(
    String? initialCategory, {
    required List<String> categories,
  }) {
    if (initialCategory == null || initialCategory.isEmpty) {
      return categories.first;
    }
    return categories.contains(initialCategory)
        ? initialCategory
        : categories.first;
  }

  void _onKeyTap(String key) {
    setState(() {
      if (key == '.') {
        if (_value.contains('.')) {
          return;
        }
        _value = _value.isEmpty ? '0.' : '$_value.';
        return;
      }

      if (_displayValue == '0') {
        _value = key;
      } else {
        _value += key;
      }
    });
  }

  void _onBackspace() {
    if (_value.isEmpty) return;
    setState(() {
      _value = _value.substring(0, _value.length - 1);
    });
  }

  void _startBackspaceHold() {
    if (_value.isEmpty) return;

    _backspaceHoldTimer?.cancel();

    // Remove one immediately, then continue at a short interval.
    _onBackspace();
    _backspaceHoldTimer = Timer.periodic(const Duration(milliseconds: 90), (_) {
      if (!mounted || _value.isEmpty) {
        _stopBackspaceHold();
        return;
      }
      _onBackspace();
    });
  }

  void _stopBackspaceHold() {
    _backspaceHoldTimer?.cancel();
    _backspaceHoldTimer = null;
  }

  Future<void> _submit() async {
    final shouldClose = await widget.onSubmit(
      context,
      _displayValue,
      _isExpense,
      _logDateTime,
      _selectedCategory,
    );
    if (!mounted || !shouldClose) return;
    Navigator.of(context).pop();
  }

  void _setCtaPressed(bool value) {
    if (_ctaPressed == value) return;
    setState(() {
      _ctaPressed = value;
    });
  }

  Future<void> _releaseCtaWithPause() async {
    await Future.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    _setCtaPressed(false);
  }

  void _setClosePressed(bool value) {
    if (_closePressed == value) return;
    setState(() {
      _closePressed = value;
    });
  }

  Future<void> _releaseCloseWithPause() async {
    await Future.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    _setClosePressed(false);
  }

  void _setCategory(String category) {
    if (_selectedCategory == category) return;
    setState(() => _selectedCategory = category);
  }

  void _updateExpenseType(bool isExpense) {
    if (_isExpense == isExpense) return;
    setState(() {
      _isExpense = isExpense;
      final categories = _availableCategories;
      if (!categories.contains(_selectedCategory)) {
        _selectedCategory = categories.first;
      }
    });
  }

  Future<void> _onLogTimeTap() async {
    final picked = await showLogTimePickerDialog(
      context,
      initialDateTime: _logDateTime,
    );
    if (picked == null) return;
    if (!mounted) return;
    setState(() => _logDateTime = picked);
  }

  @override
  void dispose() {
    _backspaceHoldTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;
    final sheetHeight =
        mediaQuery.size.height - kToolbarHeight - mediaQuery.padding.top;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: sheetHeight,
        width: double.infinity,
        child: OutlinedSurface(
          height: sheetHeight,
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                const Spacer(),
                Center(
                  child: _ExpenseTypeToggle(
                    isExpense: _isExpense,
                    onChanged: _updateExpenseType,
                  ),
                ),
                const SizedBox(height: 12),
                _CategorySection(
                  selected: _selectedCategory,
                  onChanged: _setCategory,
                  categories: _availableCategories,
                ),
                const SizedBox(height: 16),
                Center(
                  child: _LogTimeSection(
                    label: _logTimeLabel,
                    onTap: _onLogTimeTap,
                  ),
                ),
                const SizedBox(height: 28),
                Center(child: _AmountHeader(value: _displayValue)),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.65,
                    child: _NumberPad(
                      onKeyTap: _onKeyTap,
                      onBackspace: _onBackspace,
                      onBackspaceHoldStart: _startBackspaceHold,
                      onBackspaceHoldEnd: _stopBackspaceHold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedSurface(
                        height: 56,
                        isPressed: _closePressed,
                        duration: const Duration(milliseconds: 80),
                        curve: Curves.easeOut,
                        child: const Center(
                          child: Text(
                            'Close',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ).onTap(
                        onTapDown: (_) => _setClosePressed(true),
                        onTapUp: (_) => _releaseCloseWithPause(),
                        onTapCancel: () => _releaseCloseWithPause(),
                        onTap: () => Navigator.of(context).pop(),
                        behavior: HitTestBehavior.opaque,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedSurface(
                        height: 56,
                        isPressed: _ctaPressed,
                        duration: const Duration(milliseconds: 80),
                        color: Colors.black,
                        curve: Curves.easeOut,
                        child: const Center(
                          child: Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ).onTap(
                        onTapDown: (_) => _setCtaPressed(true),
                        onTapUp: (_) => _releaseCtaWithPause(),
                        onTapCancel: () => _releaseCtaWithPause(),
                        onTap: _submit,
                        behavior: HitTestBehavior.opaque,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountHeader extends StatelessWidget {
  const _AmountHeader({required this.value});

  final String value;

  @override
  Widget build(BuildContext context) {
    final formattedValue = _formatInputValue(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                const Text(
                  '฿',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: AutoSizeText(
                    formattedValue,
                    maxLines: 1,
                    minFontSize: 28,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _formatInputValue(String raw) {
    if (raw.isEmpty) return '0';

    final parts = raw.split('.');
    final integerPart = int.tryParse(parts.first) ?? 0;
    final formattedInteger = formatAmountWithComma(integerPart);

    if (parts.length == 1) return formattedInteger;

    final fraction = parts[1];
    return fraction.isEmpty
        ? '$formattedInteger.'
        : '$formattedInteger.$fraction';
  }
}

class _ExpenseTypeToggle extends StatelessWidget {
  const _ExpenseTypeToggle({required this.isExpense, required this.onChanged});

  final bool isExpense;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedSurface(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TypeChip(
            label: 'Expense',
            selected: isExpense,
            onTap: () => onChanged(true),
          ),
          Container(
            width: 1,
            height: 20,
            color: Colors.black,
          ).paddingSymmetric(horizontal: 10),
          _TypeChip(
            label: 'Income',
            selected: !isExpense,
            onTap: () => onChanged(false),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      isPressed: false,
      color: Colors.white,
      pressedColor: Colors.white,
      border: const Border.fromBorderSide(
        BorderSide(color: Colors.transparent, width: 0),
      ),
      unpressedShadowOffset: Offset.zero,
      pressedShadowOffset: Offset.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              letterSpacing: 0.6,
              color: selected ? Colors.black : Colors.grey[600],
              decoration: TextDecoration.none,
            ),
          ),
          const SizedBox(height: 3),
          Container(
            height: 2,
            width: 34,
            color: selected ? Colors.black : Colors.transparent,
          ),
        ],
      ),
    ).onTap(onTap: onTap, behavior: HitTestBehavior.opaque);
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.selected,
    required this.onChanged,
    required this.categories,
  });

  final String selected;
  final ValueChanged<String> onChanged;
  final List<String> categories;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final category in categories) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CategoryChip(
                    label: category,
                    selected: category == selected,
                    onTap: () => onChanged(category),
                  ),
                ),
                if (category != categories.last) const SizedBox(width: 10),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedSurface(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      borderRadius: const BorderRadius.all(Radius.circular(18)),
      color: selected ? Colors.black : Colors.white,
      child: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : Colors.black,
        ),
      ),
    ).onTap(onTap: onTap, behavior: HitTestBehavior.opaque);
  }
}

class _LogTimeSection extends StatelessWidget {
  const _LogTimeSection({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: OutlinedSurface(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.black,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down,
              size: 22,
              color: Colors.black,
            ),
          ],
        ),
      ).onTap(onTap: onTap, behavior: HitTestBehavior.opaque),
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({
    required this.onKeyTap,
    required this.onBackspace,
    required this.onBackspaceHoldStart,
    required this.onBackspaceHoldEnd,
  });

  final Function(String) onKeyTap;
  final VoidCallback onBackspace;
  final VoidCallback onBackspaceHoldStart;
  final VoidCallback onBackspaceHoldEnd;

  @override
  Widget build(BuildContext context) {
    final rows = [
      const ['1', '2', '3'],
      const ['4', '5', '6'],
      const ['7', '8', '9'],
      const ['.', '0', 'back'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children:
          rows
              .map(
                (row) => Padding(
                  padding: EdgeInsets.zero,
                  child: Row(
                    children: [
                      for (var i = 0; i < row.length; i++) ...[
                        Expanded(
                          child: _KeyButton(
                            label: row[i],
                            isBackspace: row[i] == 'back',
                            onTap: () {
                              if (row[i] == 'back') {
                                onBackspace();
                              } else {
                                onKeyTap(row[i]);
                              }
                            },
                            onLongPressStart:
                                row[i] == 'back' ? onBackspaceHoldStart : null,
                            onLongPressEnd:
                                row[i] == 'back' ? onBackspaceHoldEnd : null,
                          ),
                        ),
                        if (i != row.length - 1) const SizedBox(width: 12),
                      ],
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.label,
    required this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd,
    this.isBackspace = false,
  });

  final String label;
  final VoidCallback onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;
  final bool isBackspace;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _pressed = false;
  bool _showBubble = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _setBubble(bool value) {
    if (_showBubble == value) return;
    setState(() => _showBubble = value);
  }

  Future<void> _releaseWithPause() async {
    await Future.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    _setPressed(false);
  }

  Future<void> _hideBubbleWithPause() async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;
    _setBubble(false);
  }

  Widget _buildBubble({required bool isBackspace, required String label}) {
    return Positioned(
      top: -64,
      left: 0,
      right: 0,
      child: Center(
        child: PhysicalShape(
          color: const Color(0xFFE8F2FF),
          shadowColor: Colors.black.withValues(alpha: 0.18),
          elevation: 8,
          clipper: _BubbleDropClipper(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            alignment: Alignment.center,
            child: Transform.translate(
              offset: const Offset(0, -7),
              child:
                  isBackspace
                      ? const Icon(
                        Icons.backspace_outlined,
                        color: Color(0xFF0D47A1),
                        size: 24,
                      )
                      : Text(
                        label,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0D47A1),
                        ),
                      ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBackspace = widget.isBackspace;
    final label = widget.label;

    return AspectRatio(
      aspectRatio: 1.5,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (_showBubble) _buildBubble(isBackspace: isBackspace, label: label),
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              color:
                  _pressed
                      ? (isBackspace
                          ? const Color(0xFFF5D9D9)
                          : const Color(0xFFF7F7F7))
                      : (isBackspace ? const Color(0xFFFDEBEB) : Colors.white),
              borderRadius: const BorderRadius.all(Radius.circular(12)),
            ),
            child: Center(
              child:
                  isBackspace
                      ? const Icon(
                        Icons.backspace_outlined,
                        color: Colors.black,
                      )
                      : AutoSizeText(
                        label,
                        maxLines: 1,
                        minFontSize: 24,
                        maxFontSize: label == '.' ? 30 : 24,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
            ),
          ).onTap(
            onTapDown: (_) {
              _setPressed(true);
              _setBubble(true);
            },
            onTapUp: (_) {
              _releaseWithPause();
              _hideBubbleWithPause();
            },
            onTapCancel: () {
              _releaseWithPause();
              _hideBubbleWithPause();
            },
            onLongPressStart:
                widget.isBackspace && widget.onLongPressStart != null
                    ? (_) {
                      _setPressed(true);
                      _setBubble(true);
                      widget.onLongPressStart!();
                    }
                    : null,
            onLongPressEnd:
                widget.isBackspace && widget.onLongPressEnd != null
                    ? (_) {
                      widget.onLongPressEnd!();
                      _releaseWithPause();
                      _hideBubbleWithPause();
                    }
                    : null,
            onLongPressCancel:
                widget.isBackspace && widget.onLongPressEnd != null
                    ? () {
                      widget.onLongPressEnd!();
                      _releaseWithPause();
                      _hideBubbleWithPause();
                    }
                    : null,
            onTap: widget.onTap,
            behavior: HitTestBehavior.opaque,
          ),
        ],
      ),
    );
  }
}

class _BubbleDropClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const tailHeight = 14.0;
    const tailWidth = 20.0;
    const radius = 18.0;

    final bodyHeight = size.height - tailHeight;
    final tailCenterX = size.width / 2;
    final tailLeftX = tailCenterX - tailWidth / 2;
    final tailRightX = tailCenterX + tailWidth / 2;

    final path =
        Path()
          ..moveTo(radius, 0)
          ..lineTo(size.width - radius, 0)
          ..quadraticBezierTo(size.width, 0, size.width, radius)
          ..lineTo(size.width, bodyHeight - radius)
          ..quadraticBezierTo(
            size.width,
            bodyHeight,
            size.width - radius,
            bodyHeight,
          )
          ..lineTo(tailRightX, bodyHeight)
          ..lineTo(tailCenterX, bodyHeight + tailHeight)
          ..lineTo(tailLeftX, bodyHeight)
          ..lineTo(radius, bodyHeight)
          ..quadraticBezierTo(0, bodyHeight, 0, bodyHeight - radius)
          ..lineTo(0, radius)
          ..quadraticBezierTo(0, 0, radius, 0)
          ..close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
