/// Dashboard blocks shown on [DashboardScreen] (fixed order).
enum DashboardSectionId {
  spentToday,
  dueNow,
  upcoming,
  transactions,
}

/// Fixed section order for [DashboardScreen].
const List<DashboardSectionId> kDashboardSectionOrder = [
  DashboardSectionId.spentToday,
  DashboardSectionId.dueNow,
  DashboardSectionId.upcoming,
  DashboardSectionId.transactions,
];
