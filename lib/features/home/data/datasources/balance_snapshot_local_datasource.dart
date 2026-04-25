import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/data/models/balance_snapshot_model.dart';

part 'balance_snapshot_local_datasource.g.dart';

class BalanceSnapshotLocalDatasource {
  static const _fileName = 'balance_snapshots.json';
  static const _versionKey = 'version';
  static const _itemsKey = 'items';
  static const _currentVersion = 1;

  Future<File> _ensureFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');

    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(
        jsonEncode({
          _versionKey: _currentVersion,
          _itemsKey: <Map<String, dynamic>>[],
        }),
      );
    }

    return file;
  }

  Future<Map<String, dynamic>> _readRoot() async {
    final file = await _ensureFile();
    final content = await file.readAsString();
    if (content.trim().isEmpty) {
      return {
        _versionKey: _currentVersion,
        _itemsKey: <Map<String, dynamic>>[],
      };
    }
    final decoded = jsonDecode(content);
    if (decoded is! Map<String, dynamic>) {
      return {
        _versionKey: _currentVersion,
        _itemsKey: <Map<String, dynamic>>[],
      };
    }
    return decoded;
  }

  Future<void> _writeRoot(Map<String, dynamic> map) async {
    final file = await _ensureFile();
    await file.writeAsString(jsonEncode(map));
  }

  Future<List<BalanceSnapshotModel>> readAll() async {
    final map = await _readRoot();
    final raw = map[_itemsKey];
    if (raw is! List) return [];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map((e) => BalanceSnapshotModel.fromJson(
              e.map(
                (k, v) => MapEntry(
                  k.toString(),
                  v,
                ),
              ),
            ))
        .toList();
  }

  Future<void> append(BalanceSnapshotModel model) async {
    final map = await _readRoot();
    final raw = map[_itemsKey];
    final list = <Map<String, dynamic>>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map<String, dynamic>) {
          list.add(item);
        } else if (item is Map) {
          list.add(
            item.map(
              (k, v) => MapEntry(
                k.toString(),
                v,
              ),
            ),
          );
        }
      }
    }
    list.add(model.toJson());
    list.sort(
      (a, b) {
        final aStr = a['effectiveAt'] as String? ?? '';
        final bStr = b['effectiveAt'] as String? ?? '';
        return aStr.compareTo(bStr);
      },
    );
    map[_versionKey] = _currentVersion;
    map[_itemsKey] = list;
    await _writeRoot(map);
  }

  Future<void> deleteFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');
    if (await file.exists()) {
      await file.delete();
    }
  }
}

@riverpod
BalanceSnapshotLocalDatasource balanceSnapshotLocalDatasource(Ref ref) {
  return BalanceSnapshotLocalDatasource();
}
