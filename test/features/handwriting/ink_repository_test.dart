import 'dart:io';

import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/handwriting/data/repositories/ink_repository.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_layer.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late CasStorageService storage;
  late InkRepository repository;

  setUp(() async {
    db = AppDatabase.inMemory();
    tempDir = Directory.systemTemp.createTempSync('atlas_ink_repo_test_');
    storage = CasStorageService(rootDirectory: tempDir);
    repository = InkRepository(inkDao: db.inkDao, blobStorage: storage);

    // Setup default workspace and notebook node
    await db.workspacesDao.getOrCreateDefaultWorkspace();
    await db.nodesDao.createNode(
      NodesCompanion.insert(
        id: 'nb_test_01',
        workspaceId: 'workspace-default-primary',
        type: 'notebook',
        title: 'Physics Lab',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('InkRepository', () {
    test('loads empty drawing for newly initialized page', () async {
      final docEntry = await db.inkDao.getOrCreateDocumentForNode(
        'nb_test_01',
        defaultTemplate: 'ruled',
      );
      final pages = await db.inkDao.getPagesForDocument(docEntry.id);
      expect(pages, isNotEmpty);

      final inkDoc = await repository.loadPageDrawing(pages.first);

      expect(inkDoc.isEmpty, isTrue);
      expect(inkDoc.documentId, equals(docEntry.id));
      expect(inkDoc.backgroundTemplate, equals('ruled'));
    });

    test(
      'saves and reloads handwritten page drawing with CAS deduplication',
      () async {
        final docEntry = await db.inkDao.getOrCreateDocumentForNode(
          'nb_test_01',
        );
        final page = (await db.inkDao.getPagesForDocument(docEntry.id)).first;

        final stroke = InkStroke(
          id: 's_test_1',
          tool: InkToolType.ballpointPen,
          color: 0xFF18181B,
          baseWidth: 3.0,
          points: const [
            InkPoint(x: 10, y: 10, pressure: 0.5, timeOffsetMs: 0),
            InkPoint(x: 20, y: 25, pressure: 0.8, timeOffsetMs: 15),
          ],
        );

        final inkDocToSave = AtlasInkDocument(
          version: 1,
          documentId: docEntry.id,
          pageNumber: 1,
          width: page.width,
          height: page.height,
          backgroundTemplate: page.templateType,
          backgroundColor: page.backgroundColor,
          layers: [
            InkLayer(id: 'l1', name: 'Ink', strokes: [stroke]),
          ],
        );

        final updatedPage = await repository.savePageDrawing(
          page: page,
          doc: inkDocToSave,
        );

        expect(updatedPage.portableInkHash, isNotNull);
        expect(updatedPage.portableInkHash!.isNotEmpty, isTrue);

        // Verify blob exists in CAS
        expect(await storage.hasBlob(updatedPage.portableInkHash!), isTrue);

        // Re-load drawing
        final loadedDoc = await repository.loadPageDrawing(updatedPage);
        expect(loadedDoc.isEmpty, isFalse);
        expect(loadedDoc.layers.length, equals(1));
        expect(loadedDoc.layers.first.strokes.length, equals(1));
        expect(loadedDoc.layers.first.strokes.first.id, equals('s_test_1'));
      },
    );

    test(
      'gracefully recovers when portable ink blob is missing from storage',
      () async {
        final docEntry = await db.inkDao.getOrCreateDocumentForNode(
          'nb_test_01',
        );
        final page = (await db.inkDao.getPagesForDocument(docEntry.id)).first;

        // Assign non-existent hash
        final updatedCompanion = page
            .toCompanion(true)
            .copyWith(portableInkHash: const Value('non_existent_hash_12345'));
        await db.inkDao.updatePage(updatedCompanion);
        final corruptedPage = (await db.inkDao.getPage(page.id))!;

        // Should return an empty document rather than crashing
        final loadedDoc = await repository.loadPageDrawing(corruptedPage);
        expect(loadedDoc, isNotNull);
        expect(loadedDoc.isEmpty, isTrue);
      },
    );
  });
}
