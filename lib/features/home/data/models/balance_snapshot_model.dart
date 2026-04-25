import 'package:anti/features/home/domain/entities/balance_snapshot.dart';

class BalanceSnapshotModel {
  const BalanceSnapshotModel({
    required this.id,
    required this.amount,
    required this.effectiveAt,
    this.note,
  });

  final String id;
  final double amount;
  final DateTime effectiveAt;
  final String? note;

  factory BalanceSnapshotModel.fromEntity(BalanceSnapshot entity) {
    return BalanceSnapshotModel(
      id: entity.id,
      amount: entity.amount,
      effectiveAt: entity.effectiveAt,
      note: entity.note,
    );
  }

  BalanceSnapshot toEntity() {
    return BalanceSnapshot(
      id: id,
      amount: amount,
      effectiveAt: effectiveAt,
      note: note,
    );
  }

  factory BalanceSnapshotModel.fromJson(Map<String, dynamic> json) {
    final effectiveRaw = json['effectiveAt'];
    return BalanceSnapshotModel(
      id: json['id'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      effectiveAt: effectiveRaw is String
          ? DateTime.parse(effectiveRaw)
          : DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'amount': amount,
        'effectiveAt': effectiveAt.toIso8601String(),
        if (note != null) 'note': note,
      };
}
