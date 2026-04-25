import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:anti/core/utils/formatters.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/entities/weekly_recap_data.dart';
import 'package:anti/features/home/presentation/controllers/weekly_recap_controller.dart';
import 'package:anti/features/home/presentation/screens/dashboard/utils/dashboard_log_filters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Query value for `/weekly-recap?week=YYYY-MM-DD` (local Monday; any day in that week is normalized by callers).
String formatWeeklyRecapQueryDate(DateTime monday) {
  final m = startOfLocalWeekMonday(normalizeToLocalDate(monday));
  return '${m.year}-${m.month.toString().padLeft(2, '0')}-${m.day.toString().padLeft(2, '0')}';
}

/// Parses `YYYY-MM-DD` as a local calendar date; used for the week= query (Monday of the week to show).
DateTime? parseWeeklyRecapDateFromQuery(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return startOfLocalWeekMonday(DateTime(y, m, d));
}

/// Ink color for text and chrome on weekly recap light slides.
const Color _kWeeklyRecapInk = Color(0xFF0A0A0A);

/// Letter spacing for recap editorial kicker labels (uppercase).
const double _kRecapKickerLetterSpacing = 2.5;

TextStyle _recapKickerStyle({double alpha = 0.55}) => TextStyle(
  color: _kWeeklyRecapInk.withValues(alpha: alpha),
  fontSize: 12,
  fontWeight: FontWeight.w600,
  letterSpacing: _kRecapKickerLetterSpacing,
  height: 1.2,
);

const Duration _kRecapRevealDuration = Duration(milliseconds: 450);

/// Fade + translate-up entrance for recap copy; replays when [isActive] becomes true.
class _RecapReveal extends StatefulWidget {
  const _RecapReveal({
    required this.child,
    required this.isActive,
    this.delay = Duration.zero,
  });

  final Widget child;
  final bool isActive;
  final Duration delay;

  @override
  State<_RecapReveal> createState() => _RecapRevealState();
}

