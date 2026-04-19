import 'dart:math' as math;

import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/daily_recap_data.dart';
import 'package:anti/features/home/presentation/controllers/daily_recap_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Query value for `/daily-recap?date=YYYY-MM-DD` (local calendar date).
String formatDailyRecapQueryDate(DateTime date) {
  final d = normalizeToLocalDate(date);
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// Parses `YYYY-MM-DD` as a local calendar date.
DateTime? parseDailyRecapDateFromQuery(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

class DailyRecapScreen extends ConsumerStatefulWidget {
  const DailyRecapScreen({super.key, required this.recapDate});

  final DateTime recapDate;

  @override
  ConsumerState<DailyRecapScreen> createState() => _DailyRecapScreenState();
}

class _DailyRecapScreenState extends ConsumerState<DailyRecapScreen>
    with TickerProviderStateMixin {
  static const _slideCount = 6;
  static const _segmentDuration = Duration(seconds: 5);

  late final PageController _pageController;
  late AnimationController _progressController;

  int _pageIndex = 0;
  DateTime? _pointerDownTime;
  Offset? _pointerDownPosition;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _progressController = AnimationController(
      vsync: this,
      duration: _segmentDuration,
    )..addStatusListener(_onProgressStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _progressController.forward(from: 0);
    });
  }

  void _onProgressStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _goToNextSlide();
    }
  }

  void _resetProgress() {
    _progressController
      ..reset()
      ..forward();
  }

  void _goToNextSlide() {
    if (!mounted) return;
    if (_pageIndex < _slideCount - 1) {
      final next = _pageIndex + 1;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      context.pop();
    }
  }

  void _goToPreviousSlide() {
    if (_pageIndex > 0) {
      final prev = _pageIndex - 1;
      _pageController.animateToPage(
        prev,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      _resetProgress();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _pageIndex = index);
    _resetProgress();
  }

  void _handlePointerDown(PointerDownEvent e) {
    _pointerDownTime = DateTime.now();
    _pointerDownPosition = e.localPosition;
    _progressController.stop();
  }

  void _handlePointerUp(PointerUpEvent e) {
    final downTime = _pointerDownTime;
    final downPos = _pointerDownPosition;
    _pointerDownTime = null;
    _pointerDownPosition = null;

    if (downTime == null || downPos == null) {
      _progressController.forward();
      return;
    }

    final elapsed = DateTime.now().difference(downTime);
    final width = MediaQuery.sizeOf(context).width;

    if (elapsed.inMilliseconds < 280) {
      if (downPos.dx < width / 3) {
        _goToPreviousSlide();
      } else if (downPos.dx > 2 * width / 3) {
        _goToNextSlide();
      } else {
        _progressController.forward();
      }
    } else {
      _progressController.forward();
    }
  }

  void _handlePointerCancel(PointerCancelEvent e) {
    _pointerDownTime = null;
    _pointerDownPosition = null;
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.removeStatusListener(_onProgressStatus);
    _progressController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = normalizeToLocalDate(widget.recapDate);
    final asyncData = ref.watch(dailyRecapControllerProvider(day));

    return asyncData.when(
      data: (data) => _buildStory(context, data),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
        backgroundColor: Colors.black,
      ),
      error:
          (_, __) => Scaffold(
            backgroundColor: Colors.black,
            appBar: AppBar(
              backgroundColor: Colors.black,
              leading: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Something went wrong. Close and try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildStory(BuildContext context, DailyRecapData data) {
    final colors = _slideBackgrounds(data.hasActivity);

    return Scaffold(
      backgroundColor: colors[_pageIndex.clamp(0, _slideCount - 1)],
      body: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _handlePointerDown,
        onPointerUp: _handlePointerUp,
        onPointerCancel: _handlePointerCancel,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: _StoryProgressBar(
                  segmentCount: _slideCount,
                  activeIndex: _pageIndex,
                  progress: _progressController,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _IntroSlide(data: data, backgroundColor: colors[0]),
                    _TotalSpentSlide(data: data, backgroundColor: colors[1]),
                    _TopCategorySlide(data: data, backgroundColor: colors[2]),
                    _TransactionCountSlide(data: data, backgroundColor: colors[3]),
                    _BiggestExpenseSlide(data: data, backgroundColor: colors[4]),
                    _OutroSlide(data: data, backgroundColor: colors[5]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _slideBackgrounds(bool hasActivity) {
    const palette = <Color>[
      Color(0xFF0D9488),
      Color(0xFFDB2777),
      Color(0xFF7C3AED),
      Color(0xFFEA580C),
      Color(0xFF2563EB),
      Color(0xFF059669),
    ];
    if (!hasActivity) {
      return List<Color>.filled(_slideCount, const Color(0xFF475569));
    }
    return palette;
  }
}

class _StoryProgressBar extends StatelessWidget {
  const _StoryProgressBar({
    required this.segmentCount,
    required this.activeIndex,
    required this.progress,
  });

  final int segmentCount;
  final int activeIndex;
  final AnimationController progress;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(segmentCount, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < segmentCount - 1 ? 4 : 0),
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                final fill =
                    i < activeIndex
                        ? 1.0
                        : i == activeIndex
                        ? progress.value.clamp(0.0, 1.0)
                        : 0.0;
                return ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final w = constraints.maxWidth * fill;
                      return Stack(
                        children: [
                          Container(
                            height: 3,
                            width: constraints.maxWidth,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          Positioned(
                            left: 0,
                            top: 0,
                            height: 3,
                            width: w,
                            child: Container(color: Colors.white),
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ),
        );
      }),
    );
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({required this.data, required this.backgroundColor});

  final DailyRecapData data;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final label = _formatDayTitle(data.date);
    return _SlideScaffold(
      backgroundColor: backgroundColor,
      seed: 0,
      decorativeText: '${data.date.day}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            data.hasActivity
                ? 'Here\'s your spending recap'
                : 'No transactions that day — tap through for a quick look',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.95),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalSpentSlide extends StatelessWidget {
  const _TotalSpentSlide({required this.data, required this.backgroundColor});

  final DailyRecapData data;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final amount = formatAmountWithComma(data.totalSpent, decimalDigits: 2);
    return _SlideScaffold(
      backgroundColor: backgroundColor,
      seed: 1,
      decorativeText: '฿',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            data.hasActivity ? 'You spent' : 'Spending',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.hasActivity ? '฿$amount' : '฿0',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'on this day',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCategorySlide extends StatelessWidget {
  const _TopCategorySlide({required this.data, required this.backgroundColor});

  final DailyRecapData data;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final category = data.topCategory;
    final amount = formatAmountWithComma(
      data.topCategoryAmount,
      decimalDigits: 2,
    );
    return _SlideScaffold(
      backgroundColor: backgroundColor,
      seed: 2,
      decorativeText: '#1',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            category != null ? 'Top category' : 'Categories',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            category ?? '—',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (category != null) ...[
            const SizedBox(height: 12),
            Text(
              '฿$amount',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            category != null
                ? 'Where most of your spending went'
                : 'No expense categories for this day',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCountSlide extends StatelessWidget {
  const _TransactionCountSlide({
    required this.data,
    required this.backgroundColor,
  });

  final DailyRecapData data;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final n = data.transactionCount;
    return _SlideScaffold(
      backgroundColor: backgroundColor,
      seed: 3,
      decorativeText: '$n',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$n',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            n == 1 ? 'transaction logged' : 'transactions logged',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BiggestExpenseSlide extends StatelessWidget {
  const _BiggestExpenseSlide({
    required this.data,
    required this.backgroundColor,
  });

  final DailyRecapData data;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    final log = data.biggestExpense;
    final title =
        log == null
            ? null
            : (log.category.isNotEmpty ? log.category : log.timeLabel);
    final amount =
        log != null
            ? formatAmountWithComma(log.amount.abs(), decimalDigits: 2)
            : null;

    return _SlideScaffold(
      backgroundColor: backgroundColor,
      seed: 4,
      decorativeText: '฿',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Biggest purchase',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          if (log != null && title != null) ...[
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '฿$amount',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.95),
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ] else
            Text(
              'No expenses to highlight',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

class _OutroSlide extends StatelessWidget {
  const _OutroSlide({required this.data, required this.backgroundColor});

  final DailyRecapData data;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return _SlideScaffold(
      backgroundColor: backgroundColor,
      seed: 5,
      decorativeText: '✓',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Nice work tracking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.hasActivity
                ? 'Keep logging to sharpen your insights'
                : 'Add a log tomorrow to build your streak',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 18,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecapBgPainter extends CustomPainter {
  const _RecapBgPainter({required this.color, required this.seed});

  final Color color;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);

    final rng = math.Random(seed);
    final linePaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
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
        ..color = Colors.white.withValues(alpha: 0.07)
        ..strokeWidth = 55
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(_RecapBgPainter old) =>
      old.color != color || old.seed != seed;
}

class _SlideScaffold extends StatelessWidget {
  const _SlideScaffold({
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
          painter: _RecapBgPainter(color: backgroundColor, seed: seed),
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
                color: Colors.white.withValues(alpha: 0.09),
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

String _formatDayTitle(DateTime date) {
  const weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
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
  final wd = weekdays[date.weekday - 1];
  final m = months[date.month - 1];
  return '$wd, $m ${date.day}, ${date.year}';
}
