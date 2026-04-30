import 'package:flutter/material.dart';

/// A white card with rounded corners, light border, and shadow
/// for wrapping content sections on grey screen backgrounds.
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  final Widget child;

  /// When null, uses a white surface and a white border (default card look).
  final Color? backgroundColor;

  /// When null, matches the default white border.
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final fill = backgroundColor ?? Colors.white;
    final outline = borderColor ?? Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: outline),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
