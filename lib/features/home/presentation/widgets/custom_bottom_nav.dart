import 'package:baht/features/settings/domain/entities/bottom_nav_style.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    required this.navigationShell,
    required this.onAddPressed,
    required this.style,
    super.key,
  });

  final StatefulNavigationShell navigationShell;
  final VoidCallback onAddPressed;
  final BottomNavStyle style;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case BottomNavStyle.floating:
        return _FloatingBottomNav(
          navigationShell: navigationShell,
          onAddPressed: onAddPressed,
        );
      case BottomNavStyle.standard:
        return _StandardBottomNav(
          navigationShell: navigationShell,
          onAddPressed: onAddPressed,
        );
    }
  }
}

class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav({
    required this.navigationShell,
    required this.onAddPressed,
  });

  final StatefulNavigationShell navigationShell;
  final VoidCallback onAddPressed;

  static const _activeColor = Color(0xFF2D4A3E);

  void _handleTabTap(int index, {required bool isActive}) {
    if (isActive) return;
    navigationShell.goBranch(index);
  }

  Widget _buildNavIcon({
    required VoidCallback onTap,
    required HeroIcons icon,
    required String label,
    required String semanticLabel,
    required bool isActive,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isActive)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _activeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: HeroIcon(
                  icon,
                  style: HeroIconStyle.solid,
                  color: Colors.white,
                  size: 22,
                  semanticLabel: semanticLabel,
                ),
              )
            else
              HeroIcon(
                icon,
                style: HeroIconStyle.outline,
                color: Colors.grey[500]!,
                size: 24,
                semanticLabel: semanticLabel,
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.black87 : Colors.grey[500],
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onAddPressed,
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFFE05C4B),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final isHomeActive = currentIndex == 0;
    final isInsightActive = currentIndex == 1;
    final isScheduleActive = currentIndex == 2;
    final isSettingsActive = currentIndex == 3;

    return Container(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: true,
        minimum: const EdgeInsets.only(bottom: 8),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildNavIcon(
                    onTap: () => _handleTabTap(0, isActive: isHomeActive),
                    icon: HeroIcons.home,
                    label: 'Home',
                    semanticLabel: 'Dashboard',
                    isActive: isHomeActive,
                  ),
                ),
                Expanded(
                  child: _buildNavIcon(
                    onTap: () => _handleTabTap(1, isActive: isInsightActive),
                    icon: HeroIcons.chartBar,
                    label: 'Analytics',
                    semanticLabel: 'Insight',
                    isActive: isInsightActive,
                  ),
                ),
                _buildAddButton(),
                Expanded(
                  child: _buildNavIcon(
                    onTap: () => _handleTabTap(2, isActive: isScheduleActive),
                    icon: HeroIcons.rectangleStack,
                    label: 'Schedule',
                    semanticLabel: 'Scheduled payments',
                    isActive: isScheduleActive,
                  ),
                ),
                Expanded(
                  child: _buildNavIcon(
                    onTap: () => _handleTabTap(3, isActive: isSettingsActive),
                    icon: HeroIcons.cog6Tooth,
                    label: 'Settings',
                    semanticLabel: 'Settings',
                    isActive: isSettingsActive,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StandardBottomNav extends StatelessWidget {
  const _StandardBottomNav({
    required this.navigationShell,
    required this.onAddPressed,
  });

  final StatefulNavigationShell navigationShell;
  final VoidCallback onAddPressed;

  void _handleTabTap(int index, {required bool isActive}) {
    if (isActive) return;
    navigationShell.goBranch(index);
  }

  Widget _buildNavIcon({
    required VoidCallback onTap,
    required HeroIcons icon,
    required String semanticLabel,
    required bool isActive,
  }) {
    final color = isActive ? Colors.black : Colors.grey[500]!;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 56,
        child: Center(
          child: HeroIcon(
            icon,
            style: isActive ? HeroIconStyle.solid : HeroIconStyle.outline,
            color: color,
            size: 24,
            semanticLabel: semanticLabel,
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onAddPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.grey[900],
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.add, color: Colors.white, size: 26),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final isHomeActive = currentIndex == 0;
    final isInsightActive = currentIndex == 1;
    final isScheduleActive = currentIndex == 2;
    final isSettingsActive = currentIndex == 3;

    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                offset: const Offset(0, -6),
                blurRadius: 16,
                spreadRadius: 0,
              ),
            ],
          ),
          child: SizedBox(
            height: 56,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildNavIcon(
                      onTap: () => _handleTabTap(0, isActive: isHomeActive),
                      icon: HeroIcons.home,
                      semanticLabel: 'Dashboard',
                      isActive: isHomeActive,
                    ),
                  ),
                  Expanded(
                    child: _buildNavIcon(
                      onTap: () => _handleTabTap(1, isActive: isInsightActive),
                      icon: HeroIcons.chartBar,
                      semanticLabel: 'Insight',
                      isActive: isInsightActive,
                    ),
                  ),
                  _buildAddButton(),
                  Expanded(
                    child: _buildNavIcon(
                      onTap: () => _handleTabTap(2, isActive: isScheduleActive),
                      icon: HeroIcons.rectangleStack,
                      semanticLabel: 'Scheduled payments',
                      isActive: isScheduleActive,
                    ),
                  ),
                  Expanded(
                    child: _buildNavIcon(
                      onTap: () => _handleTabTap(3, isActive: isSettingsActive),
                      icon: HeroIcons.cog6Tooth,
                      semanticLabel: 'Settings',
                      isActive: isSettingsActive,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (bottomInset > 0)
          ColoredBox(
            color: Colors.white,
            child: SizedBox(height: bottomInset, width: double.infinity),
          ),
      ],
    );
  }
}
