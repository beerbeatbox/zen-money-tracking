class ScheduledTransaction {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime scheduledDate;
  final DateTime createdAt;
  final PaymentFrequency frequency;
  final bool isActive;
  final int remindDaysBefore;

  const ScheduledTransaction({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.scheduledDate,
    required this.createdAt,
    this.frequency = PaymentFrequency.oneTime,
    this.isActive = true,
    this.remindDaysBefore = 0,
  });

  bool get isSubscription => frequency != PaymentFrequency.oneTime;

  ScheduledTransaction copyWith({
    String? id,
    String? title,
    String? category,
    double? amount,
    DateTime? scheduledDate,
    DateTime? createdAt,
    PaymentFrequency? frequency,
    bool? isActive,
    int? remindDaysBefore,
  }) {
    return ScheduledTransaction(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      createdAt: createdAt ?? this.createdAt,
      frequency: frequency ?? this.frequency,
      isActive: isActive ?? this.isActive,
      remindDaysBefore: remindDaysBefore ?? this.remindDaysBefore,
    );
  }
}

enum PaymentFrequency { oneTime, monthly, yearly }


