import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/utils/formatters.dart';
import 'package:baht/features/home/domain/entities/expense_log.dart';

class WeeklyStreak extends ConsumerWidget {
  const WeeklyStreak({
    super.key,
    required this.logs,
    required this.dailyBudgetLimit,
    this.now,
  });

  final List<ExpenseLog> logs;
  final double dailyBudgetLimit;
  final DateTime? now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nowValue = now ?? DateTime.now();
    final today = DateUtils.dateOnly(nowValue);
    final isMasked = ref.watch(amountMaskControllerProvider);
    final monday = today.subtract(
      Duration(days: today.weekday - DateTime.monday),
    );
    final weekDates = List<DateTime>.generate(
      7,
      (i) => DateUtils.dateOnly(monday.add(Duration(days: i))),
    );
    final spentByDate = _spentByDate(logs);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Streak',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.black,
                ),
              ),
              Text(
                'Daily limit ${formatNetBalanceMasked(dailyBudgetLimit, isMasked: isMasked)}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(weekDates.length, (index) {
              final date = weekDates[index];
              final spent = spentByDate[date] ?? 0;
              final isToday = DateUtils.isSameDay(date, today);
              final isFuture = date.isAfter(today);
              final isPast = date.isBefore(today);
              final isUnderLimit = spent <= dailyBudgetLimit;

              return Expanded(
                child: Center(
                  child: _StreakDayItem(
                    weekdayLabel: _weekdayLabel(date),
                    isToday: isToday,
                    isFuture: isFuture,
                    isPast: isPast,
                    isUnderLimit: isUnderLimit,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Map<DateTime, double> _spentByDate(List<ExpenseLog> logs) {
    final map = <DateTime, double>{};

    for (final log in logs) {
      if (log.amount >= 0) continue;
      final dateKey = DateUtils.dateOnly(log.createdAt);
      final spent = log.amount.abs();
      map[dateKey] = (map[dateKey] ?? 0) + spent;
    }

    return map;
  }

  String _weekdayLabel(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'M';
      case DateTime.tuesday:
        return 'Tu';
      case DateTime.wednesday:
        return 'W';
      case DateTime.thursday:
        return 'Th';
      case DateTime.friday:
        return 'F';
      case DateTime.saturday:
        return 'Sa';
      case DateTime.sunday:
        return 'Su';
      default:
        return '';
    }
  }
}

class _StreakDayItem extends StatelessWidget {
  const _StreakDayItem({
    required this.weekdayLabel,
    required this.isToday,
    required this.isFuture,
    required this.isPast,
    required this.isUnderLimit,
  });

  final String weekdayLabel;
  final bool isToday;
  final bool isFuture;
  final bool isPast;
  final bool isUnderLimit;

  @override
  Widget build(BuildContext context) {
    final labelColor = Colors.grey[700];
    final circleSize = 24.0;

    final showCheck = isPast && isUnderLimit;
    final isIncomplete = !isUnderLimit && !isFuture; // today or past only
    final isComplete = isPast && isUnderLimit;
    final borderColor = isComplete ? Colors.black : Colors.grey[300]!;

    final fillColor = () {
      if (isIncomplete) return Colors.grey[300]!;
      if (isPast && isUnderLimit) return const Color(0xFFF4C44E);
      return Colors.grey[300]!;
    }();

    final icon =
        showCheck
            ? const Icon(Icons.check, size: 18, color: Colors.black)
            : null;

    return Column(
      children: [
        Text(
          weekdayLabel,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: circleSize,
              height: circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: fillColor,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: Center(child: icon ?? const SizedBox.shrink()),
            ),
          ],
        ),
      ],
    );
  }
}
