// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_dao.dart';

// ignore_for_file: type=lint
mixin _$SyncDaoMixin on DatabaseAccessor<AppDatabase> {
  $SyncHistoryTable get syncHistory => attachedDatabase.syncHistory;
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $NodesTable get nodes => attachedDatabase.nodes;
  $NodeLinksTable get nodeLinks => attachedDatabase.nodeLinks;
  $TagsTable get tags => attachedDatabase.tags;
  $NodeTagsTable get nodeTags => attachedDatabase.nodeTags;
  $InkDocumentsTable get inkDocuments => attachedDatabase.inkDocuments;
  $PdfDocumentsTable get pdfDocuments => attachedDatabase.pdfDocuments;
  $InkPagesTable get inkPages => attachedDatabase.inkPages;
  $ProjectsTable get projects => attachedDatabase.projects;
  $TasksTable get tasks => attachedDatabase.tasks;
  $CalendarEventsTable get calendarEvents => attachedDatabase.calendarEvents;
  $HabitsTable get habits => attachedDatabase.habits;
  $HabitLogsTable get habitLogs => attachedDatabase.habitLogs;
  $GoalsTable get goals => attachedDatabase.goals;
  $JournalEntriesTable get journalEntries => attachedDatabase.journalEntries;
  SyncDaoManager get managers => SyncDaoManager(this);
}

class SyncDaoManager {
  final _$SyncDaoMixin _db;
  SyncDaoManager(this._db);
  $$SyncHistoryTableTableManager get syncHistory =>
      $$SyncHistoryTableTableManager(_db.attachedDatabase, _db.syncHistory);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db.attachedDatabase, _db.nodes);
  $$NodeLinksTableTableManager get nodeLinks =>
      $$NodeLinksTableTableManager(_db.attachedDatabase, _db.nodeLinks);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$NodeTagsTableTableManager get nodeTags =>
      $$NodeTagsTableTableManager(_db.attachedDatabase, _db.nodeTags);
  $$InkDocumentsTableTableManager get inkDocuments =>
      $$InkDocumentsTableTableManager(_db.attachedDatabase, _db.inkDocuments);
  $$PdfDocumentsTableTableManager get pdfDocuments =>
      $$PdfDocumentsTableTableManager(_db.attachedDatabase, _db.pdfDocuments);
  $$InkPagesTableTableManager get inkPages =>
      $$InkPagesTableTableManager(_db.attachedDatabase, _db.inkPages);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db.attachedDatabase, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db.attachedDatabase, _db.tasks);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(
        _db.attachedDatabase,
        _db.calendarEvents,
      );
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db.attachedDatabase, _db.habits);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db.attachedDatabase, _db.habitLogs);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db.attachedDatabase, _db.goals);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(
        _db.attachedDatabase,
        _db.journalEntries,
      );
}
