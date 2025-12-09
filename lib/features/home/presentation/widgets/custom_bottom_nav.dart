import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  void _handleSettingsTap(BuildContext context, {required bool isActive}) {
    if (isActive) return; // avoid re-triggering same route on iOS
    context.go(AppRouter.settings.path);
  }

  void _handleHomeTap(BuildContext context, {required bool isActive}) {
    if (isActive) return;
    context.go(AppRouter.dashboard.path);
  }

  void _handleBudgetTap(BuildContext context, {required bool isActive}) {
    if (isActive) return;
    context.go(AppRouter.budget.path);
  }

  void _handleReportTap(BuildContext context, {required bool isActive}) {
    if (isActive) return;
    context.go(AppRouter.report.path);
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
    ).onTap(onTap: onTap, behavior: HitTestBehavior.opaque);
  }

  Widget _buildSettingsButton(BuildContext context, {required bool isActive}) {
    return _buildNavItem(
      onTap: () => _handleSettingsTap(context, isActive: isActive),
      icon: HeroIcons.cog6Tooth,
      semanticLabel: 'Settings',
      label: 'Settings',
      isActive: isActive,
    );
  }

  Widget _buildHomeButton(BuildContext context, {required bool isActive}) {
    return _buildNavItem(
      onTap: () => _handleHomeTap(context, isActive: isActive),
      icon: HeroIcons.home,
      semanticLabel: 'Home',
      label: 'Home',
      isActive: isActive,
    );
  }

  Widget _buildReportButton(BuildContext context, {required bool isActive}) {
    return _buildNavItem(
      onTap: () => _handleReportTap(context, isActive: isActive),
      icon: HeroIcons.chartBar,
      semanticLabel: 'Report',
      label: 'Report',
      isActive: isActive,
    );
  }

  Widget _buildBudgetButton(BuildContext context, {required bool isActive}) {
    return _buildNavItem(
      onTap: () => _handleBudgetTap(context, isActive: isActive),
      icon: HeroIcons.wallet,
      semanticLabel: 'Budget',
      label: 'Budget',
      isActive: isActive,
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isHomeActive = location.startsWith(AppRouter.dashboard.path);
    final isBudgetActive = location.startsWith(AppRouter.budget.path);
    final isReportActive = location.startsWith(AppRouter.report.path);
    final isSettingsActive = location.startsWith(AppRouter.settings.path);

    return SafeArea(
      top: false,
      child: DecoratedBox(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              spreadRadius: 1,
              offset: const Offset(0, -2),
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
              _buildHomeButton(context, isActive: isHomeActive),
              _buildReportButton(context, isActive: isReportActive),
              const SizedBox(width: 32), // gap for the FAB notch
              _buildBudgetButton(context, isActive: isBudgetActive),
              _buildSettingsButton(context, isActive: isSettingsActive),
            ],
          ),
        ),
      ),
    );
  }
}
