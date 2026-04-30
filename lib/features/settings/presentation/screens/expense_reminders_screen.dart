import 'package:baht/core/extensions/widget_extension.dart';
import 'package:baht/core/widgets/section_card.dart';
import 'package:baht/features/settings/presentation/controllers/expense_reminder_controller.dart';
import 'package:baht/features/settings/presentation/widgets/reminder_time_picker_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:heroicons/heroicons.dart';

class ExpenseRemindersScreen extends ConsumerWidget {
  const ExpenseRemindersScreen({super.key});

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(expenseReminderControllerProvider);

    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                onAdd: () async {
                  final time = await showReminderTimePickerBottomSheet(context);
                  if (time != null && context.mounted) {
                    await ref
                        .read(expenseReminderControllerProvider.notifier)
                        .addReminder(time);
                  }
                },
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 24),
              SectionCard(
                child: remindersAsync.when(
                  data: (reminders) {
                    if (reminders.isEmpty) {
                      return _EmptyState();
                    }
                    return _RemindersList(
                      reminders: reminders,
                      onDelete: (time) async {
                        await ref
                            .read(expenseReminderControllerProvider.notifier)
                            .removeReminder(time);
                      },
                      formatTime: _formatTime,
                    );
                  },
                  loading:
                      () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  error:
                      (error, stack) => Center(
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                'Expense reminders',
                style: TextStyle(
                  fontSize: 24,
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
