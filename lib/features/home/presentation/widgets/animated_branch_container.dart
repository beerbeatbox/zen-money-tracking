import 'package:flutter/material.dart';

/// Branch container for [StatefulShellRoute] that slides the incoming branch
/// horizontally based on index direction, matching the default IndexedStack
/// state preservation (inactive branches stay mounted offstage with ticker off).
class AnimatedBranchContainer extends StatefulWidget {
  const AnimatedBranchContainer({
    required this.currentIndex,
    required this.children,
    super.key,
  });

  final int currentIndex;
  final List<Widget> children;

  @override
  State<AnimatedBranchContainer> createState() =>
      _AnimatedBranchContainerState();
}

class _AnimatedBranchContainerState extends State<AnimatedBranchContainer>
    with SingleTickerProviderStateMixin {
  static const _duration = Duration(milliseconds: 300);

  late int _currentIndex;
  int _previousIndex = 0;
  bool _isForward = true;

  late final AnimationController _controller;
  late Animation<Offset> _outgoing;
  late Animation<Offset> _incoming;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.currentIndex;
    _previousIndex = _currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: _duration,
    )..addStatusListener(_onAnimationStatus);
    final placeheld = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(_controller);
    _outgoing = placeheld;
    _incoming = placeheld;
  }

  void _onAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      setState(() {
        // Rest frame: only [current] tab is "on stage".
        _previousIndex = _currentIndex;
      });
    }
  }

  void _setupTransitionAnimations() {
    final curve = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
    if (_isForward) {
      _outgoing = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-1, 0),
      ).animate(curve);
      _incoming = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(curve);
    } else {
      _outgoing = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(1, 0),
      ).animate(curve);
      _incoming = Tween<Offset>(
        begin: const Offset(-1, 0),
        end: Offset.zero,
      ).animate(curve);
    }
  }

  @override
  void didUpdateWidget(AnimatedBranchContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex == _currentIndex) return;
    if (widget.children.length != oldWidget.children.length) {
      _currentIndex = widget.currentIndex;
      _previousIndex = _currentIndex;
      return;
    }
    if (_controller.isAnimating) {
      _controller.value = 1.0;
    }
    _previousIndex = _currentIndex;
    _currentIndex = widget.currentIndex;
    _isForward = _currentIndex > _previousIndex;
    _setupTransitionAnimations();
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.removeStatusListener(_onAnimationStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return child!;
      },
      child: _buildStack(),
    );
  }

  Widget _buildStack() {
    final n = widget.children.length;
    assert(n > 0, 'AnimatedBranchContainer requires at least one child branch.');
    if (_currentIndex < 0 || _currentIndex >= n) {
      return widget.children[0];
    }

    if (_controller.isAnimating) {
      return Stack(
        fit: StackFit.expand,
        clipBehavior: Clip.hardEdge,
        children: [
          for (int i = 0; i < n; i++)
            if (i != _previousIndex && i != _currentIndex)
              Offstage(
                offstage: true,
                child: TickerMode(
                  enabled: false,
                  child: widget.children[i],
                ),
              ),
          Positioned.fill(
            child: SlideTransition(
              position: _outgoing,
              child: TickerMode(
                enabled: true,
                child: widget.children[_previousIndex],
              ),
            ),
          ),
          Positioned.fill(
            child: SlideTransition(
              position: _incoming,
              child: TickerMode(
                enabled: true,
                child: widget.children[_currentIndex],
              ),
            ),
          ),
        ],
      );
    }

    // At rest: mirror go_router's IndexedStack + Offstage + TickerMode.
    return Stack(
      fit: StackFit.expand,
      children: [
        for (int i = 0; i < n; i++)
          Offstage(
            offstage: i != _currentIndex,
            child: TickerMode(
              enabled: i == _currentIndex,
              child: widget.children[i],
            ),
          ),
      ],
    );
  }
}
