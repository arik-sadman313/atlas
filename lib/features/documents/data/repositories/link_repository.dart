import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/links_dao.dart';
import '../../../../core/database/daos/nodes_dao.dart';
import '../../domain/parser/wiki_link_parser.dart';

class LinkRepository {
  final LinksDao linksDao;
  final NodesDao nodesDao;
  final Uuid uuid;

  LinkRepository({required this.linksDao, required this.nodesDao, Uuid? uuid})
    : uuid = uuid ?? const Uuid();

  /// Watches all incoming backlinks pointing to [nodeId].
  Stream<List<BacklinkItem>> watchBacklinks(String nodeId) {
    return linksDao.watchBacklinksForTarget(nodeId);
  }

  /// Gets all incoming backlinks pointing to [nodeId].
  Future<List<BacklinkItem>> getBacklinks(String nodeId) {
    return linksDao.getBacklinksForTarget(nodeId);
  }

  /// Watches forward links originating from [nodeId].
  Stream<List<ForwardLinkItem>> watchForwardLinks(String nodeId) {
    return linksDao.watchForwardLinksForSource(nodeId);
  }

  /// Synchronizes wiki links found in document text with the `node_links` table.
  /// Resolves target node IDs by searching node titles in the given [workspaceId].
  Future<void> syncLinksFromText({
    required String sourceNodeId,
    required String workspaceId,
    required String text,
  }) async {
    final matches = WikiLinkParser.extractLinks(text);
    await syncLinks(
      sourceNodeId: sourceNodeId,
      workspaceId: workspaceId,
      linkMatches: matches,
    );
  }

  /// Synchronizes extracted wiki link matches with the database.
  Future<void> syncLinks({
    required String sourceNodeId,
    required String workspaceId,
    required List<WikiLinkMatch> linkMatches,
  }) async {
    final companions = <NodeLinksCompanion>[];
    final seenTargetIds = <String>{};

    for (final match in linkMatches) {
      final targetNode = await nodesDao.findNodeByTitle(
        workspaceId,
        match.targetTitle,
      );

      // Only link if the target node exists in this workspace and isn't self-referencing
      if (targetNode != null && targetNode.id != sourceNodeId) {
        // Prevent duplicate link rows between the same pair in a single sync
        if (seenTargetIds.add(targetNode.id)) {
          companions.add(
            NodeLinksCompanion.insert(
              id: uuid.v4(),
              sourceNodeId: sourceNodeId,
              targetNodeId: targetNode.id,
              linkText: Value(match.displayText),
              createdAt: DateTime.now(),
            ),
          );
        }
      }
    }

    await linksDao.syncLinksForSource(sourceNodeId, companions);
  }

  /// Searches nodes matching [query] within [workspaceId] for autocompleting wiki-links.
  Future<List<NodeEntry>> searchTargets(String workspaceId, String query) {
    return nodesDao.searchNodes(workspaceId, query);
  }

  /// Resolves an exact or case-insensitive node title to a node entry.
  Future<NodeEntry?> resolveTitle(String workspaceId, String title) {
    return nodesDao.findNodeByTitle(workspaceId, title);
  }
}
