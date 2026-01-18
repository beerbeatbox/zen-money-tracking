import 'package:anti/core/extensions/widget_extension.dart';
import 'package:flutter/material.dart';

class OutlinedActionButton extends StatefulWidget {
  const OutlinedActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.textColor = Colors.black,
    this.borderColor = Colors.black,
    this.backgroundColor = Colors.white,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color textColor;
  final Color borderColor;
  final Color backgroundColor;

  @override
  State<OutlinedActionButton> createState() => _OutlinedActionButtonState();
}

class _OutlinedActionButtonState extends State<OutlinedActionButton> {
  static const _radius = BorderRadius.all(Radius.circular(12));
  static const _releaseDelay = Duration(milliseconds: 90);
  static const _disabledBackgroundColor = Color(0xFFF4F4F4);

  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  Future<void> _releaseWithPause() async {
    await Future.delayed(_releaseDelay);
    if (!mounted) return;
    _setPressed(false);
  }

  void _handleTap() {
    if (widget.onPressed == null) return;
    widget.onPressed!();
  }

  void _handleTapDown(TapDownDetails _) {
    if (widget.onPressed == null) return;
    _setPressed(true);
  }

  void _handleTapUp(TapUpDetails _) {
    if (widget.onPressed == null) return;
    _releaseWithPause();
  }

  void _handleTapCancel() {
    if (widget.onPressed == null) return;
    _releaseWithPause();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;

    final effectiveBackgroundColor =
        enabled ? widget.backgroundColor : _disabledBackgroundColor;
    final effectiveBorderColor =
        enabled ? widget.borderColor : Colors.black.withValues(alpha: 0.12);
    final effectiveTextColor =
        enabled ? widget.textColor : Colors.black.withValues(alpha: 0.45);

    final child = AnimatedContainer(
      duration: const Duration(milliseconds: 70),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: _pressed
            ? effectiveBackgroundColor.withValues(alpha: 0.9)
            : effectiveBackgroundColor,
        borderRadius: _radius,
        border: Border.all(color: effectiveBorderColor, width: 2),
      ),
      child: Center(
        child: Text(
          widget.label,
          style: TextStyle(
            color: effectiveTextColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );

    if (!enabled) return child;

    return child.onTap(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
    );
  }
}
