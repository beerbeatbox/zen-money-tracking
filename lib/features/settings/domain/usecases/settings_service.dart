import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:baht/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:baht/features/settings/data/repositories/settings_repository.dart';
import 'package:baht/features/settings/domain/entities/bottom_nav_style.dart';

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

  Future<List<TimeOfDay>> getExpenseReminders() =>
      _repository.getExpenseReminders();

  Future<void> setExpenseReminders(List<TimeOfDay> times) =>
      _repository.setExpenseReminders(times);

  Future<bool> getScheduledNotificationsEnabled() =>
      _repository.getScheduledNotificationsEnabled();

  Future<void> setScheduledNotificationsEnabled(bool enabled) =>
      _repository.setScheduledNotificationsEnabled(enabled);

  Future<bool> getWeeklyRecapNotificationEnabled() =>
      _repository.getWeeklyRecapNotificationEnabled();

  Future<void> setWeeklyRecapNotificationEnabled(bool enabled) =>
      _repository.setWeeklyRecapNotificationEnabled(enabled);

  Future<BottomNavStyle> getBottomNavStyle() => _repository.getBottomNavStyle();

  Future<void> setBottomNavStyle(BottomNavStyle style) =>
      _repository.setBottomNavStyle(style);
}

@riverpod
SettingsService settingsService(Ref ref) {
  final repo = ref.watch(settingsRepositoryProvider);
  return SettingsService(repo);
}

