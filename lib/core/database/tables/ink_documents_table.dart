import 'package:drift/drift.dart';

import 'nodes_table.dart';

@DataClassName('InkDocumentEntry')
class InkDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();
  RealColumn get defaultPageWidth =>
      real().withDefault(const Constant(1600.0))();
  RealColumn get defaultPageHeight =>
      real().withDefault(const Constant(2200.0))();
  TextColumn get defaultTemplate =>
      text().withDefault(const Constant('dot_grid_5mm'))();
  IntColumn get defaultBackgroundColor =>
      integer().withDefault(const Constant(4294967295))(); // 0xFFFFFFFF
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
