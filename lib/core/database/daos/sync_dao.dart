import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/calendar_events_table.dart';
import '../tables/goals_table.dart';
import '../tables/habit_logs_table.dart';
import '../tables/habits_table.dart';
import '../tables/ink_pages_table.dart';
import '../tables/journal_entries_table.dart';
import '../tables/node_links_table.dart';
import '../tables/nodes_table.dart';
import '../tables/pdf_documents_table.dart';
import '../tables/projects_table.dart';
import '../tables/sync_history_table.dart';
import '../tables/tags_table.dart';
import '../tables/tasks_table.dart';
import '../tables/workspaces_table.dart';

part 'sync_dao.g.dart';

@DriftAccessor(
  tables: [
    SyncHistory,
    Workspaces,
    Nodes,
    NodeLinks,
    Tags,
    NodeTags,
    InkPages,
    PdfDocuments,
    Projects,
    Tasks,
    CalendarEvents,
    Habits,
    HabitLogs,
    Goals,
    JournalEntries,
  ],
)
class SyncDao extends DatabaseAccessor<AppDatabase> with _$SyncDaoMixin {
  SyncDao(super.db);

  // --- Sync History & Metrics ---

  Future<void> startSync({
    required String id,
    required String syncType,
    DateTime? startedAt,
  }) async {
    final now = startedAt ?? DateTime.now().toUtc();
    await into(syncHistory).insert(
      SyncHistoryCompanion.insert(
        id: id,
        syncStartedAt: now,
        syncType: syncType,
        status: 'in_progress',
      ),
    );
  }

  Future<void> completeSync({
    required String id,
    int recordsExported = 0,
    int recordsImported = 0,
    int blobsTransferred = 0,
    DateTime? completedAt,
  }) async {
    final now = completedAt ?? DateTime.now().toUtc();
    await (update(syncHistory)..where((tbl) => tbl.id.equals(id))).write(
      SyncHistoryCompanion(
        syncCompletedAt: Value(now),
        status: const Value('completed'),
        recordsExported: Value(recordsExported),
        recordsImported: Value(recordsImported),
        blobsTransferred: Value(blobsTransferred),
      ),
    );
  }

  Future<void> failSync({
    required String id,
    required String errorMessage,
    int recordsExported = 0,
    int recordsImported = 0,
    int blobsTransferred = 0,
    DateTime? failedAt,
  }) async {
    final now = failedAt ?? DateTime.now().toUtc();
    await (update(syncHistory)..where((tbl) => tbl.id.equals(id))).write(
      SyncHistoryCompanion(
        syncCompletedAt: Value(now),
        status: const Value('failed'),
        errorMessage: Value(errorMessage),
        recordsExported: Value(recordsExported),
        recordsImported: Value(recordsImported),
        blobsTransferred: Value(blobsTransferred),
      ),
    );
  }

