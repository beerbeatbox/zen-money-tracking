import 'package:flutter/foundation.dart';

@immutable
class BalanceSnapshot {
  const BalanceSnapshot({
    required this.id,
    required this.amount,
    required this.effectiveAt,
    this.note,
  });

  final String id;
  final double amount;
  final DateTime effectiveAt;
  final String? note;
}
