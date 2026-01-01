class ScheduledTransaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime scheduledDate;
  final DateTime createdAt;

  const ScheduledTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.scheduledDate,
    required this.createdAt,
  });
}


