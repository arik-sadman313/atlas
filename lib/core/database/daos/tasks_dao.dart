import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/nodes_table.dart';
import '../tables/projects_table.dart';
import '../tables/tasks_table.dart';

part 'tasks_dao.g.dart';

@DriftAccessor(tables: [Tasks, Projects, Nodes])
class TasksDao extends DatabaseAccessor<AppDatabase> with _$TasksDaoMixin {
  TasksDao(super.db);

  // --- Task Queries & Streams ---

  Stream<List<TaskEntry>> watchTasksForWorkspace(
    String workspaceId, {
    bool? isCompleted,
    String? projectId,
    DateTime? dueBefore,
    bool topLevelOnly = false,
  }) {
    final query = select(tasks)
      ..where((tbl) {
        Expression<bool> predicate = tbl.workspaceId.equals(workspaceId);

        if (isCompleted != null) {
          predicate &= tbl.isCompleted.equals(isCompleted);
        }
        if (projectId != null) {
          predicate &= tbl.projectId.equals(projectId);
        }
        if (dueBefore != null) {
          predicate &= tbl.dueDate.isSmallerOrEqualValue(dueBefore);
        }
        if (topLevelOnly) {
          predicate &= tbl.parentTaskId.isNull();
        }

        return predicate;
      })
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.isCompleted, mode: OrderingMode.asc),
        (tbl) =>
            OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
        (tbl) => OrderingTerm(expression: tbl.priority, mode: OrderingMode.asc),
        (tbl) => OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.asc),
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
      ]);

    return query.watch();
  }

  Future<List<TaskEntry>> getTasksForWorkspace(
    String workspaceId, {
    bool? isCompleted,
    String? projectId,
    DateTime? dueBefore,
    bool topLevelOnly = false,
  }) {
    final query = select(tasks)
      ..where((tbl) {
        Expression<bool> predicate = tbl.workspaceId.equals(workspaceId);

        if (isCompleted != null) {
          predicate &= tbl.isCompleted.equals(isCompleted);
        }
        if (projectId != null) {
          predicate &= tbl.projectId.equals(projectId);
        }
        if (dueBefore != null) {
          predicate &= tbl.dueDate.isSmallerOrEqualValue(dueBefore);
        }
        if (topLevelOnly) {
          predicate &= tbl.parentTaskId.isNull();
        }

        return predicate;
      })
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.isCompleted, mode: OrderingMode.asc),
        (tbl) =>
            OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
        (tbl) => OrderingTerm(expression: tbl.priority, mode: OrderingMode.asc),
        (tbl) => OrderingTerm(expression: tbl.dueDate, mode: OrderingMode.asc),
        (tbl) =>
            OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
      ]);

    return query.get();
  }

  Stream<List<TaskEntry>> watchTasksForNode(String nodeId) {
    return (select(tasks)
          ..where((tbl) => tbl.nodeId.equals(nodeId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.isCompleted,
              mode: OrderingMode.asc,
            ),
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<TaskEntry>> getTasksForNode(String nodeId) {
    return (select(tasks)
          ..where((tbl) => tbl.nodeId.equals(nodeId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.isCompleted,
              mode: OrderingMode.asc,
            ),
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Stream<List<TaskEntry>> watchSubtasks(String parentTaskId) {
    return (select(tasks)
          ..where((tbl) => tbl.parentTaskId.equals(parentTaskId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.isCompleted,
              mode: OrderingMode.asc,
            ),
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<TaskEntry>> getSubtasks(String parentTaskId) {
    return (select(tasks)
          ..where((tbl) => tbl.parentTaskId.equals(parentTaskId))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.isCompleted,
              mode: OrderingMode.asc,
            ),
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<TaskEntry?> getTask(String id) {
    return (select(tasks)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Stream<TaskEntry?> watchTask(String id) {
    return (select(
      tasks,
    )..where((tbl) => tbl.id.equals(id))).watchSingleOrNull();
  }

  // --- Task Mutations ---

  Future<void> createTask(TasksCompanion task) {
    return into(tasks).insert(task);
  }

  Future<bool> updateTask(TasksCompanion task) {
    return update(tasks).replace(task);
  }

  Future<void> updateTaskPartial(String id, TasksCompanion updates) {
    return (update(tasks)..where((tbl) => tbl.id.equals(id))).write(updates);
  }

  Future<void> toggleTaskCompletion(String taskId, bool isCompleted) async {
    final now = DateTime.now();
    await (update(tasks)..where((tbl) => tbl.id.equals(taskId))).write(
      TasksCompanion(
        isCompleted: Value(isCompleted),
        completedAt: Value(isCompleted ? now : null),
        updatedAt: Value(now),
      ),
    );
  }

  Future<int> deleteTask(String id) {
    return (delete(tasks)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<void> batchReorderTasks(List<String> taskIds) async {
    await transaction(() async {
      for (int i = 0; i < taskIds.length; i++) {
        await (update(tasks)..where((tbl) => tbl.id.equals(taskIds[i]))).write(
          TasksCompanion(sortOrder: Value(i), updatedAt: Value(DateTime.now())),
        );
      }
    });
  }

  // --- Project CRUD ---

  Stream<List<ProjectEntry>> watchProjects(
    String workspaceId, {
    bool includeArchived = false,
  }) {
    return (select(projects)
          ..where((tbl) {
            Expression<bool> predicate = tbl.workspaceId.equals(workspaceId);
            if (!includeArchived) {
              predicate &= tbl.isArchived.equals(false);
            }
            return predicate;
          })
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<ProjectEntry>> getProjects(
    String workspaceId, {
    bool includeArchived = false,
  }) {
    return (select(projects)
          ..where((tbl) {
            Expression<bool> predicate = tbl.workspaceId.equals(workspaceId);
            if (!includeArchived) {
              predicate &= tbl.isArchived.equals(false);
            }
            return predicate;
          })
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
            (tbl) => OrderingTerm(expression: tbl.name, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<ProjectEntry?> getProject(String id) {
    return (select(
      projects,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> createProject(ProjectsCompanion project) {
    return into(projects).insert(project);
  }

  Future<bool> updateProject(ProjectsCompanion project) {
    return update(projects).replace(project);
  }

  Future<int> deleteProject(String id) {
    return (delete(projects)..where((tbl) => tbl.id.equals(id))).go();
  }
}
