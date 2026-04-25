import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/presentation/controllers/weekly_recap_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
import 'package:anti/features/home/presentation/screens/weekly_recap_screen.dart';
import 'package:flutter/material.dart';
import 'package:anti/core/router/app_router.dart';
import 'package:go_router/go_router.dart';

class WeeklyRecapCard extends StatelessWidget {
  const WeeklyRecapCard({
    super.key,
    required this.summary,
  });

  final WeeklyRecapWeekSummary summary;

  @override
  Widget build(BuildContext context) {
    final amount = formatAmountWithComma(summary.totalSpent, decimalDigits: 2);
    final weekEnd = endOfLocalWeekSunday(summary.weekStart);
    final dateLabel = _formatWeekRangeLine(summary.weekStart, weekEnd);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap:
            () => context.push(
              '${AppRouter.weeklyRecap.path}?week=${formatWeeklyRecapQueryDate(summary.weekStart)}',
            ),
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          width: 220,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_stories_rounded, color: Colors.grey[800]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Weekly recap',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                dateLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Spent ฿$amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${summary.transactionCount} ${summary.transactionCount == 1 ? 'log' : 'logs'}',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatWeekRangeLine(DateTime weekStart, DateTime weekEnd) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final a = months[weekStart.month - 1];
  final b = months[weekEnd.month - 1];
  if (weekStart.month == weekEnd.month && weekStart.year == weekEnd.year) {
    return '$a ${weekStart.day}–${weekEnd.day}, ${weekStart.year}';
  }
  if (weekStart.year == weekEnd.year) {
    return '$a ${weekStart.day} – $b ${weekEnd.day}, ${weekStart.year}';
  }
  return '$a ${weekStart.day}, ${weekStart.year} – $b ${weekEnd.day}, ${weekEnd.year}';
}
