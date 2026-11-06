import 'package:drift/drift.dart';

import 'nodes_table.dart';

@DataClassName('NodeLinkEntry')
@TableIndex(name: 'idx_node_links_source', columns: {#sourceNodeId})
@TableIndex(name: 'idx_node_links_target', columns: {#targetNodeId})
class NodeLinks extends Table {
  TextColumn get id => text()();
  @ReferenceName('outgoingLinks')
  TextColumn get sourceNodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();

  @ReferenceName('incomingLinks')
  TextColumn get targetNodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();
  TextColumn get linkText => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
