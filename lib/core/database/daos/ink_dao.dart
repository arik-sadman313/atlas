import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/ink_documents_table.dart';
import '../tables/ink_pages_table.dart';

part 'ink_dao.g.dart';

@DriftAccessor(tables: [InkDocuments, InkPages])
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
          ..where((tbl) => tbl.documentId.equals(documentId))
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
          ..where((tbl) => tbl.documentId.equals(documentId))
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

  Future<int> deletePage(String id) {
    return (delete(inkPages)..where((tbl) => tbl.id.equals(id))).go();
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
