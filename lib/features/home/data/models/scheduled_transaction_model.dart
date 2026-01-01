import 'package:anti/features/home/domain/entities/scheduled_transaction.dart';

class ScheduledTransactionModel {
  final String id;
  final String title;
  final String category;
  final double amount;
  final DateTime scheduledDate;
  final DateTime createdAt;

  const ScheduledTransactionModel({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.scheduledDate,
    required this.createdAt,
  });

  factory ScheduledTransactionModel.fromEntity(ScheduledTransaction entity) {
    return ScheduledTransactionModel(
      id: entity.id,
      title: entity.title,
      category: entity.category,
      amount: entity.amount,
      scheduledDate: entity.scheduledDate,
      createdAt: entity.createdAt,
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
    );
  }
}


