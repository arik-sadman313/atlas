import 'package:drift/drift.dart';

import 'nodes_table.dart';

@DataClassName('NodeBlockEntry')
class NodeBlocks extends Table {
  TextColumn get id => text()();
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();
  TextColumn get parentBlockId => text().nullable().references(
    NodeBlocks,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get type => text()(); // 'paragraph', 'heading_1', etc.
  TextColumn get contentJson => text().withDefault(const Constant('{}'))();
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
