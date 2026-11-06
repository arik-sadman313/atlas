import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/node_blocks_table.dart';
import '../tables/nodes_table.dart';

part 'nodes_dao.g.dart';

@DriftAccessor(tables: [Nodes, NodeBlocks])
class NodesDao extends DatabaseAccessor<AppDatabase> with _$NodesDaoMixin {
  NodesDao(super.db);

  Stream<List<NodeEntry>> watchNodesInWorkspace(
    String workspaceId, {
    String? type,
    String? parentId,
  }) {
    final query = select(nodes)
      ..where((tbl) => tbl.workspaceId.equals(workspaceId))
      ..where((tbl) => tbl.isDeleted.equals(false));

    if (type != null) {
      query.where((tbl) => tbl.type.equals(type));
    }
    if (parentId != null) {
      query.where((tbl) => tbl.parentId.equals(parentId));
    } else {
      query.where((tbl) => tbl.parentId.isNull());
    }

    query.orderBy([
      (tbl) => OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
      (tbl) => OrderingTerm(expression: tbl.updatedAt, mode: OrderingMode.desc),
    ]);

    return query.watch();
  }

  Stream<List<NodeEntry>> watchRecentNodes(
    String workspaceId, {
    int limit = 10,
  }) {
    return (select(nodes)
          ..where((tbl) => tbl.workspaceId.equals(workspaceId))
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit))
        .watch();
  }

  Future<List<NodeEntry>> getRecentNodes(String workspaceId, {int limit = 10}) {
    return (select(nodes)
          ..where((tbl) => tbl.workspaceId.equals(workspaceId))
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(limit))
        .get();
  }

  Stream<List<NodeEntry>> watchFavoriteNodes(String workspaceId) {
    return (select(nodes)
          ..where((tbl) => tbl.workspaceId.equals(workspaceId))
          ..where((tbl) => tbl.isFavorite.equals(true))
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }

  Future<NodeEntry?> getNode(String id) {
    return (select(nodes)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> createNode(NodesCompanion node) {
    return into(nodes).insert(node);
  }

  Future<bool> updateNode(NodesCompanion node) {
    return update(nodes).replace(node);
  }

  Future<int> updateNodePartial(String id, NodesCompanion fields) {
    return (update(nodes)..where((tbl) => tbl.id.equals(id))).write(fields);
  }

  Future<int> deleteNode(String id, {bool hardDelete = false}) {
    if (hardDelete) {
      return (delete(nodes)..where((tbl) => tbl.id.equals(id))).go();
    } else {
      return (update(nodes)..where((tbl) => tbl.id.equals(id))).write(
        NodesCompanion(
          isDeleted: const Value(true),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  Future<List<NodeEntry>> searchNodes(String workspaceId, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value([]);
    return (select(nodes)
          ..where((tbl) => tbl.workspaceId.equals(workspaceId))
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..where((tbl) => tbl.title.like('%$trimmed%'))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Future<NodeEntry?> findNodeByTitle(String workspaceId, String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return Future.value(null);
    return (select(nodes)
          ..where((tbl) => tbl.workspaceId.equals(workspaceId))
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..where((tbl) => tbl.title.collate(Collate.noCase).equals(trimmed))
          ..limit(1))
        .getSingleOrNull();
  }

  Future<int> updateContentHash(String nodeId, String? contentHash) {
    return (update(nodes)..where((tbl) => tbl.id.equals(nodeId))).write(
      NodesCompanion(
        contentHash: Value(contentHash),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Stream<List<NodeBlockEntry>> watchBlocksForNode(String nodeId) {
    return (select(nodeBlocks)
          ..where((tbl) => tbl.nodeId.equals(nodeId))
          ..orderBy([
            (tbl) =>
                OrderingTerm(expression: tbl.sortOrder, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Future<void> createBlock(NodeBlocksCompanion block) {
    return into(nodeBlocks).insert(block);
  }

  Future<bool> updateBlock(NodeBlocksCompanion block) {
    return update(nodeBlocks).replace(block);
  }

  Future<int> deleteBlock(String blockId) {
    return (delete(nodeBlocks)..where((tbl) => tbl.id.equals(blockId))).go();
  }

  Future<List<NodeEntry>> getAllNodes(String workspaceId) {
    return (select(nodes)
          ..where((tbl) => tbl.workspaceId.equals(workspaceId))
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .get();
  }

  Stream<List<NodeEntry>> watchAllNodes(String workspaceId) {
    return (select(nodes)
          ..where((tbl) => tbl.workspaceId.equals(workspaceId))
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.updatedAt,
              mode: OrderingMode.desc,
            ),
          ]))
        .watch();
  }
}
