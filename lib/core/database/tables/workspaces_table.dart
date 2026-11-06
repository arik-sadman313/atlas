import 'package:drift/drift.dart';

@DataClassName('WorkspaceEntry')
class Workspaces extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 255)();
  TextColumn get icon => text().nullable()();
  TextColumn get settingsJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get clientModifiedAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get modifiedDeviceId =>
      text().withDefault(const Constant('local'))();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
