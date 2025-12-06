import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

import 'package:anti/core/router/app_router.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:anti/features/settings/presentation/screens/settings_events.dart';

class SettingsScreen extends ConsumerWidget with SettingsEvents {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopBar(),
              const SizedBox(height: 16),
              const Divider(thickness: 2, color: Colors.black),
              const SizedBox(height: 24),
              _SettingsList(
                ref: ref,
                onDeleteAll: () => deleteAllData(context, ref),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SETTINGS',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Personalize your experience',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        Container(
          height: 46,
          width: 46,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            splashRadius: 24,
            onPressed: () => context.go(AppRouter.dashboard.path),
            icon: const Icon(Icons.arrow_back, size: 20, color: Colors.black),
          ),
        ),
      ],
    );
  }
}

class _SettingsList extends StatelessWidget {
  const _SettingsList({required this.ref, required this.onDeleteAll});

  final WidgetRef ref;
  final Future<void> Function() onDeleteAll;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsCard(
          icon: HeroIcons.sparkles,
          title: 'Money Tracker with AI',
          onTap: () => context.go(AppRouter.dashboard.path),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: HeroIcons.arrowRightOnRectangle,
          title: 'Log Out',
          onTap: () => context.go(AppRouter.onboarding.path),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: HeroIcons.trash,
          title: 'Delete All Data',
          color: Colors.red,
          onTap: onDeleteAll,
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    this.color = Colors.black,
    required this.onTap,
  });

  final HeroIcons icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: OutlinedSurface(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: HeroIcon(
                icon,
                style: HeroIconStyle.outline,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
