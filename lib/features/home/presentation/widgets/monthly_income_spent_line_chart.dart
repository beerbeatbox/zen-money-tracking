import 'dart:math';

import 'package:baht/core/controllers/amount_mask_controller.dart';
import 'package:baht/core/utils/date_time_formatter.dart';
import 'package:baht/core/utils/formatters.dart';
import 'package:baht/features/home/domain/entities/expense_log.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_doodle_divider.dart';
import 'package:baht/features/home/presentation/screens/dashboard/widgets/dashboard_section_header_styles.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonthlyIncomeSpentLineChart extends ConsumerStatefulWidget {
  const MonthlyIncomeSpentLineChart({
    super.key,
    required this.selectedMonth,
    required this.logs,
  });

  final DateTime selectedMonth;
  final List<ExpenseLog> logs;

  @override
  ConsumerState<MonthlyIncomeSpentLineChart> createState() =>
      _MonthlyIncomeSpentLineChartState();
}

class _MonthlyIncomeSpentLineChartState
    extends ConsumerState<MonthlyIncomeSpentLineChart> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(MonthlyIncomeSpentLineChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Check if the month changed
    if (oldWidget.selectedMonth.year != widget.selectedMonth.year ||
        oldWidget.selectedMonth.month != widget.selectedMonth.month) {
      // Scroll to current date when month changes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentDate();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentDate() {
    if (!_scrollController.hasClients) return;

    final now = DateTime.now();
    final selectedMonth = widget.selectedMonth;

    // Determine the current day to show
    int currentDay;
    if (selectedMonth.year == now.year && selectedMonth.month == now.month) {
      // Viewing current month - show today's date
      currentDay = now.day;
    } else {
      // Viewing past/future month - show the last day of that month
      final daysInMonth =
          DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
      currentDay = daysInMonth;
    }

    // Calculate scroll position
    // Each day is 40 pixels wide
    const dayWidth = 40.0;
    final targetPosition = (currentDay - 1) * dayWidth;

    // Get viewport width to ensure we don't scroll past the end
    final maxScroll = _scrollController.position.maxScrollExtent;
    final viewportWidth = _scrollController.position.viewportDimension;

    // Calculate scroll offset to center the current date in the viewport
    // Center of the current day: targetPosition + (dayWidth / 2)
    // To center it: scroll to center of day minus half viewport width
    final centerOfDay = targetPosition + (dayWidth / 2);
    final scrollOffset = (centerOfDay - (viewportWidth / 2)).clamp(
      0.0,
      maxScroll,
    );

    // Use jumpTo for immediate positioning
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(scrollOffset);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMasked = ref.watch(amountMaskControllerProvider);
    if (widget.logs.isEmpty) {
      return const _EmptyChart();
    }

    final daysInMonth =
        DateTime(
          widget.selectedMonth.year,
          widget.selectedMonth.month + 1,
          0,
        ).day;

    final (incomeByDay, spentByDay) = _aggregateDailyTotals(
      logs: widget.logs,
      daysInMonth: daysInMonth,
    );

    final incomeSpots = _toSpots(incomeByDay);
    final spentSpots = _toSpots(spentByDay);

    final maxIncome = incomeByDay.fold<double>(0, max);
    final maxSpent = spentByDay.fold<double>(0, max);
    final rawMaxY = max(maxIncome, maxSpent);
    final maxY = rawMaxY <= 0 ? 1.0 : rawMaxY * 1.15;

    // Auto-scroll to current date after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentDate();
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _Header(),
        const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: daysInMonth * 40.0,
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Stack(
                    children: [
                      LineChart(
                        _buildChartData(
                          incomeSpots: incomeSpots,
                          spentSpots: spentSpots,
                          daysInMonth: daysInMonth,
                          maxY: maxY,
                          incomeByDay: incomeByDay,
                          spentByDay: spentByDay,
                          isMasked: isMasked,
                        ),
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.linear,
                      ),
                      _DataIndicators(
                        incomeByDay: incomeByDay,
                        spentByDay: spentByDay,
                        daysInMonth: daysInMonth,
                        maxY: maxY,
                        incomeColor: const Color(0xFF1A5C52),
                        spentColor: const Color(0xFFE05C4B),
                        isMasked: isMasked,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _Legend(),
        ],
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
    required List<double> incomeByDay,
    required List<double> spentByDay,
    required bool isMasked,
  }) {
    const incomeColor = Color(0xFF1A5C52);
    const spentColor = Color(0xFFE05C4B);

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
          return spotIndexes
              .map((_) {
                return TouchedSpotIndicatorData(
                  FlLine(
                    color: Colors.black.withValues(alpha: 0.15),
                    strokeWidth: 2,
                  ),
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
              })
              .toList(growable: false);
        },
        touchTooltipData: LineTouchTooltipData(
          tooltipBorderRadius: const BorderRadius.all(Radius.circular(12)),
          tooltipPadding: const EdgeInsets.all(12),
          tooltipMargin: 12,
          getTooltipColor: (_) => Colors.white,
          getTooltipItems: (touchedSpots) {
            if (touchedSpots.isEmpty) return const [];

            final day = touchedSpots.first.x.toInt();
            final date = DateTime(
              widget.selectedMonth.year,
              widget.selectedMonth.month,
              day,
            );
            final dateLabel = formatDateLabel(date);

            return touchedSpots
                .map((spot) {
                  final isIncome = spot.bar.color == incomeColor;
                  final seriesLabel = isIncome ? 'Income' : 'Spent';
                  final valueLabel = formatCurrencyUnsignedMasked(
                    spot.y,
                    isMasked: isMasked,
                  );

                  return LineTooltipItem(
                    '$dateLabel\n$seriesLabel: $valueLabel',
                    const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                      color: Colors.black,
                    ),
                  );
                })
                .toList(growable: false);
          },
        ),
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final day = value.toInt();
              if (day < 1 || day > daysInMonth) {
                return const SizedBox.shrink();
              }

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
              // Skip the topmost label if it's at maxY to prevent clipping
              if (value == maxY && meta.max == maxY) {
                return const SizedBox.shrink();
              }
              return Text(
                _formatYAxis(value, isMasked: isMasked),
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
          isCurved: false,
          color: incomeColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: incomeColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: incomeColor.withValues(alpha: 0.10),
          ),
        ),
        LineChartBarData(
          spots: spentSpots,
          isCurved: false,
          color: spentColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, bar, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: spentColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: spentColor.withValues(alpha: 0.08),
          ),
        ),
      ],
    );
  }

  String _formatYAxis(double value, {required bool isMasked}) {
    if (isMasked) return '฿*****';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Monthly Trend',
          style: DashboardSectionHeaderStyles.titleStyle(
            color: const Color(0xFF1A5C52),
          ),
        ),
        const SizedBox(height: 4),
        const DashboardDoodleDivider.zigzag(color: Colors.black38),
      ],
    );
  }
}

