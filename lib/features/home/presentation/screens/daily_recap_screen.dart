import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/daily_recap_data.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
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

/// Ink color for text and chrome on daily recap light slides.
const Color _kDailyRecapInk = Color(0xFF0A0A0A);

class DailyRecapScreen extends ConsumerStatefulWidget {
  const DailyRecapScreen({super.key, required this.recapDate});

  final DateTime recapDate;

  @override
  ConsumerState<DailyRecapScreen> createState() => _DailyRecapScreenState();
}

class _DailyRecapScreenState extends ConsumerState<DailyRecapScreen> {
  static const _slideCount = 7;

  late final PageController _pageController;

  int _pageIndex = 0;
  DateTime? _pointerDownTime;
  Offset? _pointerDownPosition;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
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
    }
  }

  void _onPageChanged(int index) {
    setState(() => _pageIndex = index);
  }

  void _handlePointerDown(PointerDownEvent e) {
    _pointerDownTime = DateTime.now();
    _pointerDownPosition = e.localPosition;
  }

  void _handlePointerUp(PointerUpEvent e) {
    final downTime = _pointerDownTime;
    final downPos = _pointerDownPosition;
    _pointerDownTime = null;
    _pointerDownPosition = null;

    if (downTime == null || downPos == null) return;

    final elapsed = DateTime.now().difference(downTime);
    final width = MediaQuery.sizeOf(context).width;

    if (elapsed.inMilliseconds < 280) {
      if (downPos.dx < width / 3) {
        _goToPreviousSlide();
      } else if (downPos.dx > 2 * width / 3) {
        _goToNextSlide();
      }
    }
  }

  void _handlePointerCancel(PointerCancelEvent e) {
    _pointerDownTime = null;
    _pointerDownPosition = null;
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = normalizeToLocalDate(widget.recapDate);
    final asyncData = ref.watch(dailyRecapControllerProvider(day));

    return asyncData.when(
      data: (data) => _buildStory(context, data),
      loading:
          () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: _kDailyRecapInk),
            ),
            backgroundColor: Color(0xFFF5F5F5),
          ),
      error:
          (_, __) => Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF5F5F5),
              leading: IconButton(
                icon: const Icon(Icons.close, color: _kDailyRecapInk),
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
                    color: _kDailyRecapInk,
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
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, color: _kDailyRecapInk, size: 28),
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  children: [
                    _IntroSlide(data: data, backgroundColor: colors[0]),
                    _TotalSpentSlide(data: data, backgroundColor: colors[1]),
                    _TopCategorySlide(data: data, backgroundColor: colors[2]),
                    _TransactionCountSlide(
                      data: data,
                      backgroundColor: colors[3],
                    ),
                    _BiggestExpenseSlide(
                      data: data,
                      backgroundColor: colors[4],
                    ),
                    _SpendingTimelineSlide(
                      data: data,
                      backgroundColor: colors[5],
                      isActive: _pageIndex == 5,
                    ),
                    _OutroSlide(data: data, backgroundColor: colors[6]),
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
      Color(0xFFFFFFFF), // white          – intro
      Color(0xFFFAFAFA), // off-white      – total spent
      Color(0xFFF5F5F5), // light grey     – top category
      Color(0xFFF0F0F0), // grey tint      – transaction count
      Color(0xFFFAFAFA), // off-white      – biggest expense
      Color(0xFFFCFCFC), // near-white     – spending timeline
      Color(0xFFFFFFFF), // white          – outro
    ];
    if (!hasActivity) {
      return List<Color>.filled(_slideCount, const Color(0xFFF3F3F3));
    }
    return palette;
  }
}

