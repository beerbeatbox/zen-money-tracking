import 'dart:math' as math;

import 'package:baht/features/settings/domain/entities/bottom_nav_style.dart';
import 'package:flutter/widgets.dart';

class Sizes {
  Sizes._();

  /// Bottom inset to reserve for the overlay bottom nav so the last widget
  /// is not covered. Must match [CustomBottomNav] layout per style.
  ///
  /// **Floating:** 80 (SafeArea min bottom 8 + vertical margin 16 + row 56
  /// effective to ~64 icon row) plus `max(8, safe bottom)` — same formula as
  /// before style customization.
  ///
  /// **Standard:** 56px bar row plus device bottom safe inset (home indicator).
  static double bottomNavInset(BuildContext context, BottomNavStyle style) {
    final bottomSafe = MediaQuery.of(context).padding.bottom;
    switch (style) {
      case BottomNavStyle.floating:
        return 80 + math.max(8.0, bottomSafe);
      case BottomNavStyle.standard:
        return 56 + bottomSafe;
    }
  }

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

