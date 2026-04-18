import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:flutter/foundation.dart';

@immutable
class DailyRecapData {
  const DailyRecapData({
    required this.date,
    required this.totalSpent,
    required this.totalIncome,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.transactionCount,
    required this.biggestExpense,
    required this.logs,
  });

  /// Calendar date this recap covers (local, date-only).
  final DateTime date;
  final double totalSpent;
  final double totalIncome;
  final String? topCategory;
  final double topCategoryAmount;
  final int transactionCount;
  final ExpenseLog? biggestExpense;
  final List<ExpenseLog> logs;

  bool get hasActivity => logs.isNotEmpty;
}
