import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class Sizes {
  Sizes._();

  /// Bottom inset to reserve for the overlay bottom nav so the last widget
  /// is not covered. Matches bar height: 80 (margin 8+8, content 64) plus
  /// SafeArea bottom (min 8). Use as extra bottom padding in shell scroll views.
  static double bottomNavInset(BuildContext context) =>
      80 + math.max(8.0, MediaQuery.of(context).padding.bottom);

  static const double kP0 = 0.0;
  static const double kP4 = 4.0;
  static const double kP8 = 8.0;
  static const double kP12 = 12.0;
  static const double kP16 = 16.0;
  static const double kP20 = 20.0;
  static const double kP24 = 24.0;
  static const double kP32 = 32.0;

  // Widget specific heights
  static const double kSearchBoxHeight = 48.0;
}

