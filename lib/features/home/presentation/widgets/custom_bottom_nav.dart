import 'dart:async';

import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/router/app_router.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/presentation/controllers/expense_log_actions_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import 'number_keyboard_bottom_sheet.dart';
import 'outlined_surface.dart';

class CustomBottomNav extends ConsumerStatefulWidget {
  const CustomBottomNav({super.key});

  @override
  ConsumerState<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends ConsumerState<CustomBottomNav> {
  bool _addPressed = false;
  OverlayEntry? _snackEntry;
  Timer? _snackTimer;

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _removeSnack() {
    _snackTimer?.cancel();
    _snackTimer = null;
    _snackEntry?.remove();
    _snackEntry = null;
  }

  void _showSnack(BuildContext context, String message) {
    _removeSnack();

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    final topPadding = MediaQuery.of(context).padding.top;

    _snackEntry = OverlayEntry(
      builder:
          (_) => Positioned(
            top: topPadding + 12,
            left: 16,
            right: 16,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
    );

    overlay.insert(_snackEntry!);
    _snackTimer = Timer(const Duration(seconds: 2), _removeSnack);
  }

  Future<void> _openKeyboard(BuildContext context) async {
    await showNumberKeyboardBottomSheet(
      context,
      onSubmit: (sheetContext, rawValue, isExpense) async {
        final parsed = double.tryParse(rawValue);
        if (parsed == null) {
          _showSnack(sheetContext, 'Please enter a valid number.');
          return false;
        }
        if (parsed <= 0) {
          _showSnack(
            sheetContext,
            'Add an amount above zero to log your spending.',
          );
          return false;
        }

        final now = DateTime.now();
        final amount = isExpense ? -parsed.abs() : parsed.abs();
        final log = ExpenseLog(
          id: now.microsecondsSinceEpoch.toString(),
          title: 'Quick entry',
          timeLabel: _formatTimeLabel(now),
          category: 'General',
          amount: amount,
          createdAt: now,
        );

        try {
          await ref.read(addExpenseLogActionProvider(log).future);
          return true;
        } catch (error) {
          _showSnack(sheetContext, "Let's try that again.");
          return false;
        }
      },
    );
  }

  @override
  void dispose() {
    _removeSnack();
    super.dispose();
  }

  void _setAddPressed(bool value) {
    if (_addPressed == value) return;
    setState(() => _addPressed = value);
  }

  Future<void> _releaseAddWithPause() async {
    await Future.delayed(const Duration(milliseconds: 90));
    if (!mounted) return;
    _setAddPressed(false);
  }

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
    const hitWidth = 48.0;
    const hitHeight = 80.0;

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

  Widget _buildAddButton(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedSurface(
          width: 64,
          height: 64,
          shape: BoxShape.circle,
          isPressed: _addPressed,
          pressedColor: const Color(0xFFF7F7F7),
          duration: const Duration(milliseconds: 80),
          curve: Curves.easeOut,
          child: const Icon(Icons.add, color: Colors.black, size: 28),
        ),
      ],
    ).onTap(
      onTapDown: (_) => _setAddPressed(true),
      onTapUp: (_) => _releaseAddWithPause(),
      onTapCancel: () => _releaseAddWithPause(),
      onTap: () => _openKeyboard(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isHomeActive = location.startsWith(AppRouter.dashboard.path);
    final isBudgetActive = location.startsWith(AppRouter.budget.path);
    final isReportActive = location.startsWith(AppRouter.report.path);
    final isSettingsActive = location.startsWith(AppRouter.settings.path);

    const barHeight = 80.0;
    const addButtonSize = 64.0;
    const buttonSpacing = 32.0;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: barHeight,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: barHeight,
              child: CustomPaint(painter: _CurvedNavPainter()),
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: barHeight,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildHomeButton(context, isActive: isHomeActive),
                  _buildReportButton(context, isActive: isReportActive),
                  const SizedBox(width: buttonSpacing),
                  _buildBudgetButton(context, isActive: isBudgetActive),
                  _buildSettingsButton(context, isActive: isSettingsActive),
                ],
              ),
            ),
            Positioned(
              top: -(addButtonSize / 2),
              left: 0,
              right: 0,
              child: Center(child: _buildAddButton(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurvedNavPainter extends CustomPainter {
  const _CurvedNavPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const addButtonDiameter = 64.0;
    final notchRadius = addButtonDiameter / 2; // match add button radius
    const top = 0.0;
    final bottom = size.height;
    const left = 0.0;
    final right = size.width;
    final centerX = size.width / 2;

    final baseRect = RRect.fromRectAndCorners(
      Rect.fromLTRB(left, top, right, bottom),
      topLeft: Radius.zero,
      topRight: Radius.zero,
      bottomLeft: Radius.zero,
      bottomRight: Radius.zero,
    );

    final notchRect = Rect.fromCircle(
      center: Offset(centerX, top),
      radius: notchRadius,
    );

    // Draw the bar then punch a transparent hole matching the add button radius.
    final layerBounds = Offset.zero & size;
    canvas.saveLayer(layerBounds, Paint());
    canvas.drawRRect(baseRect, Paint()..color = Colors.white);
    canvas.drawOval(
      notchRect.inflate(0.5),
      Paint()..blendMode = BlendMode.clear,
    );
    // Solid top border only.
    canvas.drawLine(
      Offset(left, top),
      Offset(right, top),
      Paint()
        ..color = Colors.black
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
