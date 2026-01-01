import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_selected_month_controller.g.dart';

@riverpod
class DashboardSelectedMonth extends _$DashboardSelectedMonth {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void goToPreviousMonth() {
    final current = state;
    state = DateTime(current.year, current.month - 1);
  }

  void goToNextMonth() {
    final current = state;
    state = DateTime(current.year, current.month + 1);
  }
}
