import 'package:drift/drift.dart';

import 'nodes_table.dart';
import 'workspaces_table.dart';

@DataClassName('JournalEntryData')
class JournalEntries extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();
  TextColumn get journalDate => text()(); // YYYY-MM-DD
  TextColumn get mood =>
      text().nullable()(); // great, good, neutral, bad, awful
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get clientModifiedAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get modifiedDeviceId =>
      text().withDefault(const Constant('local'))();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workspaceId, journalDate},
  ];
}
