import 'package:flutter/material.dart';

/// Typography for dashboard cards wrapped in [SectionCard] so titles align.
abstract final class DashboardSectionHeaderStyles {
  static const Color dueNowTitleColor = Color(0xFFCC5533);
  static const Color upcomingTitleColor = Color(0xFF2B5FA8);
  static const Color transactionsTitleColor = Color(0xFF1A5C52);

  static TextStyle titleStyle({required Color color}) {
    return TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.4,
      color: color,
    );
  }

  /// Secondary line under titles (e.g. transaction counter).
  static TextStyle subtitleStyle() {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
      color: Colors.grey[600],
    );
  }

  /// Consistent gutter from section title row to first body content.
  static const double spacingBelowTitle = 12;
}
