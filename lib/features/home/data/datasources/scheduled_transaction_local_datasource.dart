import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/data/models/scheduled_transaction_model.dart';

part 'scheduled_transaction_local_datasource.g.dart';

class ScheduledTransactionLocalDatasource {
  static const _fileName = 'scheduled_transactions.json';

  Future<File> _ensureFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');

    if (!await file.exists()) {
      await file.create(recursive: true);
      await file.writeAsString(jsonEncode(<dynamic>[]));
    }

    return file;
  }

  Future<List<dynamic>> _readList() async {
    final file = await _ensureFile();
    final content = await file.readAsString();
    if (content.trim().isEmpty) return <dynamic>[];

    final decoded = jsonDecode(content);
    if (decoded is List<dynamic>) return decoded;
    return <dynamic>[];
  }

  Future<void> _writeList(List<dynamic> list) async {
    final file = await _ensureFile();
    await file.writeAsString(jsonEncode(list));
  }

  Future<List<ScheduledTransactionModel>> readAll() async {
    final raw = await _readList();
    final models = <ScheduledTransactionModel>[];

    for (final item in raw) {
      if (item is Map<String, dynamic>) {
        models.add(ScheduledTransactionModel.fromJson(item));
      } else if (item is Map) {
        models.add(
          ScheduledTransactionModel.fromJson(
            item.map(
              (key, value) => MapEntry(key.toString(), value),
            ),
          ),
        );
      }
    }

    return models;
  }

  Future<void> overwrite(List<ScheduledTransactionModel> items) async {
    final list = items.map((e) => e.toJson()).toList(growable: false);
    await _writeList(list);
  }

  Future<void> append(ScheduledTransactionModel item) async {
    final items = await readAll();
    await overwrite([...items, item]);
  }

  Future<void> deleteById(String id) async {
    final items = await readAll();
    final updated = items.where((e) => e.id != id).toList(growable: false);
    await overwrite(updated);
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
ScheduledTransactionLocalDatasource scheduledTransactionLocalDatasource(Ref ref) {
  return ScheduledTransactionLocalDatasource();
}


