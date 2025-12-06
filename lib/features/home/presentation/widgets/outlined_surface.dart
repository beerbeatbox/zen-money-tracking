import 'package:flutter/material.dart';

class OutlinedSurface extends StatelessWidget {
  const OutlinedSurface({
    super.key,
    required this.child,
    this.padding,
    this.color = Colors.white,
    Color? pressedColor,
    this.isPressed = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.border = const Border.fromBorderSide(
      BorderSide(color: Colors.black, width: 2),
    ),
    this.unpressedShadowOffset = const Offset(3, 3),
    this.pressedShadowOffset = const Offset(3, 3),
    this.duration = const Duration(milliseconds: 70),
    this.curve = Curves.linear,
    this.width,
    this.height,
  }) : pressedColor = pressedColor ?? color;

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color color;
  final Color pressedColor;
  final bool isPressed;
  final BorderRadius borderRadius;
  final BoxBorder border;
  final Offset unpressedShadowOffset;
  final Offset pressedShadowOffset;
  final Duration duration;
  final Curve curve;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final surfaceOffset = isPressed ? pressedShadowOffset : Offset.zero;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topLeft,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black,
                    offset: unpressedShadowOffset,
                    blurRadius: 0,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: duration,
            curve: curve,
            padding: padding,
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: isPressed ? pressedColor : color,
              border: border,
              borderRadius: borderRadius,
            ),
            transform: Matrix4.translationValues(
              surfaceOffset.dx,
              surfaceOffset.dy,
              0,
            ),
            transformAlignment: Alignment.topLeft,
            child: child,
          ),
        ],
      ),
    );
  }
}
