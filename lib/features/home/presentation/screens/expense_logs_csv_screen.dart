import 'dart:convert';
import 'dart:io';

import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/widgets/section_card.dart';
import 'package:anti/features/home/data/models/expense_log_model.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/usecases/expense_log_service.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:anti/features/settings/presentation/widgets/outlined_confirmation_dialog.dart';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExpenseLogsCsvScreen extends ConsumerWidget {
  const ExpenseLogsCsvScreen({super.key});

  static const _headers = <String>[
    'id',
    'title',
    'timeLabel',
    'category',
    'amount',
    'createdAt',
  ];

  static const _csvEol = '\n';

  bool get _isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeaderSection(onBackPressed: context.pop),
            const SizedBox(height: 16),
            const SizedBox(height: 24),
            SectionCard(
              child: _BodySection(
                isIOS: _isIOS,
                onDownloadTemplate: () => _downloadTemplate(context),
                onExport: () => _exportAllLogs(context, ref),
                onImport: () => _importCsv(context, ref),
              ),
            ),
          ],
        ).paddingAll(24),
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _normalizeCell(Object? v) => (v ?? '').toString().trim().toLowerCase();

  Future<File> _writeCsvToTemp({
    required String fileName,
    required List<List<dynamic>> rows,
  }) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/$fileName');
    final csv = const ListToCsvConverter(eol: _csvEol).convert(rows);
    return file.writeAsString(csv, flush: true);
  }

  Future<void> _shareFile(
    BuildContext context,
    File file, {
    required String subject,
  }) async {
    final renderObject = context.findRenderObject();
    final box = renderObject is RenderBox ? renderObject : null;
    final origin =
        box == null ? null : (box.localToGlobal(Offset.zero) & box.size);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: subject,
      sharePositionOrigin: origin,
    );
  }

  Future<void> _downloadTemplate(BuildContext context) async {
    if (!_isIOS) {
      _showSnack(context, 'iOS support is ready. Android is coming soon.');
      return;
    }

    final now = DateTime.now();
    final sampleCreatedAt = DateTime(now.year, now.month, now.day, 8, 30);

    final rows = <List<dynamic>>[
      _headers,
      [
        '',
        'Coffee',
        '08:30',
        'Food',
        '-4.50',
        sampleCreatedAt.toIso8601String(),
      ],
    ];

    try {
      final file = await _writeCsvToTemp(
        fileName: 'expense_logs_template.csv',
        rows: rows,
      );
      if (!context.mounted) return;
      await _shareFile(context, file, subject: 'Expense logs template');
      if (!context.mounted) return;
      _showSnack(context, 'Template ready to save or share.');
    } catch (e) {
      debugPrint('Download template failed: $e');
      if (!context.mounted) return;
      _showSnack(context, "Couldn't create the template. Please try again.");
    }
  }

  Future<void> _exportAllLogs(BuildContext context, WidgetRef ref) async {
    if (!_isIOS) {
      _showSnack(context, 'iOS support is ready. Android is coming soon.');
      return;
    }

    try {
      final service = ref.read(expenseLogServiceProvider);
      final logs = await service.getExpenseLogs();
      final models = logs
          .map(ExpenseLogModel.fromEntity)
          .toList(growable: false);

      final rows = <List<dynamic>>[
        _headers,
        ...models.map((m) => m.toCsvRow()),
      ];

      final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final file = await _writeCsvToTemp(
        fileName: 'expense_logs_export_$stamp.csv',
        rows: rows,
      );

      if (!context.mounted) return;
      await _shareFile(context, file, subject: 'Expense logs export');

      if (!context.mounted) return;
      _showSnack(context, 'Export ready to save or share.');
    } catch (e) {
      debugPrint('Export logs failed: $e');
      if (!context.mounted) return;
      _showSnack(context, "Couldn't export your logs. Please try again.");
    }
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    if (!_isIOS) {
      _showSnack(context, 'iOS support is ready. Android is coming soon.');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
        withData: true,
      );
      if (!context.mounted) return;
      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;
      final bytes = file.bytes;
      if (bytes == null || bytes.isEmpty) {
        _showSnack(context, 'Please pick a CSV file with content.');
        return;
      }

      final content = utf8.decode(bytes);
      final rows = const CsvToListConverter(eol: _csvEol).convert(content);
      if (rows.isEmpty) {
        _showSnack(context, 'This CSV looks empty. Add at least one row.');
        return;
      }

      final header = rows.first;
      final normalizedHeader = header
          .map(_normalizeCell)
          .toList(growable: false);
      final expected = _headers
          .map((h) => h.toLowerCase())
          .toList(growable: false);
      final matchesExpected =
          normalizedHeader.length >= expected.length &&
          () {
            for (var i = 0; i < expected.length; i++) {
              if (normalizedHeader[i] != expected[i]) return false;
            }
            return true;
          }();
      if (!matchesExpected) {
        _showSnack(
          context,
          'Template mismatch. Download the template and try again.',
        );
        return;
      }

      final dataRows = rows
          .skip(1)
          .where((row) => row.isNotEmpty)
          .toList(growable: false);

      if (dataRows.isEmpty) {
        _showSnack(context, 'Add at least one log row before importing.');
        return;
      }

      final parsed = <ExpenseLog>[];
      for (var i = 0; i < dataRows.length; i++) {
        final row = dataRows[i];
        if (row.every((cell) => _normalizeCell(cell).isEmpty)) continue;

        final padded = List<dynamic>.from(row);
        while (padded.length < _headers.length) {
          padded.add('');
        }

        ExpenseLogModel model;
        try {
          model = ExpenseLogModel.fromCsvRow(padded);
        } catch (_) {
          // Skip invalid rows (e.g., bad date format) but keep importing others.
          continue;
        }
        final entity = model.toEntity();

        final id =
            entity.id.trim().isEmpty
                ? '${DateTime.now().microsecondsSinceEpoch + i}'
                : entity.id.trim();

        final createdAt = entity.createdAt;
        final timeLabel =
            entity.timeLabel.trim().isEmpty
                ? DateFormat('HH:mm').format(createdAt.toLocal())
                : entity.timeLabel.trim();

        final category =
            entity.category.trim().isEmpty
                ? model.title.trim()
                : entity.category.trim();

        parsed.add(
          ExpenseLog(
            id: id,
            timeLabel: timeLabel,
            category: category,
            amount: entity.amount,
            createdAt: createdAt,
          ),
        );
      }

      if (parsed.isEmpty) {
        _showSnack(context, 'No valid rows found to import.');
        return;
      }

      final shouldOverwrite = await showDialog<bool>(
        context: context,
        barrierDismissible: true,
        builder: (dialogContext) {
          return OutlinedConfirmationDialog(
            title: 'Replace your logs?',
            description:
                'Importing replaces every log on this device. Export your logs first if you want a backup.',
            primaryLabel: 'Replace my logs',
            onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
            secondaryLabel: 'Keep my data',
            onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
          );
        },
      );
      if (!context.mounted) return;

      if (shouldOverwrite != true) return;
      if (!context.mounted) return;

      final service = ref.read(expenseLogServiceProvider);
      await service.setExpenseLogs(parsed);

      ref.invalidate(expenseLogsProvider);
      await ref.read(expenseLogsProvider.future);

      if (!context.mounted) return;
      _showSnack(context, 'Import complete. Your logs are ready.');
    } catch (_) {
      if (!context.mounted) return;
      _showSnack(context, "Couldn't import that file. Please try again.");
    }
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({required this.onBackPressed});

  final VoidCallback onBackPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBackPressed,
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          tooltip: 'Back',
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Import & export',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Save your logs as a CSV, or import a CSV to restore them on this device.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BodySection extends StatelessWidget {
  const _BodySection({
    required this.isIOS,
    required this.onDownloadTemplate,
    required this.onExport,
    required this.onImport,
  });

  final bool isIOS;
  final Future<void> Function() onDownloadTemplate;
  final Future<void> Function() onExport;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ActionCard(
          title: 'Download Template',
          description: 'Get a ready-to-fill CSV with the right columns.',
          onTap: onDownloadTemplate,
        ),
        Divider(color: Colors.grey[300], thickness: 1),
        _ActionCard(
          title: 'Export My Logs',
          description: 'Create a CSV file of all logs on this device.',
          onTap: onExport,
        ),
        Divider(color: Colors.grey[300], thickness: 1),
        _ActionCard(
          title: 'Import From CSV',
          description:
              isIOS
                  ? 'Import a CSV and replace your current logs.'
                  : 'iOS support is ready. Android is coming soon.',
          onTap: onImport,
        ),
      ],
    );
  }
}

class _ActionCard extends StatefulWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.onTap,
  });

  final String title;
  final String description;
  final Future<void> Function() onTap;

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  var _isBusy = false;

  Future<void> _handleTap() async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await widget.onTap();
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child:
                _isBusy
                    ? const CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    )
                    : const Icon(
                      Icons.swap_horiz,
                      color: Colors.black,
                      size: 22,
                    ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.description,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).onTap(behavior: HitTestBehavior.opaque, onTap: _handleTap);
  }
}
