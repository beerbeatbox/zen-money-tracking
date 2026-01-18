import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/router/app_router.dart';

import '../../domain/entities/feature_flags.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featureFlagsAsync = ref.watch(onboardingControllerProvider);
    final isLoading = featureFlagsAsync.isLoading;

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          const _BackgroundSection(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 600),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              );

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offsetAnimation, child: child),
              );
            },
            child: featureFlagsAsync.when(
              // AnimatedSwitcher animates from "empty" to content when loading finishes
              loading: () => const SizedBox.shrink(),
              error:
                  (error, stack) => _ErrorView(
                    key: const ValueKey('error'),
                    error: error.toString(),
                    onRetry:
                        () =>
                            ref
                                .read(onboardingControllerProvider.notifier)
                                .refresh(),
                  ),
              data:
                  (featureFlags) => _OnboardingContent(
                    key: const ValueKey('content'),
                    featureFlags: featureFlags,
                  ),
            ),
          ),
          if (isLoading) const _LoadingView(key: ValueKey('loading')),
        ],
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Color(0xFF1A202C)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Color(0xFF1A202C),
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A202C),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Please try again',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ).paddingSymmetric(horizontal: 32),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A202C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  final FeatureFlags featureFlags;

  const _OnboardingContent({super.key, required this.featureFlags});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const _FloatingElementsSection(),
        _MainContentSection(featureFlags: featureFlags),
      ],
    );
  }
}

class _BackgroundSection extends StatelessWidget {
  const _BackgroundSection();

  @override
  Widget build(BuildContext context) {
    return Container(decoration: const BoxDecoration(color: Colors.white));
  }
}

class _FloatingElementsSection extends StatefulWidget {
  const _FloatingElementsSection();

  @override
  State<_FloatingElementsSection> createState() =>
      _FloatingElementsSectionState();
}

class _FloatingElementsSectionState extends State<_FloatingElementsSection> {
  // Pool of expense-related emojis (no graphs)
  static const List<String> _expenseEmojis = [
    // Food & Drinks
    '🍜', '🍔', '🍕', '🍣', '🍱', '🥗', '🍝', '🍛', '🥑', '🌮', '🥟', '🍎',
    '🥬', '🫐', '🌽', '🍞', '🥐', '🧁', '🍩', '🍪',
    '☕', '🧋', '🍺', '🍷', '🧃', '🥤',
    // Shopping
    '🛍️', '🛒', '👕', '👟', '💄', '🎁', '👜', '👗',
    // Housing & Utilities
    '🏠', '💡', '🔌', '💧', '📺', '🛋️', '🛏️', '🚿',
    // Transportation
    '🚗', '⛽', '🚌', '🚇', '✈️', '🚕', '🚲', '🛵',
    // Entertainment
    '🎬', '🎮', '🎵', '📚', '🎭', '🎪', '🎯',
    // Health & Personal
    '💊', '🏥', '💇', '🧴', '🏋️', '💅',
    // Finance & Bills
    '💵', '💳', '🧾', '📝', '💰', '💸', '🏦',
    // Others
    '📱', '💻', '🌴', '🎓', '✂️', '🔧',
  ];

  late final List<String> _selectedEmojis;

  @override
  void initState() {
    super.initState();
    // Randomly select 13 unique emojis
    final random = math.Random();
    final shuffled = List<String>.from(_expenseEmojis)..shuffle(random);
    _selectedEmojis = shuffled.take(13).toList();
  }

