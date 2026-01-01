import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _handleTabTap(int index, {required bool isActive}) {
    if (isActive) return;
    navigationShell.goBranch(index);
  }

  Text _buildNavLabel(String label, {required bool isActive}) {
    return Text(
      label,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
        color: Colors.black.withValues(alpha: isActive ? 1 : 0.6),
        height: 1.1,
      ),
    );
  }

  Widget _buildNavItem({
    required VoidCallback onTap,
    required HeroIcons icon,
    required String semanticLabel,
    required String label,
    required bool isActive,
  }) {
    const hitWidth = 56.0;
    const hitHeight = 64.0;

    return SizedBox(
      width: hitWidth,
      height: hitHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          HeroIcon(
            icon,
            style: isActive ? HeroIconStyle.solid : HeroIconStyle.outline,
            color: Colors.black,
            size: 24,
            semanticLabel: semanticLabel,
          ),
          const SizedBox(height: 6),
          _buildNavLabel(label, isActive: isActive),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context, {required bool isActive}) {
    return _buildNavItem(
      onTap: () => _handleTabTap(3, isActive: isActive),
      icon: HeroIcons.cog6Tooth,
      semanticLabel: 'Settings',
      label: 'Settings',
      isActive: isActive,
    );
  }

  Widget _buildHomeButton(BuildContext context, {required bool isActive}) {
    return _buildNavItem(
      onTap: () => _handleTabTap(0, isActive: isActive),
      icon: HeroIcons.home,
      semanticLabel: 'Home',
      label: 'Home',
      isActive: isActive,
    );
  }

  Widget _buildReportButton(BuildContext context, {required bool isActive}) {
    return _buildNavItem(
      onTap: () => _handleTabTap(1, isActive: isActive),
      icon: HeroIcons.chartBar,
      semanticLabel: 'Report',
      label: 'Report',
      isActive: isActive,
    );
  }

  Widget _buildBudgetButton(BuildContext context, {required bool isActive}) {
    return _buildNavItem(
      onTap: () => _handleTabTap(2, isActive: isActive),
      icon: HeroIcons.wallet,
      semanticLabel: 'Budget',
      label: 'Budget',
      isActive: isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;
    final isHomeActive = currentIndex == 0;
    final isReportActive = currentIndex == 1;
    final isBudgetActive = currentIndex == 2;
    final isSettingsActive = currentIndex == 3;

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              spreadRadius: 2,
              offset: const Offset(0, -1),
            ),
          ],
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          color: Colors.white,
          elevation: 0, // box shadow handles depth
          surfaceTintColor: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleTabTap(0, isActive: isHomeActive),
                child: _buildHomeButton(context, isActive: isHomeActive),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleTabTap(1, isActive: isReportActive),
                child: _buildReportButton(context, isActive: isReportActive),
              ),
              const SizedBox(width: 32), // gap for the FAB notch
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleTabTap(2, isActive: isBudgetActive),
                child: _buildBudgetButton(context, isActive: isBudgetActive),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _handleTabTap(3, isActive: isSettingsActive),
                child: _buildSettingsButton(
                  context,
                  isActive: isSettingsActive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
