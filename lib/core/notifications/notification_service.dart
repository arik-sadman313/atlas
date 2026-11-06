import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../database/daos/calendar_dao.dart';
import '../database/daos/tasks_dao.dart';

/// Cross-platform notification and reminder dispatcher for ATLAS.
///
/// Features:
/// - Desktop Linux: DBus desktop notification daemon (`flutter_local_notifications_linux`).
/// - Android: Notification channels and exact alarm scheduling (`SCHEDULE_EXACT_ALARM`).
/// - iOS / iPadOS: `UNUserNotificationCenter` alert and badge alerts.
/// - Graceful degradation: If notification permissions are withheld or no desktop daemon
///   is listening, notifications log warnings without crashing the app.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _isInitialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get isInitialized => _isInitialized;

  /// Initializes timezone data and platform-specific notification plugins.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz.initializeTimeZones();

      const linuxSettings = LinuxInitializationSettings(
        defaultActionName: 'Open ATLAS',
      );

      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );

      const darwinSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        linux: linuxSettings,
        android: androidSettings,
        iOS: darwinSettings,
      );

      final initialized = await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (response) {
          developer.log(
            'Notification tapped with payload: ${response.payload}',
            name: 'NotificationService',
          );
        },
      );

      _isInitialized = initialized ?? false;
      developer.log(
        'NotificationService initialized: $_isInitialized',
        name: 'NotificationService',
      );
    } catch (e, st) {
      developer.log(
        'Failed to initialize NotificationService (degraded to silent mode): $e',
        name: 'NotificationService',
        error: e,
        stackTrace: st,
      );
      _isInitialized = false;
    }
  }

  /// Explicitly requests notification permissions on supported platforms.
  Future<bool> requestPermissions() async {
    try {
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? false;
      } else if (defaultTargetPlatform == TargetPlatform.iOS) {
        final iosImpl = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await iosImpl?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      developer.log(
        'Could not request notification permissions: $e',
        name: 'NotificationService',
      );
      return false;
    }
  }

  /// Maps string entity UUID to positive 31-bit integer for notification dispatchers.
  int generateNotificationId(String entityId) {
    return entityId.hashCode.abs() % 2147483647;
  }

  /// Computes target trigger time given a due date and reminder offset in minutes.
  DateTime? computeReminderTime(DateTime dueDate, int? reminderMinutesBefore) {
    if (reminderMinutesBefore == null || reminderMinutesBefore < 0) {
      return dueDate;
    }
    return dueDate.subtract(Duration(minutes: reminderMinutesBefore));
  }

  /// Schedules a reminder notification for an ATLAS task.
  Future<void> scheduleTaskReminder({
    required String taskId,
    required String title,
    String? description,
    required DateTime dueDate,
    int? reminderMinutesBefore,
  }) async {
    final triggerTime = computeReminderTime(dueDate, reminderMinutesBefore);
    if (triggerTime == null) return;

    if (triggerTime.isBefore(DateTime.now())) {
      developer.log(
        'Reminder time for task "$title" is in the past ($triggerTime). Skipping schedule.',
        name: 'NotificationService',
      );
      return;
    }

    if (!_isInitialized) {
      developer.log(
        'NotificationService not initialized. Reminder for "$title" not scheduled.',
        name: 'NotificationService',
      );
      return;
    }

    try {
      final id = generateNotificationId(taskId);
      final tzScheduled = tz.TZDateTime.from(triggerTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'atlas_tasks_channel',
        'Tasks & Reminders',
        channelDescription:
            'Notifications for ATLAS task deadlines and reminders',
        importance: Importance.high,
        priority: Priority.high,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const linuxDetails = LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.normal,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        linux: linuxDetails,
      );

      await _plugin.zonedSchedule(
        id: id,
        title: 'Task Reminder: $title',
        body: description ?? 'Your task is due soon.',
        scheduledDate: tzScheduled,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'task:$taskId',
      );

      developer.log(
        'Scheduled reminder for task $taskId at $tzScheduled',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Failed to schedule task reminder: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Schedules a reminder notification for a calendar event.
  Future<void> scheduleEventReminder({
    required String eventId,
    required String title,
    String? location,
    required DateTime startTime,
    int reminderMinutesBefore = 10,
  }) async {
    final triggerTime = startTime.subtract(
      Duration(minutes: reminderMinutesBefore),
    );
    if (triggerTime.isBefore(DateTime.now())) return;
    if (!_isInitialized) return;

    try {
      final id = generateNotificationId(eventId);
      final tzScheduled = tz.TZDateTime.from(triggerTime, tz.local);

      const androidDetails = AndroidNotificationDetails(
        'atlas_events_channel',
        'Calendar Events',
        channelDescription:
            'Notifications for upcoming calendar events and meetings',
        importance: Importance.high,
        priority: Priority.high,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const linuxDetails = LinuxNotificationDetails(
        urgency: LinuxNotificationUrgency.normal,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        linux: linuxDetails,
      );

      final body = location != null && location.isNotEmpty
          ? 'Starts in $reminderMinutesBefore min at $location'
          : 'Starts in $reminderMinutesBefore min';

      await _plugin.zonedSchedule(
        id: id,
        title: 'Event: $title',
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: 'event:$eventId',
      );
    } catch (e) {
      developer.log(
        'Failed to schedule event reminder: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Cancels any scheduled reminder associated with [entityId] (task or event).
  Future<void> cancelReminder(String entityId) async {
    if (!_isInitialized) return;
    try {
      final id = generateNotificationId(entityId);
      await _plugin.cancel(id: id);
      developer.log(
        'Cancelled reminder for entity $entityId (id: $id)',
        name: 'NotificationService',
      );
    } catch (e) {
      developer.log(
        'Failed to cancel reminder: $e',
        name: 'NotificationService',
      );
    }
  }

  /// Cancels all pending notifications across all channels.
  Future<void> cancelAllReminders() async {
    if (!_isInitialized) return;
    try {
      await _plugin.cancelAll();
    } catch (_) {}
  }

  /// Startup reconciliation: reads all uncompleted tasks with upcoming reminders
  /// and re-schedules them in the operating system's alarm/notification daemon.
  Future<void> reschedulePendingReminders({
    required TasksDao tasksDao,
    required CalendarDao calendarDao,
    required String workspaceId,
  }) async {
    if (!_isInitialized) return;

    try {
      final now = DateTime.now();

      // 1. Pending tasks with reminders
      final uncompletedTasks = await tasksDao.getTasksForWorkspace(
        workspaceId,
        isCompleted: false,
      );

      for (final task in uncompletedTasks) {
        if (task.dueDate != null && task.reminderMinutesBefore != null) {
          final triggerTime = computeReminderTime(
            task.dueDate!,
            task.reminderMinutesBefore,
          );
          if (triggerTime != null && triggerTime.isAfter(now)) {
            await scheduleTaskReminder(
              taskId: task.id,
              title: task.title,
              description: task.description,
              dueDate: task.dueDate!,
              reminderMinutesBefore: task.reminderMinutesBefore,
            );
          }
        }
      }

      // 2. Upcoming calendar events
      final nextWeek = now.add(const Duration(days: 7));
      final upcomingEvents = await calendarDao.getEventsForRange(
        workspaceId,
        now,
        nextWeek,
      );

      for (final event in upcomingEvents) {
        if (event.startTime.isAfter(now)) {
          await scheduleEventReminder(
            eventId: event.id,
            title: event.title,
            location: event.location,
            startTime: event.startTime,
          );
        }
      }
    } catch (e) {
      developer.log(
        'Failed to reschedule pending reminders on startup: $e',
        name: 'NotificationService',
      );
    }
  }
}
