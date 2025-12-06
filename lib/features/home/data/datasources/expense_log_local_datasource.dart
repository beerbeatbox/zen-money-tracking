import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:anti/features/home/data/models/expense_log_model.dart';

part 'expense_log_local_datasource.g.dart';

class ExpenseLogLocalDatasource {
  static const _fileName = 'expense_logs.csv';
  static const _headers = [
    'id',
    'title',
    'timeLabel',
    'category',
    'amount',
    'createdAt',
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

  Future<List<ExpenseLogModel>> readAll() async {
    final file = await _ensureFile();
    final content = await file.readAsString();

    if (content.trim().isEmpty) {
      return [];
    }

    final rows = const CsvToListConverter(eol: _csvEol).convert(content);

    if (rows.isEmpty) {
      return [];
    }

    // Skip header row and drop blank lines
    final dataRows = rows
        .skip(1)
        .where((row) => row.isNotEmpty)
        .toList(growable: false);
    return dataRows.map(ExpenseLogModel.fromCsvRow).toList();
  }

  Future<void> append(ExpenseLogModel log) async {
    final file = await _ensureFile();
    final csvRow = const ListToCsvConverter(
      eol: _csvEol,
    ).convert([log.toCsvRow()]);
    final sink = file.openWrite(mode: FileMode.append);
    sink.write('$_csvEol$csvRow');
    await sink.close();
  }

  Future<void> overwrite(List<ExpenseLogModel> logs) async {
    final file = await _ensureFile();
    final rows = [_headers, ...logs.map((log) => log.toCsvRow())];
    final csv = const ListToCsvConverter(eol: _csvEol).convert(rows);
    await file.writeAsString(csv);
  }
}

@riverpod
ExpenseLogLocalDatasource expenseLogLocalDatasource(Ref ref) {
  return ExpenseLogLocalDatasource();
}
