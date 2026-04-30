import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:baht/features/settings/data/datasources/settings_local_datasource.dart';
import 'package:baht/features/settings/domain/entities/bottom_nav_style.dart';

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

  Future<List<TimeOfDay>> getExpenseReminders() =>
      _datasource.readExpenseReminders();

  Future<void> setExpenseReminders(List<TimeOfDay> times) =>
      _datasource.writeExpenseReminders(times);

  Future<bool> getScheduledNotificationsEnabled() =>
      _datasource.readScheduledNotificationsEnabled();

  Future<void> setScheduledNotificationsEnabled(bool enabled) =>
      _datasource.writeScheduledNotificationsEnabled(enabled);

  Future<bool> getWeeklyRecapNotificationEnabled() =>
      _datasource.readWeeklyRecapNotificationEnabled();

  Future<void> setWeeklyRecapNotificationEnabled(bool enabled) =>
      _datasource.writeWeeklyRecapNotificationEnabled(enabled);

  Future<BottomNavStyle> getBottomNavStyle() => _datasource.readBottomNavStyle();

  Future<void> setBottomNavStyle(BottomNavStyle style) =>
      _datasource.writeBottomNavStyle(style);
}

@riverpod
SettingsRepository settingsRepository(Ref ref) {
  final datasource = ref.watch(settingsLocalDatasourceProvider);
  return SettingsRepository(datasource);
}

