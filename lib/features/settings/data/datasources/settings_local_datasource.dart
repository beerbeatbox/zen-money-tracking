import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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
}

@riverpod
SettingsLocalDatasource settingsLocalDatasource(Ref ref) {
  return SettingsLocalDatasource();
}

