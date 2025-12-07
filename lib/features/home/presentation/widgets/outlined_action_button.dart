import 'package:flutter/material.dart';

import 'package:anti/core/extensions/widget_extension.dart';

import 'outlined_surface.dart';

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
    return OutlinedSurface(
      borderRadius: _radius,
      border: Border.all(color: widget.borderColor, width: 2),
      color: widget.backgroundColor,
      pressedColor: widget.backgroundColor,
      isPressed: _pressed,
      duration: const Duration(milliseconds: 0),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Text(
          widget.label,
          style: TextStyle(
            color: widget.textColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
      ),
    ).onTap(
      behavior: HitTestBehavior.opaque,
      onTap: _handleTap,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
    );
  }
}
