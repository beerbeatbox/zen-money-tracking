import 'package:flutter/material.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';

Future<String?> showNumberKeyboardBottomSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const NumberKeyboardBottomSheet(),
  );
}

class NumberKeyboardBottomSheet extends StatefulWidget {
  const NumberKeyboardBottomSheet({super.key});

  @override
  State<NumberKeyboardBottomSheet> createState() =>
      _NumberKeyboardBottomSheetState();
}

class _NumberKeyboardBottomSheetState extends State<NumberKeyboardBottomSheet> {
  String _value = '';
  bool _ctaPressed = false;

  String get _displayValue => _value.isEmpty ? '0' : _value;

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

  void _submit() {
    Navigator.of(context).pop(_displayValue);
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

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.viewInsets.bottom;

    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: double.infinity,
        child: OutlinedSurface(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + bottomPadding),
          borderRadius: const BorderRadius.only(topLeft: Radius.circular(28)),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: 320,
                    maxWidth: 520,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _AmountHeader(value: _displayValue),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FractionallySizedBox(
                          widthFactor: 0.5,
                          child: _NumberPad(
                            onKeyTap: _onKeyTap,
                            onBackspace: _onBackspace,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                GestureDetector(
                  onTapDown: (_) => _setCtaPressed(true),
                  onTapUp: (_) => _releaseCtaWithPause(),
                  onTapCancel: () => _releaseCtaWithPause(),
                  onTap: _submit,
                  behavior: HitTestBehavior.opaque,
                  child: OutlinedSurface(
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
                  ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Enter amount',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        OutlinedSurface(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          borderRadius: const BorderRadius.all(Radius.circular(16)),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              height: 48,
              child: AutoSizeText(
                value,
                maxLines: 1,
                minFontSize: 18,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.onKeyTap, required this.onBackspace});

  final Function(String) onKeyTap;
  final VoidCallback onBackspace;

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
                  padding: EdgeInsets.only(bottom: 0),
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
    this.isBackspace = false,
  });

  final String label;
  final VoidCallback onTap;
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

    return GestureDetector(
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _releaseWithPause(),
      onTapCancel: () => _releaseWithPause(),
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isBackspace
                  ? (_pressed
                      ? const Color(0xFFF5D9D9)
                      : const Color(0xFFFDEBEB))
                  : (_pressed ? const Color(0xFFF7F7F7) : Colors.white),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black,
              offset: _pressed ? const Offset(1, 1) : const Offset(3, 3),
              blurRadius: 0,
              spreadRadius: 0,
            ),
          ],
        ),
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
      ),
    );
  }
}
