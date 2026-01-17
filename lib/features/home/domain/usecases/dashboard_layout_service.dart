import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/data/repositories/dashboard_layout_repository.dart';
import 'package:anti/features/home/domain/entities/dashboard_layout.dart';

part 'dashboard_layout_service.g.dart';

class DashboardLayoutService {
  const DashboardLayoutService(this._repository);

  final DashboardLayoutRepository _repository;

  Future<DashboardLayout> getLayout() => _repository.readLayout();

  Future<void> setLayout(DashboardLayout layout) =>
      _repository.writeLayout(layout);
}

@riverpod
DashboardLayoutService dashboardLayoutService(Ref ref) {
  final repo = ref.watch(dashboardLayoutRepositoryProvider);
  return DashboardLayoutService(repo);
}
