import 'package:flutter/material.dart';
import '../constants/app_sizes.dart';

extension WidgetExtension on Widget {
  Widget padding(EdgeInsets padding) => Padding(
        padding: padding,
        child: this,
      );

  Widget paddingAll(double value) =>
      Padding(padding: EdgeInsets.all(value), child: this);

  Widget paddingSymmetric({
    double horizontal = Sizes.kP0,
    double vertical = Sizes.kP0,
  }) =>
      Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: vertical,
          ),
          child: this);

  Widget paddingOnly({
    double left = Sizes.kP0,
    double right = Sizes.kP0,
    double top = Sizes.kP0,
    double bottom = Sizes.kP0,
  }) =>
      Padding(
        padding: EdgeInsets.only(
          left: left,
          right: right,
          top: top,
          bottom: bottom,
        ),
        child: this,
      );

  Widget onTap(VoidCallback? onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: this,
      );

  // Returns true to disable the back button, false to enable it.
  Widget withBackButtonListener(Future<bool> Function() onBackButtonPressed) =>
      BackButtonListener(
        onBackButtonPressed: onBackButtonPressed,
        child: this,
      );
}

