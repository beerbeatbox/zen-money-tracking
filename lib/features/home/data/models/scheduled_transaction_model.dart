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
    );
  }

  ScheduledTransaction toEntity() {
    return ScheduledTransaction(
      id: id,
      title: title,
      category: category,
      amount: amount,
      scheduledDate: scheduledDate,
      createdAt: createdAt,
      frequency: _frequencyFromString(frequency),
      isActive: isActive,
      remindDaysBefore: remindDaysBefore,
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
  }
}

PaymentFrequency _frequencyFromString(String raw) {
  switch (raw) {
    case 'monthly':
      return PaymentFrequency.monthly;
    case 'yearly':
      return PaymentFrequency.yearly;
    case 'oneTime':
    default:
      return PaymentFrequency.oneTime;
  }
}

bool _parseBool(dynamic raw, {required bool fallback}) {
  if (raw is bool) return raw;
  final str = raw?.toString().toLowerCase();
  if (str == 'true') return true;
  if (str == 'false') return false;
  return fallback;
}

int _parseInt(dynamic raw, {required int fallback}) {
  if (raw is int) return raw;
  return int.tryParse(raw?.toString() ?? '') ?? fallback;
}


