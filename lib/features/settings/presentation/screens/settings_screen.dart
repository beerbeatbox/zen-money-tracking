import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/router/app_router.dart';
import 'package:anti/features/home/presentation/widgets/outlined_surface.dart';
import 'package:anti/features/settings/presentation/controllers/carry_balance_setting_controller.dart';
import 'package:anti/features/settings/presentation/screens/settings_events.dart';
import 'package:anti/features/settings/presentation/widgets/outlined_confirmation_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

class SettingsScreen extends ConsumerWidget with SettingsEvents {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
                onDeleteAll: () => _confirmAndDeleteData(context, ref),
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
    final carryAsync = ref.watch(carryBalanceSettingControllerProvider);
    final carryEnabled = carryAsync.value ?? false;
    final canToggle = !carryAsync.isLoading;
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return Column(
      children: [
        OutlinedSurface(
          padding: const EdgeInsets.all(16),
          borderRadius: BorderRadius.circular(12),
          child: Row(
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: HeroIcon(
                  HeroIcons.arrowPath,
                  style: HeroIconStyle.outline,
                  color: Colors.black,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARRY BALANCE FORWARD',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Include last month’s balance in your current month.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Switch(
                value: carryEnabled,
                onChanged:
                    canToggle
                        ? (value) => ref
                            .read(
                              carryBalanceSettingControllerProvider.notifier,
                            )
                            .setEnabled(value)
                        : null,
                activeColor: Colors.green,
                inactiveThumbColor: Colors.black,
                inactiveTrackColor: Colors.grey[300],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: HeroIcons.bell,
          title: 'Expense Reminders',
          onTap: () => context.pushNamed(AppRouter.expenseReminders.name),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: HeroIcons.banknotes,
          title: 'Budget',
          onTap: () => context.pushNamed(AppRouter.budget.name),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: HeroIcons.tag,
          title: 'Categories',
          onTap: () => context.pushNamed(AppRouter.categoryManagement.name),
        ),
        const SizedBox(height: 12),
        _SettingsCard(
          icon: HeroIcons.arrowPath,
          title: 'Import & Export',
          onTap: () {
            if (isIOS) {
              context.pushNamed(AppRouter.expenseLogsCsv.name);
              return;
            }
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Android support is coming soon.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          },
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

Future<void> _confirmAndDeleteData(BuildContext context, WidgetRef ref) async {
  final shouldDelete = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return OutlinedConfirmationDialog(
        title: 'Clear all data?',
        description:
            'This removes every expense log from this device. You can start fresh anytime.',
        primaryLabel: 'Clear everything',
        onPrimaryPressed: () => Navigator.of(dialogContext).pop(true),
        secondaryLabel: 'Keep my data',
        onSecondaryPressed: () => Navigator.of(dialogContext).pop(false),
      );
    },
  );

  if (shouldDelete != true) return;

  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  try {
    await SettingsScreen().deleteAllData(ref);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('All data cleared. Ready for a fresh start.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  } catch (_) {
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Could not clear data. Please try again.'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
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
    return OutlinedSurface(
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
    ).onTap(behavior: HitTestBehavior.opaque, onTap: onTap);
  }
}
