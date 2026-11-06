import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/notifications/notification_service.dart';
import 'package:atlas/features/calendar/data/repositories/calendar_repository.dart';
import 'package:atlas/features/calendar/domain/models/calendar_agenda_item.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarRepository Tests', () {
    late AppDatabase database;
    late NotificationService notificationService;
    late CalendarRepository repository;

    setUp(() {
      database = AppDatabase.inMemory();
      notificationService = NotificationService();
      repository = CalendarRepository(
        calendarDao: database.calendarDao,
        tasksDao: database.tasksDao,
        notificationService: notificationService,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('creates, updates, and deletes calendar events', () async {
      final now = DateTime(2026, 11, 6, 10, 0);

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-cal-repo',
              name: 'Cal Repo WS',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final created = await repository.createEvent(
        workspaceId: 'ws-cal-repo',
        title: 'Weekly Standup',
        description: 'Sync on sprint goals',
        startTime: now,
        endTime: now.add(const Duration(minutes: 30)),
        location: 'Zoom Room 1',
        colorHex: '#3B82F6',
      );

      expect(created.title, 'Weekly Standup');
      expect(created.location, 'Zoom Room 1');
      expect(created.colorHex, '#3B82F6');

      // Update event
      final updated = created.copyWith(
        title: 'Executive Standup',
        location: const Value('Boardroom'),
      );
      await repository.updateEvent(updated);

      final fetched = await database.calendarDao.getEvent(created.id);
      expect(fetched!.title, 'Executive Standup');
      expect(fetched.location, 'Boardroom');

      // Delete event
      await repository.deleteEvent(created.id);
      final afterDelete = await database.calendarDao.getEvent(created.id);
      expect(afterDelete, isNull);
    });

    test(
      'watchAgendaForDay combines events and tasks with all-day sorted first',
      () async {
        final targetDay = DateTime(2026, 11, 6);
        final now = DateTime(2026, 11, 6, 8, 0);

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: 'ws-agenda',
                name: 'Agenda WS',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // 1. Timed Event at 2:00 PM
        await repository.createEvent(
          workspaceId: 'ws-agenda',
          title: 'Afternoon Architecture Review',
          startTime: DateTime(2026, 11, 6, 14, 0),
          endTime: DateTime(2026, 11, 6, 15, 0),
        );

        // 2. All-day Event (e.g. Conference)
        await repository.createEvent(
          workspaceId: 'ws-agenda',
          title: 'Flutter Forward Hackathon',
          startTime: DateTime(2026, 11, 6, 0, 0),
          endTime: DateTime(2026, 11, 6, 23, 59),
          isAllDay: true,
        );

        // 3. Timed Task due at 10:00 AM
        await database
            .into(database.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-morning',
                workspaceId: 'ws-agenda',
                title: 'Deploy Hotfix to Staging',
                dueDate: Value(DateTime(2026, 11, 6, 10, 0)),
                hasTime: const Value(true),
                priority: const Value(1),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // 4. Task due next month (should NOT appear on target day)
        await database
            .into(database.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-next-month',
                workspaceId: 'ws-agenda',
                title: 'Annual Tax Review',
                dueDate: Value(DateTime(2026, 12, 1)),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final agenda = await repository
            .watchAgendaForDay('ws-agenda', targetDay)
            .first;

        // Exactly 3 items for targetDay
        expect(agenda.length, 3);

        // 1st item should be the all-day event
        expect(agenda[0].title, 'Flutter Forward Hackathon');
        expect(agenda[0].isAllDay, isTrue);
        expect(agenda[0].type, CalendarItemType.event);

        // 2nd item should be the 10:00 AM task
        expect(agenda[1].title, 'Deploy Hotfix to Staging');
        expect(agenda[1].type, CalendarItemType.task);
        expect(agenda[1].startTime.hour, 10);

        // 3rd item should be the 2:00 PM event
        expect(agenda[2].title, 'Afternoon Architecture Review');
        expect(agenda[2].type, CalendarItemType.event);
        expect(agenda[2].startTime.hour, 14);
      },
    );
  });
}
