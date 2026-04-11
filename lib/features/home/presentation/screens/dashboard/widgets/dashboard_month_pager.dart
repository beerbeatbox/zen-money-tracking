import 'package:anti/core/constants/app_sizes.dart';
import 'package:anti/features/settings/domain/entities/bottom_nav_style.dart';
import 'package:anti/features/settings/presentation/controllers/bottom_nav_style_setting_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardMonthPager extends StatefulWidget {
  const DashboardMonthPager({
    super.key,
    required this.selectedMonth,
    required this.header,
    required this.monthContent,
    required this.onSwipeToPreviousMonth,
    required this.onSwipeToNextMonth,
    this.onRefresh,
    this.padding = const EdgeInsets.all(24),
  });

  final DateTime selectedMonth;
  final Widget header;
  final Widget monthContent;
  final VoidCallback onSwipeToPreviousMonth;
  final VoidCallback onSwipeToNextMonth;
  final Future<void> Function()? onRefresh;
  final EdgeInsets padding;

  @override
  State<DashboardMonthPager> createState() => _DashboardMonthPagerState();
}

class _DashboardMonthPagerState extends State<DashboardMonthPager>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final ScrollController _scrollController;
  double _dragOffset = 0.0;
  int _lastSwipeDirection = 0; // -1 = next, 1 = previous
  Animation<double>? _currentAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    if (_currentAnimation != null) {
      _currentAnimation!.removeListener(_animationListener);
      _currentAnimation = null;
    }
    _animationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _snapToTop() async {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 0) {
      _scrollController.jumpTo(0);
      return;
    }

    await _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 1),
      curve: Curves.linear,
    );
  }

  Future<void> _handleRefresh() async {
    if (widget.onRefresh == null) return;
    await _snapToTop();
    await widget.onRefresh!.call();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_currentAnimation != null) {
      _currentAnimation!.removeListener(_animationListener);
      _currentAnimation = null;
    }
    _animationController.stop();
    _animationController.reset();

    setState(() {
      final delta = details.primaryDelta ?? 0;
      _dragOffset += delta;
      final screenWidth = MediaQuery.of(context).size.width;
      _dragOffset = _dragOffset.clamp(-screenWidth, screenWidth);
    });
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final screenWidth = MediaQuery.of(context).size.width;
    final threshold = screenWidth * 0.25;
    final velocity = details.primaryVelocity ?? 0;

    if (_dragOffset.abs() > threshold || velocity.abs() > 500) {
      final isSwipeLeft = _dragOffset < 0 || velocity < 0;
      final targetOffset = isSwipeLeft ? -screenWidth : screenWidth;

      _animateToOffset(targetOffset, () {
        if (!mounted) return;

        if (isSwipeLeft) {
          setState(() {
            _lastSwipeDirection = -1; // Next month (slide from right)
          });
          widget.onSwipeToNextMonth();
        } else {
          setState(() {
            _lastSwipeDirection = 1; // Previous month (slide from left)
          });
          widget.onSwipeToPreviousMonth();
        }

        setState(() {
          _dragOffset = 0.0;
        });
      });
    } else {
      _animateBackToCenter();
    }
  }

  void _onHorizontalDragCancel() {
    _animateBackToCenter();
  }

  void _animateBackToCenter() {
    _animateToOffset(0.0, () {
      if (mounted) {
        _animationController.reset();
      }
    });
  }

  void _animationListener() {
    if (mounted && _currentAnimation != null) {
      setState(() {
        _dragOffset = _currentAnimation!.value;
      });
    }
  }

  void _animateToOffset(double targetOffset, VoidCallback? onComplete) {
    final startOffset = _dragOffset;

    if (_currentAnimation != null) {
      _currentAnimation!.removeListener(_animationListener);
    }

    _currentAnimation = Tween<double>(
      begin: startOffset,
      end: targetOffset,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _currentAnimation!.addListener(_animationListener);

    _animationController.forward(from: 0.0).then((_) {
      if (mounted) {
        if (_currentAnimation != null) {
          _currentAnimation!.removeListener(_animationListener);
          _currentAnimation = null;
        }
        _animationController.reset();
        onComplete?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Consumer(
          builder: (context, ref, _) {
            final navStyle =
                ref.watch(bottomNavStyleSettingControllerProvider).value ??
                BottomNavStyle.floating;
            final bottomInset = Sizes.bottomNavInset(context, navStyle);

            final scrollable = SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: widget.padding.copyWith(
                bottom: widget.padding.bottom + bottomInset,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  widget.header,
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      final slideOffset =
                          _lastSwipeDirection == 0
                              ? const Offset(0.2, 0)
                              : Offset(_lastSwipeDirection * 0.2, 0);

                      final tween = Tween<Offset>(
                        begin: slideOffset,
                        end: Offset.zero,
                      ).chain(CurveTween(curve: Curves.easeOutCubic));

                      final offsetAnimation = animation.drive(tween);

                      return SlideTransition(
                        position: offsetAnimation,
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Transform.translate(
                      offset: Offset(_dragOffset, 0),
                      child: widget.monthContent,
                    ),
                  ),
                ],
              ),
            );

            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              onHorizontalDragCancel: _onHorizontalDragCancel,
              child: SizedBox(
                height: constraints.maxHeight,
                child:
                    widget.onRefresh == null
                        ? scrollable
                        : RefreshIndicator(
                          onRefresh: _handleRefresh,
                          color: Colors.black,
                          child: scrollable,
                        ),
              ),
            );
          },
        );
      },
    );
  }
}
