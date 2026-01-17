import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/settings/data/datasources/settings_local_datasource.dart';

part 'settings_repository.g.dart';

class SettingsRepository {
  const SettingsRepository(this._datasource);

  final SettingsLocalDatasource _datasource;

  Future<bool> getCarryBalanceEnabled() => _datasource.readCarryBalanceEnabled();

  Future<void> setCarryBalanceEnabled(bool enabled) =>
      _datasource.writeCarryBalanceEnabled(enabled);

  Future<BudgetSource> getBudgetSource() => _datasource.readBudgetSource();

  Future<void> setBudgetSource(BudgetSource source) =>
      _datasource.writeBudgetSource(source);

  Future<double?> getCustomBudgetAmount() =>
      _datasource.readCustomBudgetAmount();

  Future<void> setCustomBudgetAmount(double? amount) =>
      _datasource.writeCustomBudgetAmount(amount);
}

@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final datasource = ref.watch(settingsLocalDatasourceProvider);
  return SettingsRepository(datasource);
}

