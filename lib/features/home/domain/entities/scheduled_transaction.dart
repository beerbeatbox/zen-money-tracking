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
  final int? intervalCount;
  final IntervalUnit? intervalUnit;
  final bool isDynamicAmount;
  final double? budgetAmount;

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
    this.intervalCount,
    this.intervalUnit,
    this.isDynamicAmount = false,
    this.budgetAmount,
  });

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
    int? intervalCount,
    IntervalUnit? intervalUnit,
    bool? isDynamicAmount,
    double? budgetAmount,
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
      intervalCount: intervalCount ?? this.intervalCount,
      intervalUnit: intervalUnit ?? this.intervalUnit,
      isDynamicAmount: isDynamicAmount ?? this.isDynamicAmount,
      budgetAmount: budgetAmount ?? this.budgetAmount,
    );
  }
}

enum PaymentFrequency { oneTime, monthly, yearly, interval }

enum IntervalUnit { days, weeks, months, years }
