import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:flutter/foundation.dart';

@immutable
class WeeklyRecapData {
  const WeeklyRecapData({
    required this.weekStart,
    required this.weekEnd,
    required this.totalSpent,
    required this.totalIncome,
    required this.topCategory,
    required this.topCategoryAmount,
    required this.transactionCount,
    required this.biggestExpense,
    required this.logs,
  });

  /// Monday of the week (local, date-only).
  final DateTime weekStart;

  /// Sunday of the week (local, date-only).
  final DateTime weekEnd;
  final double totalSpent;
  final double totalIncome;
  final String? topCategory;
  final double topCategoryAmount;
  final int transactionCount;
  final ExpenseLog? biggestExpense;
  final List<ExpenseLog> logs;

  bool get hasActivity => logs.isNotEmpty;
}
