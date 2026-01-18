import 'dart:math';

import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/categories/domain/entities/category.dart';
import 'package:anti/features/categories/domain/usecases/category_service.dart';
import 'package:anti/features/categories/presentation/controllers/categories_controller.dart';
import 'package:anti/features/categories/presentation/widgets/category_name_with_emoji.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MonthlyCategoryLineChart extends ConsumerStatefulWidget {
  const MonthlyCategoryLineChart({
    super.key,
    required this.selectedMonth,
    required this.logs,
  });

  final DateTime selectedMonth;
  final List<ExpenseLog> logs;

  @override
  ConsumerState<MonthlyCategoryLineChart> createState() =>
      _MonthlyCategoryLineChartState();
}

class _MonthlyCategoryLineChartState
    extends ConsumerState<MonthlyCategoryLineChart> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void didUpdateWidget(MonthlyCategoryLineChart oldWidget) {
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
    final categoriesAsync = ref.watch(categoriesControllerProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (widget.logs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const _EmptyChart(),
          );
        }

        final daysInMonth =
            DateTime(
              widget.selectedMonth.year,
              widget.selectedMonth.month + 1,
              0,
            ).day;

        final categoryData = _aggregateByCategoryAndDay(
          logs: widget.logs,
          daysInMonth: daysInMonth,
          categories: categories,
        );

        if (categoryData.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const _EmptyChart(),
          );
        }

        final categoryNames = categoryData.keys.toList()..sort();
        final colorMap = _generateCategoryColors(categoryNames);

        // Calculate max Y value across all categories
        double rawMaxY = 0;
        for (final dailyTotals in categoryData.values) {
          final maxForCategory = dailyTotals.fold<double>(0, max);
          if (maxForCategory > rawMaxY) {
            rawMaxY = maxForCategory;
          }
        }
        final maxY = rawMaxY <= 0 ? 1.0 : rawMaxY * 1.15;

        // Auto-scroll to current date after the widget is built
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToCurrentDate();
        });

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
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
                              categoryData: categoryData,
                              categoryNames: categoryNames,
                              colorMap: colorMap,
                              daysInMonth: daysInMonth,
                              maxY: maxY,
                              categories: categories,
                            ),
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.linear,
                          ),
                          _CategoryEmojiOverlay(
                            categoryData: categoryData,
                            categoryNames: categoryNames,
                            daysInMonth: daysInMonth,
                            maxY: maxY,
                            categories: categories,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _Legend(
                categoryNames: categoryNames,
                colorMap: colorMap,
                categories: categories,
              ),
            ],
          ),
        );
      },
      loading:
          () => const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: CircularProgressIndicator(color: Colors.black),
            ),
          ),
      error: (_, __) => const _EmptyChart(),
    );
  }

  String _extractMainCategory(String categoryLabel) {
    final parts = categoryLabel.split(CategoryService.labelSeparator);
    return parts.first.trim();
  }

  Map<String, List<double>> _aggregateByCategoryAndDay({
    required List<ExpenseLog> logs,
    required int daysInMonth,
    required List<Category> categories,
  }) {
    final categoryData = <String, List<double>>{};

    for (final log in logs) {
      final dayIndex = log.createdAt.day - 1;
      if (dayIndex < 0 || dayIndex >= daysInMonth) continue;

      final mainCategory = _extractMainCategory(log.category);
      if (mainCategory.isEmpty) continue;

      // Initialize the list for this category if it doesn't exist
      categoryData.putIfAbsent(
        mainCategory,
        () => List<double>.filled(daysInMonth, 0),
      );

      // Add the absolute amount to the category's daily total
      final amount = log.amount.abs();
      categoryData[mainCategory]![dayIndex] += amount;
    }

    // Remove categories with no data
    categoryData.removeWhere(
      (_, dailyTotals) => dailyTotals.every((value) => value == 0),
    );

    return categoryData;
  }

  Map<String, Color> _generateCategoryColors(List<String> categoryNames) {
    final colorMap = <String, Color>{};
    if (categoryNames.isEmpty) return colorMap;

    // Use a color palette with good contrast
    // Using HSL color space with varying hues
    final baseColors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.indigo,
      Colors.amber,
      Colors.cyan,
      Colors.deepOrange,
      Colors.lime,
      Colors.brown,
    ];

    for (var i = 0; i < categoryNames.length; i++) {
      final categoryName = categoryNames[i];
      if (i < baseColors.length) {
        colorMap[categoryName] = baseColors[i];
      } else {
        // Generate colors using HSL for additional categories
        final hue = (i * 137.508) % 360; // Golden angle approximation
        colorMap[categoryName] =
            HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
      }
    }

    return colorMap;
  }

  List<FlSpot> _toSpots(List<double> values) {
    return List.generate(values.length, (i) => FlSpot(i + 1.0, values[i]));
  }

  LineChartData _buildChartData({
    required Map<String, List<double>> categoryData,
    required List<String> categoryNames,
    required Map<String, Color> colorMap,
    required int daysInMonth,
    required double maxY,
    required List<Category> categories,
  }) {
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
      lineTouchData: LineTouchData(enabled: false),
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
      lineBarsData:
          categoryNames.map((categoryName) {
            final dailyTotals = categoryData[categoryName]!;
            final spots = _toSpots(dailyTotals);
            final color = colorMap[categoryName]!;

            return LineChartBarData(
              spots: spots,
              isCurved: false,
              color: color,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: color.withValues(alpha: 0.10),
              ),
            );
          }).toList(),
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
      'Monthly Category Trend',
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
  const _Legend({
    required this.categoryNames,
    required this.colorMap,
    required this.categories,
  });

  final List<String> categoryNames;
  final Map<String, Color> colorMap;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    if (categoryNames.isEmpty) {
      return const SizedBox.shrink();
    }

    // Find category entities for emoji lookup
    final categoryMap = <String, Category?>{};
    for (final categoryName in categoryNames) {
      Category? category;
      try {
        category = categories.firstWhere(
          (c) =>
              c.parentId == null &&
              c.label.trim().toLowerCase() == categoryName.toLowerCase(),
        );
      } catch (_) {
        try {
          category = categories.firstWhere(
            (c) => c.label.trim().toLowerCase() == categoryName.toLowerCase(),
          );
        } catch (_) {
          category = null;
        }
      }
      categoryMap[categoryName] = category;
    }

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children:
          categoryNames.map((categoryName) {
            final color = colorMap[categoryName]!;
            final category = categoryMap[categoryName];
            final emoji = category?.emoji;

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _LegendDot(color: color),
                const SizedBox(width: 6),
                CategoryNameWithEmoji(
                  label: categoryName,
                  emoji: emoji,
                  textStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            );
          }).toList(),
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

