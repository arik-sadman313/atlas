import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/workspaces_table.dart';

part 'workspaces_dao.g.dart';

@DriftAccessor(tables: [Workspaces])
class WorkspacesDao extends DatabaseAccessor<AppDatabase>
    with _$WorkspacesDaoMixin {
  WorkspacesDao(super.db);

  Stream<List<WorkspaceEntry>> watchAllWorkspaces() {
    return (select(workspaces)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<List<WorkspaceEntry>> getAllWorkspaces() {
    return (select(workspaces)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.createdAt, mode: OrderingMode.asc),
          ]))
        .get();
  }

  Future<WorkspaceEntry?> getWorkspace(String id) {
    return (select(
      workspaces,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> createWorkspace(WorkspacesCompanion workspace) {
    return into(workspaces).insert(workspace);
  }

  Future<bool> updateWorkspace(WorkspacesCompanion workspace) {
    return update(workspaces).replace(workspace);
  }

  Future<int> deleteWorkspace(String id, {bool hardDelete = false}) {
    if (hardDelete) {
      return (delete(workspaces)..where((tbl) => tbl.id.equals(id))).go();
    } else {
      return (update(workspaces)..where((tbl) => tbl.id.equals(id))).write(
        WorkspacesCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<WorkspaceEntry> getOrCreateDefaultWorkspace() async {
    final existing = await getAllWorkspaces();
    if (existing.isNotEmpty) {
      return existing.first;
    }
    final now = DateTime.now();
    const defaultId = 'workspace-default-primary';
    final companion = WorkspacesCompanion(
      id: const Value(defaultId),
      name: const Value('Personal Workspace'),
      icon: const Value('space_dashboard'),
      settingsJson: const Value('{}'),
      createdAt: Value(now),
      updatedAt: Value(now),
      isDeleted: const Value(false),
    );
    await createWorkspace(companion);
    return (await getWorkspace(defaultId))!;
  }
}
