import 'package:anti/features/home/domain/entities/expense_log.dart';

class ExpenseLogModel {
  final String id;
  final String title;
  final String timeLabel;
  final String category;
  final double amount;
  final DateTime createdAt;

  const ExpenseLogModel({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.category,
    required this.amount,
    required this.createdAt,
  });

  factory ExpenseLogModel.fromEntity(ExpenseLog entity) {
    return ExpenseLogModel(
      id: entity.id,
      title: entity.category,
      timeLabel: entity.timeLabel,
      category: entity.category,
      amount: entity.amount,
      createdAt: entity.createdAt,
    );
  }

  ExpenseLog toEntity() {
    return ExpenseLog(
      id: id,
      timeLabel: timeLabel,
      category: category.isEmpty ? title : category,
      amount: amount,
      createdAt: createdAt,
    );
  }

  List<dynamic> toCsvRow() {
    return [
      id,
      title,
      timeLabel,
      category,
      amount,
      createdAt.toIso8601String(),
    ];
  }

  factory ExpenseLogModel.fromCsvRow(List<dynamic> row) {
    return ExpenseLogModel(
      id: row[0].toString(),
      title: row[1].toString(),
      timeLabel: row[2].toString(),
      category: row[3].toString(),
      amount: double.tryParse(row[4].toString()) ?? 0,
      createdAt: DateTime.parse(row[5].toString()),
    );
  }
}