class _Legend extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _LegendDot(color: Color(0xFF1A5C52)),
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
        const _LegendDot(color: Color(0xFFE05C4B)),
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
        Text(
          'Monthly Trend',
          style: DashboardSectionHeaderStyles.titleStyle(
            color: const Color(0xFF1A5C52),
          ),
        ),
        const SizedBox(height: 4),
        const DashboardDoodleDivider.zigzag(color: Colors.black38),
        const SizedBox(height: DashboardSectionHeaderStyles.spacingBelowTitle),
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

class _DataIndicators extends StatelessWidget {
  const _DataIndicators({
    required this.incomeByDay,
    required this.spentByDay,
    required this.daysInMonth,
    required this.maxY,
    required this.incomeColor,
    required this.spentColor,
    required this.isMasked,
  });

  final List<double> incomeByDay;
  final List<double> spentByDay;
  final int daysInMonth;
  final double maxY;
  final Color incomeColor;
  final Color spentColor;
  final bool isMasked;

  @override
  Widget build(BuildContext context) {
    // Chart dimensions (approximate, adjusted for padding and margins)
    const chartHeight = 200.0 - 8.0; // minus top padding
    const chartWidth = 40.0; // per day
    const leftPadding = 52.0; // reservedSize for left titles
    const bottomPadding = 50.0; // reservedSize for bottom titles
    const topPadding = 8.0;

    final effectiveChartHeight = chartHeight - bottomPadding - topPadding;
    final effectiveChartWidth = daysInMonth * chartWidth;

    return CustomPaint(
      size: Size(effectiveChartWidth, chartHeight),
      painter: _DataIndicatorPainter(
        incomeByDay: incomeByDay,
        spentByDay: spentByDay,
        daysInMonth: daysInMonth,
        maxY: maxY,
        incomeColor: incomeColor,
        spentColor: spentColor,
        chartHeight: effectiveChartHeight,
        chartWidth: effectiveChartWidth,
        leftPadding: leftPadding,
        bottomPadding: bottomPadding,
        topPadding: topPadding,
        isMasked: isMasked,
      ),
    );
  }
}

