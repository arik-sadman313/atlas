import 'package:drift/drift.dart';
import 'package:rxdart/rxdart.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/calendar_dao.dart';
import '../../../../core/database/daos/tasks_dao.dart';
import '../../../../core/notifications/notification_service.dart';
import '../../domain/models/calendar_agenda_item.dart';

class CalendarRepository {
  final CalendarDao calendarDao;
  final TasksDao tasksDao;
  final NotificationService notificationService;
  final Uuid uuid;

  CalendarRepository({
    required this.calendarDao,
    required this.tasksDao,
    required this.notificationService,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  Stream<List<CalendarEventEntry>> watchAllEvents(String workspaceId) {
    return calendarDao.watchAllEvents(workspaceId);
  }

  Stream<List<CalendarEventEntry>> watchEventsForRange(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) {
    return calendarDao.watchEventsForRange(workspaceId, start, end);
  }

  Future<List<CalendarEventEntry>> getEventsForRange(
    String workspaceId,
    DateTime start,
    DateTime end,
  ) {
    return calendarDao.getEventsForRange(workspaceId, start, end);
  }

  /// Combined agenda stream for a specific day: merges scheduled events and tasks due that day.
  Stream<List<CalendarAgendaItem>> watchAgendaForDay(
    String workspaceId,
    DateTime day,
  ) {
    final startOfDay = DateTime(day.year, day.month, day.day);
    final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59, 999);

    final eventsStream = calendarDao.watchEventsForDay(workspaceId, day);
    final tasksStream = tasksDao.watchTasksForWorkspace(workspaceId);

    return Rx.combineLatest2<
      List<CalendarEventEntry>,
      List<TaskEntry>,
      List<CalendarAgendaItem>
    >(eventsStream, tasksStream, (events, allTasks) {
      final items = <CalendarAgendaItem>[];

      // 1. Add Calendar Events
      for (final e in events) {
        items.add(CalendarAgendaItem.fromEvent(e));
      }

      // 2. Add Tasks due on this day
      for (final t in allTasks) {
        if (t.parentTaskId != null) continue; // Exclude subtasks
        if (t.dueDate != null) {
          final due = t.dueDate!;
          if (!due.isBefore(startOfDay) && !due.isAfter(endOfDay)) {
            items.add(CalendarAgendaItem.fromTask(t));
          }
        }
      }

      // 3. Sort: All-day items first, then by startTime ascending
      items.sort((a, b) {
        if (a.isAllDay && !b.isAllDay) return -1;
        if (!a.isAllDay && b.isAllDay) return 1;
        return a.startTime.compareTo(b.startTime);
      });

      return items;
    });
  }

  /// Creates a calendar event and schedules a reminder notification.
  Future<CalendarEventEntry> createEvent({
    required String workspaceId,
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    bool isAllDay = false,
    String? colorHex,
    String? location,
    String? nodeId,
    String? taskId,
  }) async {
    final id = uuid.v4();
    final now = DateTime.now();

    final companion = CalendarEventsCompanion.insert(
      id: id,
      workspaceId: workspaceId,
      taskId: Value(taskId),
      nodeId: Value(nodeId),
      title: title.trim(),
      description: Value(description?.trim()),
      startTime: startTime,
      endTime: endTime,
      isAllDay: Value(isAllDay),
      colorHex: Value(colorHex),
      location: Value(location?.trim()),
      createdAt: now,
      updatedAt: now,
    );

    await calendarDao.createEvent(companion);

    // Schedule 10 min reminder before event
    if (!isAllDay && startTime.isAfter(DateTime.now())) {
      await notificationService.scheduleEventReminder(
        eventId: id,
        title: title,
        location: location,
        startTime: startTime,
        reminderMinutesBefore: 10,
      );
    }

    final created = await calendarDao.getEvent(id);
    return created!;
  }

  /// Updates a calendar event.
  Future<void> updateEvent(CalendarEventEntry event) async {
    await calendarDao.updateEvent(
      event.toCompanion(true).copyWith(updatedAt: Value(DateTime.now())),
    );

    await notificationService.cancelReminder(event.id);
    if (!event.isAllDay && event.startTime.isAfter(DateTime.now())) {
      await notificationService.scheduleEventReminder(
        eventId: event.id,
        title: event.title,
        location: event.location,
        startTime: event.startTime,
      );
    }
  }

  /// Deletes a calendar event and cancels its reminder.
  Future<void> deleteEvent(String eventId) async {
    await notificationService.cancelReminder(eventId);
    await calendarDao.deleteEvent(eventId);
  }
}
