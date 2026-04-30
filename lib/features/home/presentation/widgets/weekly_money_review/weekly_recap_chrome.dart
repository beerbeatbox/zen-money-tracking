import 'dart:math' as math;

import 'package:baht/features/home/domain/entities/weekly_recap_data.dart';
import 'package:flutter/material.dart';

/// Shared ink, motion, and slide chrome for Weekly Money Review.
const Color kWeeklyRecapInk = Color(0xFF0A0A0A);

const double kRecapKickerLetterSpacing = 2.5;

const Duration kRecapRevealDuration = Duration(milliseconds: 450);

TextStyle recapKickerStyle({double alpha = 0.55}) => TextStyle(
  color: kWeeklyRecapInk.withValues(alpha: alpha),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: kRecapKickerLetterSpacing,
  height: 1.2,
);

String formatWeekRangeKicker(DateTime weekStart, DateTime weekEnd) {
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

const List<Color> kWeeklyReviewPalette = <Color>[
  Color(0xFFFFFFFF),
  Color(0xFFFAFAFA),
  Color(0xFFF5F5F5),
  Color(0xFFF0F0F0),
  Color(0xFFFAFAFA),
  Color(0xFFFCFCFC),
  Color(0xFFFFFFFF),
  Color(0xFFFAFAFA),
];

List<Color> weeklyReviewSlideBackgrounds({
  required int slideCount,
  required bool hasActivity,
}) {
  if (!hasActivity) {
    return List<Color>.filled(
      slideCount,
      const Color(0xFFF3F3F3),
    );
  }
  if (kWeeklyReviewPalette.length >= slideCount) {
    return kWeeklyReviewPalette.sublist(0, slideCount);
  }
  return List<Color>.generate(
    slideCount,
    (i) => kWeeklyReviewPalette[i % kWeeklyReviewPalette.length],
  );
}

/// Fade + translate-up; replays when [isActive] becomes true.
class RecapReveal extends StatefulWidget {
  const RecapReveal({
    super.key,
    required this.child,
    required this.isActive,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool isActive;
  final Duration delay;

  @override
  State<RecapReveal> createState() => _RecapRevealState();
}

class _RecapRevealState extends State<RecapReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: kRecapRevealDuration,
    );
    if (widget.isActive) {
      _scheduleForward();
    }
  }

  void _scheduleForward() {
    Future<void>.delayed(widget.delay, () {
      if (!mounted) return;
      if (widget.isActive) {
        _controller.forward(from: 0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant RecapReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _scheduleForward();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = Curves.easeOutCubic.transform(_controller.value);
        return Opacity(
          opacity: v,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - v)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class StoryProgressBar extends StatelessWidget {
  const StoryProgressBar({
    super.key,
    required this.segmentCount,
    required this.activeIndex,
  });

  final int segmentCount;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(segmentCount, (i) {
        final fill = i <= activeIndex ? 1.0 : 0.0;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < segmentCount - 1 ? 4 : 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth * fill;
                  return Stack(
                    children: [
                      Container(
                        height: 3,
                        width: constraints.maxWidth,
                        color: kWeeklyRecapInk.withValues(alpha: 0.18),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        height: 3,
                        width: w,
                        child: const ColoredBox(color: kWeeklyRecapInk),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      }),
    );
  }
}

class RecapBackgroundPainter extends CustomPainter {
  const RecapBackgroundPainter({required this.color, required this.seed});

  final Color color;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);

    final rng = math.Random(seed);
    final linePaint =
        Paint()
          ..color = kWeeklyRecapInk.withValues(alpha: 0.12)
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    final lineCount = 5 + rng.nextInt(3);
    for (var i = 0; i < lineCount; i++) {
      final y = size.height * rng.nextDouble();
      final path = Path()..moveTo(-20, y);
      path.cubicTo(
        size.width * (0.2 + rng.nextDouble() * 0.3),
        y + (rng.nextDouble() - 0.5) * size.height * 0.3,
        size.width * (0.5 + rng.nextDouble() * 0.2),
        y + (rng.nextDouble() - 0.5) * size.height * 0.3,
        size.width + 20,
        y + (rng.nextDouble() - 0.5) * size.height * 0.15,
      );
      canvas.drawPath(path, linePaint);
    }

    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(size.width + 60, size.height + 60),
        width: size.width * 1.1,
        height: size.width * 1.1,
      ),
      math.pi,
      1.1,
      false,
      Paint()
        ..color = kWeeklyRecapInk.withValues(alpha: 0.07)
        ..strokeWidth = 55
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(RecapBackgroundPainter old) =>
      old.color != color || old.seed != seed;
}

class WeeklyReviewSlideScaffold extends StatelessWidget {
  const WeeklyReviewSlideScaffold({
    super.key,
    required this.backgroundColor,
    required this.child,
    required this.seed,
    this.decorativeText,
  });

  final Color backgroundColor;
  final Widget child;
  final int seed;
  final String? decorativeText;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CustomPaint(
          painter: RecapBackgroundPainter(color: backgroundColor, seed: seed),
        ),
        if (decorativeText != null)
          Positioned(
            bottom: -30,
            left: 0,
            right: 0,
            child: Text(
              decorativeText!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kWeeklyRecapInk.withValues(alpha: 0.07),
                fontSize: 220,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: child,
        ),
      ],
    );
  }
}

String patternTypeLabel(WeeklyReviewPatternType t) {
  return switch (t) {
    WeeklyReviewPatternType.weekendSpender => 'Weekend focus',
    WeeklyReviewPatternType.frequentSmallSpender => 'Frequent small buys',
    WeeklyReviewPatternType.oneBigPurchaseWeek => 'One big move',
    WeeklyReviewPatternType.foodHeavyWeek => 'Food-forward week',
    WeeklyReviewPatternType.steadyWeek => 'Steady week',
    WeeklyReviewPatternType.mixedWeek => 'Mixed patterns',
  };
}
