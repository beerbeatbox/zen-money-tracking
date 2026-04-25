import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/settings/domain/entities/bottom_nav_style.dart';

part 'settings_local_datasource.g.dart';

enum BudgetSource {
  custom,
  autoConservative,
  autoExactly;

  String toJson() => name;
  static BudgetSource fromJson(String json) {
    return BudgetSource.values.firstWhere(
      (e) => e.name == json,
      orElse: () => BudgetSource.autoConservative,
    );
  }
}

class SettingsLocalDatasource {
  static const _fileName = 'settings.json';
  static const _carryBalanceEnabledKey = 'carry_balance_enabled';
  static const _budgetSourceKey = 'budget_source';
  static const _customBudgetAmountKey = 'custom_budget_amount';
  static const _expenseRemindersKey = 'expense_reminders';
  static const _scheduledNotificationsEnabledKey = 'scheduled_notifications_enabled';
  static const _dailyRecapNotificationEnabledKey =
      'daily_recap_notification_enabled';
  static const _weeklyRecapNotificationEnabledKey =
      'weekly_recap_notification_enabled';
  static const _bottomNavStyleKey = 'bottom_nav_style';

  Future<File> _ensureFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');

    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(<String, dynamic>{}));
    }

    return file;
  }

  Future<Map<String, dynamic>> _readMap() async {
    final file = await _ensureFile();
    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      return <String, dynamic>{};
    }

    final decoded = jsonDecode(content);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{};
  }

  Future<void> _writeMap(Map<String, dynamic> map) async {
    final file = await _ensureFile();
    await file.writeAsString(jsonEncode(map));
  }

  Future<bool> readCarryBalanceEnabled() async {
    final map = await _readMap();
    final raw = map[_carryBalanceEnabledKey];
    if (raw is bool) return raw;
    return false;
  }

  Future<void> writeCarryBalanceEnabled(bool enabled) async {
    final map = await _readMap();
    map[_carryBalanceEnabledKey] = enabled;
    await _writeMap(map);
  }

  Future<BudgetSource> readBudgetSource() async {
    final map = await _readMap();
    final raw = map[_budgetSourceKey];
    if (raw is String) {
      return BudgetSource.fromJson(raw);
    }
    return BudgetSource.autoConservative;
  }

  Future<void> writeBudgetSource(BudgetSource source) async {
    final map = await _readMap();
    map[_budgetSourceKey] = source.toJson();
    await _writeMap(map);
  }

  Future<double?> readCustomBudgetAmount() async {
    final map = await _readMap();
    final raw = map[_customBudgetAmountKey];
    if (raw is num) return raw.toDouble();
    return null;
  }

  Future<void> writeCustomBudgetAmount(double? amount) async {
    final map = await _readMap();
    if (amount == null) {
      map.remove(_customBudgetAmountKey);
    } else {
      map[_customBudgetAmountKey] = amount;
    }
    await _writeMap(map);
  }

  Future<List<TimeOfDay>> readExpenseReminders() async {
    final map = await _readMap();
    final raw = map[_expenseRemindersKey];
    if (raw is List) {
      return raw
          .map((item) {
            if (item is Map<String, dynamic>) {
              final hour = item['hour'];
              final minute = item['minute'];
              if (hour is int && minute is int) {
                return TimeOfDay(hour: hour, minute: minute);
              }
            }
            return null;
          })
          .whereType<TimeOfDay>()
          .toList();
    }
    return [];
  }

  Future<void> writeExpenseReminders(List<TimeOfDay> times) async {
    final map = await _readMap();
    map[_expenseRemindersKey] = times
        .map((time) => {'hour': time.hour, 'minute': time.minute})
        .toList();
    await _writeMap(map);
  }

  Future<bool> readScheduledNotificationsEnabled() async {
    final map = await _readMap();
    final raw = map[_scheduledNotificationsEnabledKey];
    if (raw is bool) return raw;
    return false;
  }

  Future<void> writeScheduledNotificationsEnabled(bool enabled) async {
    final map = await _readMap();
    map[_scheduledNotificationsEnabledKey] = enabled;
    await _writeMap(map);
  }

  Future<bool> readWeeklyRecapNotificationEnabled() async {
    final map = await _readMap();
    if (map.containsKey(_weeklyRecapNotificationEnabledKey)) {
      final raw = map[_weeklyRecapNotificationEnabledKey];
      if (raw is bool) return raw;
    }
    final legacy = map[_dailyRecapNotificationEnabledKey];
    if (legacy is bool) {
      map[_weeklyRecapNotificationEnabledKey] = legacy;
      await _writeMap(map);
      return legacy;
    }
    return true;
  }

  Future<void> writeWeeklyRecapNotificationEnabled(bool enabled) async {
    final map = await _readMap();
    map[_weeklyRecapNotificationEnabledKey] = enabled;
    await _writeMap(map);
  }

  Future<BottomNavStyle> readBottomNavStyle() async {
    final map = await _readMap();
    final raw = map[_bottomNavStyleKey];
    if (raw is String) return BottomNavStyle.fromJson(raw);
    return BottomNavStyle.floating;
  }

  Future<void> writeBottomNavStyle(BottomNavStyle style) async {
    final map = await _readMap();
    map[_bottomNavStyleKey] = style.toJson();
    await _writeMap(map);
  }
}

@riverpod
SettingsLocalDatasource settingsLocalDatasource(Ref ref) {
  return SettingsLocalDatasource();
}

