import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../router/app_router.dart';
import '../../features/home/domain/entities/scheduled_transaction.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const _timezoneChannel = MethodChannel('com.dopaminelab.thumby/timezone');

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _permissionsGranted = false;

  Future<String> _getLocalTimezone() async {
    try {
      if (Platform.isIOS || Platform.isAndroid) {
        final timezone = await _timezoneChannel.invokeMethod<String>('getLocalTimezone');
        return timezone ?? 'UTC';
      }
      // Fallback for other platforms
      return 'UTC';
    } catch (e) {
      developer.log('Error getting timezone: $e', name: 'NotificationService');
      return 'UTC'; // Fallback
    }
  }

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();

      // Get device's actual timezone and set it
      final String timeZoneName = await _getLocalTimezone();
      developer.log('Device timezone: $timeZoneName');
      final location = tz.getLocation(timeZoneName);
      tz.setLocalLocation(location);
      developer.log('Timezone set to: ${tz.local.name}');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize plugin
      final initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _handleNotificationTap,
      );

      if (initialized == null || initialized == false) {
        developer.log('Failed to initialize notifications plugin', name: 'NotificationService');
        return;
      }

      // Request and verify permissions on iOS
      _permissionsGranted = await hasPermissions();
      if (!_permissionsGranted) {
        developer.log('Notification permissions not granted', name: 'NotificationService');
      } else {
        developer.log('Notification permissions granted', name: 'NotificationService');
      }

      _initialized = true;
    } catch (e, stackTrace) {
      developer.log(
        'Error initializing notification service: $e',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<bool> hasPermissions() async {
    try {
      final ios = _notifications.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        final result = await ios.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        final granted = result ?? false;
        return granted;
      }
      // Android always returns true
      return true;
    } catch (e) {
      developer.log('Error checking permissions: $e', name: 'NotificationService');
      return false;
    }
  }

  void _handleNotificationTap(NotificationResponse response) {
    final navigatorKey = rootNavigatorKey;
    if (navigatorKey.currentContext == null) return;

    // Check if this is a scheduled transaction notification
    final payload = response.payload;
    if (payload != null && payload.isNotEmpty) {
      try {
        final data = jsonDecode(payload) as Map<String, dynamic>;
        final scheduledId = data['scheduledId'] as String?;
        if (scheduledId != null) {
          // Navigate to scheduled transaction detail
          navigatorKey.currentContext!.go(
            AppRouter.scheduledTransactionDetail.path.replaceFirst(':id', scheduledId),
          );
          return;
        }
      } catch (e) {
        developer.log('Error parsing notification payload: $e', name: 'NotificationService');
      }
    }

    // Default: Navigate to dashboard
    navigatorKey.currentContext!.go(AppRouter.dashboard.path);
  }

  int _generateReminderId(TimeOfDay time) {
    // Generate unique ID based on hour and minute
    return time.hour * 100 + time.minute;
  }

  Future<bool> scheduleDailyReminder(TimeOfDay time) async {
    try {
      if (!_initialized) await initialize();

      if (!_permissionsGranted) {
        _permissionsGranted = await hasPermissions();
        if (!_permissionsGranted) {
          developer.log(
            'Cannot schedule notification: permissions not granted',
            name: 'NotificationService',
          );
          return false;
        }
      }

      final id = _generateReminderId(time);
      final now = tz.TZDateTime.now(tz.local);
      
      // Create scheduled date for today with the specified time
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        time.hour,
        time.minute,
      );

      // If the time has already passed today, schedule for tomorrow
      // This ensures the first notification fires tomorrow, then daily after that
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      developer.log(
        'Scheduling daily reminder at ${time.hour}:${time.minute.toString().padLeft(2, '0')} '
        '(ID: $id, Scheduled for: $scheduledDate)',
        name: 'NotificationService',
      );

      // Schedule daily recurring notification
      await _notifications.zonedSchedule(
        id,
        'Time to track your expenses',
        'Don\'t forget to add your expenses for today',
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'expense_reminders',
            'Expense Reminders',
            channelDescription: 'Daily reminders to track your expenses',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            threadIdentifier: 'expense_reminders',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );

      // Verify notification was scheduled
      final pending = await _notifications.pendingNotificationRequests();
      final wasScheduled = pending.any((n) => n.id == id);
      
      if (wasScheduled) {
        developer.log(
          'Notification scheduled successfully (ID: $id)',
          name: 'NotificationService',
        );
        return true;
      } else {
        developer.log(
          'Warning: Notification may not have been scheduled (ID: $id)',
          name: 'NotificationService',
        );
        return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error scheduling notification: $e',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> cancelReminder(TimeOfDay time) async {
    try {
      if (!_initialized) return;

      final id = _generateReminderId(time);
      await _notifications.cancel(id);
      developer.log('Cancelled reminder (ID: $id)', name: 'NotificationService');
    } catch (e) {
      developer.log('Error cancelling reminder: $e', name: 'NotificationService');
    }
  }

  Future<void> cancelAllReminders() async {
    try {
      if (!_initialized) return;

      await _notifications.cancelAll();
      developer.log('Cancelled all reminders', name: 'NotificationService');
    } catch (e) {
      developer.log('Error cancelling all reminders: $e', name: 'NotificationService');
    }
  }

  Future<void> rescheduleAllReminders(List<TimeOfDay> times) async {
    try {
      if (!_initialized) await initialize();

      // Cancel all existing reminders
      await cancelAllReminders();

      // Schedule new reminders
      for (final time in times) {
        await scheduleDailyReminder(time);
      }

      // Log pending notifications for debugging
      final pending = await _notifications.pendingNotificationRequests();
      developer.log(
        'Rescheduled ${times.length} reminders. Total pending: ${pending.length}',
        name: 'NotificationService',
      );
      
      if (pending.length > 64) {
        developer.log(
          'Warning: iOS allows max 64 pending notifications. Current: ${pending.length}',
          name: 'NotificationService',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error rescheduling reminders: $e',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      if (!_initialized) return [];
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      developer.log('Error getting pending notifications: $e', name: 'NotificationService');
      return [];
    }
  }

  int _generateScheduledTransactionId(String scheduledId) {
    // Generate unique ID by hashing the scheduled transaction ID
    // Use 100000+ range to avoid conflicts with expense reminder IDs (hour * 100 + minute)
    return 100000 + (scheduledId.hashCode % 900000).abs();
  }

  Future<bool> scheduleScheduledTransactionNotification(
    ScheduledTransaction scheduled,
  ) async {
    try {
      if (!_initialized) await initialize();

      if (!_permissionsGranted) {
        _permissionsGranted = await hasPermissions();
        if (!_permissionsGranted) {
          developer.log(
            'Cannot schedule notification: permissions not granted',
            name: 'NotificationService',
          );
          return false;
        }
      }

      // Only schedule for active and due transactions
      final today = DateTime.now();
      final scheduledDay = DateTime(
        scheduled.scheduledDate.year,
        scheduled.scheduledDate.month,
        scheduled.scheduledDate.day,
      );
      final todayOnly = DateTime(today.year, today.month, today.day);

      if (!scheduled.isActive || scheduledDay.isAfter(todayOnly)) {
        developer.log(
          'Skipping notification for scheduled transaction ${scheduled.id}: '
          'not active or not due yet',
          name: 'NotificationService',
        );
        return false;
      }

      final id = _generateScheduledTransactionId(scheduled.id);
      final now = tz.TZDateTime.now(tz.local);

      // Schedule for 9 AM today, or tomorrow if 9 AM has passed
      var scheduledDate = tz.TZDateTime(
        tz.local,
        now.year,
        now.month,
        now.day,
        9, // 9 AM
        0,
      );

      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Create notification payload with scheduled transaction ID
      final payload = jsonEncode({'scheduledId': scheduled.id});

      // Format amount for display
      final amount = scheduled.isDynamicAmount
          ? (scheduled.budgetAmount ?? scheduled.amount.abs())
          : scheduled.amount.abs();
      final amountText = amount.toStringAsFixed(2);

      developer.log(
        'Scheduling notification for scheduled transaction ${scheduled.id} '
        '(ID: $id, Scheduled for: $scheduledDate)',
        name: 'NotificationService',
      );

      // Schedule daily recurring notification at 9 AM
      await _notifications.zonedSchedule(
        id,
        'Scheduled payment due',
        '${scheduled.title} - \$$amountText',
        scheduledDate,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'scheduled_transactions',
            'Scheduled Transactions',
            channelDescription: 'Notifications for scheduled payments that are due',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
            threadIdentifier: 'scheduled_transactions',
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );

      // Verify notification was scheduled
      final pending = await _notifications.pendingNotificationRequests();
      final wasScheduled = pending.any((n) => n.id == id);

      if (wasScheduled) {
        developer.log(
          'Scheduled transaction notification scheduled successfully (ID: $id)',
          name: 'NotificationService',
        );
        return true;
      } else {
        developer.log(
          'Warning: Scheduled transaction notification may not have been scheduled (ID: $id)',
          name: 'NotificationService',
        );
        return false;
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error scheduling scheduled transaction notification: $e',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }

  Future<void> cancelScheduledTransactionNotification(String scheduledId) async {
    try {
      if (!_initialized) return;

      final id = _generateScheduledTransactionId(scheduledId);
      await _notifications.cancel(id);
      developer.log(
        'Cancelled scheduled transaction notification (ID: $id, Scheduled ID: $scheduledId)',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Error cancelling scheduled transaction notification: $e',
        name: 'NotificationService',
      );
    }
  }

  Future<void> rescheduleAllScheduledTransactionNotifications(
    List<ScheduledTransaction> scheduledTransactions,
  ) async {
    try {
      if (!_initialized) await initialize();

      // Cancel all existing scheduled transaction notifications
      // (We identify them by their ID range 100000-999999)
      final pending = await _notifications.pendingNotificationRequests();
      for (final notification in pending) {
        if (notification.id >= 100000 && notification.id < 1000000) {
          await _notifications.cancel(notification.id);
        }
      }

      // Schedule new notifications for due transactions
      int scheduledCount = 0;
      for (final scheduled in scheduledTransactions) {
        if (await scheduleScheduledTransactionNotification(scheduled)) {
          scheduledCount++;
        }
      }

      // Log pending notifications for debugging
      final updatedPending = await _notifications.pendingNotificationRequests();
      developer.log(
        'Rescheduled $scheduledCount scheduled transaction notifications. '
        'Total pending: ${updatedPending.length}',
        name: 'NotificationService',
      );

      if (updatedPending.length > 64) {
        developer.log(
          'Warning: iOS allows max 64 pending notifications. Current: ${updatedPending.length}',
          name: 'NotificationService',
        );
      }
    } catch (e, stackTrace) {
      developer.log(
        'Error rescheduling scheduled transaction notifications: $e',
        name: 'NotificationService',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
