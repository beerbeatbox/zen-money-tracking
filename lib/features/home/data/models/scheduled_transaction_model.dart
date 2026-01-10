import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';

class ScheduledTransactionModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime scheduledDate;
  final DateTime createdAt;
  final String frequency;
  final bool isActive;
  final int remindDaysBefore;
  final int? intervalCount;
  final String? intervalUnit;

  const ScheduledTransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.scheduledDate,
    required this.createdAt,
    required this.frequency,
    required this.isActive,
    required this.remindDaysBefore,
    this.intervalCount,
    this.intervalUnit,
  });

  factory ScheduledTransactionModel.fromEntity(ScheduledTransaction entity) {
    return ScheduledTransactionModel(
      id: entity.id,
      title: entity.title,
      category: entity.category,
      amount: entity.amount,
      scheduledDate: entity.scheduledDate,
      createdAt: entity.createdAt,
      frequency: _frequencyToString(entity.frequency),
      isActive: entity.isActive,
      remindDaysBefore: entity.remindDaysBefore,
      intervalCount: entity.intervalCount,
      intervalUnit: entity.intervalUnit != null
          ? _intervalUnitToString(entity.intervalUnit!)
          : null,
    );
  }

  ScheduledTransaction toEntity() {
    final freq = _frequencyFromString(frequency);
    // Migrate legacy monthly/yearly to interval
    final (migratedFreq, migratedCount, migratedUnit) = _migrateLegacyFrequency(
      freq,
      intervalCount,
      intervalUnit,
    );

    return ScheduledTransaction(
      id: id,
      title: title,
      category: category,
      amount: amount,
      scheduledDate: scheduledDate,
      createdAt: createdAt,
      frequency: migratedFreq,
      isActive: isActive,
      remindDaysBefore: remindDaysBefore,
      intervalCount: migratedCount,
      intervalUnit: migratedUnit,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'scheduledDate': scheduledDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'frequency': frequency,
      'isActive': isActive,
      'remindDaysBefore': remindDaysBefore,
      if (intervalCount != null) 'intervalCount': intervalCount,
      if (intervalUnit != null) 'intervalUnit': intervalUnit,
    };
  }

  factory ScheduledTransactionModel.fromJson(Map<String, dynamic> json) {
    return ScheduledTransactionModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      scheduledDate: DateTime.parse(json['scheduledDate']?.toString() ?? ''),
      createdAt: DateTime.parse(json['createdAt']?.toString() ?? ''),
      frequency: json['frequency']?.toString() ?? 'oneTime',
      isActive: _parseBool(json['isActive'], fallback: true),
      remindDaysBefore: _parseInt(json['remindDaysBefore'], fallback: 0),
      intervalCount: _parseIntNullable(json['intervalCount']),
      intervalUnit: json['intervalUnit']?.toString(),
    );
  }
}

String _frequencyToString(PaymentFrequency frequency) {
  switch (frequency) {
    case PaymentFrequency.oneTime:
      return 'oneTime';
    case PaymentFrequency.monthly:
      return 'monthly';
    case PaymentFrequency.yearly:
      return 'yearly';
    case PaymentFrequency.interval:
      return 'interval';
  }
}

PaymentFrequency _frequencyFromString(String raw) {
  switch (raw) {
    case 'monthly':
      return PaymentFrequency.monthly;
    case 'yearly':
      return PaymentFrequency.yearly;
    case 'interval':
      return PaymentFrequency.interval;
    case 'oneTime':
    default:
      return PaymentFrequency.oneTime;
  }
}

(PaymentFrequency, int?, IntervalUnit?) _migrateLegacyFrequency(
  PaymentFrequency freq,
  int? existingCount,
  String? existingUnit,
) {
  // If already has interval data, use it
  if (freq == PaymentFrequency.interval &&
      existingCount != null &&
      existingUnit != null) {
    return (
      PaymentFrequency.interval,
      existingCount,
      _intervalUnitFromString(existingUnit),
    );
  }

  // Migrate legacy monthly/yearly to interval
  switch (freq) {
    case PaymentFrequency.monthly:
      return (
        PaymentFrequency.interval,
        1,
        IntervalUnit.months,
      );
    case PaymentFrequency.yearly:
      return (
        PaymentFrequency.interval,
        1,
        IntervalUnit.years,
      );
    case PaymentFrequency.interval:
      // Should have interval data, but fallback to monthly if missing
      return (
        PaymentFrequency.interval,
        existingCount ?? 1,
        existingUnit != null
            ? _intervalUnitFromString(existingUnit)
            : IntervalUnit.months,
      );
    case PaymentFrequency.oneTime:
      return (PaymentFrequency.oneTime, null, null);
  }
}

String _intervalUnitToString(IntervalUnit unit) {
  switch (unit) {
    case IntervalUnit.days:
      return 'days';
    case IntervalUnit.weeks:
      return 'weeks';
    case IntervalUnit.months:
      return 'months';
    case IntervalUnit.years:
      return 'years';
  }
}

IntervalUnit _intervalUnitFromString(String raw) {
  switch (raw) {
    case 'days':
      return IntervalUnit.days;
    case 'weeks':
      return IntervalUnit.weeks;
    case 'months':
      return IntervalUnit.months;
    case 'years':
      return IntervalUnit.years;
    default:
      return IntervalUnit.months;
  }
}

bool _parseBool(dynamic raw, {required bool fallback}) {
  if (raw is bool) return raw;
  final str = raw?.toString().toLowerCase();
  if (str == 'true') return true;
  if (str == 'false') return false;
  return fallback;
}

int? _parseIntNullable(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  return int.tryParse(raw.toString());
}

int _parseInt(dynamic raw, {required int fallback}) {
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '') ?? fallback;
}


