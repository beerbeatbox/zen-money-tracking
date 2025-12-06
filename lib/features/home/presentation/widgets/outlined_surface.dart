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
    this.pressedShadowOffset = const Offset(1, 1),
    this.duration = Duration.zero,
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
    final decoration = BoxDecoration(
      color: isPressed ? pressedColor : color,
      border: border,
      borderRadius: borderRadius,
      boxShadow: [
        BoxShadow(
          color: Colors.black,
          offset: isPressed ? pressedShadowOffset : unpressedShadowOffset,
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ],
    );

    return AnimatedContainer(
      duration: duration,
      curve: curve,
      padding: padding,
      width: width,
      height: height,
      decoration: decoration,
      child: child,
    );
  }
}

