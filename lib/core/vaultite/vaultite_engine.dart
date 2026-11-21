import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../database/daos/ink_dao.dart';
import '../database/daos/links_dao.dart';
import '../database/daos/nodes_dao.dart';
import '../storage/blob_storage_service.dart';
import '../../features/handwriting/data/serializers/ink_json_serializer.dart';
import '../../features/handwriting/domain/models/atlas_ink_document.dart';
import 'vaultite_frontmatter.dart';
import 'vaultite_index.dart';
import 'vaultite_link_parser.dart';
import 'vaultite_models.dart';

/// Central Vaultite Note-Taking Engine for Atlas.
///
/// Merges file-based Obsidian/Vaultite markdown semantics, bidirectional knowledge graphs,
/// YAML frontmatter properties, and interactive handwritten notebooks/canvases into one unified system.
class VaultiteEngine {
  final NodesDao nodesDao;
  final LinksDao linksDao;
  final InkDao inkDao;
  final BlobStorageService blobStorage;
  final VaultiteIndex index;
  final Uuid _uuid;

  VaultiteEngine({
    required this.nodesDao,
    required this.linksDao,
    required this.inkDao,
    required this.blobStorage,
    VaultiteIndex? index,
    Uuid? uuid,
  }) : index = index ?? VaultiteIndex(),
       _uuid = uuid ?? const Uuid();

  /// Loads and indexes all notes and handwritten notebooks for [workspaceId] into the Vaultite Index.
  Future<void> loadVault(String workspaceId) async {
    final nodes = await nodesDao.getAllNodes(workspaceId);
    final items = <VaultiteItem>[];

    for (final node in nodes) {
      if (node.isDeleted || node.deletedAt != null) continue;

      String body = '';
      if (node.contentHash != null && node.contentHash!.isNotEmpty) {
        try {
          final bytes = await blobStorage.readBlob(node.contentHash!);
          if (bytes.isNotEmpty) {
            body = utf8.decode(bytes);
          }
        } catch (_) {
          // Fallback if blob is temporarily unavailable
        }
      }

      final (props, cleanBody) = VaultiteFrontmatter.parse(body);

      // Determine kind: note, notebook, idea, etc.
      VaultiteKind kind;
      if (node.type == 'notebook') {
        kind = VaultiteKind.notebook;
      } else {
        kind = VaultiteKind.fromString(props['kind']?.toString());
      }

      final status = VaultiteStatus.fromString(props['status']?.toString());
      final tags = VaultiteFrontmatter.extractTags(props['tags']);
      final aliases = VaultiteFrontmatter.extractAliases(props['aliases']);

      items.add(
        VaultiteItem(
          id: node.id,
          title: node.title,
          path: '${node.title}.md',
          kind: kind,
          status: status,
          tags: tags,
          aliases: aliases,
          created: node.createdAt,
          updated: node.updatedAt,
          source: props['source']?.toString(),
          properties: props,
          body: cleanBody,
          handwritingDocumentId: node.type == 'notebook' ? node.id : null,
        ),
      );
    }

    index.setAll(items);
  }

  /// Saves a Markdown note with Vaultite frontmatter and syncs bidirectional links.
  Future<VaultiteItem> saveMarkdownNote({
    required String id,
    required String workspaceId,
    required String title,
    required String markdownBody,
    Map<String, dynamic>? properties,
  }) async {
    final now = DateTime.now().toUtc();
    final (parsedProps, bodyText) = VaultiteFrontmatter.parse(markdownBody);

    final mergedProps = <String, dynamic>{
      'title': title,
      'updated': now.toIso8601String(),
      ...parsedProps,
      ...?properties,
    };

    final fullMarkdown = VaultiteFrontmatter.render(mergedProps, bodyText);
    final bytes = Uint8List.fromList(utf8.encode(fullMarkdown));
    final hash = await blobStorage.writeBlob(bytes);

    // Save or update Node entry
    final existingNode = await nodesDao.getNode(id);
    if (existingNode == null) {
      await nodesDao.createNode(
        NodesCompanion(
          id: Value(id),
          workspaceId: Value(workspaceId),
          type: const Value('document'),
          title: Value(title),
          contentHash: Value(hash),
          createdAt: Value(now),
          updatedAt: Value(now),
          clientModifiedAt: Value(now),
        ),
      );
    } else {
      await nodesDao.updateNodePartial(
        id,
        NodesCompanion(
          title: Value(title),
          contentHash: Value(hash),
          updatedAt: Value(now),
          clientModifiedAt: Value(now),
        ),
      );
    }

    // Synchronize Wiki-Links to the database
    final links = VaultiteLinkParser.extractLinks(fullMarkdown);
    await _syncDatabaseLinks(
      sourceNodeId: id,
      workspaceId: workspaceId,
      links: links,
    );

    // Update in-memory index
    final item = VaultiteItem(
      id: id,
      title: title,
      path: '$title.md',
      kind: VaultiteKind.fromString(mergedProps['kind']?.toString()),
      status: VaultiteStatus.fromString(mergedProps['status']?.toString()),
      tags: VaultiteFrontmatter.extractTags(mergedProps['tags']),
      aliases: VaultiteFrontmatter.extractAliases(mergedProps['aliases']),
      created: existingNode?.createdAt ?? now,
      updated: now,
      source: mergedProps['source']?.toString(),
      properties: mergedProps,
      body: bodyText,
    );

    index.registerItem(item);
    return item;
  }

