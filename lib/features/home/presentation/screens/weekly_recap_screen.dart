import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:anti/core/utils/local_week.dart';
import 'package:anti/features/home/domain/entities/weekly_recap_data.dart';
import 'package:anti/features/home/presentation/controllers/weekly_recap_controller.dart';
import 'package:anti/features/home/presentation/utils/weekly_review_aggregation.dart';
import 'package:anti/features/home/presentation/widgets/weekly_money_review/weekly_recap_chrome.dart';
import 'package:anti/features/home/presentation/widgets/weekly_money_review/weekly_review_slides.dart';

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

class WeeklyRecapScreen extends ConsumerStatefulWidget {
  const WeeklyRecapScreen({super.key, required this.recapWeekAnchor});

  /// Any local date in the week to show; the screen uses that week (Mon–Sun).
  final DateTime recapWeekAnchor;

  @override
  ConsumerState<WeeklyRecapScreen> createState() => _WeeklyRecapScreenState();
}

class _WeeklyRecapScreenState extends ConsumerState<WeeklyRecapScreen> {
  @override
  Widget build(BuildContext context) {
    final monday =
        startOfLocalWeekMonday(normalizeToLocalDate(widget.recapWeekAnchor));
    final asyncData = ref.watch(weeklyRecapControllerProvider(monday));

    return asyncData.when(
      data: (WeeklyRecapData data) => _WeeklyRecapStoryBody(recap: data),
      loading:
          () => const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: kWeeklyRecapInk),
            ),
            backgroundColor: Color(0xFFF5F5F5),
          ),
      error:
          (_, __) => Scaffold(
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF5F5F5),
              leading: IconButton(
                icon: const Icon(Icons.close, color: kWeeklyRecapInk),
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
                    color: kWeeklyRecapInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
    );
  }
}

class _WeeklyRecapStoryBody extends StatefulWidget {
  const _WeeklyRecapStoryBody({required this.recap});

  final WeeklyRecapData recap;

  @override
  State<_WeeklyRecapStoryBody> createState() => _WeeklyRecapStoryBodyState();
}

class _WeeklyRecapStoryBodyState extends State<_WeeklyRecapStoryBody> {
  late final PageController _pageController;

  int _pageIndex = 0;
  DateTime? _pointerDownTime;
  Offset? _pointerDownPosition;

  int get _slideCount => weeklyReviewSlideCount(widget.recap);

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    final colors = weeklyReviewSlideBackgrounds(
      slideCount: _slideCount,
      hasActivity: widget.recap.hasActivity,
    );

    final safeIndex = _pageIndex.clamp(0, _slideCount - 1);

    return Scaffold(
      backgroundColor: colors[safeIndex],
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
                child: StoryProgressBar(
                  segmentCount: _slideCount,
                  activeIndex: _pageIndex,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(
                    Icons.close,
                    color: kWeeklyRecapInk,
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
                  children: buildWeeklyReviewSlides(
                    data: widget.recap,
                    colors: colors,
                    pageIndex: _pageIndex,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