class _RecapRevealState extends State<_RecapReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: _kRecapRevealDuration,
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
  void didUpdateWidget(covariant _RecapReveal oldWidget) {
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

class WeeklyRecapScreen extends ConsumerStatefulWidget {
  const WeeklyRecapScreen({super.key, required this.recapWeekAnchor});

  /// Any local date in the week to show; the screen uses that week (Mon–Sun).
  final DateTime recapWeekAnchor;

  @override
  ConsumerState<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends ConsumerState<WeeklyRecapScreen> {
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
    final monday =
        startOfLocalWeekMonday(normalizeToLocalDate(widget.recapWeekAnchor));
    final asyncData = ref.watch(weeklyRecapControllerProvider(monday));

    return asyncData.when(
      data: (WeeklyRecapData data) => _buildStory(context, data),
      loading:
          () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: _kWeeklyRecapInk),
            ),
            backgroundColor: Color(0xFFF5F5F5),
          ),
      error:
          (_, __) => Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF5F5F5),
              leading: IconButton(
                icon: const Icon(Icons.close, color: _kWeeklyRecapInk),
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
                    color: _kWeeklyRecapInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildStory(BuildContext context, WeeklyRecapData recap) {
    final colors = _slideBackgrounds(recap.hasActivity);

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
                  icon: const Icon(
                    Icons.close,
                    color: _kWeeklyRecapInk,
                    size: 28,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: _onPageChanged,
                  children: [
                    _IntroSlide(
                      data: recap,
                      backgroundColor: colors[0],
                      isActive: _pageIndex == 0,
                    ),
                    _TotalSpentSlide(
                      data: recap,
                      backgroundColor: colors[1],
                      isActive: _pageIndex == 1,
                    ),
                    _TopCategorySlide(
                      data: recap,
                      backgroundColor: colors[2],
                      isActive: _pageIndex == 2,
                    ),
                    _TransactionCountSlide(
                      data: recap,
                      backgroundColor: colors[3],
                      isActive: _pageIndex == 3,
                    ),
                    _BiggestExpenseSlide(
                      data: recap,
                      backgroundColor: colors[4],
                      isActive: _pageIndex == 4,
                    ),
                    _SpendingTimelineSlide(
                      data: recap,
                      backgroundColor: colors[5],
                      isActive: _pageIndex == 5,
                    ),
                    _OutroSlide(
                      data: recap,
                      backgroundColor: colors[6],
                      isActive: _pageIndex == 6,
                    ),
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
                        color: _kWeeklyRecapInk.withValues(alpha: 0.18),
                      ),
                      Positioned(
                        left: 0,
                        top: 0,
                        height: 3,
                        width: w,
                        child: const ColoredBox(color: _kWeeklyRecapInk),
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
  const _IntroSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final label = _formatWeekRangeKicker(data.weekStart, data.weekEnd);
    return _SlideScaffold(
      backgroundColor: backgroundColor,
      seed: 0,
      decorativeText: '${data.weekStart.day}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RecapReveal(
            isActive: isActive,
            child: Text(
              label.toUpperCase(),
              textAlign: TextAlign.center,
              style: _recapKickerStyle(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 20),
          _RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 100),
            child: Text(
              data.hasActivity
                  ? 'Here\'s your spending recap'
                  : 'A quiet week — tap through for a quick look',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kWeeklyRecapInk.withValues(alpha: 0.92),
                fontSize: data.hasActivity ? 40 : 30,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalSpentSlide extends StatelessWidget {
  const _TotalSpentSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final amount = formatAmountWithComma(data.totalSpent, decimalDigits: 2);
    return _SlideScaffold(
      backgroundColor: backgroundColor,
      seed: 1,
      decorativeText: '฿',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RecapReveal(
            isActive: isActive,
            child: Text(
              data.hasActivity ? 'YOU SPENT' : 'SPENDING',
              textAlign: TextAlign.center,
              style: _recapKickerStyle(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 16),
          _RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 100),
            child: Text(
              data.hasActivity ? '฿$amount' : '฿0',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kWeeklyRecapInk,
                fontSize: 64,
                fontWeight: FontWeight.w900,
                letterSpacing: -1.2,
                height: 1.05,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 200),
            child: Text(
              'THIS WEEK',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kWeeklyRecapInk.withValues(alpha: 0.55),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: 1.8,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCategorySlide extends StatelessWidget {
  const _TopCategorySlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RecapReveal(
            isActive: isActive,
            child: Text(
              category != null ? 'TOP CATEGORY' : 'CATEGORIES',
              textAlign: TextAlign.center,
              style: _recapKickerStyle(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 20),
          _RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 100),
            child: Text(
              category ?? '—',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kWeeklyRecapInk,
                fontSize: 44,
                fontWeight: FontWeight.w900,
                height: 1.08,
                letterSpacing: -1.0,
              ),
            ),
          ),
          if (category != null) ...[
            const SizedBox(height: 12),
            _RecapReveal(
              isActive: isActive,
              delay: const Duration(milliseconds: 200),
              child: Text(
                '฿$amount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kWeeklyRecapInk.withValues(alpha: 0.88),
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 300),
            child: Text(
              category != null
                  ? 'Where most of your spending went'
                  : 'No expense categories this week',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kWeeklyRecapInk.withValues(alpha: 0.58),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
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
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final n = data.transactionCount;
    return _SlideScaffold(
      backgroundColor: backgroundColor,
      seed: 3,
      decorativeText: '$n',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RecapReveal(
            isActive: isActive,
            child: Text(
              '$n',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: _kWeeklyRecapInk,
                fontSize: 88,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 100),
            child: Text(
              n == 1 ? 'TRANSACTION LOGGED' : 'TRANSACTIONS LOGGED',
              textAlign: TextAlign.center,
              style: _recapKickerStyle(alpha: 0.75),
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
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RecapReveal(
            isActive: isActive,
            child: Text(
              'BIGGEST PURCHASE',
              textAlign: TextAlign.center,
              style: _recapKickerStyle(alpha: 0.72),
            ),
          ),
          const SizedBox(height: 20),
          if (log != null && title != null) ...[
            _RecapReveal(
              isActive: isActive,
              delay: const Duration(milliseconds: 100),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _kWeeklyRecapInk,
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _RecapReveal(
              isActive: isActive,
              delay: const Duration(milliseconds: 200),
              child: Text(
                '฿$amount',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kWeeklyRecapInk.withValues(alpha: 0.88),
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ] else
            _RecapReveal(
              isActive: isActive,
              delay: const Duration(milliseconds: 100),
              child: Text(
                'No expenses to highlight',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kWeeklyRecapInk.withValues(alpha: 0.72),
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                ),
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
    required this.category,
  });

  final double x;
  final double amountAbs;
  final DateTime time;
  final String category;
}

String _formatChartAxisAmount(double v) {
  if (v >= 1000000) return '฿${(v / 1000000).toStringAsFixed(1)}M';
  if (v >= 1000) return '฿${(v / 1000).toStringAsFixed(1)}k';
  return '฿${formatAmountWithComma(v, decimalDigits: 0)}';
}

String _formatTimelineClock(DateTime d) {
  return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}

const _weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _formatTimelineWeekTime(DateTime d) {
  return '${_weekdayShort[d.weekday - 1]} ${_formatTimelineClock(d)}';
}

class _SpendingTimelineSlide extends StatefulWidget {
  const _SpendingTimelineSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  State<_SpendingTimelineSlide> createState() => _SpendingTimelineSlideState();
}

class _SpendingTimelineSlideState extends State<_SpendingTimelineSlide>
    with TickerProviderStateMixin {
  static const _revealDuration = Duration(seconds: 10);
  static const _pixelsPerMinute = 0.55;

  /// Monday 00:00 through Sunday 23:59 on the X axis.
  static const _minutesInWeek = 7 * 24 * 60.0;

  late final AnimationController _revealController;
  late final AnimationController _zoomController;
  late final Animation<double> _zoomAnim;
  late final ScrollController _scrollController;

  List<_TimelinePoint> _cachedPoints = [];
  double _cachedChartWidth = 0;
  int _lastZoomedIndex = -1;
  int? _zoomPointIndex;

  /// After the final point’s zoom finishes, keep its label/dot visible.
  int? _pinnedLastPointIndex;

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
      if (!mounted) return;
      final reachedLastPoint =
          _cachedPoints.isNotEmpty &&
          _lastZoomedIndex >= _cachedPoints.length - 1;
      _zoomPointIndex = null;
      if (reachedLastPoint) {
        _pinnedLastPointIndex = _lastZoomedIndex;
        // Stop here: do not reveal the rest of the week past the final expense.
        setState(() {});
        return;
      }
      _pinnedLastPointIndex = null;
      _revealController.forward();
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
      _pinnedLastPointIndex = null;
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
      _pinnedLastPointIndex = null;
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

  DateTime _startOfRecapWeek() {
    final d = widget.data.weekStart;
    return DateTime(d.year, d.month, d.day);
  }

  /// Minutes from Monday 00:00, capped at one week.
  double _minutesSinceWeekStart(DateTime t) {
    final start = _startOfRecapWeek();
    final m = t.difference(start).inSeconds / 60.0;
    return m.clamp(0.0, _minutesInWeek);
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
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'YOUR WEEK IN SPENDING',
              textAlign: TextAlign.center,
              style: _recapKickerStyle(alpha: 0.72),
            ),
            const SizedBox(height: 20),
            Text(
              'Log an expense to see your week here',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kWeeklyRecapInk.withValues(alpha: 0.58),
                fontSize: 16,
                fontWeight: FontWeight.w500,
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
          _minutesInWeek * _pixelsPerMinute,
        );

        final points = <_TimelinePoint>[];
        for (final e in expenses) {
          final mins = _minutesSinceWeekStart(e.createdAt);
          final x = (mins / _minutesInWeek) * chartWidth;
          points.add(
            _TimelinePoint(
              x: x.clamp(0.0, chartWidth),
              amountAbs: e.amount.abs(),
              time: e.createdAt,
              category: e.category,
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'YOUR WEEK IN SPENDING',
                textAlign: TextAlign.center,
                style: _recapKickerStyle(alpha: 0.75),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: plotHeight + 44,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 52,
                          height: plotHeight,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatChartAxisAmount(maxAmount),
                                style: TextStyle(
                                  color: _kWeeklyRecapInk.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                _formatChartAxisAmount(maxAmount / 2),
                                style: TextStyle(
                                  color: _kWeeklyRecapInk.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '฿0',
                                style: TextStyle(
                                  color: _kWeeklyRecapInk.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 44),
                      ],
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
                                      pinnedPointIndex: _pinnedLastPointIndex,
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
                                              'Mon',
                                              'Tue',
                                              'Wed',
                                              'Thu',
                                              'Fri',
                                              'Sat',
                                              'Sun',
                                            ])
                                              Text(
                                                label,
                                                style: TextStyle(
                                                  color: _kWeeklyRecapInk
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
                                                  _formatTimelineWeekTime(
                                                    p.time,
                                                  ),
                                                  style: TextStyle(
                                                    color: _kWeeklyRecapInk
                                                        .withValues(
                                                          alpha: 0.58,
                                                        ),
                                                    fontSize: 9,
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
    this.pinnedPointIndex,
  });

  final List<_TimelinePoint> points;
  final double progress;
  final double revealedX;
  final double maxAmount;
  final double chartWidth;
  final int? zoomPointIndex;
  final double zoomValue;
  final int? pinnedPointIndex;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final maxA = maxAmount > 0 ? maxAmount : 1.0;

    final gridPaint =
        Paint()
          ..color = _kWeeklyRecapInk.withValues(alpha: 0.12)
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
    final rx = revealedX.clamp(0.0, w);
    final baseline = yAt(0);
    path.moveTo(0, baseline);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final x = p.x;
      final y = yAt(p.amountAbs);
      if (x <= rx) {
        path.lineTo(x, y);
      } else {
        final p0 = i > 0 ? points[i - 1] : null;
        final x0 = p0?.x ?? 0.0;
        final y0 = p0 != null ? yAt(p0.amountAbs) : baseline;
        if (rx > x0 && (x - x0).abs() > 1e-6) {
          final t = (rx - x0) / (x - x0);
          final yi = y0 + t * (y - y0);
          path.lineTo(rx, yi);
        }
        break;
      }
    }

    final glow =
        Paint()
          ..color = _kWeeklyRecapInk.withValues(alpha: 0.22)
          ..strokeWidth = 6
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    final line =
        Paint()
          ..color = _kWeeklyRecapInk.withValues(alpha: 0.92)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glow);
    canvas.drawPath(path, line);

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
          ..color = _kWeeklyRecapInk.withValues(alpha: 0.92)
          ..style = PaintingStyle.fill;
    final dotGlow =
        Paint()
          ..color = _kWeeklyRecapInk.withValues(alpha: 0.22)
          ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      if (p.x > rx) continue;
      final isZoomed = zoomPointIndex == i;
      final isPinned = pinnedPointIndex == i;
      final raw = rx - p.x;
      var popT = 1.0;
      if (!isZoomed && raw < window) {
        popT = (raw / window).clamp(0.0, 1.0);
      }
      if (isPinned) popT = 1.0;
      final targetY = yAt(p.amountAbs);
      final dotY =
          ui.lerpDouble(h, targetY, Curves.easeOutBack.transform(popT)) ??
          targetY;
      var baseR = 6.0 * Curves.easeOutCubic.transform(popT);
      if (isZoomed) {
        baseR += 12.0 * zoomValue;
      } else if (isPinned) {
        baseR += 3.0;
      }
      final r = baseR;
      if (r < 0.4 && !isZoomed && !isPinned) continue;
      canvas.drawCircle(Offset(p.x, dotY), r + 2, dotGlow);
      canvas.drawCircle(Offset(p.x, dotY), r, dotFill);
      if (isZoomed && zoomValue > 0) {
        _drawZoomLabel(
          canvas,
          p.x,
          dotY,
          r,
          p.amountAbs,
          p.category,
          zoomValue,
        );
      } else if (isPinned) {
        _drawZoomLabel(canvas, p.x, dotY, r, p.amountAbs, p.category, 1.0);
      }
    }
  }

  void _drawZoomLabel(
    Canvas canvas,
    double x,
    double dotY,
    double dotRadius,
    double amountAbs,
    String category,
    double z,
  ) {
    final opacity = z.clamp(0.0, 1.0);
    if (opacity <= 0) return;
    final amountLabel = _formatChartAxisAmount(amountAbs);
    final categoryLabel = category.trim().isNotEmpty ? category.trim() : '—';
    final tpAmount = TextPainter(
      text: TextSpan(
        text: amountLabel,
        style: TextStyle(
          color: _kWeeklyRecapInk.withValues(alpha: opacity),
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final tpCategory = TextPainter(
      text: TextSpan(
        text: categoryLabel,
        style: TextStyle(
          color: _kWeeklyRecapInk.withValues(alpha: 0.85 * opacity),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    )..layout(maxWidth: 200);
    const padH = 10.0;
    const padV = 6.0;
    const gapBetweenLines = 2.0;
    final contentW = math.max(tpAmount.width, tpCategory.width);
    final tw = contentW + padH * 2;
    final th = padV * 2 + tpAmount.height + gapBetweenLines + tpCategory.height;
    final aboveTop = dotY - dotRadius - 10 - th;
    final top =
        aboveTop < 0
            ? dotY + dotRadius + 8
            : aboveTop.clamp(4.0, double.infinity);
    final left = x - tw / 2;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, tw, th),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      rect,
      Paint()..color = _kWeeklyRecapInk.withValues(alpha: 0.08 * opacity),
    );
    final amountTop = top + padV;
    tpAmount.paint(canvas, Offset(left + padH, amountTop));
    tpCategory.paint(
      canvas,
      Offset(left + padH, amountTop + tpAmount.height + gapBetweenLines),
    );
  }

  @override
  bool shouldRepaint(covariant _TimelineChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.revealedX != revealedX ||
        oldDelegate.points.length != points.length ||
        oldDelegate.maxAmount != maxAmount ||
        oldDelegate.chartWidth != chartWidth ||
        oldDelegate.zoomPointIndex != zoomPointIndex ||
        oldDelegate.zoomValue != zoomValue ||
        oldDelegate.pinnedPointIndex != pinnedPointIndex;
  }
}

class _OutroSlide extends StatelessWidget {
  const _OutroSlide({
    required this.data,
    required this.backgroundColor,
    required this.isActive,
  });

  final WeeklyRecapData data;
  final Color backgroundColor;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return _SlideScaffold(
      backgroundColor: backgroundColor,
      seed: 6,
      decorativeText: '✓',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _RecapReveal(
            isActive: isActive,
            child: Text(
              'NICE WORK',
              textAlign: TextAlign.center,
              style: _recapKickerStyle(alpha: 0.65),
            ),
          ),
          const SizedBox(height: 16),
          _RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 100),
            child: const Text(
              'Nice work tracking',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kWeeklyRecapInk,
                fontSize: 40,
                fontWeight: FontWeight.w900,
                height: 1.1,
                letterSpacing: -0.8,
              ),
            ),
          ),
          const SizedBox(height: 16),
          _RecapReveal(
            isActive: isActive,
            delay: const Duration(milliseconds: 200),
            child: Text(
              data.hasActivity
                  ? 'Keep logging to sharpen your insights'
                  : 'Add a log to build your streak',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _kWeeklyRecapInk.withValues(alpha: 0.62),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.35,
              ),
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
          ..color = _kWeeklyRecapInk.withValues(alpha: 0.12)
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
        ..color = _kWeeklyRecapInk.withValues(alpha: 0.07)
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
                color: _kWeeklyRecapInk.withValues(alpha: 0.07),
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

String _formatWeekRangeKicker(DateTime weekStart, DateTime weekEnd) {
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
