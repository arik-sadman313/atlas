import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/node_links_table.dart';
import '../tables/nodes_table.dart';
import '../tables/tags_table.dart';

part 'links_dao.g.dart';

class BacklinkItem {
  final String linkId;
  final String sourceNodeId;
  final String sourceTitle;
  final String sourceType;
  final String? sourceIcon;
  final String? linkText;
  final DateTime sourceUpdatedAt;
  final DateTime createdAt;

  const BacklinkItem({
    required this.linkId,
    required this.sourceNodeId,
    required this.sourceTitle,
    required this.sourceType,
    this.sourceIcon,
    this.linkText,
    required this.sourceUpdatedAt,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BacklinkItem &&
          runtimeType == other.runtimeType &&
          linkId == other.linkId &&
          sourceNodeId == other.sourceNodeId;

  @override
  int get hashCode => linkId.hashCode ^ sourceNodeId.hashCode;
}

class ForwardLinkItem {
  final String linkId;
  final String targetNodeId;
  final String targetTitle;
  final String targetType;
  final String? targetIcon;
  final String? linkText;
  final DateTime createdAt;

  const ForwardLinkItem({
    required this.linkId,
    required this.targetNodeId,
    required this.targetTitle,
    required this.targetType,
    this.targetIcon,
    this.linkText,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ForwardLinkItem &&
          runtimeType == other.runtimeType &&
          linkId == other.linkId &&
          targetNodeId == other.targetNodeId;

  @override
  int get hashCode => linkId.hashCode ^ targetNodeId.hashCode;
}

@DriftAccessor(tables: [NodeLinks, Nodes, Tags, NodeTags])
class LinksDao extends DatabaseAccessor<AppDatabase> with _$LinksDaoMixin {
  LinksDao(super.db);

  Future<void> insertLink(NodeLinksCompanion link) {
    return into(nodeLinks).insert(link);
  }

  Future<void> insertLinks(List<NodeLinksCompanion> links) {
    return batch((b) => b.insertAll(nodeLinks, links));
  }

  Future<int> deleteLinksForSource(String sourceNodeId) {
    return (delete(nodeLinks)..where((tbl) => tbl.sourceNodeId.equals(sourceNodeId))).go();
  }

  Future<void> syncLinksForSource(
    String sourceNodeId,
    List<NodeLinksCompanion> newLinks,
  ) async {
    await (delete(nodeLinks)..where((tbl) => tbl.sourceNodeId.equals(sourceNodeId))).go();
    if (newLinks.isNotEmpty) {
      await batch((b) => b.insertAll(nodeLinks, newLinks));
    }
  }

  Stream<List<BacklinkItem>> watchBacklinksForTarget(String targetNodeId) {
    final query = select(nodeLinks).join([
      innerJoin(nodes, nodes.id.equalsExp(nodeLinks.sourceNodeId)),
    ])..where(nodeLinks.targetNodeId.equals(targetNodeId))
      ..where(nodes.isDeleted.equals(false))
      ..orderBy([
        OrderingTerm(expression: nodes.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.watch().map((rows) {
      return rows.map((row) {
        final link = row.readTable(nodeLinks);
        final sourceNode = row.readTable(nodes);
        return BacklinkItem(
          linkId: link.id,
          sourceNodeId: sourceNode.id,
          sourceTitle: sourceNode.title,
          sourceType: sourceNode.type,
          sourceIcon: sourceNode.icon,
          linkText: link.linkText,
          sourceUpdatedAt: sourceNode.updatedAt,
          createdAt: link.createdAt,
        );
      }).toList();
    });
  }

  Future<List<BacklinkItem>> getBacklinksForTarget(String targetNodeId) {
    final query = select(nodeLinks).join([
      innerJoin(nodes, nodes.id.equalsExp(nodeLinks.sourceNodeId)),
    ])..where(nodeLinks.targetNodeId.equals(targetNodeId))
      ..where(nodes.isDeleted.equals(false))
      ..orderBy([
        OrderingTerm(expression: nodes.updatedAt, mode: OrderingMode.desc),
      ]);

    return query.get().then((rows) {
      return rows.map((row) {
        final link = row.readTable(nodeLinks);
        final sourceNode = row.readTable(nodes);
        return BacklinkItem(
          linkId: link.id,
          sourceNodeId: sourceNode.id,
          sourceTitle: sourceNode.title,
          sourceType: sourceNode.type,
          sourceIcon: sourceNode.icon,
          linkText: link.linkText,
          sourceUpdatedAt: sourceNode.updatedAt,
          createdAt: link.createdAt,
        );
      }).toList();
    });
  }

  Stream<List<ForwardLinkItem>> watchForwardLinksForSource(String sourceNodeId) {
    final query = select(nodeLinks).join([
      innerJoin(nodes, nodes.id.equalsExp(nodeLinks.targetNodeId)),
    ])..where(nodeLinks.sourceNodeId.equals(sourceNodeId))
      ..where(nodes.isDeleted.equals(false));

    return query.watch().map((rows) {
      return rows.map((row) {
        final link = row.readTable(nodeLinks);
        final targetNode = row.readTable(nodes);
        return ForwardLinkItem(
          linkId: link.id,
          targetNodeId: targetNode.id,
          targetTitle: targetNode.title,
          targetType: targetNode.type,
          targetIcon: targetNode.icon,
          linkText: link.linkText,
          createdAt: link.createdAt,
        );
      }).toList();
    });
  }

  Future<List<NodeLinkEntry>> getLinksForSource(String sourceNodeId) {
    return (select(nodeLinks)..where((tbl) => tbl.sourceNodeId.equals(sourceNodeId))).get();
  }

  // Tags
  Future<void> addTag(TagsCompanion tag) => into(tags).insert(tag);

  Future<TagEntry?> getTagByName(String workspaceId, String name) =>
      (select(tags)..where((t) => t.workspaceId.equals(workspaceId) & t.name.equals(name)))
          .getSingleOrNull();

  Future<void> tagNode(String nodeId, String tagId) =>
      into(nodeTags).insert(
        NodeTagsCompanion.insert(nodeId: nodeId, tagId: tagId),
        mode: InsertMode.insertOrIgnore,
      );

  Stream<List<TagEntry>> watchTagsForNode(String nodeId) {
    final query = select(tags).join([
      innerJoin(nodeTags, nodeTags.tagId.equalsExp(tags.id)),
    ])..where(nodeTags.nodeId.equals(nodeId));

    return query.watch().map((rows) => rows.map((r) => r.readTable(tags)).toList());
  }
}
