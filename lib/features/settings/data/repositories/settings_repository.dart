import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/settings/data/datasources/settings_local_datasource.dart';

part 'settings_repository.g.dart';

class SettingsRepository {
  const SettingsRepository(this._datasource);

  final SettingsLocalDatasource _datasource;

  Future<bool> getCarryBalanceEnabled() => _datasource.readCarryBalanceEnabled();

  Future<void> setCarryBalanceEnabled(bool enabled) =>
      _datasource.writeCarryBalanceEnabled(enabled);
}

@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final datasource = ref.watch(settingsLocalDatasourceProvider);
  return SettingsRepository(datasource);
}