  Future<List<SyncHistoryEntry>> getRecentSyncHistory({int limit = 20}) {
    return (select(syncHistory)
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.syncStartedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit))
        .get();
  }

  Stream<List<SyncHistoryEntry>> watchRecentSyncHistory({int limit = 10}) {
    return (select(syncHistory)
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.syncStartedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit))
        .watch();
  }

  Future<DateTime?> getLastSuccessfulSyncTime(String syncType) async {
    final row =
        await (select(syncHistory)
              ..where(
                (tbl) =>
                    tbl.syncType.equals(syncType) &
                    tbl.status.equals('completed'),
              )
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.syncCompletedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();

    return row?.syncCompletedAt;
  }

  // --- Local Mutation Scanning ---

  Future<List<WorkspaceEntry>> getMutatedWorkspaces(DateTime since) {
    return (select(
      workspaces,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<NodeEntry>> getMutatedNodes(DateTime since) {
    return (select(
      nodes,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<NodeLinkEntry>> getMutatedNodeLinks(DateTime since) {
    return (select(
      nodeLinks,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<TagEntry>> getMutatedTags(DateTime since) {
    return (select(
      tags,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<NodeTagEntry>> getMutatedNodeTags(DateTime since) {
    return (select(
      nodeTags,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<InkPageEntry>> getMutatedInkPages(DateTime since) {
    return (select(
      inkPages,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<PdfDocumentEntry>> getMutatedPdfDocuments(DateTime since) {
    return (select(
      pdfDocuments,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<ProjectEntry>> getMutatedProjects(DateTime since) {
    return (select(
      projects,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<TaskEntry>> getMutatedTasks(DateTime since) {
    return (select(
      tasks,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<CalendarEventEntry>> getMutatedCalendarEvents(DateTime since) {
    return (select(
      calendarEvents,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<HabitEntry>> getMutatedHabits(DateTime since) {
    return (select(
      habits,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<HabitLogEntry>> getMutatedHabitLogs(DateTime since) {
    return (select(
      habitLogs,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<GoalEntry>> getMutatedGoals(DateTime since) {
    return (select(
      goals,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  Future<List<JournalEntryData>> getMutatedJournalEntries(DateTime since) {
    return (select(
      journalEntries,
    )..where((tbl) => tbl.clientModifiedAt.isBiggerThanValue(since))).get();
  }

  // --- Remote Ingestion with Last-Write-Wins (LWW) ---

  Future<bool> upsertRemoteWorkspace(WorkspaceEntry incoming) async {
    final existing = await (select(
      workspaces,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false; // Local record is newer; keep local
    }

    await into(workspaces).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteNode(NodeEntry incoming) async {
    final existing = await (select(
      nodes,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(nodes).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteNodeLink(NodeLinkEntry incoming) async {
    final existing = await (select(
      nodeLinks,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(nodeLinks).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteTag(TagEntry incoming) async {
    final existing = await (select(
      tags,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(tags).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteNodeTag(NodeTagEntry incoming) async {
    final existing =
        await (select(nodeTags)..where(
              (tbl) =>
                  tbl.nodeId.equals(incoming.nodeId) &
                  tbl.tagId.equals(incoming.tagId),
            ))
            .getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(nodeTags).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteInkPage(InkPageEntry incoming) async {
    final existing = await (select(
      inkPages,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(inkPages).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemotePdfDocument(PdfDocumentEntry incoming) async {
    final existing = await (select(
      pdfDocuments,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(pdfDocuments).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteProject(ProjectEntry incoming) async {
    final existing = await (select(
      projects,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(projects).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteTask(TaskEntry incoming) async {
    final existing = await (select(
      tasks,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(tasks).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteCalendarEvent(CalendarEventEntry incoming) async {
    final existing = await (select(
      calendarEvents,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(calendarEvents).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteHabit(HabitEntry incoming) async {
    final existing = await (select(
      habits,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(habits).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteHabitLog(HabitLogEntry incoming) async {
    final existing = await (select(
      habitLogs,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(habitLogs).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteGoal(GoalEntry incoming) async {
    final existing = await (select(
      goals,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(goals).insertOnConflictUpdate(incoming);
    return true;
  }

  Future<bool> upsertRemoteJournalEntry(JournalEntryData incoming) async {
    final existing = await (select(
      journalEntries,
    )..where((tbl) => tbl.id.equals(incoming.id))).getSingleOrNull();

    if (existing != null &&
        existing.clientModifiedAt.isAfter(incoming.clientModifiedAt)) {
      return false;
    }

    await into(journalEntries).insertOnConflictUpdate(incoming);
    return true;
  }

  // --- Soft Delete Helper ---

  Future<void> softDeleteNode(
    String id, {
    String deviceId = 'local',
    DateTime? deletedAt,
  }) async {
    final now = deletedAt ?? DateTime.now().toUtc();
    final node = await (select(
      nodes,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
    if (node != null) {
      await (update(nodes)..where((tbl) => tbl.id.equals(id))).write(
        NodesCompanion(
          isDeleted: const Value(true),
          deletedAt: Value(now),
          clientModifiedAt: Value(now),
          modifiedDeviceId: Value(deviceId),
          syncVersion: Value(node.syncVersion + 1),
        ),
      );
    }
  }
}