  /// Saves a Handwritten Notebook / Ink Document as a native Vaultite entity,
  /// indexing its text elements, sticky notes, and [[WikiLinks]].
  Future<VaultiteItem> saveHandwrittenNotebook({
    required String id,
    required String workspaceId,
    required String title,
    required AtlasInkDocument inkDoc,
    Map<String, dynamic>? properties,
  }) async {
    final now = DateTime.now().toUtc();

    // 1. Serialize ink document
    final inkJson = InkJsonSerializer.serialize(inkDoc);
    final inkBytes = Uint8List.fromList(utf8.encode(inkJson));
    final inkHash = await blobStorage.writeBlob(inkBytes);

    // 2. Extract text transcripts and any [[WikiLinks]] in text boxes or sticky notes
    final textElements = <String>[];
    for (final stroke in inkDoc.allStrokes) {
      if (stroke.text != null && stroke.text!.trim().isNotEmpty) {
        textElements.add(stroke.text!.trim());
      }
    }
    final extractedBody = textElements.join('\n\n');

    // 3. Frontmatter properties for the notebook
    final mergedProps = <String, dynamic>{
      'title': title,
      'kind': 'notebook',
      'pages': inkDoc.pageNumber,
      'updated': now.toIso8601String(),
      ...?properties,
    };

    // Update Node entry
    final existingNode = await nodesDao.getNode(id);
    if (existingNode == null) {
      await nodesDao.createNode(
        NodesCompanion(
          id: Value(id),
          workspaceId: Value(workspaceId),
          type: const Value('notebook'),
          title: Value(title),
          contentHash: Value(inkHash),
          createdAt: Value(now),
          updatedAt: Value(now),
          clientModifiedAt: Value(now),
        ),
      );
    } else {
      await nodesDao.updateNodePartial(
        id,
        NodesCompanion(
          title: Value(title),
          contentHash: Value(inkHash),
          updatedAt: Value(now),
          clientModifiedAt: Value(now),
        ),
      );
    }

    // 4. Sync links found inside handwritten text/sticky notes
    final links = VaultiteLinkParser.extractLinks(extractedBody);
    await _syncDatabaseLinks(
      sourceNodeId: id,
      workspaceId: workspaceId,
      links: links,
    );

    final item = VaultiteItem(
      id: id,
      title: title,
      path: '$title.atlas.md',
      kind: VaultiteKind.notebook,
      tags: VaultiteFrontmatter.extractTags(mergedProps['tags']),
      aliases: VaultiteFrontmatter.extractAliases(mergedProps['aliases']),
      created: existingNode?.createdAt ?? now,
      updated: now,
      source: mergedProps['source']?.toString(),
      properties: mergedProps,
      body: extractedBody,
      handwritingDocumentId: id,
      pageCount: inkDoc.pageNumber,
    );

    index.registerItem(item);
    return item;
  }

  /// Syncs extracted links to the database `node_links` table for persistent bidirectional backlinks.
  Future<void> _syncDatabaseLinks({
    required String sourceNodeId,
    required String workspaceId,
    required List<VaultiteLink> links,
  }) async {
    final companions = <NodeLinksCompanion>[];
    final seenTargetIds = <String>{};
    final now = DateTime.now().toUtc();

    for (final link in links) {
      final target = index.resolve(link.target);
      String? targetId = target?.id;

      if (targetId == null) {
        // Fallback to database lookup
        final node = await nodesDao.findNodeByTitle(workspaceId, link.target);
        targetId = node?.id;
      }

      if (targetId != null &&
          !seenTargetIds.contains(targetId) &&
          targetId != sourceNodeId) {
        seenTargetIds.add(targetId);
        companions.add(
          NodeLinksCompanion.insert(
            id: _uuid.v4(),
            sourceNodeId: sourceNodeId,
            targetNodeId: targetId,
            linkText: Value(link.displayText),
            createdAt: now,
          ),
        );
      }
    }

    await linksDao.syncLinksForSource(sourceNodeId, companions);
  }

  /// Creates a standard Obsidian embed string for a notebook or page.
  /// Example: `![[Architecture Notes#Page 1]]`
  static String formatNotebookEmbed(String title, {int? pageNumber}) {
    if (pageNumber != null && pageNumber > 1) {
      return '![[$title#Page $pageNumber]]';
    }
    return '![[$title]]';
  }
}
