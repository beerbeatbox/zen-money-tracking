import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    required this.navigationShell,
    required this.onAddPressed,
    super.key,
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 64,
        child: Center(
          child: HeroIcon(
            icon,
            style: isActive ? HeroIconStyle.solid : HeroIconStyle.outline,
            color: Colors.white,
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
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.add, color: Colors.grey[900], size: 28),
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
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
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
    );
  }
}
