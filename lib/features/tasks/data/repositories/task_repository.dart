import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/tasks_dao.dart';
import '../../../../core/notifications/notification_service.dart';

enum TaskFilter { inbox, today, upcoming, projects, completed }

enum TaskGrouping { none, byProject, byDueDate, byPriority }

class TaskRepository {
  final TasksDao tasksDao;
  final NotificationService notificationService;
  final Uuid uuid;

  TaskRepository({
    required this.tasksDao,
    required this.notificationService,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  /// Watches tasks for a workspace with filter conditions.
  Stream<List<TaskEntry>> watchTasks(
    String workspaceId, {
    TaskFilter filter = TaskFilter.inbox,
    String? projectId,
    String? nodeId,
  }) {
    if (nodeId != null) {
      return tasksDao.watchTasksForNode(nodeId);
    }

    final now = DateTime.now();
    final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59, 999);

    return tasksDao.watchTasksForWorkspace(workspaceId).map((allTasks) {
      return allTasks.where((task) {
        // Exclude subtasks from primary task view list
        if (task.parentTaskId != null) return false;

        switch (filter) {
          case TaskFilter.inbox:
            // Uncompleted tasks not assigned to any project
            return !task.isCompleted && task.projectId == null;

          case TaskFilter.today:
            // Uncompleted tasks due today or overdue
            if (task.isCompleted || task.dueDate == null) return false;
            return task.dueDate!.isBefore(endOfToday);

          case TaskFilter.upcoming:
            // Uncompleted tasks with future due date (after today)
            if (task.isCompleted || task.dueDate == null) return false;
            return task.dueDate!.isAfter(endOfToday);

          case TaskFilter.projects:
            // Filter by specific project if selected, else any project task
            if (task.isCompleted) return false;
            if (projectId != null) {
              return task.projectId == projectId;
            }
            return task.projectId != null;

          case TaskFilter.completed:
            // Any completed task
            if (!task.isCompleted) return false;
            if (projectId != null) {
              return task.projectId == projectId;
            }
            return true;
        }
      }).toList();
    });
  }

  /// Watches all subtasks belonging to [parentTaskId].
  Stream<List<TaskEntry>> watchSubtasks(String parentTaskId) {
    return tasksDao.watchSubtasks(parentTaskId);
  }

  /// Creates a new task and schedules notification if reminder is configured.
  Future<TaskEntry> createTask({
    required String workspaceId,
    required String title,
    String? description,
    String? projectId,
    String? nodeId,
    String? parentTaskId,
    int priority = 4,
    String status = 'todo',
    DateTime? dueDate,
    bool hasTime = false,
    String? recurrenceRule,
    int? reminderMinutesBefore,
  }) async {
    final id = uuid.v4();
    final now = DateTime.now();

    final companion = TasksCompanion.insert(
      id: id,
      workspaceId: workspaceId,
      projectId: Value(projectId),
      nodeId: Value(nodeId),
      parentTaskId: Value(parentTaskId),
      title: title.trim(),
      description: Value(description?.trim()),
      priority: Value(priority),
      status: Value(status),
      dueDate: Value(dueDate),
      hasTime: Value(hasTime),
      recurrenceRule: Value(recurrenceRule),
      reminderMinutesBefore: Value(reminderMinutesBefore),
      createdAt: now,
      updatedAt: now,
    );

    await tasksDao.createTask(companion);

    // Schedule notification if reminder set
    if (dueDate != null && reminderMinutesBefore != null) {
      await notificationService.scheduleTaskReminder(
        taskId: id,
        title: title,
        description: description,
        dueDate: dueDate,
        reminderMinutesBefore: reminderMinutesBefore,
      );
    }

    final created = await tasksDao.getTask(id);
    return created!;
  }

  /// Toggles task completion state.
  /// If completed, cancels pending reminder notifications.
  /// If uncompleted, re-schedules reminder notifications.
  Future<void> toggleTask(String taskId, bool isCompleted) async {
    await tasksDao.toggleTaskCompletion(taskId, isCompleted);

    if (isCompleted) {
      await notificationService.cancelReminder(taskId);
    } else {
      final task = await tasksDao.getTask(taskId);
      if (task != null &&
          task.dueDate != null &&
          task.reminderMinutesBefore != null) {
        await notificationService.scheduleTaskReminder(
          taskId: task.id,
          title: task.title,
          description: task.description,
          dueDate: task.dueDate!,
          reminderMinutesBefore: task.reminderMinutesBefore,
        );
      }
    }
  }

  /// Updates task fields and synchronizes reminders.
  Future<void> updateTask(TaskEntry task) async {
    final companion = task
        .toCompanion(true)
        .copyWith(updatedAt: Value(DateTime.now()));
    await tasksDao.updateTask(companion);

    // Cancel existing reminder and reschedule if due date is set
    await notificationService.cancelReminder(task.id);
    if (!task.isCompleted &&
        task.dueDate != null &&
        task.reminderMinutesBefore != null) {
      await notificationService.scheduleTaskReminder(
        taskId: task.id,
        title: task.title,
        description: task.description,
        dueDate: task.dueDate!,
        reminderMinutesBefore: task.reminderMinutesBefore,
      );
    }
  }

  /// Deletes a task and cancels pending reminders.
  Future<void> deleteTask(String taskId) async {
    await notificationService.cancelReminder(taskId);
    await tasksDao.deleteTask(taskId);
  }

  /// Reorders tasks in batch.
  Future<void> reorderTasks(List<String> taskIds) {
    return tasksDao.batchReorderTasks(taskIds);
  }

  /// Updates task status (e.g. 'todo', 'in_progress', 'done').
  Future<void> updateTaskStatus(String taskId, String status) async {
    await tasksDao.updateTaskStatus(taskId, status);
    final isDone = status == 'done' || status == 'completed';
    if (isDone) {
      await notificationService.cancelReminder(taskId);
    }
  }

  /// Updates task priority level (1=Urgent, 2=High, 3=Medium, 4=Low).
  Future<void> updateTaskPriority(String taskId, int priority) async {
    await tasksDao.updateTaskPriority(taskId, priority);
  }

  /// Updates individual task sort order in column.
  Future<void> reorderTaskInColumn(String taskId, int newSortOrder) {
    return tasksDao.reorderTaskInColumn(taskId, newSortOrder);
  }

  // --- Projects ---

  Stream<List<ProjectEntry>> watchProjects(String workspaceId) {
    return tasksDao.watchProjects(workspaceId);
  }

  Future<List<ProjectEntry>> getProjects(String workspaceId) {
    return tasksDao.getProjects(workspaceId);
  }

  Future<ProjectEntry> createProject({
    required String workspaceId,
    required String name,
    String? description,
    String colorHex = '#4F46E5',
    String? icon,
  }) async {
    final id = uuid.v4();
    final now = DateTime.now();

    final companion = ProjectsCompanion.insert(
      id: id,
      workspaceId: workspaceId,
      name: name.trim(),
      description: Value(description?.trim()),
      colorHex: Value(colorHex),
      icon: Value(icon),
      createdAt: now,
      updatedAt: now,
    );

    await tasksDao.createProject(companion);
    final created = await tasksDao.getProject(id);
    return created!;
  }

  Future<void> updateProject(ProjectEntry project) async {
    await tasksDao.updateProject(
      project.toCompanion(true).copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> deleteProject(String projectId) {
    return tasksDao.deleteProject(projectId);
  }
}
