import 'package:drift/drift.dart';

import 'nodes_table.dart';
import 'projects_table.dart';
import 'workspaces_table.dart';

@DataClassName('TaskEntry')
class Tasks extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get projectId => text().nullable().references(
    Projects,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get nodeId =>
      text().nullable().references(Nodes, #id, onDelete: KeyAction.setNull)();
  TextColumn get parentTaskId =>
      text().nullable().references(Tasks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 1000)();
  TextColumn get description => text().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
  IntColumn get priority => integer().withDefault(const Constant(4))();
  DateTimeColumn get dueDate => dateTime().nullable()();
  BoolColumn get hasTime => boolean().withDefault(const Constant(false))();
  DateTimeColumn get completedAt => dateTime().nullable()();
  TextColumn get recurrenceRule => text().nullable()();
  IntColumn get reminderMinutesBefore => integer().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
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
}
