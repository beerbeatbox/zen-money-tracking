import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:baht/features/home/domain/entities/dashboard_layout.dart';

part 'dashboard_layout_local_datasource.g.dart';

class DashboardLayoutLocalDatasource {
  static const _fileName = 'dashboard_layout.json';
  static const _activeKey = 'active';
  static const _inactiveKey = 'inactive';

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

  List<DashboardSectionId> _parseList(dynamic raw) {
    if (raw is! List) return <DashboardSectionId>[];
    return raw
        .whereType<String>()
        .map(_sectionFromString)
        .whereType<DashboardSectionId>()
        .toList(growable: false);
  }

  DashboardSectionId? _sectionFromString(String value) {
    for (final section in DashboardSectionId.values) {
      if (section.name == value) return section;
    }
    return null;
  }

  Future<void> _writeMap(Map<String, dynamic> map) async {
    final file = await _ensureFile();
    await file.writeAsString(jsonEncode(map));
  }

  Future<DashboardLayout> readLayout() async {
    final map = await _readMap();
    final active = _parseList(map[_activeKey]);
    final inactive = _parseList(map[_inactiveKey]);

    if (active.isEmpty && inactive.isEmpty) {
      return DashboardLayout.defaults();
    }

    return DashboardLayout.normalize(active: active, inactive: inactive);
  }

  Future<void> writeLayout(DashboardLayout layout) async {
    final map = <String, dynamic>{
      _activeKey: layout.active.map((e) => e.name).toList(growable: false),
      _inactiveKey: layout.inactive.map((e) => e.name).toList(growable: false),
    };
    await _writeMap(map);
  }
}

@riverpod
DashboardLayoutLocalDatasource dashboardLayoutLocalDatasource(Ref ref) {
  return DashboardLayoutLocalDatasource();
}
