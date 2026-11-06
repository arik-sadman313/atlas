import 'package:atlas/core/database/app_database.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Schema Migration v4 Tests', () {
    late AppDatabase database;

    setUp(() {
      database = AppDatabase.inMemory();
    });

    tearDown(() async {
      await database.close();
    });

    test(
      'fresh database initializes schema version 4 with all tables',
      () async {
        expect(database.schemaVersion, greaterThanOrEqualTo(4));

        final now = DateTime.now();

        // 1. Verify workspace insertion
        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: 'ws-v4',
                name: 'Workspace v4',
                createdAt: now,
                updatedAt: now,
              ),
            );

        // 2. Verify notebook node insertion
        await database
            .into(database.nodes)
            .insert(
              NodesCompanion.insert(
                id: 'node-nb-1',
                workspaceId: 'ws-v4',
                type: 'notebook',
                title: 'Quarterly Financials',
                icon: const Value('picture_as_pdf'),
                createdAt: now,
                updatedAt: now,
              ),
            );

        // 3. Verify pdf_documents table insertion
        final pdfId = 'pdf-doc-1';
        await database.inkDao.insertPdfDocument(
          PdfDocumentsCompanion.insert(
            id: pdfId,
            nodeId: 'node-nb-1',
            casHash: 'cas-pdf-sha256-abc',
            fileName: 'quarterly_report.pdf',
            fileSizeBytes: 1048576,
            pageCount: 3,
            createdAt: now,
          ),
        );

        final pdfDoc = await database.inkDao.getPdfDocument(pdfId);
        expect(pdfDoc, isNotNull);
        expect(pdfDoc!.fileName, 'quarterly_report.pdf');
        expect(pdfDoc.pageCount, 3);
        expect(pdfDoc.casHash, 'cas-pdf-sha256-abc');

        final pdfDocByNode = await database.inkDao.getPdfDocumentForNode(
          'node-nb-1',
        );
        expect(pdfDocByNode?.id, pdfId);

        // 4. Create ink_documents container
        final inkDocId = 'inkdoc-node-nb-1';
        await database.inkDao.createDocument(
          InkDocumentsCompanion.insert(
            id: inkDocId,
            nodeId: 'node-nb-1',
            defaultPageWidth: const Value(595.28),
            defaultPageHeight: const Value(841.89),
            defaultTemplate: const Value('blank'),
            createdAt: now,
            updatedAt: now,
          ),
        );

        // 5. Insert pages with new v4 columns: pdfDocumentId, pdfPageIndex, templateSpacing
        await database.inkDao.createPage(
          InkPagesCompanion.insert(
            id: 'page-1',
            documentId: inkDocId,
            pageNumber: 1,
            width: const Value(595.28),
            height: const Value(841.89),
            templateType: const Value('blank'),
            templateSpacing: const Value(28.35),
            pdfDocumentId: const Value('pdf-doc-1'),
            pdfSourceHash: const Value('cas-pdf-sha256-abc'),
            pdfPageIndex: const Value(0),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await database.inkDao.createPage(
          InkPagesCompanion.insert(
            id: 'page-2',
            documentId: inkDocId,
            pageNumber: 2,
            width: const Value(595.28),
            height: const Value(841.89),
            templateType: const Value('ruled'),
            templateSpacing: const Value(32.0),
            pdfDocumentId: const Value('pdf-doc-1'),
            pdfSourceHash: const Value('cas-pdf-sha256-abc'),
            pdfPageIndex: const Value(1),
            createdAt: now,
            updatedAt: now,
          ),
        );

        final pages = await database.inkDao.getPagesForDocument(inkDocId);
        expect(pages.length, 2);
        expect(pages[0].pdfDocumentId, 'pdf-doc-1');
        expect(pages[0].pdfPageIndex, 0);
        expect(pages[0].templateSpacing, 28.35);
        expect(pages[1].pdfPageIndex, 1);
        expect(pages[1].templateSpacing, 32.0);
      },
    );

    test('multi-page reordering (batchReorderPages) updates 1-based page numbers contiguously', () async {
      final now = DateTime.now();

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-reorder',
              name: 'Workspace Reorder',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'node-reorder',
              workspaceId: 'ws-reorder',
              type: 'notebook',
              title: 'Reorder Test',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final docId = 'doc-reorder';
      await database.inkDao.createDocument(
        InkDocumentsCompanion.insert(
          id: docId,
          nodeId: 'node-reorder',
          createdAt: now,
          updatedAt: now,
        ),
      );

      for (int i = 1; i <= 4; i++) {
        await database.inkDao.createPage(
          InkPagesCompanion.insert(
            id: 'p-$i',
            documentId: docId,
            pageNumber: i,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }

      var pages = await database.inkDao.getPagesForDocument(docId);
      expect(pages.map((p) => p.id).toList(), ['p-1', 'p-2', 'p-3', 'p-4']);

      // Reverse order: p-4, p-3, p-2, p-1
      await database.inkDao.batchReorderPages(docId, [
        'p-4',
        'p-3',
        'p-2',
        'p-1',
      ]);

      pages = await database.inkDao.getPagesForDocument(docId);
      expect(pages.map((p) => p.id).toList(), ['p-4', 'p-3', 'p-2', 'p-1']);
      expect(pages.map((p) => p.pageNumber).toList(), [1, 2, 3, 4]);
    });

    test(
      'insertPageAt shifts subsequent page numbers and maintains sequence',
      () async {
        final now = DateTime.now();

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: 'ws-insert',
                name: 'Workspace Insert',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await database
            .into(database.nodes)
            .insert(
              NodesCompanion.insert(
                id: 'node-insert',
                workspaceId: 'ws-insert',
                type: 'notebook',
                title: 'Insert Test',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final docId = 'doc-insert';
        await database.inkDao.createDocument(
          InkDocumentsCompanion.insert(
            id: docId,
            nodeId: 'node-insert',
            createdAt: now,
            updatedAt: now,
          ),
        );

        await database.inkDao.createPage(
          InkPagesCompanion.insert(
            id: 'orig-1',
            documentId: docId,
            pageNumber: 1,
            createdAt: now,
            updatedAt: now,
          ),
        );
        await database.inkDao.createPage(
          InkPagesCompanion.insert(
            id: 'orig-2',
            documentId: docId,
            pageNumber: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );

        // Insert at position 2
        await database.inkDao.insertPageAt(
          docId,
          2,
          InkPagesCompanion.insert(
            id: 'inserted-mid',
            documentId: docId,
            pageNumber: 2,
            createdAt: now,
            updatedAt: now,
          ),
        );

        final pages = await database.inkDao.getPagesForDocument(docId);
        expect(pages.length, 3);
        expect(pages[0].id, 'orig-1');
        expect(pages[0].pageNumber, 1);
        expect(pages[1].id, 'inserted-mid');
        expect(pages[1].pageNumber, 2);
        expect(pages[2].id, 'orig-2');
        expect(pages[2].pageNumber, 3);
      },
    );

    test(
      'duplicatePage duplicates page properties and inserts right below source',
      () async {
        final now = DateTime.now();

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: 'ws-dup',
                name: 'Workspace Dup',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await database
            .into(database.nodes)
            .insert(
              NodesCompanion.insert(
                id: 'node-dup',
                workspaceId: 'ws-dup',
                type: 'notebook',
                title: 'Dup Test',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final docId = 'doc-dup';
        await database.inkDao.createDocument(
          InkDocumentsCompanion.insert(
            id: docId,
            nodeId: 'node-dup',
            createdAt: now,
            updatedAt: now,
          ),
        );

        await database.inkDao.createPage(
          InkPagesCompanion.insert(
            id: 'source-p1',
            documentId: docId,
            pageNumber: 1,
            templateType: const Value('dot_grid_5mm'),
            templateSpacing: const Value(14.17),
            rawPencilkitHash: const Value('cas-pk-hash-xyz'),
            createdAt: now,
            updatedAt: now,
          ),
        );

        final duplicated = await database.inkDao.duplicatePage(
          'source-p1',
          'dup-p2',
        );

        expect(duplicated, isNotNull);
        expect(duplicated!.id, 'dup-p2');
        expect(duplicated.pageNumber, 2);
        expect(duplicated.templateType, 'dot_grid_5mm');
        expect(duplicated.templateSpacing, 14.17);
        expect(duplicated.rawPencilkitHash, 'cas-pk-hash-xyz');

        final pages = await database.inkDao.getPagesForDocument(docId);
        expect(pages.length, 2);
        expect(pages[0].id, 'source-p1');
        expect(pages[1].id, 'dup-p2');
      },
    );

    test(
      'deletePageAndReorder removes page and closes gap in numbering',
      () async {
        final now = DateTime.now();

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: 'ws-del',
                name: 'Workspace Del',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await database
            .into(database.nodes)
            .insert(
              NodesCompanion.insert(
                id: 'node-del',
                workspaceId: 'ws-del',
                type: 'notebook',
                title: 'Delete Test',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final docId = 'doc-del';
        await database.inkDao.createDocument(
          InkDocumentsCompanion.insert(
            id: docId,
            nodeId: 'node-del',
            createdAt: now,
            updatedAt: now,
          ),
        );

        for (int i = 1; i <= 3; i++) {
          await database.inkDao.createPage(
            InkPagesCompanion.insert(
              id: 'del-p$i',
              documentId: docId,
              pageNumber: i,
              createdAt: now,
              updatedAt: now,
            ),
          );
        }

        // Delete page 2 ('del-p2')
        await database.inkDao.deletePageAndReorder('del-p2');

        final pages = await database.inkDao.getPagesForDocument(docId);
        expect(pages.length, 2);
        expect(pages[0].id, 'del-p1');
        expect(pages[0].pageNumber, 1);
        expect(pages[1].id, 'del-p3');
        expect(pages[1].pageNumber, 2); // shifted from 3 to 2
      },
    );

    test(
      'updatePageTemplate changes stationery template and spacing',
      () async {
        final now = DateTime.now();

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: 'ws-tpl',
                name: 'Workspace Tpl',
                createdAt: now,
                updatedAt: now,
              ),
            );

        await database
            .into(database.nodes)
            .insert(
              NodesCompanion.insert(
                id: 'node-tpl',
                workspaceId: 'ws-tpl',
                type: 'notebook',
                title: 'Template Test',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final docId = 'doc-tpl';
        await database.inkDao.createDocument(
          InkDocumentsCompanion.insert(
            id: docId,
            nodeId: 'node-tpl',
            createdAt: now,
            updatedAt: now,
          ),
        );

        await database.inkDao.createPage(
          InkPagesCompanion.insert(
            id: 'tpl-p1',
            documentId: docId,
            pageNumber: 1,
            templateType: const Value('ruled'),
            templateSpacing: const Value(28.0),
            createdAt: now,
            updatedAt: now,
          ),
        );

        await database.inkDao.updatePageTemplate('tpl-p1', 'grid', 40.0);

        final page = await database.inkDao.getPage('tpl-p1');
        expect(page, isNotNull);
        expect(page!.templateType, 'grid');
        expect(page.templateSpacing, 40.0);
      },
    );
  });
}
