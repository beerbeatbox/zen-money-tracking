import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import 'package:anti/core/router/app_router.dart';
import 'package:anti/features/home/domain/entities/expense_log.dart';
import 'package:anti/features/home/domain/usecases/expense_log_service.dart';
import 'package:anti/features/home/presentation/controllers/expense_logs_controller.dart';

import 'number_keyboard_bottom_sheet.dart';

class CustomBottomBar extends ConsumerStatefulWidget {
  const CustomBottomBar({super.key});

  @override
  ConsumerState<CustomBottomBar> createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends ConsumerState<CustomBottomBar> {
  bool _addPressed = false;

  String _formatTimeLabel(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _openKeyboard(BuildContext context) async {
    final rawValue = await showNumberKeyboardBottomSheet(context);
    if (rawValue == null) return;

    final parsed = double.tryParse(rawValue);
    if (parsed == null) {
      _showSnack(context, 'Please enter a valid number.');
      return;
    }

    final now = DateTime.now();
    final log = ExpenseLog(
      id: now.microsecondsSinceEpoch.toString(),
      title: 'Quick entry',
      timeLabel: _formatTimeLabel(now),
      category: 'General',
      amount: -parsed.abs(),
      createdAt: now,
    );

    try {
      final service = ref.read(expenseLogServiceProvider);
      await service.addExpenseLog(log);
      ref.invalidate(expenseLogsProvider);
      await ref.read(expenseLogsProvider.future);
      _showSnack(context, 'Great job! Expense saved.');
    } catch (_) {
      _showSnack(context, 'Something went wrong. Please try again.');
    }
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

  void _handleSettingsTap(BuildContext context) {
    context.go(AppRouter.settings.path);
  }

  void _handleHomeTap(BuildContext context) {
    context.go(AppRouter.dashboard.path);
  }

  BoxDecoration _circleDecoration(bool isPressed) {
    return BoxDecoration(
      shape: BoxShape.circle,
      color: isPressed ? const Color(0xFFF7F7F7) : Colors.white,
      border: Border.all(color: Colors.black, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black,
          offset: isPressed ? const Offset(1, 1) : const Offset(3, 3),
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ],
    );
  }

  Widget _buildSettingsButton(BuildContext context, {required bool isActive}) {
    return IconButton(
      onPressed: () => _handleSettingsTap(context),
      icon:
          isActive
              ? const HeroIcon(
                HeroIcons.cog6Tooth,
                style: HeroIconStyle.solid,
                color: Colors.black,
                size: 24,
              )
              : const HeroIcon(
                HeroIcons.cog6Tooth,
                style: HeroIconStyle.outline,
                color: Colors.black,
                size: 24,
              ),
      splashRadius: 26,
    );
  }

  Widget _buildHomeButton(BuildContext context, {required bool isActive}) {
    return IconButton(
      onPressed: () => _handleHomeTap(context),
      icon:
          isActive
              ? const HeroIcon(
                HeroIcons.home,
                style: HeroIconStyle.solid,
                color: Colors.black,
                size: 24,
              )
              : const HeroIcon(
                HeroIcons.home,
                style: HeroIconStyle.outline,
                color: Colors.black,
                size: 24,
              ),
      splashRadius: 26,
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _setAddPressed(true),
      onTapUp: (_) => _releaseAddWithPause(),
      onTapCancel: () => _releaseAddWithPause(),
      onTap: () => _openKeyboard(context),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.easeOut,
        width: 64,
        height: 64,
        decoration: _circleDecoration(_addPressed),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isHomeActive = location.startsWith(AppRouter.dashboard.path);
    final isSettingsActive = location.startsWith(AppRouter.settings.path);

    const addButtonSize = 64.0;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: 80,
        width: double.infinity,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: CustomPaint(painter: _CurvedNavPainter()),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildHomeButton(context, isActive: isHomeActive),
                    const SizedBox(width: addButtonSize + 24),
                    _buildSettingsButton(context, isActive: isSettingsActive),
                  ],
                ),
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
