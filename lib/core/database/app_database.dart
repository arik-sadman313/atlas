import 'dart:io';

import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;
import 'daos/calendar_dao.dart';
import 'daos/habits_dao.dart';
import 'daos/ink_dao.dart';
import 'daos/journal_dao.dart';
import 'daos/links_dao.dart';
import 'daos/nodes_dao.dart';
import 'daos/sync_dao.dart';
import 'daos/tasks_dao.dart';
import 'daos/workspaces_dao.dart';
import 'tables/attachments_table.dart';
import 'tables/calendar_events_table.dart';
import 'tables/goals_table.dart';
import 'tables/habit_logs_table.dart';
import 'tables/habits_table.dart';
import 'tables/ink_documents_table.dart';
import 'tables/ink_pages_table.dart';
import 'tables/journal_entries_table.dart';
import 'tables/node_blocks_table.dart';
import 'tables/node_links_table.dart';
import 'tables/nodes_table.dart';
import 'tables/pdf_documents_table.dart';
import 'tables/projects_table.dart';
import 'tables/sync_history_table.dart';
import 'tables/tags_table.dart';
import 'tables/tasks_table.dart';
import 'tables/workspaces_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Workspaces,
    Nodes,
    NodeBlocks,
    Attachments,
    InkDocuments,
    InkPages,
    PdfDocuments,
    NodeLinks,
    Tags,
    NodeTags,
    Projects,
    Tasks,
    CalendarEvents,
    Habits,
    HabitLogs,
    Goals,
    JournalEntries,
    SyncHistory,
  ],
  daos: [
    WorkspacesDao,
    NodesDao,
    InkDao,
    LinksDao,
    TasksDao,
    CalendarDao,
    HabitsDao,
    JournalDao,
    SyncDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? impl.connect());

  AppDatabase.forTesting(DatabaseConnection super.connection);

  AppDatabase.inMemory() : super(impl.connect(inMemory: true));

  AppDatabase.withFile(File file) : super(impl.connect(overrideFile: file));

  @override
  int get schemaVersion => 7;

  /// Flushes in-flight WAL journal to the main SQLite database file.
  Future<void> walCheckpoint() async {
    try {
      await customStatement('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {
      // Gracefully handle in-memory or unsupported checkpointing
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(inkDocuments);
        await m.createTable(inkPages);
      }
      if (from < 3) {
        await m.addColumn(nodes, nodes.contentHash);
        await m.createTable(nodeLinks);
        await m.createTable(tags);
        await m.createTable(nodeTags);
      }
      if (from < 4) {
        await m.createTable(pdfDocuments);
        await m.addColumn(inkPages, inkPages.pdfDocumentId);
        await m.addColumn(inkPages, inkPages.templateSpacing);
      }
      if (from < 5) {
        await m.createTable(projects);
        await m.createTable(tasks);
        await m.createTable(calendarEvents);
      }
      if (from < 6) {
        await m.createTable(habits);
        await m.createTable(habitLogs);
        await m.createTable(goals);
        await m.createTable(journalEntries);
      }
      if (from < 7) {
        await m.createTable(syncHistory);

        // Add sync metadata columns to all 14 tables
        final List<TableInfo> tablesWithSync = [
          workspaces,
          nodes,
          nodeLinks,
          tags,
          nodeTags,
          inkPages,
          pdfDocuments,
          projects,
          tasks,
          calendarEvents,
          habits,
          habitLogs,
          goals,
          journalEntries,
        ];

        for (final table in tablesWithSync) {
          await m.addColumn(table, table.columnsByName['deleted_at']!);
          await m.addColumn(table, table.columnsByName['client_modified_at']!);
          await m.addColumn(table, table.columnsByName['modified_device_id']!);
          await m.addColumn(table, table.columnsByName['sync_version']!);
        }
      }
    },
    beforeOpen: (details) async {
      // Foreign keys are enabled in connection setup
    },
  );
}
