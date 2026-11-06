import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/settings/data/markdown_export_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MarkdownExportService Tests', () {
    late Directory tempDir;
    late Directory casDir;
    late CasStorageService blobStorage;
    late AppDatabase database;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('atlas_md_export_test_');
      casDir = Directory(p.join(tempDir.path, 'cas'));
      await casDir.create(recursive: true);

      blobStorage = CasStorageService(rootDirectory: casDir);
      database = AppDatabase.inMemory();
    });

    tearDown(() async {
      await database.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('exports documents with YAML frontmatter, [[WikiLinks]], and assets into ZIP', () async {
      final now = DateTime.utc(2026, 11, 7, 10, 0);
      const wsId = 'ws-md-export';
      const nodeId = 'node-doc-1';

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Markdown Export WS',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // 1. Create a dummy PNG image blob
      final imageBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG magic header
        0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
      ]);
      final imageHash = await blobStorage.writeBlob(imageBytes);

      // 2. Create document content delta JSON
      final deltaOps = [
        {
          'insert': 'Project Architecture\n',
          'attributes': {'header': 1},
        },
        {'insert': 'Key principles include '},
        {
          'insert': 'offline-first',
          'attributes': {'bold': true},
        },
        {'insert': ' and '},
        {
          'insert': 'local storage',
          'attributes': {'italic': true},
        },
        {'insert': '.\n'},
        {'insert': 'Refer to '},
        {
          'insert': '[[System Design]]',
          'attributes': {'link': 'atlas://node/sys-design-id'},
        },
        {'insert': ' for details.\n'},
        {
          'insert': {'image': imageHash},
        },
        {'insert': '\n'},
      ];
      final deltaJson = jsonEncode(deltaOps);
      final contentHash = await blobStorage.writeBlob(
        Uint8List.fromList(utf8.encode(deltaJson)),
      );

      // 3. Insert node in database
      await database.nodesDao.createNode(
        NodesCompanion.insert(
          id: nodeId,
          workspaceId: wsId,
          type: 'document',
          title: 'Architecture Overview',
          contentHash: Value(contentHash),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 4. Attach tags to node
      const tagId = 'tag-arch';
      await database
          .into(database.tags)
          .insert(
            TagsCompanion.insert(
              id: tagId,
              workspaceId: wsId,
              name: 'engineering',
              color: const Value(0xFF3B82F6),
              createdAt: now,
            ),
          );
      await database
          .into(database.nodeTags)
          .insert(NodeTagsCompanion.insert(nodeId: nodeId, tagId: tagId));

      // 5. Run Markdown export
      final service = MarkdownExportService(
        database: database,
        blobStorage: blobStorage,
      );

      final zipFile = await service.exportWorkspaceToMarkdownZip(
        workspaceId: wsId,
      );
      expect(zipFile.existsSync(), isTrue);
      expect(zipFile.lengthSync(), greaterThan(0));

      // 6. Decode and verify ZIP contents
      final zipBytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(zipBytes);

      // Verify .md file exists
      final mdFiles = archive.where((f) => f.name.endsWith('.md')).toList();
      expect(mdFiles.length, 1);
      final mdContent = utf8.decode(mdFiles.first.content as List<int>);

      // Verify YAML frontmatter
      expect(mdContent, contains('---'));
      expect(mdContent, contains('id: "node-doc-1"'));
      expect(mdContent, contains('title: "Architecture Overview"'));
      expect(mdContent, contains('tags:'));
      expect(mdContent, contains('- "engineering"'));

      // Verify Markdown body formatting
      expect(mdContent, contains('# Project Architecture'));
      expect(mdContent, contains('**offline-first**'));
      expect(mdContent, contains('*local storage*'));
      expect(mdContent, contains('[[System Design]]'));
      expect(mdContent, contains('![image](assets/$imageHash.png)'));

      // Verify assets/ subfolder contains image
      final assetFiles = archive
          .where((f) => f.name.startsWith('assets/'))
          .toList();
      expect(assetFiles.length, 1);
      expect(assetFiles.first.name, 'assets/$imageHash.png');
      expect(assetFiles.first.content, imageBytes);
    });
  });
}