  /// Calculates responsive icon size based on screen width and device pixel ratio
  /// to prevent icons from appearing too large on small DPI screens
  double _getResponsiveSize(double baseSize, BuildContext context) {
    const double referenceWidth = 200.0; // Standard iPhone width
    final screenWidth = MediaQuery.of(context).size.width;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // Scale based on screen width (smaller screens = smaller icons)
    final widthScale = screenWidth / referenceWidth;

    // Scale based on device pixel ratio (lower DPI = scale up, higher DPI = scale down)
    // Clamp DPR between 1.0 and 3.0 to prevent extreme scaling
    final dprScale = 1.0 / devicePixelRatio.clamp(1.0, 3.0);

    return baseSize * widthScale * dprScale;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate responsive sizes for all icons
    final size30 = _getResponsiveSize(30, context);
    final size40 = _getResponsiveSize(40, context);
    final size45 = _getResponsiveSize(45, context);
    final size50 = _getResponsiveSize(50, context);
    final size55 = _getResponsiveSize(55, context);
    final size60 = _getResponsiveSize(60, context);
    final size65 = _getResponsiveSize(65, context);
    final size70 = _getResponsiveSize(70, context);
    final size75 = _getResponsiveSize(75, context);
    final size100 = _getResponsiveSize(100, context);

    final centerPosition =
        (screenWidth - size65) / 2; // Center the emoji using responsive size

    return Stack(
      children: [
        // === TOP ROW ===
        // Top left corner
        _FloatingItem(
          emoji: _selectedEmojis[0],
          top: 40,
          left: 30,
          angle: -0.1,
          size: size45,
        ),
        // Top center (blurred)
        _FloatingItem(
          emoji: _selectedEmojis[1],
          top: 55,
          left: 150,
          angle: 0.15,
          size: size40,
          blur: true,
        ),
        // Top right (large)
        _FloatingItem(
          emoji: _selectedEmojis[2],
          top: 80,
          right: 60,
          angle: 0.1,
          size: size70,
        ),

        // === UPPER SIDES ===
        // Left side upper
        _FloatingItem(
          emoji: _selectedEmojis[3],
          top: 120,
          left: -15,
          angle: -0.15,
          size: size60,
        ),
        // Left side lower (blurred)
        _FloatingItem(
          emoji: _selectedEmojis[4],
          top: 200,
          left: 100,
          size: size45,
          blur: true,
        ),
        // Right side (large)
        _FloatingItem(
          emoji: _selectedEmojis[5],
          top: 160,
          right: -30,
          size: size100,
        ),

        // === AROUND TITLE (left & right sides) ===
        // Large left
        _FloatingItem(
          emoji: _selectedEmojis[6],
          top: 340,
          left: -40,
          size: size100,
        ),
        // Right of title
        _FloatingItem(
          emoji: _selectedEmojis[7],
          top: 400,
          right: 20,
          angle: 0.1,
          size: size50,
        ),

        // === CENTER BELOW TITLE ===
        // Blurred, center
        _FloatingItem(
          emoji: _selectedEmojis[8],
          top: 130,
          left: centerPosition,
          size: size65,
          blur: true,
        ),

        // === BOTTOM AREA ===
        // Left small
        _FloatingItem(
          emoji: _selectedEmojis[9],
          bottom: 340,
          left: 90,
          size: size30,
        ),
        // Right
        _FloatingItem(
          emoji: _selectedEmojis[10],
          bottom: 280,
          right: 140,
          angle: -0.1,
          size: size55,
        ),
        // Bottom left corner (blurred)
        _FloatingItem(
          emoji: _selectedEmojis[11],
          bottom: 180,
          left: -20,
          blur: true,
          size: size75,
        ),
        // Bottom right corner (blurred)
        _FloatingItem(
          emoji: _selectedEmojis[12],
          bottom: 160,
          right: -15,
          blur: true,
          size: size65,
        ),
      ],
    );
  }
}

class _MainContentSection extends StatelessWidget {
  final FeatureFlags featureFlags;

  const _MainContentSection({required this.featureFlags});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          const Spacer(flex: 3),
          _TitleSection(showAIBadge: featureFlags.showAIBadge),
          const Spacer(flex: 4),
          _ActionButtonsSection(
            buttonText: featureFlags.primaryButtonText,
            showLanguageSelector: featureFlags.enableLanguageSelector,
          ),
        ],
      ),
    );
  }
}

class _TitleSection extends StatelessWidget {
  final bool showAIBadge;

  const _TitleSection({required this.showAIBadge});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Money Tracker',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w800,
            color: Colors.black,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),
        if (showAIBadge) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'with',
                style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 12),
              const _AIBadge(),
            ],
          ),
        ],
      ],
    ).paddingSymmetric(horizontal: 24.0);
  }
}

class _ActionButtonsSection extends StatelessWidget {
  final String buttonText;
  final bool showLanguageSelector;

  const _ActionButtonsSection({
    required this.buttonText,
    required this.showLanguageSelector,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showLanguageSelector) const _LanguageSelector(),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              context.go(AppRouter.dashboard.path);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A202C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            child: Text(
              buttonText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ).paddingSymmetric(horizontal: 32.0).paddingOnly(top: 16, bottom: 32),
      ],
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'EN',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            SizedBox(width: 6),
            Text('🇬🇧', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    ).paddingOnly(left: 32);
  }
}

class _FloatingItem extends StatefulWidget {
  final String emoji;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final double angle;
  final double size;
  final bool blur;

  const _FloatingItem({
    required this.emoji,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.angle = 0,
    this.size = 40,
    this.blur = false,
  });

  @override
  State<_FloatingItem> createState() => _FloatingItemState();
}

class _FloatingItemState extends State<_FloatingItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _bounceAnimation;
  late final double _bounceDistance;
  late final int _duration;

  @override
  void initState() {
    super.initState();

    final random = math.Random();

    // Random bounce distance between 6 and 16 pixels
    _bounceDistance = 6 + random.nextDouble() * 10;

    // Random duration between 1500ms and 3000ms
    _duration = 1500 + random.nextInt(1500);

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _duration),
    );

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: -_bounceDistance,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // All items bounce with random timing
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget content =
        widget.blur
            ? ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
              child: Opacity(
                opacity: 0.7,
                child: Text(
                  widget.emoji,
                  style: TextStyle(fontSize: widget.size),
                ),
              ),
            )
            : Text(widget.emoji, style: TextStyle(fontSize: widget.size));

    content = Transform.rotate(angle: widget.angle, child: content);

    content = AnimatedBuilder(
      animation: _bounceAnimation,
      child: content,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _bounceAnimation.value),
          child: child,
        );
      },
    );

    return Positioned(
      top: widget.top,
      bottom: widget.bottom,
      left: widget.left,
      right: widget.right,
      child: content,
    );
  }
}

class _AIBadge extends StatelessWidget {
  const _AIBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3), // Border thickness
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00D4FF), // Cyan
            Color(0xFF00FF88), // Green
            Color(0xFFFFEB3B), // Yellow
            Color(0xFFFF6B6B), // Red/Pink
            Color(0xFFFF00FF), // Magenta
            Color(0xFF6B5BFF), // Purple
          ],
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(27),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 4),
            const Text('✨', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
