import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/data/datasources/dashboard_layout_local_datasource.dart';
import 'package:anti/features/home/domain/entities/dashboard_layout.dart';

part 'dashboard_layout_repository.g.dart';

class DashboardLayoutRepository {
  const DashboardLayoutRepository(this._datasource);

  final DashboardLayoutLocalDatasource _datasource;

  Future<DashboardLayout> readLayout() => _datasource.readLayout();

  Future<void> writeLayout(DashboardLayout layout) =>
      _datasource.writeLayout(layout);
}

@riverpod
DashboardLayoutRepository dashboardLayoutRepository(Ref ref) {
  final datasource = ref.watch(dashboardLayoutLocalDatasourceProvider);
  return DashboardLayoutRepository(datasource);
}
