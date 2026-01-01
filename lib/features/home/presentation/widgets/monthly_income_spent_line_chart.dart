import 'dart:math';

import 'package:anti/core/utils/date_time_formatter.dart';
import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class MonthlyIncomeSpentLineChart extends StatelessWidget {
  const MonthlyIncomeSpentLineChart({
    super.key,
    required this.selectedMonth,
    required this.logs,
  });

  final DateTime selectedMonth;
  final List<ExpenseLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return OutlinedSurface(
        padding: const EdgeInsets.all(16),
        child: const _EmptyChart(),
      );
    }

    final daysInMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
      0,
    ).day;

    final (incomeByDay, spentByDay) = _aggregateDailyTotals(
      logs: logs,
      daysInMonth: daysInMonth,
    );

    final incomeSpots = _toSpots(incomeByDay);
    final spentSpots = _toSpots(spentByDay);

    final maxIncome = incomeByDay.fold<double>(0, max);
    final maxSpent = spentByDay.fold<double>(0, max);
    final rawMaxY = max(maxIncome, maxSpent);
    final maxY = rawMaxY <= 0 ? 1.0 : rawMaxY * 1.15;

    return OutlinedSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Header(),
          const SizedBox(height: 12),
          _Legend(),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: LineChart(
              _buildChartData(
                incomeSpots: incomeSpots,
                spentSpots: spentSpots,
                daysInMonth: daysInMonth,
                maxY: maxY,
              ),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }

  (List<double> incomeByDay, List<double> spentByDay) _aggregateDailyTotals({
    required List<ExpenseLog> logs,
    required int daysInMonth,
  }) {
    final income = List<double>.filled(daysInMonth, 0);
    final spent = List<double>.filled(daysInMonth, 0);

    for (final log in logs) {
      final dayIndex = log.createdAt.day - 1;
      if (dayIndex < 0 || dayIndex >= daysInMonth) continue;

      final amount = log.amount;
      if (amount > 0) {
        income[dayIndex] += amount;
      } else if (amount < 0) {
        spent[dayIndex] += -amount; // plot spent as positive
      }
    }

    return (income, spent);
  }

  List<FlSpot> _toSpots(List<double> values) {
    return List.generate(values.length, (i) => FlSpot(i + 1.0, values[i]));
  }

  LineChartData _buildChartData({
    required List<FlSpot> incomeSpots,
    required List<FlSpot> spentSpots,
    required int daysInMonth,
    required double maxY,
  }) {
    final incomeColor = Colors.green[700] ?? Colors.green;
    final spentColor = Colors.red[700] ?? Colors.red;

    return LineChartData(
      minX: 1,
      maxX: daysInMonth.toDouble(),
      minY: 0,
      maxY: maxY,
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY <= 0 ? 1 : maxY / 4,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.withValues(alpha: 0.25),
            strokeWidth: 1,
            dashArray: const [6, 6],
          );
        },
      ),
      borderData: FlBorderData(show: false),
      lineTouchData: LineTouchData(
        enabled: true,
        touchSpotThreshold: 24,
        handleBuiltInTouches: true,
        getTouchedSpotIndicator: (barData, spotIndexes) {
          return spotIndexes.map((_) {
            return TouchedSpotIndicatorData(
              FlLine(color: Colors.black.withValues(alpha: 0.15), strokeWidth: 2),
              FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: bar.color ?? Colors.black,
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  );
                },
              ),
            );
          }).toList(growable: false);
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipBorderRadius: const BorderRadius.all(Radius.circular(12)),
          tooltipPadding: const EdgeInsets.all(12),
          tooltipMargin: 12,
          getTooltipColor: (_) => Colors.white,
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return const [];

            final day = touchedSpots.first.x.toInt();
            final date = DateTime(selectedMonth.year, selectedMonth.month, day);
            final dateLabel = formatDateLabel(date);

            return touchedSpots.map((spot) {
              final isIncome = spot.bar.color == incomeColor;
              final seriesLabel = isIncome ? 'Income' : 'Spent';
              final valueLabel = formatNetBalance(spot.y);

              return LineTooltipItem(
                '$dateLabel\n$seriesLabel: $valueLabel',
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: Colors.black,
                ),
              );
            }).toList(growable: false);
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 26,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final day = value.toInt();
              final show =
                  day == 1 ||
                  day == 7 ||
                  day == 14 ||
                  day == 21 ||
                  day == 28 ||
                  day == daysInMonth;

              if (!show) return const SizedBox.shrink();

              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 52,
            interval: maxY <= 0 ? 1 : maxY / 4,
            getTitlesWidget: (value, meta) {
              return Text(
                _formatYAxis(value),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[700],
                ),
              );
            },
          ),
        ),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: incomeSpots,
          isCurved: true,
          color: incomeColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: incomeColor.withValues(alpha: 0.10),
          ),
        ),
        LineChartBarData(
          spots: spentSpots,
          isCurved: true,
          color: spentColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: spentColor.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  String _formatYAxis(double value) {
    if (value <= 0) return '฿0';
    if (value >= 1000000) {
      return '฿${formatAmountWithComma((value / 1000000).round())}m';
    }
    if (value >= 1000) {
      return '฿${formatAmountWithComma((value / 1000).round())}k';
    }
    return '฿${formatAmountWithComma(value.round())}';
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Monthly Trend',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.4,
        color: Colors.black,
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LegendDot(color: Colors.green[700] ?? Colors.green),
        const SizedBox(width: 6),
        Text(
          'Income',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 16),
        _LegendDot(color: Colors.red[700] ?? Colors.red),
        const SizedBox(width: 6),
        Text(
          'Spent',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Trend',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your first log to see your income and spending trend.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }
}


