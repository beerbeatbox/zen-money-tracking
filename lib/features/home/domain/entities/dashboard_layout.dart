import 'package:flutter/foundation.dart';

enum DashboardSectionId {
  budgetLeftToday,
  balance,
  incomeSpent,
  monthEndSufficiency,
  scheduledThisMonth,
  dueNow,
  recentActivity,
}

@immutable
class DashboardLayout {
  const DashboardLayout({
    required this.active,
    required this.inactive,
  });

  final List<DashboardSectionId> active;
  final List<DashboardSectionId> inactive;

  DashboardLayout copyWith({
    List<DashboardSectionId>? active,
    List<DashboardSectionId>? inactive,
  }) {
    return DashboardLayout(
      active: active ?? this.active,
      inactive: inactive ?? this.inactive,
    );
  }

  static List<DashboardSectionId> allSections() {
    return const [
      DashboardSectionId.budgetLeftToday,
      DashboardSectionId.balance,
      DashboardSectionId.incomeSpent,
      DashboardSectionId.monthEndSufficiency,
      DashboardSectionId.scheduledThisMonth,
      DashboardSectionId.dueNow,
      DashboardSectionId.recentActivity,
    ];
  }

  static DashboardLayout defaults() {
    return DashboardLayout(
      active: allSections(),
      inactive: const [],
    );
  }

  static DashboardLayout normalize({
    required List<DashboardSectionId> active,
    required List<DashboardSectionId> inactive,
  }) {
    final seen = <DashboardSectionId>{};
    final normalizedActive = <DashboardSectionId>[];
    final normalizedInactive = <DashboardSectionId>[];

    for (final item in active) {
      if (seen.add(item)) {
        normalizedActive.add(item);
      }
    }

    for (final item in inactive) {
      if (seen.add(item)) {
        normalizedInactive.add(item);
      }
    }

    for (final section in allSections()) {
      if (seen.add(section)) {
        normalizedInactive.add(section);
      }
    }

    return DashboardLayout(active: normalizedActive, inactive: normalizedInactive);
  }
}

extension DashboardSectionLabel on DashboardSectionId {
  String get title {
    switch (this) {
      case DashboardSectionId.budgetLeftToday:
        return 'Budget left today';
      case DashboardSectionId.balance:
        return 'Balance';
      case DashboardSectionId.incomeSpent:
        return 'Income and spending';
      case DashboardSectionId.monthEndSufficiency:
        return 'Month-end insight';
      case DashboardSectionId.scheduledThisMonth:
        return 'Scheduled this month';
      case DashboardSectionId.dueNow:
        return 'Due now';
      case DashboardSectionId.recentActivity:
        return 'Recent activity';
    }
  }

  String get subtitle {
    switch (this) {
      case DashboardSectionId.budgetLeftToday:
        return 'Track your daily budget';
      case DashboardSectionId.balance:
        return 'See your month balance';
      case DashboardSectionId.incomeSpent:
        return 'Compare income and spending';
      case DashboardSectionId.monthEndSufficiency:
        return 'Stay on track this month';
      case DashboardSectionId.scheduledThisMonth:
        return 'Review upcoming schedules';
      case DashboardSectionId.dueNow:
        return 'Check what is due today';
      case DashboardSectionId.recentActivity:
        return 'Review your latest logs';
    }
  }
}
