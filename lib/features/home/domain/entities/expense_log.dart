class ExpenseLog {
  final String id;
  final String title;
  final String timeLabel;
  final String category;
  final double amount;
  final DateTime createdAt;

  const ExpenseLog({
    required this.id,
    required this.title,
    required this.timeLabel,
    required this.category,
    required this.amount,
    required this.createdAt,
  });
}
