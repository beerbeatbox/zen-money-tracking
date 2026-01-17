import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/domain/entities/dashboard_layout.dart';
import 'package:anti/features/home/domain/usecases/dashboard_layout_service.dart';

part 'dashboard_layout_controller.g.dart';

@Riverpod(keepAlive: true)
class DashboardLayoutController extends _$DashboardLayoutController {
  @override
  FutureOr<DashboardLayout> build() async {
    final service = ref.watch(dashboardLayoutServiceProvider);
    return service.getLayout();
  }

  Future<void> reorderActive(int fromIndex, int toIndex) async {
    final layout = _currentLayout();
    final reordered = _reorderList(layout.active, fromIndex, toIndex);
    await _save(layout.copyWith(active: reordered));
  }

  Future<void> reorderInactive(int fromIndex, int toIndex) async {
    final layout = _currentLayout();
    final reordered = _reorderList(layout.inactive, fromIndex, toIndex);
    await _save(layout.copyWith(inactive: reordered));
  }

  Future<void> moveToActive(
    DashboardSectionId sectionId, {
    int? index,
  }) async {
    final layout = _currentLayout();
    if (layout.active.contains(sectionId)) return;

    final nextInactive = [...layout.inactive]..remove(sectionId);
    final nextActive = [...layout.active];
    final insertIndex =
        index == null ? nextActive.length : index.clamp(0, nextActive.length);
    nextActive.insert(insertIndex, sectionId);

    await _save(
      DashboardLayout.normalize(active: nextActive, inactive: nextInactive),
    );
  }

  Future<void> moveToInactive(
    DashboardSectionId sectionId, {
    int? index,
  }) async {
    final layout = _currentLayout();
    if (layout.inactive.contains(sectionId)) return;

    final nextActive = [...layout.active]..remove(sectionId);
    final nextInactive = [...layout.inactive];
    final insertIndex =
        index == null
            ? nextInactive.length
            : index.clamp(0, nextInactive.length);
    nextInactive.insert(insertIndex, sectionId);

    await _save(
      DashboardLayout.normalize(active: nextActive, inactive: nextInactive),
    );
  }

  Future<void> resetToDefault() async {
    await _save(DashboardLayout.defaults());
  }

  DashboardLayout _currentLayout() {
    return state.value ?? DashboardLayout.defaults();
  }

  List<DashboardSectionId> _reorderList(
    List<DashboardSectionId> list,
    int fromIndex,
    int toIndex,
  ) {
    if (fromIndex == toIndex) return list;
    if (fromIndex < 0 || fromIndex >= list.length) return list;
    if (toIndex < 0 || toIndex > list.length) return list;

    final updated = [...list];
    final item = updated.removeAt(fromIndex);
    final insertIndex =
        fromIndex < toIndex ? (toIndex - 1).clamp(0, updated.length) : toIndex;
    updated.insert(insertIndex, item);
    return updated;
  }

  Future<void> _save(DashboardLayout layout) async {
    state = AsyncData(layout);
    final service = ref.read(dashboardLayoutServiceProvider);
    await service.setLayout(layout);
  }
}