class _StoryProgressBar extends StatelessWidget {
  const _StoryProgressBar({
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
                        color: _kDailyRecapInk.withValues(alpha: 0.18),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        height: 3,
                        width: w,
                        child: const ColoredBox(color: _kDailyRecapInk),
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
              color: _kDailyRecapInk,
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
              color: _kDailyRecapInk.withValues(alpha: 0.92),
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
              color: _kDailyRecapInk.withValues(alpha: 0.85),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.hasActivity ? '฿$amount' : '฿0',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kDailyRecapInk,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'on this day',
            style: TextStyle(
              color: _kDailyRecapInk.withValues(alpha: 0.72),
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
              color: _kDailyRecapInk.withValues(alpha: 0.85),
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            category ?? '—',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _kDailyRecapInk,
              fontSize: 36,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (category != null) ...[
            const SizedBox(height: 12),
            Text(
              '฿$amount',
              style: TextStyle(
                color: _kDailyRecapInk.withValues(alpha: 0.88),
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
              color: _kDailyRecapInk.withValues(alpha: 0.72),
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
              color: _kDailyRecapInk,
              fontSize: 64,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            n == 1 ? 'transaction logged' : 'transactions logged',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kDailyRecapInk.withValues(alpha: 0.85),
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
              color: _kDailyRecapInk.withValues(alpha: 0.85),
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
                color: _kDailyRecapInk,
                fontSize: 32,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '฿$amount',
              style: TextStyle(
                color: _kDailyRecapInk.withValues(alpha: 0.88),
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ] else
            Text(
              'No expenses to highlight',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kDailyRecapInk.withValues(alpha: 0.78),
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
        ],
      ),
    );
  }
}

/// One plotted sample on the spending timeline (x = pixels along chart, y = amount).
class _TimelinePoint {
  const _TimelinePoint({
    required this.x,
    required this.amountAbs,
    required this.time,
  });

  final double x;
  final double amountAbs;
  final DateTime time;
}

String _formatChartAxisAmount(double v) {
  if (v >= 1000000) return '฿${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '฿${(v / 1000).toStringAsFixed(1)}k';
  return '฿${formatAmountWithComma(v, decimalDigits: 0)}';
}

String _formatTimelineClock(DateTime d) {
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

class _SpendingTimelineSlide extends StatefulWidget {
  const _SpendingTimelineSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final DailyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  State<_SpendingTimelineSlide> createState() => _SpendingTimelineSlideState();
}

class _SpendingTimelineSlideState extends State<_SpendingTimelineSlide>
    with TickerProviderStateMixin {
  static const _revealDuration = Duration(seconds: 10);
  static const _pixelsPerMinute = 4.0;

  /// Full local day 00:00 → 23:59:59 on the X axis.
  static const _minutesInDay = 24 * 60.0;

  late final AnimationController _revealController;
  late final AnimationController _zoomController;
  late final Animation<double> _zoomAnim;
  late final ScrollController _scrollController;

  List<_TimelinePoint> _cachedPoints = [];
  double _cachedChartWidth = 0;
  int _lastZoomedIndex = -1;
  int? _zoomPointIndex;

  @override
  void initState() {
    super.initState();
    _revealController = AnimationController(
      vsync: this,
      duration: _revealDuration,
    )..addListener(_onRevealTick);
    _scrollController = ScrollController();

    _zoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addListener(_onZoomTick);
    _zoomController.addStatusListener(_onZoomStatus);

    _zoomAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.0,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 6,
      ),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 5),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 2,
      ),
    ]).animate(_zoomController);
  }

  void _onZoomTick() {
    setState(() {});
  }

  void _onZoomStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _zoomPointIndex = null;
      if (mounted) {
        _revealController.forward();
      }
    }
  }

  void _onRevealTick() {
    setState(() {});
    _syncScroll();

    if (_zoomController.isAnimating) return;

    final cw = _cachedChartWidth;
    if (cw <= 0) return;

    final rx = _revealController.value * cw;
    for (var i = _lastZoomedIndex + 1; i < _cachedPoints.length; i++) {
      if (_cachedPoints[i].x <= rx) {
        _lastZoomedIndex = i;
        _zoomPointIndex = i;
        _revealController.stop();
        _zoomController.forward(from: 0);
        break;
      }
    }
  }

  void _syncScroll() {
    final c = _scrollController;
    if (!c.hasClients) return;
    final maxScroll = c.position.maxScrollExtent;
    if (!maxScroll.isFinite || maxScroll <= 0) return;
    c.jumpTo(_revealController.value.clamp(0.0, 1.0) * maxScroll);
  }

  @override
  void didUpdateWidget(covariant _SpendingTimelineSlide oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _lastZoomedIndex = -1;
      _zoomPointIndex = null;
      _zoomController.reset();
      _revealController.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _syncScroll();
      });
    }
    if (!widget.isActive && oldWidget.isActive) {
      _revealController.reset();
      _zoomController.reset();
      _zoomPointIndex = null;
      _lastZoomedIndex = -1;
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    }
  }

  @override
  void dispose() {
    _revealController.removeListener(_onRevealTick);
    _revealController.dispose();
    _zoomController.removeListener(_onZoomTick);
    _zoomController.removeStatusListener(_onZoomStatus);
    _zoomController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  List<ExpenseLog> _sortedExpenses() {
    final list =
        widget.data.logs.where((l) => l.amount < 0).toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  DateTime _startOfRecapDay() {
    final d = widget.data.date;
    return DateTime(d.year, d.month, d.day);
  }

  /// Minutes from local midnight [0, 1440], including fractional minutes.
  double _minutesSinceMidnight(DateTime t) {
    final start = _startOfRecapDay();
    final m = t.difference(start).inSeconds / 60.0;
    return m.clamp(0.0, _minutesInDay);
  }

  @override
  Widget build(BuildContext context) {
    final expenses = _sortedExpenses();
    if (expenses.isEmpty) {
      return _SlideScaffold(
        backgroundColor: widget.backgroundColor,
        seed: 5,
        decorativeText: '—',
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Your day in spending',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kDailyRecapInk.withValues(alpha: 0.88),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Log an expense to see your timeline here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kDailyRecapInk.withValues(alpha: 0.72),
                fontSize: 17,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ],
        ),
      );
    }

    final media = MediaQuery.sizeOf(context);
    final plotHeight = math.min(220.0, media.height * 0.32);

    return LayoutBuilder(
      builder: (context, constraints) {
        final viewportW = constraints.maxWidth;
        final chartInnerW = viewportW - 52;
        final chartWidth = math.max(
          chartInnerW,
          _minutesInDay * _pixelsPerMinute,
        );

        final points = <_TimelinePoint>[];
        for (final e in expenses) {
          final mins = _minutesSinceMidnight(e.createdAt);
          final x = (mins / _minutesInDay) * chartWidth;
          points.add(
            _TimelinePoint(
              x: x.clamp(0.0, chartWidth),
              amountAbs: e.amount.abs(),
              time: e.createdAt,
            ),
          );
        }

        final maxAmount = points
            .map((p) => p.amountAbs)
            .reduce(math.max)
            .clamp(1.0, double.infinity);

        _cachedPoints = points;
        _cachedChartWidth = chartWidth;

        final revealedX = _revealController.value * chartWidth;

        return _SlideScaffold(
          backgroundColor: widget.backgroundColor,
          seed: 5,
          decorativeText: '⌁',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your day in spending',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kDailyRecapInk.withValues(alpha: 0.92),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      width: 52,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatChartAxisAmount(maxAmount),
                            style: TextStyle(
                              color: _kDailyRecapInk.withValues(alpha: 0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _formatChartAxisAmount(maxAmount / 2),
                            style: TextStyle(
                              color: _kDailyRecapInk.withValues(alpha: 0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '฿0',
                            style: TextStyle(
                              color: _kDailyRecapInk.withValues(alpha: 0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ClipRect(
                        child: SingleChildScrollView(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          physics: const NeverScrollableScrollPhysics(),
                          child: SizedBox(
                            width: chartWidth,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: plotHeight,
                                  width: chartWidth,
                                  child: CustomPaint(
                                    painter: _TimelineChartPainter(
                                      points: points,
                                      progress: _revealController.value,
                                      revealedX: revealedX,
                                      maxAmount: maxAmount,
                                      chartWidth: chartWidth,
                                      zoomPointIndex: _zoomPointIndex,
                                      zoomValue: _zoomAnim.value,
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  height: 44,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                        height: 14,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            for (final label in const [
                                              '00:00',
                                              '06:00',
                                              '12:00',
                                              '18:00',
                                              '23:59',
                                            ])
                                              Text(
                                                label,
                                                style: TextStyle(
                                                  color: _kDailyRecapInk
                                                      .withValues(alpha: 0.42),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Stack(
                                          clipBehavior: Clip.none,
                                          children: [
                                            for (final p in points)
                                              Positioned(
                                                left: p.x - 18,
                                                top: 0,
                                                child: Text(
                                                  _formatTimelineClock(p.time),
                                                  style: TextStyle(
                                                    color: _kDailyRecapInk
                                                        .withValues(alpha: 0.58),
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TimelineChartPainter extends CustomPainter {
  _TimelineChartPainter({
    required this.points,
    required this.progress,
    required this.revealedX,
    required this.maxAmount,
    required this.chartWidth,
    this.zoomPointIndex,
    this.zoomValue = 0.0,
  });

  final List<_TimelinePoint> points;
  final double progress;
  final double revealedX;
  final double maxAmount;
  final double chartWidth;
  final int? zoomPointIndex;
  final double zoomValue;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final maxA = maxAmount > 0 ? maxAmount : 1.0;

    final gridPaint =
        Paint()
          ..color = _kDailyRecapInk.withValues(alpha: 0.12)
          ..strokeWidth = 1;

    double yAt(double amountAbs) {
      const padY = 0.06;
      final plotH = h * (1 - 2 * padY);
      final top = h * padY;
      return top + plotH * (1 - amountAbs / maxA);
    }

    for (var k = 0; k <= 2; k++) {
      final amt = maxA * (1 - k / 2);
      final y = yAt(amt);
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    if (points.length < 2) {
      _paintDotsOnly(canvas, size, maxA, yAt);
      return;
    }

    final path = Path();
    var started = false;
    final rx = revealedX.clamp(0.0, w);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = p.x;
      final y = yAt(p.amountAbs);
      if (x <= rx) {
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      } else {
        if (i > 0 && started) {
          final p0 = points[i - 1];
          final x0 = p0.x;
          final y0 = yAt(p0.amountAbs);
          if (rx > x0 && (x - x0).abs() > 1e-6) {
            final t = (rx - x0) / (x - x0);
            final yi = y0 + t * (y - y0);
            path.lineTo(rx, yi);
          }
        }
        break;
      }
    }

    final glow =
        Paint()
          ..color = _kDailyRecapInk.withValues(alpha: 0.22)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final line =
        Paint()
          ..color = _kDailyRecapInk.withValues(alpha: 0.92)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    if (started) {
      canvas.drawPath(path, glow);
      canvas.drawPath(path, line);
    }

    _paintDots(canvas, size, maxA, yAt, rx);
  }

  void _paintDotsOnly(
    Canvas canvas,
    Size size,
    double maxA,
    double Function(double) yAt,
  ) {
    final h = size.height;
    final rx = revealedX.clamp(0.0, size.width);
    final window = chartWidth * 0.08;
    _paintDotsLayer(canvas, size, maxA, yAt, rx, h, window);
  }

  void _paintDots(
    Canvas canvas,
    Size size,
    double maxA,
    double Function(double) yAt,
    double rx,
  ) {
    final h = size.height;
    final window = chartWidth * 0.08;
    _paintDotsLayer(canvas, size, maxA, yAt, rx, h, window);
  }

  void _paintDotsLayer(
    Canvas canvas,
    Size size,
    double maxA,
    double Function(double) yAt,
    double rx,
    double h,
    double window,
  ) {
    final dotFill =
        Paint()
          ..color = _kDailyRecapInk.withValues(alpha: 0.92)
          ..style = PaintingStyle.fill;
    final dotGlow =
        Paint()
          ..color = _kDailyRecapInk.withValues(alpha: 0.22)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.x > rx) continue;
      final raw = rx - p.x;
      var popT = 1.0;
      if (raw < window) {
        popT = (raw / window).clamp(0.0, 1.0);
      }
      final targetY = yAt(p.amountAbs);
      final dotY =
          ui.lerpDouble(h, targetY, Curves.easeOutBack.transform(popT)) ??
          targetY;
      var baseR = 6.0 * Curves.easeOutCubic.transform(popT);
      final isZoomed = zoomPointIndex == i;
      if (isZoomed) {
        baseR += 12.0 * zoomValue;
      }
      final r = baseR;
      if (r < 0.4 && !isZoomed) continue;
      canvas.drawCircle(Offset(p.x, dotY), r + 2, dotGlow);
      canvas.drawCircle(Offset(p.x, dotY), r, dotFill);
      if (isZoomed && zoomValue > 0) {
        _drawZoomLabel(canvas, p.x, dotY, r, p.amountAbs, zoomValue);
      }
    }
  }

  void _drawZoomLabel(
    Canvas canvas,
    double x,
    double dotY,
    double dotRadius,
    double amountAbs,
    double z,
  ) {
    final opacity = z.clamp(0.0, 1.0);
    if (opacity <= 0) return;
    final label = _formatChartAxisAmount(amountAbs);
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: _kDailyRecapInk.withValues(alpha: opacity),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    const padH = 10.0;
    const padV = 6.0;
    final tw = tp.width + padH * 2;
    final th = tp.height + padV * 2;
    final top = math.max(4.0, dotY - dotRadius - 10 - th);
    final left = x - tw / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, tw, th),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = _kDailyRecapInk.withValues(alpha: 0.08 * opacity),
    );
    tp.paint(canvas, Offset(left + padH, top + padV));
  }

  @override
  bool shouldRepaint(covariant _TimelineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.revealedX != revealedX ||
        oldDelegate.points.length != points.length ||
        oldDelegate.maxAmount != maxAmount ||
        oldDelegate.chartWidth != chartWidth ||
        oldDelegate.zoomPointIndex != zoomPointIndex ||
        oldDelegate.zoomValue != zoomValue;
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
      seed: 6,
      decorativeText: '✓',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Nice work tracking',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _kDailyRecapInk,
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
              color: _kDailyRecapInk.withValues(alpha: 0.78),
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
          ..color = _kDailyRecapInk.withValues(alpha: 0.12)
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
        ..color = _kDailyRecapInk.withValues(alpha: 0.07)
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
                color: _kDailyRecapInk.withValues(alpha: 0.07),
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
