import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:anti/features/settings/data/repositories/settings_repository.dart';

part 'settings_service.g.dart';

class SettingsService {
  const SettingsService(this._repository);

  final SettingsRepository _repository;

  Future<bool> getCarryBalanceEnabled() => _repository.getCarryBalanceEnabled();

  Future<void> setCarryBalanceEnabled(bool enabled) =>
      _repository.setCarryBalanceEnabled(enabled);

  Future<BudgetSource> getBudgetSource() => _repository.getBudgetSource();

  Future<void> setBudgetSource(BudgetSource source) =>
      _repository.setBudgetSource(source);

  Future<double?> getCustomBudgetAmount() => _repository.getCustomBudgetAmount();

  Future<void> setCustomBudgetAmount(double? amount) =>
      _repository.setCustomBudgetAmount(amount);
}

@riverpod
SettingsService settingsService(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsService(repo);
}

