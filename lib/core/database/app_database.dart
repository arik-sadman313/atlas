import 'dart:io';

import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;
import 'daos/ink_dao.dart';
import 'daos/links_dao.dart';
import 'daos/nodes_dao.dart';
import 'daos/workspaces_dao.dart';
import 'tables/attachments_table.dart';
import 'tables/ink_documents_table.dart';
import 'tables/ink_pages_table.dart';
import 'tables/node_blocks_table.dart';
import 'tables/node_links_table.dart';
import 'tables/nodes_table.dart';
import 'tables/tags_table.dart';
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
    NodeLinks,
    Tags,
    NodeTags,
  ],
  daos: [WorkspacesDao, NodesDao, InkDao, LinksDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? e]) : super(e ?? impl.connect());

  AppDatabase.forTesting(DatabaseConnection super.connection);

  AppDatabase.inMemory() : super(impl.connect(inMemory: true));

  AppDatabase.withFile(File file) : super(impl.connect(overrideFile: file));

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(inkDocuments);
        await m.createTable(inkPages);
      }
      if (from < 3) {
        await m.addColumn(nodes, nodes.contentHash);
        await m.createTable(nodeLinks);
        await m.createTable(tags);
        await m.createTable(nodeTags);
      }
    },
    beforeOpen: (details) async {
      // Foreign keys are enabled in connection setup
    },
  );
}
