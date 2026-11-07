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
  int get schemaVersion => 8;

  /// Flushes in-flight WAL journal to the main SQLite database file.
  Future<void> walCheckpoint() async {
    try {
      await customStatement('PRAGMA wal_checkpoint(FULL);');
    } catch (_) {
      // Gracefully handle in-memory or unsupported checkpointing
    }
  }

  Future<bool> _tableExists(String tableName) async {
    final rows = await customSelect(
      "SELECT name FROM sqlite_master WHERE type='table' AND name='$tableName';",
    ).get();
    return rows.isNotEmpty;
  }

  Future<void> _safeAddColumn(
    Migrator m,
    TableInfo table,
    GeneratedColumn column,
  ) async {
    final rows = await customSelect(
      'PRAGMA table_info("${table.actualTableName}");',
    ).get();
    final existingCols = rows.map((r) => r.read<String>('name')).toSet();
    if (!existingCols.contains(column.name)) {
      await m.addColumn(table, column);
    }
  }

  Future<void> _safeAddColumnCustom(
    String tableName,
    String columnName,
    String columnSql,
  ) async {
    final rows = await customSelect('PRAGMA table_info("$tableName");').get();
    final existingCols = rows.map((r) => r.read<String>('name')).toSet();
    if (!existingCols.contains(columnName)) {
      await customStatement(
        'ALTER TABLE "$tableName" ADD COLUMN "$columnName" $columnSql;',
      );
    }
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        if (!await _tableExists('ink_documents')) {
          await m.createTable(inkDocuments);
        }
        if (!await _tableExists('ink_pages')) {
          await m.createTable(inkPages);
        }
      }
      if (from < 3) {
        await _safeAddColumn(m, nodes, nodes.contentHash);
        if (!await _tableExists('node_links')) {
          await m.createTable(nodeLinks);
        }
        if (!await _tableExists('tags')) {
          await m.createTable(tags);
        }
        if (!await _tableExists('node_tags')) {
          await m.createTable(nodeTags);
        }
      }
      if (from < 4) {
        if (!await _tableExists('pdf_documents')) {
          await m.createTable(pdfDocuments);
        }
        await _safeAddColumn(m, inkPages, inkPages.pdfDocumentId);
        await _safeAddColumn(m, inkPages, inkPages.templateSpacing);
      }
      if (from < 5) {
        if (!await _tableExists('projects')) {
          await m.createTable(projects);
        }
        if (!await _tableExists('tasks')) {
          await m.createTable(tasks);
        }
        if (!await _tableExists('calendar_events')) {
          await m.createTable(calendarEvents);
        }
      }
      if (from < 6) {
        if (!await _tableExists('habits')) {
          await m.createTable(habits);
        }
        if (!await _tableExists('habit_logs')) {
          await m.createTable(habitLogs);
        }
        if (!await _tableExists('goals')) {
          await m.createTable(goals);
        }
        if (!await _tableExists('journal_entries')) {
          await m.createTable(journalEntries);
        }
      }
      if (from < 7) {
        if (!await _tableExists('sync_history')) {
          await m.createTable(syncHistory);
        }

        // Add sync metadata columns to all 14 tables safely and idempotently
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

        final nowEpoch = DateTime.now().millisecondsSinceEpoch ~/ 1000;

        for (final table in tablesWithSync) {
          await _safeAddColumnCustom(
            table.actualTableName,
            'deleted_at',
            'INTEGER',
          );
          await _safeAddColumnCustom(
            table.actualTableName,
            'client_modified_at',
            'INTEGER NOT NULL DEFAULT $nowEpoch',
          );
          await _safeAddColumnCustom(
            table.actualTableName,
            'modified_device_id',
            "TEXT NOT NULL DEFAULT 'local'",
          );
          await _safeAddColumnCustom(
            table.actualTableName,
            'sync_version',
            'INTEGER NOT NULL DEFAULT 1',
          );
        }
      }
      if (from < 8) {
        await _safeAddColumn(m, tasks, tasks.status);
      }
    },
    beforeOpen: (details) async {
      // Foreign keys are enabled in connection setup
    },
  );
}
