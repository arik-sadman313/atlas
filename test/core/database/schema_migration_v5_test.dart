import 'package:atlas/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schema Migration v5 Tests', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.inMemory();
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'fresh database initializes schema version 5 with all tables',
      () async {
        expect(database.schemaVersion, 5);

        final now = DateTime.now();

        // 1. Verify workspace insertion
        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: 'ws-v5',
                name: 'Workspace V5',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // 2. Verify project insertion
        await database
            .into(database.projects)
            .insert(
              ProjectsCompanion.insert(
                id: 'proj-1',
                workspaceId: 'ws-v5',
                name: 'Productivity Overhaul',
                colorHex: const Value('#3B82F6'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final project = await (database.select(
          database.projects,
        )..where((tbl) => tbl.id.equals('proj-1'))).getSingle();
        expect(project.name, 'Productivity Overhaul');
        expect(project.colorHex, '#3B82F6');

        // 3. Verify task insertion with foreign keys
        await database
            .into(database.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-parent',
                workspaceId: 'ws-v5',
                title: 'Implement Notification Engine',
                projectId: const Value('proj-1'),
                priority: const Value(1),
                sortOrder: const Value(0),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // 4. Verify subtask insertion with parentTaskId
        await database
            .into(database.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-sub-1',
                workspaceId: 'ws-v5',
                parentTaskId: const Value('task-parent'),
                title: 'Register DBus Linux adapter',
                priority: const Value(2),
                sortOrder: const Value(0),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final subtasks = await database.tasksDao
            .watchSubtasks('task-parent')
            .first;
        expect(subtasks.length, 1);
        expect(subtasks.first.title, 'Register DBus Linux adapter');

        // 5. Verify calendar event insertion
        await database
            .into(database.calendarEvents)
            .insert(
              CalendarEventsCompanion.insert(
                id: 'event-1',
                workspaceId: 'ws-v5',
                title: 'Sprint Demo & Architecture Review',
                startTime: now,
                endTime: now.add(const Duration(hours: 1)),
                isAllDay: const Value(false),
                colorHex: const Value('#10B981'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        final event = await database.calendarDao.getEvent('event-1');
        expect(event, isNotNull);
        expect(event!.title, 'Sprint Demo & Architecture Review');
      },
    );

    test('cascading delete on parent task removes child subtasks', () async {
      final now = DateTime.now();

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-cascade',
              name: 'Cascade WS',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-main',
              workspaceId: 'ws-cascade',
              title: 'Main Feature Task',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'subtask-a',
              workspaceId: 'ws-cascade',
              parentTaskId: const Value('task-main'),
              title: 'Subtask A',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'subtask-b',
              workspaceId: 'ws-cascade',
              parentTaskId: const Value('task-main'),
              title: 'Subtask B',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Verify subtasks exist
      var subs = await database.tasksDao.watchSubtasks('task-main').first;
      expect(subs.length, 2);

      // Delete parent task
      await database.tasksDao.deleteTask('task-main');

      // Verify subtasks are removed via CASCADE
      subs = await database.tasksDao.watchSubtasks('task-main').first;
      expect(subs.isEmpty, isTrue);

      final subA = await database.tasksDao.getTask('subtask-a');
      expect(subA, isNull);
    });

    test(
      'deleting project sets task projectId to NULL (SET NULL action)',
      () async {
        final now = DateTime.now();

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: 'ws-setnull',
                name: 'SetNull WS',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await database
            .into(database.projects)
            .insert(
              ProjectsCompanion.insert(
                id: 'proj-temp',
                workspaceId: 'ws-setnull',
                name: 'Temporary Project',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await database
            .into(database.tasks)
            .insert(
              TasksCompanion.insert(
                id: 'task-in-proj',
                workspaceId: 'ws-setnull',
                projectId: const Value('proj-temp'),
                title: 'Important Milestone Task',
                createdAt: now,
                updatedAt: now,
              ),
            );

        var task = await database.tasksDao.getTask('task-in-proj');
        expect(task!.projectId, 'proj-temp');

        // Delete project
        await database.tasksDao.deleteProject('proj-temp');

        // Task must remain, but its projectId must be null
        task = await database.tasksDao.getTask('task-in-proj');
        expect(task, isNotNull);
        expect(task!.projectId, isNull);
      },
    );

    test('TasksDao batch reordering and completion toggling', () async {
      final now = DateTime.now();

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-reorder',
              name: 'Reorder WS',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-1',
              workspaceId: 'ws-reorder',
              title: 'Task 1',
              sortOrder: const Value(1),
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'task-2',
              workspaceId: 'ws-reorder',
              title: 'Task 2',
              sortOrder: const Value(2),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Reorder tasks
      await database.tasksDao.batchReorderTasks(['task-2', 'task-1']);

      var tasks = await database.tasksDao
          .watchTasksForWorkspace('ws-reorder')
          .first;
      expect(tasks[0].id, 'task-2');
      expect(tasks[1].id, 'task-1');

      // Toggle completion
      expect(tasks[0].isCompleted, isFalse);
      await database.tasksDao.toggleTaskCompletion('task-2', true);

      tasks = await database.tasksDao
          .watchTasksForWorkspace('ws-reorder')
          .first;
      final updatedTask2 = tasks.firstWhere((t) => t.id == 'task-2');
      expect(updatedTask2.isCompleted, isTrue);
      expect(updatedTask2.completedAt, isNotNull);
    });

    test('CalendarDao range queries and event retrieval', () async {
      final now = DateTime(2026, 11, 6, 12, 0);

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-cal',
              name: 'Calendar WS',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Event today
      await database
          .into(database.calendarEvents)
          .insert(
            CalendarEventsCompanion.insert(
              id: 'event-today',
              workspaceId: 'ws-cal',
              title: 'Morning Sync',
              startTime: now,
              endTime: now.add(const Duration(minutes: 30)),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Event next week
      await database
          .into(database.calendarEvents)
          .insert(
            CalendarEventsCompanion.insert(
              id: 'event-next-week',
              workspaceId: 'ws-cal',
              title: 'Future Planning',
              startTime: now.add(const Duration(days: 7)),
              endTime: now.add(const Duration(days: 7, hours: 1)),
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Query for today
      final todayEvents = await database.calendarDao.getEventsForDay(
        'ws-cal',
        now,
      );
      expect(todayEvents.length, 1);
      expect(todayEvents.first.title, 'Morning Sync');

      // Query for 2 weeks
      final rangeEvents = await database.calendarDao.getEventsForRange(
        'ws-cal',
        now.subtract(const Duration(days: 1)),
        now.add(const Duration(days: 14)),
      );
      expect(rangeEvents.length, 2);
    });
  });
}
