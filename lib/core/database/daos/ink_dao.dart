import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/ink_documents_table.dart';
import '../tables/ink_pages_table.dart';
import '../tables/pdf_documents_table.dart';

part 'ink_dao.g.dart';

@DriftAccessor(tables: [InkDocuments, InkPages, PdfDocuments])
class InkDao extends DatabaseAccessor<AppDatabase> with _$InkDaoMixin {
  InkDao(super.db);

  Stream<InkDocumentEntry?> watchDocumentForNode(String nodeId) {
    return (select(
      inkDocuments,
    )..where((tbl) => tbl.nodeId.equals(nodeId))).watchSingleOrNull();
  }

  Future<InkDocumentEntry?> getDocumentForNode(String nodeId) {
    return (select(
      inkDocuments,
    )..where((tbl) => tbl.nodeId.equals(nodeId))).getSingleOrNull();
  }

  Future<InkDocumentEntry?> getDocument(String id) {
    return (select(
      inkDocuments,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> createDocument(InkDocumentsCompanion document) {
    return into(inkDocuments).insert(document);
  }

  Future<bool> updateDocument(InkDocumentsCompanion document) {
    return update(inkDocuments).replace(document);
  }

  Stream<List<InkPageEntry>> watchPagesForDocument(String documentId) {
    return (select(inkPages)
          ..where(
            (tbl) => tbl.documentId.equals(documentId) & tbl.deletedAt.isNull(),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.pageNumber,
              mode: OrderingMode.asc,
            ),
          ]))
        .watch();
  }

  Future<List<InkPageEntry>> getPagesForDocument(String documentId) {
    return (select(inkPages)
          ..where(
            (tbl) => tbl.documentId.equals(documentId) & tbl.deletedAt.isNull(),
          )
          ..orderBy([
            (tbl) => OrderingTerm(
              expression: tbl.pageNumber,
              mode: OrderingMode.asc,
            ),
          ]))
        .get();
  }

  Future<InkPageEntry?> getPage(String id) {
    return (select(
      inkPages,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<void> createPage(InkPagesCompanion page) {
    return into(inkPages).insert(page);
  }

  Future<bool> updatePage(InkPagesCompanion page) {
    return update(inkPages).replace(page);
  }

  Future<int> deletePage(String id, {bool hardDelete = false}) {
    if (hardDelete) {
      return (delete(inkPages)..where((tbl) => tbl.id.equals(id))).go();
    }
    final now = DateTime.now().toUtc();
    return (update(inkPages)..where((tbl) => tbl.id.equals(id))).write(
      InkPagesCompanion(
        deletedAt: Value(now),
        clientModifiedAt: Value(now),
        updatedAt: Value(now),
      ),
    );
  }

  /// Batch updates page order for a given document.
  Future<void> batchReorderPages(
    String documentId,
    List<String> pageIdsInOrder,
  ) async {
    for (int i = 0; i < pageIdsInOrder.length; i++) {
      final pageId = pageIdsInOrder[i];
      await (update(inkPages)..where((tbl) => tbl.id.equals(pageId))).write(
        InkPagesCompanion(
          pageNumber: Value(i + 1),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Inserts a new page at [targetPageNumber] and shifts existing subsequent pages up.
  Future<void> insertPageAt(
    String documentId,
    int targetPageNumber,
    InkPagesCompanion newPage,
  ) async {
    final existingPages =
        await (select(inkPages)
              ..where(
                (tbl) =>
                    tbl.documentId.equals(documentId) &
                    tbl.pageNumber.isBiggerOrEqualValue(targetPageNumber),
              )
              ..orderBy([(tbl) => OrderingTerm.desc(tbl.pageNumber)]))
            .get();

    for (final page in existingPages) {
      await (update(inkPages)..where((tbl) => tbl.id.equals(page.id))).write(
        InkPagesCompanion(
          pageNumber: Value(page.pageNumber + 1),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }

    await into(inkPages).insert(newPage);
  }

  /// Deletes a page and shifts subsequent pages down to keep 1-based page numbers contiguous.
  Future<void> deletePageAndReorder(String pageId) async {
    final page = await getPage(pageId);
    if (page == null) return;

    await (delete(inkPages)..where((tbl) => tbl.id.equals(pageId))).go();

    final subsequentPages =
        await (select(inkPages)
              ..where(
                (tbl) =>
                    tbl.documentId.equals(page.documentId) &
                    tbl.pageNumber.isBiggerThanValue(page.pageNumber),
              )
              ..orderBy([(tbl) => OrderingTerm.asc(tbl.pageNumber)]))
            .get();

    for (final p in subsequentPages) {
      await (update(inkPages)..where((tbl) => tbl.id.equals(p.id))).write(
        InkPagesCompanion(
          pageNumber: Value(p.pageNumber - 1),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
  }

  /// Duplicates [sourcePageId] right after it and reorders subsequent pages.
  Future<InkPageEntry?> duplicatePage(
    String sourcePageId,
    String newPageId,
  ) async {
    final source = await getPage(sourcePageId);
    if (source == null) return null;

    final targetPageNumber = source.pageNumber + 1;
    final now = DateTime.now();
    final newPage = InkPagesCompanion.insert(
      id: newPageId,
      documentId: source.documentId,
      pageNumber: targetPageNumber,
      width: Value(source.width),
      height: Value(source.height),
      templateType: Value(source.templateType),
      templateSpacing: Value(source.templateSpacing),
      backgroundColor: Value(source.backgroundColor),
      pdfDocumentId: Value(source.pdfDocumentId),
      pdfSourceHash: Value(source.pdfSourceHash),
      pdfPageIndex: Value(source.pdfPageIndex),
      rawPencilkitHash: Value(source.rawPencilkitHash),
      portableInkHash: Value(source.portableInkHash),
      previewPngHash: Value(source.previewPngHash),
      ocrText: Value(source.ocrText),
      createdAt: now,
      updatedAt: now,
    );

    await insertPageAt(source.documentId, targetPageNumber, newPage);
    return getPage(newPageId);
  }

  /// Updates stationery template type and spacing for a page.
  Future<void> updatePageTemplate(
    String pageId,
    String templateType,
    double templateSpacing,
  ) async {
    await (update(inkPages)..where((tbl) => tbl.id.equals(pageId))).write(
      InkPagesCompanion(
        templateType: Value(templateType),
        templateSpacing: Value(templateSpacing),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  // PDF Document methods
  Future<void> insertPdfDocument(PdfDocumentsCompanion pdfDoc) {
    return into(pdfDocuments).insert(pdfDoc);
  }

  Future<PdfDocumentEntry?> getPdfDocument(String id) {
    return (select(
      pdfDocuments,
    )..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  Future<PdfDocumentEntry?> getPdfDocumentForNode(String nodeId) {
    return (select(
      pdfDocuments,
    )..where((tbl) => tbl.nodeId.equals(nodeId))).getSingleOrNull();
  }

  Future<PdfDocumentEntry?> getPdfDocumentByCasHash(String casHash) {
    return (select(
      pdfDocuments,
    )..where((tbl) => tbl.casHash.equals(casHash))).getSingleOrNull();
  }

  Future<int> deletePdfDocument(String id) {
    return (delete(pdfDocuments)..where((tbl) => tbl.id.equals(id))).go();
  }

  Future<InkDocumentEntry> getOrCreateDocumentForNode(
    String nodeId, {
    double defaultWidth = 1600.0,
    double defaultHeight = 2200.0,
    String defaultTemplate = 'dot_grid_5mm',
  }) async {
    final existing = await getDocumentForNode(nodeId);
    if (existing != null) {
      return existing;
    }
    final now = DateTime.now();
    final docId = 'inkdoc_$nodeId';
    await createDocument(
      InkDocumentsCompanion.insert(
        id: docId,
        nodeId: nodeId,
        defaultPageWidth: Value(defaultWidth),
        defaultPageHeight: Value(defaultHeight),
        defaultTemplate: Value(defaultTemplate),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Create initial page 1
    final pageId = 'page_${docId}_1';
    await createPage(
      InkPagesCompanion.insert(
        id: pageId,
        documentId: docId,
        pageNumber: 1,
        width: Value(defaultWidth),
        height: Value(defaultHeight),
        templateType: Value(defaultTemplate),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return (await getDocumentForNode(nodeId))!;
  }
}