class _CategoryEmojiOverlay extends StatelessWidget {
  const _CategoryEmojiOverlay({
    required this.categoryData,
    required this.categoryNames,
    required this.daysInMonth,
    required this.maxY,
    required this.categories,
  });

  final Map<String, List<double>> categoryData;
  final List<String> categoryNames;
  final int daysInMonth;
  final double maxY;
  final List<Category> categories;

  @override
  Widget build(BuildContext context) {
    // Chart dimensions (approximate, adjusted for padding and margins)
    const chartHeight = 200.0 - 8.0; // minus top padding
    const chartWidth = 40.0; // per day
    const leftPadding = 32.0; // reservedSize for left titles
    const bottomPadding = 64.0; // reservedSize for bottom titles
    const topPadding = 8.0;

    final effectiveChartHeight = chartHeight - bottomPadding - topPadding;
    final effectiveChartWidth = daysInMonth * chartWidth;

    // Build category emoji map
    final categoryEmojiMap = <String, String?>{};
    for (final categoryName in categoryNames) {
      Category? category;
      try {
        category = categories.firstWhere(
          (c) =>
              c.parentId == null &&
              c.label.trim().toLowerCase() == categoryName.toLowerCase(),
        );
      } catch (_) {
        try {
          category = categories.firstWhere(
            (c) => c.label.trim().toLowerCase() == categoryName.toLowerCase(),
          );
        } catch (_) {
          category = null;
        }
      }
      final emoji = category?.emoji?.trim();
      categoryEmojiMap[categoryName] = emoji?.isNotEmpty == true ? emoji : null;
    }

    return CustomPaint(
      size: Size(effectiveChartWidth, chartHeight),
      painter: _CategoryEmojiPainter(
        categoryData: categoryData,
        categoryNames: categoryNames,
        categoryEmojiMap: categoryEmojiMap,
        daysInMonth: daysInMonth,
        maxY: maxY,
        chartHeight: effectiveChartHeight,
        chartWidth: effectiveChartWidth,
        leftPadding: leftPadding,
        bottomPadding: bottomPadding,
        topPadding: topPadding,
      ),
    );
  }
}

class _CategoryEmojiPainter extends CustomPainter {
  _CategoryEmojiPainter({
    required this.categoryData,
    required this.categoryNames,
    required this.categoryEmojiMap,
    required this.daysInMonth,
    required this.maxY,
    required this.chartHeight,
    required this.chartWidth,
    required this.leftPadding,
    required this.bottomPadding,
    required this.topPadding,
  });

  final Map<String, List<double>> categoryData;
  final List<String> categoryNames;
  final Map<String, String?> categoryEmojiMap;
  final int daysInMonth;
  final double maxY;
  final double chartHeight;
  final double chartWidth;
  final double leftPadding;
  final double bottomPadding;
  final double topPadding;

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

      // Draw emoji for each category that has data on this day
      for (final categoryName in categoryNames) {
        final dailyTotals = categoryData[categoryName]!;
        if (day >= dailyTotals.length) continue;

        final value = dailyTotals[day];
        if (value <= 0) continue;

        final emoji = categoryEmojiMap[categoryName];
        if (emoji == null) continue;

        // Calculate Y position based on value (same as dot position)
        final dotY = topPadding + chartHeight - (value / maxY) * chartHeight;

        // Draw emoji at the dot position
        textPainter.text = TextSpan(
          text: emoji,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
        );
        textPainter.layout();

        textPainter.paint(
          canvas,
          Offset(x - textPainter.width / 2, dotY - textPainter.height / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Monthly Category Trend',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add your first log to see your category spending trends.',
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
