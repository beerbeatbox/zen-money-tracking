import 'package:anti/core/extensions/widget_extension.dart';
import 'package:anti/core/widgets/section_card.dart';
import 'package:anti/features/settings/presentation/controllers/daily_recap_notification_controller.dart';
import 'package:anti/features/settings/presentation/controllers/expense_reminder_controller.dart';
import 'package:anti/features/settings/presentation/controllers/notification_settings_controller.dart';
import 'package:anti/features/settings/presentation/widgets/reminder_time_picker_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

class NotificationSettingsScreen extends ConsumerWidget {
  const NotificationSettingsScreen({super.key});

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduledNotificationsAsync =
        ref.watch(notificationSettingsControllerProvider);
    final dailyRecapAsync = ref.watch(dailyRecapNotificationControllerProvider);
    final remindersAsync = ref.watch(expenseReminderControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _TopBar(),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              SectionCard(
                child: _ScheduledNotificationsSection(
                  scheduledNotificationsAsync: scheduledNotificationsAsync,
                  onToggle: (value) async {
                    await ref
                        .read(notificationSettingsControllerProvider.notifier)
                        .setEnabled(value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: _DailyRecapNotificationSection(
                  dailyRecapAsync: dailyRecapAsync,
                  onToggle: (value) async {
                    await ref
                        .read(
                          dailyRecapNotificationControllerProvider.notifier,
                        )
                        .setEnabled(value);
                  },
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                child: _ExpenseRemindersSection(
                remindersAsync: remindersAsync,
                onAdd: () async {
                  final time = await showReminderTimePickerBottomSheet(context);
                  if (time != null && context.mounted) {
                    await ref
                        .read(expenseReminderControllerProvider.notifier)
                        .addReminder(time);
                  }
                },
                onDelete: (time) async {
                  await ref
                      .read(expenseReminderControllerProvider.notifier)
                      .removeReminder(time);
                },
                formatTime: _formatTime,
              ),
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
      children: [
        IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: Colors.black),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notification settings',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your notification preferences',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScheduledNotificationsSection extends StatelessWidget {
  const _ScheduledNotificationsSection({
    required this.scheduledNotificationsAsync,
    required this.onToggle,
  });

  final AsyncValue<bool> scheduledNotificationsAsync;
  final Future<void> Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final enabled = scheduledNotificationsAsync.value ?? false;
    final canToggle = !scheduledNotificationsAsync.isLoading;

    return Row(
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: HeroIcon(
            HeroIcons.bell,
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
                'SCHEDULED NOTIFICATIONS',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Get notified daily at 9 AM for due scheduled payments',
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
          value: enabled,
          onChanged: canToggle ? onToggle : null,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.black,
          inactiveTrackColor: Colors.grey[300],
        ),
      ],
    );
  }
}

class _DailyRecapNotificationSection extends StatelessWidget {
  const _DailyRecapNotificationSection({
    required this.dailyRecapAsync,
    required this.onToggle,
  });

  final AsyncValue<bool> dailyRecapAsync;
  final Future<void> Function(bool) onToggle;

  @override
  Widget build(BuildContext context) {
    final enabled = dailyRecapAsync.value ?? true;
    final canToggle = !dailyRecapAsync.isLoading;

    return Row(
      children: [
        const SizedBox(
          width: 32,
          height: 32,
          child: HeroIcon(
            HeroIcons.sparkles,
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
                'DAILY RECAP',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Get your daily spending recap every morning at 8 AM',
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
          value: enabled,
          onChanged: canToggle ? onToggle : null,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.black,
          inactiveTrackColor: Colors.grey[300],
        ),
      ],
    );
  }
}

class _ExpenseRemindersSection extends StatelessWidget {
  const _ExpenseRemindersSection({
    required this.remindersAsync,
    required this.onAdd,
    required this.onDelete,
    required this.formatTime,
  });

  final AsyncValue<List<TimeOfDay>> remindersAsync;
  final VoidCallback onAdd;
  final Future<void> Function(TimeOfDay) onDelete;
  final String Function(TimeOfDay) formatTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'EXPENSE REMINDERS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Set daily reminders to track expenses',
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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: const HeroIcon(
                HeroIcons.plus,
                style: HeroIconStyle.outline,
                color: Colors.black,
                size: 20,
              ),
            ).onTap(behavior: HitTestBehavior.opaque, onTap: onAdd),
          ],
        ),
        const SizedBox(height: 24),
        remindersAsync.when(
          data: (reminders) {
            if (reminders.isEmpty) {
              return _EmptyState();
            }
            return _RemindersList(
              reminders: reminders,
              onDelete: onDelete,
              formatTime: formatTime,
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Something went wrong. Please try again.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RemindersList extends StatelessWidget {
  const _RemindersList({
    required this.reminders,
    required this.onDelete,
    required this.formatTime,
  });

  final List<TimeOfDay> reminders;
  final Future<void> Function(TimeOfDay) onDelete;
  final String Function(TimeOfDay) formatTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < reminders.length; i++) ...[
          _ReminderCard(
            time: reminders[i],
            formattedTime: formatTime(reminders[i]),
            onDelete: () => onDelete(reminders[i]),
          ),
          if (i < reminders.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _ReminderCard extends StatelessWidget {
  const _ReminderCard({
    required this.time,
    required this.formattedTime,
    required this.onDelete,
  });

  final TimeOfDay time;
  final String formattedTime;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: HeroIcon(
              HeroIcons.clock,
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
                Text(
                  formattedTime,
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: const HeroIcon(
              HeroIcons.trash,
              style: HeroIconStyle.outline,
              color: Colors.red,
              size: 18,
            ),
          ).onTap(
            behavior: HitTestBehavior.opaque,
            onTap: () async {
              await onDelete();
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: HeroIcon(
                HeroIcons.clock,
                style: HeroIconStyle.outline,
                color: Colors.grey[400],
                size: 48,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Start tracking your expenses',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Add your first reminder to get started',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
