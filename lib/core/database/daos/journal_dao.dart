import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../app_database.dart';
import '../tables/journal_entries_table.dart';
import '../tables/nodes_table.dart';
import '../tables/workspaces_table.dart';

part 'journal_dao.g.dart';

@DriftAccessor(tables: [JournalEntries, Nodes, Workspaces])
class JournalDao extends DatabaseAccessor<AppDatabase> with _$JournalDaoMixin {
  final Uuid _uuid;

  JournalDao(super.db, {Uuid? uuid}) : _uuid = uuid ?? const Uuid();

  // --- Queries ---

  Future<JournalEntryData?> findEntryByDate(
    String workspaceId,
    String journalDate,
  ) {
    return (select(journalEntries)..where(
          (tbl) =>
              tbl.workspaceId.equals(workspaceId) &
              tbl.journalDate.equals(journalDate),
        ))
        .getSingleOrNull();
  }

  Stream<JournalEntryData?> watchEntryByDate(
    String workspaceId,
    String journalDate,
  ) {
    return (select(journalEntries)..where(
          (tbl) =>
              tbl.workspaceId.equals(workspaceId) &
              tbl.journalDate.equals(journalDate),
        ))
        .watchSingleOrNull();
  }

  Future<JournalEntryData?> findEntryByNodeId(String nodeId) {
    return (select(
      journalEntries,
    )..where((tbl) => tbl.nodeId.equals(nodeId))).getSingleOrNull();
  }

  Stream<JournalEntryData?> watchEntryByNodeId(String nodeId) {
    return (select(
      journalEntries,
    )..where((tbl) => tbl.nodeId.equals(nodeId))).watchSingleOrNull();
  }

  Stream<List<JournalEntryData>> watchRecentJournalEntries(
    String workspaceId, {
    int limit = 7,
  }) {
    final query = select(journalEntries)
      ..where((tbl) => tbl.workspaceId.equals(workspaceId))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.journalDate, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    return query.watch();
  }

  Future<List<JournalEntryData>> getRecentJournalEntries(
    String workspaceId, {
    int limit = 7,
  }) {
    final query = select(journalEntries)
      ..where((tbl) => tbl.workspaceId.equals(workspaceId))
      ..orderBy([
        (tbl) =>
            OrderingTerm(expression: tbl.journalDate, mode: OrderingMode.desc),
      ])
      ..limit(limit);

    return query.get();
  }

  // --- Mutations ---

  Future<JournalEntryData> createJournalEntry(
    JournalEntriesCompanion companion,
  ) async {
    final now = DateTime.now();
    final entryId = companion.id.present ? companion.id.value : _uuid.v4();

    final fullCompanion = companion.copyWith(
      id: Value(entryId),
      createdAt: companion.createdAt.present ? companion.createdAt : Value(now),
      updatedAt: companion.updatedAt.present ? companion.updatedAt : Value(now),
    );

    await into(journalEntries).insert(fullCompanion);
    return (select(
      journalEntries,
    )..where((tbl) => tbl.id.equals(entryId))).getSingle();
  }

  Future<bool> updateJournalEntry(JournalEntriesCompanion companion) async {
    final updated = companion.copyWith(updatedAt: Value(DateTime.now()));
    final count = await (update(
      journalEntries,
    )..where((tbl) => tbl.id.equals(companion.id.value))).write(updated);
    return count > 0;
  }

  Future<int> deleteJournalEntry(String id) {
    return (delete(journalEntries)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<int> deleteEntryByNodeId(String nodeId) {
    return (delete(
      journalEntries,
    )..where((tbl) => tbl.nodeId.equals(nodeId))).go();
  }
}
