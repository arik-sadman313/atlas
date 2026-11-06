import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/notifications/notification_service.dart';
import 'package:atlas/features/tasks/data/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TaskRepository Tests', () {
    late AppDatabase database;
    late NotificationService notificationService;
    late TaskRepository repository;

    setUp(() {
      database = AppDatabase.inMemory();
      notificationService = NotificationService();
      repository = TaskRepository(
        tasksDao: database.tasksDao,
        notificationService: notificationService,
      );
    });

    tearDown(() async {
      await database.close();
    });

    test('creates task and retrieves via filter streams', () async {
      final now = DateTime.now();

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-repo-1',
              name: 'Workspace Repo 1',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Create an inbox task (no project)
      final inboxTask = await repository.createTask(
        workspaceId: 'ws-repo-1',
        title: 'Review PR #42',
        priority: 1,
      );
      expect(inboxTask.title, 'Review PR #42');
      expect(inboxTask.priority, 1);
      expect(inboxTask.projectId, isNull);

      // Check inbox filter
      final inboxList = await repository
          .watchTasks('ws-repo-1', filter: TaskFilter.inbox)
          .first;
      expect(inboxList.length, 1);
      expect(inboxList.first.id, inboxTask.id);

      // Create a task due today
      final todayTask = await repository.createTask(
        workspaceId: 'ws-repo-1',
        title: 'Prepare demo slides',
        dueDate: now,
        hasTime: true,
      );

      // Check today filter
      final todayList = await repository
          .watchTasks('ws-repo-1', filter: TaskFilter.today)
          .first;
      expect(todayList.length, 1);
      expect(todayList.first.id, todayTask.id);

      // Create upcoming task (due in 5 days)
      final upcomingTask = await repository.createTask(
        workspaceId: 'ws-repo-1',
        title: 'Release candidate build',
        dueDate: now.add(const Duration(days: 5)),
      );

      final upcomingList = await repository
          .watchTasks('ws-repo-1', filter: TaskFilter.upcoming)
          .first;
      expect(upcomingList.length, 1);
      expect(upcomingList.first.id, upcomingTask.id);

      // Toggle inbox task to completed
      await repository.toggleTask(inboxTask.id, true);

      final completedList = await repository
          .watchTasks('ws-repo-1', filter: TaskFilter.completed)
          .first;
      expect(completedList.length, 1);
      expect(completedList.first.id, inboxTask.id);

      // Verify inbox list no longer includes the completed task
      final inboxAfter = await repository
          .watchTasks('ws-repo-1', filter: TaskFilter.inbox)
          .first;
      expect(inboxAfter.any((t) => t.id == inboxTask.id), isFalse);
    });

    test('subtasks are excluded from primary task streams and retrieved via watchSubtasks', () async {
      final now = DateTime.now();

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-sub',
              name: 'Workspace Subtasks',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final parentTask = await repository.createTask(
        workspaceId: 'ws-sub',
        title: 'Parent Roadmap Task',
      );

      final subtask1 = await repository.createTask(
        workspaceId: 'ws-sub',
        parentTaskId: parentTask.id,
        title: 'Step 1: Write Architecture Spec',
      );

      final subtask2 = await repository.createTask(
        workspaceId: 'ws-sub',
        parentTaskId: parentTask.id,
        title: 'Step 2: Implement Data Layer',
      );

      // Primary inbox stream must ONLY contain parentTask
      final mainTasks = await repository
          .watchTasks('ws-sub', filter: TaskFilter.inbox)
          .first;
      expect(mainTasks.length, 1);
      expect(mainTasks.first.id, parentTask.id);

      // Subtasks stream contains both child tasks
      final subtasks = await repository.watchSubtasks(parentTask.id).first;
      expect(subtasks.length, 2);
      expect(
        subtasks.map((s) => s.id),
        containsAll([subtask1.id, subtask2.id]),
      );
    });

    test('project association and project filtering', () async {
      final now = DateTime.now();

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-proj',
              name: 'Workspace Proj',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final project = await repository.createProject(
        workspaceId: 'ws-proj',
        name: 'Design System M5',
        colorHex: '#8B5CF6',
      );
      expect(project.name, 'Design System M5');

      await repository.createTask(
        workspaceId: 'ws-proj',
        projectId: project.id,
        title: 'Build Agenda Item Card',
      );

      final projectTasks = await repository
          .watchTasks(
            'ws-proj',
            filter: TaskFilter.projects,
            projectId: project.id,
          )
          .first;
      expect(projectTasks.length, 1);
      expect(projectTasks.first.title, 'Build Agenda Item Card');
      expect(projectTasks.first.projectId, project.id);
    });
  });
}
