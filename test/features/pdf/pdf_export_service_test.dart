import 'dart:io';

import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/storage/blob_storage_service.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/handwriting/data/repositories/ink_repository.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/pdf/data/services/pdf_export_service.dart';
import 'package:atlas/features/pdf/data/services/pdf_rendering_service.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PdfExportService Tests', () {
    late AppDatabase database;
    late Directory tempDir;
    late BlobStorageService blobStorage;
    late InkRepository inkRepo;
    late PdfRenderingService pdfRenderingService;

    setUp(() async {
      database = AppDatabase.inMemory();
      tempDir = await Directory.systemTemp.createTemp('atlas_export_test_');
      blobStorage = CasStorageService(rootDirectory: tempDir);
      inkRepo = InkRepository(
        inkDao: database.inkDao,
        blobStorage: blobStorage,
      );
      pdfRenderingService = PdfrxRenderingService();
    });

    tearDown(() async {
      await database.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'renderCompositePageImage rasterizes page and stationery to PNG bytes',
      () async {
        final now = DateTime.now();
        final page = InkPageEntry(
          id: 'test-page-1',
          documentId: 'test-doc-1',
          pageNumber: 1,
          width: 400.0,
          height: 600.0,
          templateType: 'ruled',
          templateSpacing: 28.35,
          backgroundColor: 0xFFFFFFFF,
          createdAt: now,
          updatedAt: now,
        );

        final inkDoc = AtlasInkDocument.empty(
          documentId: 'test-doc-1',
          pageNumber: 1,
          width: 400.0,
          height: 600.0,
        );

        final pngBytes = await PdfExportService.renderCompositePageImage(
          page: page,
          inkDoc: inkDoc,
          scale: 1.0,
        );

        expect(pngBytes, isNotNull);
        expect(pngBytes.isNotEmpty, isTrue);
        // Verify PNG header bytes: 0x89, 'P', 'N', 'G'
        expect(pngBytes[0], 0x89);
        expect(pngBytes[1], 0x50);
        expect(pngBytes[2], 0x4E);
        expect(pngBytes[3], 0x47);
      },
    );

    test('exportNotebookPagesToPdf compiles multi-page document into valid PDF binary', () async {
      final now = DateTime.now();

      // Create workspace and node
      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-exp',
              name: 'Workspace Export',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'node-exp',
              workspaceId: 'ws-exp',
              type: 'notebook',
              title: 'Export Notebook',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final docId = 'doc-exp';
      await database.inkDao.createDocument(
        InkDocumentsCompanion.insert(
          id: docId,
          nodeId: 'node-exp',
          createdAt: now,
          updatedAt: now,
        ),
      );

      // Create 2 pages
      await database.inkDao.createPage(
        InkPagesCompanion.insert(
          id: 'exp-p1',
          documentId: docId,
          pageNumber: 1,
          width: const Value(500.0),
          height: const Value(700.0),
          templateType: const Value('ruled'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.inkDao.createPage(
        InkPagesCompanion.insert(
          id: 'exp-p2',
          documentId: docId,
          pageNumber: 2,
          width: const Value(500.0),
          height: const Value(700.0),
          templateType: const Value('grid'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final pages = await database.inkDao.getPagesForDocument(docId);

      final pdfBytes = await PdfExportService.exportNotebookPagesToPdf(
        pages: pages,
        inkRepo: inkRepo,
        blobStorage: blobStorage,
        pdfRenderingService: pdfRenderingService,
        rasterScale: 1.0,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));

      // Verify standard PDF header bytes: %PDF-
      final header = String.fromCharCodes(pdfBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });

    test('PdfExportService instance method exports notebook to file', () async {
      final now = DateTime.now();

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-inst',
              name: 'Workspace Instance',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'node-inst',
              workspaceId: 'ws-inst',
              type: 'notebook',
              title: 'Exported Notebook',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final docId = 'doc-inst';
      await database.inkDao.createDocument(
        InkDocumentsCompanion.insert(
          id: docId,
          nodeId: 'node-inst',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.inkDao.createPage(
        InkPagesCompanion.insert(
          id: 'inst-p1',
          documentId: docId,
          pageNumber: 1,
          width: const Value(400.0),
          height: const Value(600.0),
          templateType: const Value('blank'),
          createdAt: now,
          updatedAt: now,
        ),
      );

      final service = PdfExportService(
        inkDao: database.inkDao,
        blobStorage: blobStorage,
        pdfRenderingService: pdfRenderingService,
        inkRepo: inkRepo,
      );

      final exportedFile = await service.exportNotebookToPdf(
        documentId: docId,
        title: 'My Notes',
        outputDirectory: tempDir.path,
        rasterScale: 1.0,
      );

      expect(await exportedFile.exists(), isTrue);
      expect(exportedFile.path.endsWith('My Notes.pdf'), isTrue);
      final fileBytes = await exportedFile.readAsBytes();
      final header = String.fromCharCodes(fileBytes.sublist(0, 5));
      expect(header, '%PDF-');
    });
  });
}
