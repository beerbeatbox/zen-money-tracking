import 'dart:async';

import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:heroicons/heroicons.dart';

Future<void> showNumberKeyboardBottomSheet(
  BuildContext context, {
  required Future<bool> Function(
    BuildContext context,
    String value,
    bool isExpense,
  )
  onSubmit,
  bool initialIsExpense = true,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (context) => NumberKeyboardBottomSheet(
          onSubmit: onSubmit,
          initialIsExpense: initialIsExpense,
        ),
  );
}

class NumberKeyboardBottomSheet extends StatefulWidget {
  const NumberKeyboardBottomSheet({
    super.key,
    required this.onSubmit,
    this.initialIsExpense = true,
  });

  final Future<bool> Function(
    BuildContext context,
    String value,
    bool isExpense,
  )
  onSubmit;
  final bool initialIsExpense;

  @override
  State<NumberKeyboardBottomSheet> createState() =>
      _NumberKeyboardBottomSheetState();
}

class _NumberKeyboardBottomSheetState extends State<NumberKeyboardBottomSheet> {
  String _value = '';
  bool _ctaPressed = false;
  Timer? _backspaceHoldTimer;
  late bool _isExpense;

  String get _displayValue => _value.isEmpty ? '0' : _value;

  @override
  void initState() {
    super.initState();
    _isExpense = widget.initialIsExpense;
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

  void _updateExpenseType(bool isExpense) {
    if (_isExpense == isExpense) return;
    setState(() => _isExpense = isExpense);
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
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 320,
                    maxWidth: 520,
                  ),
                  child: _AmountHeader(
                    value: _displayValue,
                    isExpense: _isExpense,
                    onTypeChanged: _updateExpenseType,
                  ),
                ),
                const Spacer(),
                Center(
                  child: FractionallySizedBox(
                    widthFactor: 0.5,
                    child: _NumberPad(
                      onKeyTap: _onKeyTap,
                      onBackspace: _onBackspace,
                      onBackspaceHoldStart: _startBackspaceHold,
                      onBackspaceHoldEnd: _stopBackspaceHold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedSurface(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  isPressed: _ctaPressed,
                  pressedColor: const Color(0xFFF7F7F7),
                  duration: const Duration(milliseconds: 80),
                  curve: Curves.easeOut,
                  child: const Center(
                    child: Text(
                      'Next step',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountHeader extends StatelessWidget {
  const _AmountHeader({
    required this.value,
    required this.isExpense,
    required this.onTypeChanged,
  });

  final String value;
  final bool isExpense;
  final ValueChanged<bool> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
              icon: const HeroIcon(
                HeroIcons.xMark,
                style: HeroIconStyle.outline,
                color: Colors.black,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              splashRadius: 20,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        _ExpenseTypeToggle(isExpense: isExpense, onChanged: onTypeChanged),
        const SizedBox(height: 12),
        OutlinedSurface(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: SizedBox(
            height: 48,
            child: AutoSizeText(
              value,
              maxLines: 1,
              minFontSize: 18,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
        const SizedBox(height: 100),
        const _DottedDivider(),
      ],
    );
  }
}

class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 8,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dotCount = (constraints.maxWidth / 8).floor();
          final safeCount = dotCount.clamp(0, 200).toInt();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              safeCount,
              (_) => Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        },
      ),
    );
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
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
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

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  Future<void> _releaseWithPause() async {
    await Future.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    _setPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    final isBackspace = widget.isBackspace;
    final label = widget.label;

    return OutlinedSurface(
      height: 50,
      shape: BoxShape.circle,
      isPressed: _pressed,
      color: isBackspace ? const Color(0xFFFDEBEB) : Colors.white,
      pressedColor:
          isBackspace ? const Color(0xFFF5D9D9) : const Color(0xFFF7F7F7),
      duration: const Duration(milliseconds: 80),
      curve: Curves.easeOut,
      child: Center(
        child:
            isBackspace
                ? const Icon(Icons.backspace_outlined, color: Colors.black)
                : Text(
                  label,
                  style: TextStyle(
                    fontSize: label == '.' ? 32 : 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
      ),
    ).onTap(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _releaseWithPause(),
      onTapCancel: () => _releaseWithPause(),
      onLongPressStart:
          widget.isBackspace && widget.onLongPressStart != null
              ? (_) {
                _setPressed(true);
                widget.onLongPressStart!();
              }
              : null,
      onLongPressEnd:
          widget.isBackspace && widget.onLongPressEnd != null
              ? (_) {
                widget.onLongPressEnd!();
                _releaseWithPause();
              }
              : null,
      onLongPressCancel:
          widget.isBackspace && widget.onLongPressEnd != null
              ? () {
                widget.onLongPressEnd!();
                _releaseWithPause();
              }
              : null,
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
    );
  }
}