class _DataIndicatorPainter extends CustomPainter {
  _DataIndicatorPainter({
    required this.incomeByDay,
    required this.spentByDay,
    required this.daysInMonth,
    required this.maxY,
    required this.incomeColor,
    required this.spentColor,
    required this.chartHeight,
    required this.chartWidth,
    required this.leftPadding,
    required this.bottomPadding,
    required this.topPadding,
    required this.isMasked,
  });

  final List<double> incomeByDay;
  final List<double> spentByDay;
  final int daysInMonth;
  final double maxY;
  final Color incomeColor;
  final Color spentColor;
  final double chartHeight;
  final double chartWidth;
  final double leftPadding;
  final double bottomPadding;
  final double topPadding;
  final bool isMasked;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int day = 0; day < daysInMonth; day++) {
      final x =
          leftPadding +
          (day + 1) * (chartWidth / daysInMonth) -
          (chartWidth / daysInMonth / 2);

      // Draw income indicator
      if (day < incomeByDay.length && incomeByDay[day] > 0) {
        final incomeY =
            topPadding + chartHeight - (incomeByDay[day] / maxY) * chartHeight;
        final labelY = incomeY + 6; // Position below dot

        if (labelY < topPadding + chartHeight) {
          final label = _formatValue(incomeByDay[day]);
          textPainter.text = TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: incomeColor,
            ),
          );
          textPainter.layout();

          // Draw background
          final padding = 4.0;
          final backgroundRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x - textPainter.width / 2 - padding,
              labelY - padding,
              textPainter.width + padding * 2,
              textPainter.height + padding * 2,
            ),
            const Radius.circular(4),
          );
          final backgroundPaint =
              Paint()
                ..color = Colors.white.withValues(alpha: 0.9)
                ..style = PaintingStyle.fill;
          canvas.drawRRect(backgroundRect, backgroundPaint);

          // Draw border
          final borderPaint =
              Paint()
                ..color = incomeColor.withValues(alpha: 0.3)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1;
          canvas.drawRRect(backgroundRect, borderPaint);

          textPainter.paint(canvas, Offset(x - textPainter.width / 2, labelY));
        }
      }

      // Draw spent indicator
      if (day < spentByDay.length && spentByDay[day] > 0) {
        final spentY =
            topPadding + chartHeight - (spentByDay[day] / maxY) * chartHeight;
        final labelY = spentY; // Position below dot

        if (labelY < topPadding + chartHeight) {
          final label = _formatValue(spentByDay[day]);
          textPainter.text = TextSpan(
            text: label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: spentColor,
            ),
          );
          textPainter.layout();

          // Draw background
          final padding = 4.0;
          final backgroundRect = RRect.fromRectAndRadius(
            Rect.fromLTWH(
              x - textPainter.width / 2 - padding,
              labelY - padding,
              textPainter.width + padding * 2,
              textPainter.height + padding * 2,
            ),
            const Radius.circular(4),
          );
          final backgroundPaint =
              Paint()
                ..color = Colors.white.withValues(alpha: 0.9)
                ..style = PaintingStyle.fill;
          canvas.drawRRect(backgroundRect, backgroundPaint);

          // Draw border
          final borderPaint =
              Paint()
                ..color = spentColor.withValues(alpha: 0.3)
                ..style = PaintingStyle.stroke
                ..strokeWidth = 1;
          canvas.drawRRect(backgroundRect, borderPaint);

          textPainter.paint(canvas, Offset(x - textPainter.width / 2, labelY));
        }
      }
    }
  }

  String _formatValue(double value) {
    if (isMasked) return '฿*****';
    if (value <= 0) return '฿0';
    if (value >= 1000000) {
      return '฿${formatAmountWithComma((value / 1000000).round())}m';
    }
    if (value >= 1000) {
      return '฿${formatAmountWithComma((value / 1000).round())}k';
    }
    return '฿${formatAmountWithComma(value.round())}';
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
