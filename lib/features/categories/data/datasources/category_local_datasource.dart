import 'dart:io';

import 'package:baht/features/categories/data/models/category_model.dart';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'category_local_datasource.g.dart';

class CategoryLocalDatasource {
  static const _fileName = 'categories.csv';
  static const _headers = [
    'id',
    'type',
    'label',
    'createdAt',
    'sortIndex',
    'emoji',
    'parentId',
  ];
  static const _csvEol = '\n';

  Future<File> _ensureFile() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$_fileName');

    if (!await file.exists()) {
      await file.create(recursive: true);
      final header = const ListToCsvConverter(eol: _csvEol).convert([_headers]);
      await file.writeAsString(header);
    }

    return file;
  }

  Future<List<CategoryModel>> readAll() async {
    final file = await _ensureFile();
    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      return [];
    }

    final rows = const CsvToListConverter(eol: _csvEol).convert(content);
    if (rows.isEmpty) return [];

    final dataRows = rows
        .skip(1) // header
        .where((row) => row.isNotEmpty)
        .toList(growable: false);

    return dataRows.map(CategoryModel.fromCsvRow).toList();
  }

  Future<void> overwrite(List<CategoryModel> categories) async {
    final file = await _ensureFile();
    final rows = [_headers, ...categories.map((c) => c.toCsvRow())];
    final csv = const ListToCsvConverter(eol: _csvEol).convert(rows);
    await file.writeAsString(csv);
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
CategoryLocalDatasource categoryLocalDatasource(Ref ref) {
  return CategoryLocalDatasource();
}
