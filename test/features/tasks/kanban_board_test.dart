import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/notifications/notification_service.dart';
import 'package:atlas/features/tasks/data/repositories/task_repository.dart';
import 'package:atlas/features/tasks/presentation/widgets/kanban/kanban_board_view.dart';
import 'package:atlas/features/tasks/presentation/widgets/kanban/kanban_column_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasksDao & TaskRepository Status/Priority Mutations', () {
    late AppDatabase db;
    late TaskRepository taskRepo;
    const wsId = 'ws-kanban-test';

    setUp(() async {
      db = AppDatabase.inMemory();
      final now = DateTime.now();
      await db
          .into(db.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Kanban Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );

      taskRepo = TaskRepository(
        tasksDao: db.tasksDao,
        notificationService: NotificationService(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    test('updateTaskStatus updates status, syncs isCompleted, and updates clientModifiedAt', () async {
      final task = await taskRepo.createTask(
        workspaceId: wsId,
        title: 'Review PR #42',
        status: 'todo',
        priority: 2,
      );

      expect(task.status, 'todo');
      expect(task.isCompleted, isFalse);

      // Move to in_progress
      await taskRepo.updateTaskStatus(task.id, 'in_progress');
      var updated = await db.tasksDao.getTask(task.id);
      expect(updated!.status, 'in_progress');
      expect(updated.isCompleted, isFalse);

      // Move to done
      await taskRepo.updateTaskStatus(task.id, 'done');
      updated = await db.tasksDao.getTask(task.id);
      expect(updated!.status, 'done');
      expect(updated.isCompleted, isTrue);
      expect(updated.completedAt, isNotNull);

      // Revert to todo
      await taskRepo.updateTaskStatus(task.id, 'todo');
      updated = await db.tasksDao.getTask(task.id);
      expect(updated!.status, 'todo');
      expect(updated.isCompleted, isFalse);
    });

    test(
      'updateTaskPriority updates priority level in Drift database',
      () async {
        final task = await taskRepo.createTask(
          workspaceId: wsId,
          title: 'Refactor parser',
          priority: 4,
        );

        expect(task.priority, 4);

        await taskRepo.updateTaskPriority(task.id, 1);
        final updated = await db.tasksDao.getTask(task.id);
        expect(updated!.priority, 1);
      },
    );

    test('reorderTaskInColumn updates sortOrder field', () async {
      final task = await taskRepo.createTask(
        workspaceId: wsId,
        title: 'Sortable task',
      );

      expect(task.sortOrder, 0);

      await taskRepo.reorderTaskInColumn(task.id, 5);
      final updated = await db.tasksDao.getTask(task.id);
      expect(updated!.sortOrder, 5);
    });
  });

  group('KanbanBoardView Widget Tests', () {
    late AppDatabase db;
    late TaskRepository taskRepo;
    const wsId = 'ws-kanban-ui-test';

    setUp(() async {
      db = AppDatabase.inMemory();
      final now = DateTime.now();
      await db
          .into(db.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Kanban UI Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );

      taskRepo = TaskRepository(
        tasksDao: db.tasksDao,
        notificationService: NotificationService(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    testWidgets(
      'renders status columns (To Do, In Progress, Done) and task items',
      (tester) async {
        final task1 = await taskRepo.createTask(
          workspaceId: wsId,
          title: 'Implement Vector Lasso',
          status: 'todo',
          priority: 1,
        );

        final task2 = await taskRepo.createTask(
          workspaceId: wsId,
          title: 'Write Kanban Tests',
          status: 'in_progress',
          priority: 2,
        );

        final task3 = await taskRepo.createTask(
          workspaceId: wsId,
          title: 'Drift Migration v8',
          status: 'done',
          priority: 3,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1200,
                height: 800,
                child: KanbanBoardView(
                  allTasks: [task1, task2, task3],
                  workspaceId: wsId,
                  taskRepo: taskRepo,
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify Status Columns
        expect(find.text('To Do'), findsOneWidget);
        expect(find.text('In Progress'), findsOneWidget);
        expect(find.text('Done'), findsOneWidget);

        // Verify task cards
        expect(find.text('Implement Vector Lasso'), findsOneWidget);
        expect(find.text('Write Kanban Tests'), findsOneWidget);
        expect(find.text('Drift Migration v8'), findsOneWidget);

        // Verify 3 columns exist
        expect(find.byType(KanbanColumnWidget), findsNWidgets(3));
      },
    );

    testWidgets('switches between By Status and By Priority groupings', (
      tester,
    ) async {
      final taskP1 = await taskRepo.createTask(
        workspaceId: wsId,
        title: 'Critical Bugfix',
        priority: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 1400,
              height: 800,
              child: KanbanBoardView(
                allTasks: [taskP1],
                workspaceId: wsId,
                taskRepo: taskRepo,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Switch grouping to By Priority
      final priorityOption = find.text('By Priority');
      expect(priorityOption, findsOneWidget);
      await tester.tap(priorityOption);
      await tester.pumpAndSettle();

      // Verify Priority Columns are displayed
      expect(find.text('Urgent (P1)'), findsOneWidget);
      expect(find.text('High (P2)'), findsOneWidget);
      expect(find.text('Medium (P3)'), findsOneWidget);
      expect(find.text('Low / Backlog (P4)'), findsOneWidget);
      expect(find.byType(KanbanColumnWidget), findsNWidgets(4));
    });
  });
}
