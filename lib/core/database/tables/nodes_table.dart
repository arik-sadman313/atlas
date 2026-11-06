import 'package:drift/drift.dart';

import 'workspaces_table.dart';

@DataClassName('NodeEntry')
class Nodes extends Table {
  TextColumn get id => text()();
  TextColumn get workspaceId =>
      text().references(Workspaces, #id, onDelete: KeyAction.cascade)();
  TextColumn get parentId =>
      text().nullable().references(Nodes, #id, onDelete: KeyAction.cascade)();
  TextColumn get type => text()(); // 'document' | 'notebook' | 'folder'
  TextColumn get title => text().withLength(min: 1, max: 500)();
  TextColumn get icon => text().nullable()();
  TextColumn get coverImageHash => text().nullable()();
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  BoolColumn get isPinned => boolean().withDefault(const Constant(false))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
