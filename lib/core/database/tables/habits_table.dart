import 'package:drift/drift.dart';

import 'workspaces_table.dart';

@DataClassName('HabitEntry')
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get description => text().nullable()();
  TextColumn get colorHex => text().withDefault(const Constant('#4CAF50'))();
  TextColumn get icon => text().nullable()();
  TextColumn get frequency => text().withDefault(const Constant('daily'))();
  IntColumn get targetCountPerPeriod =>
      integer().withDefault(const Constant(1))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
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
