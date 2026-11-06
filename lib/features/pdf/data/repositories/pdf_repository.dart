import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/ink_dao.dart';
import '../../../../core/database/daos/nodes_dao.dart';
import '../../../../core/storage/blob_storage_service.dart';
import '../services/pdf_rendering_service.dart';

class PdfRepository {
  final InkDao inkDao;
  final NodesDao nodesDao;
  final BlobStorageService blobStorage;
  final PdfRenderingService pdfRenderingService;
  final Uuid uuid;

  PdfRepository({
    required this.inkDao,
    required this.nodesDao,
    required this.blobStorage,
    required this.pdfRenderingService,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  /// Imports a local PDF file into ATLAS:
  /// 1. Stores original PDF binary into CAS blob storage.
  /// 2. Inspects page count and dimensions via [PdfRenderingService].
  /// 3. Creates parent Notebook node in SQLite.
  /// 4. Creates `pdf_documents` entry referencing the CAS hash.
  /// 5. Scaffolds an `ink_page` for each PDF page matching its exact width/height points.
  ///
  /// Returns the newly created Notebook Node ID.
  Future<String> importPdf({
    required String workspaceId,
    required String filePath,
    String? customTitle,
    Uint8List? fileBytes,
  }) async {
    final bytes = fileBytes ?? await File(filePath).readAsBytes();
    final fileName = p.basename(filePath);

    // 1. Store PDF bytes into Content-Addressable Storage
    final casHash = await blobStorage.writeBlob(
      bytes,
      fileName: fileName,
      mimeType: 'application/pdf',
    );

    // 2. Inspect PDF structure
    final descriptor = await pdfRenderingService.openBytes(bytes);
    final now = DateTime.now();

    // 3. Create parent notebook node
    final nodeId = uuid.v4();
    final title = (customTitle != null && customTitle.trim().isNotEmpty)
        ? customTitle.trim()
        : (p.basenameWithoutExtension(fileName).isNotEmpty
              ? p.basenameWithoutExtension(fileName)
              : 'Imported PDF');

    await nodesDao.createNode(
      NodesCompanion.insert(
        id: nodeId,
        workspaceId: workspaceId,
        type: 'notebook',
        title: title,
        icon: const Value('picture_as_pdf'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 4. Create pdf_documents record
    final pdfDocId = uuid.v4();
    await inkDao.insertPdfDocument(
      PdfDocumentsCompanion.insert(
        id: pdfDocId,
        nodeId: nodeId,
        casHash: casHash,
        fileName: fileName,
        fileSizeBytes: bytes.length,
        pageCount: descriptor.pageCount,
        createdAt: now,
      ),
    );

    // 5. Create ink_documents container
    final inkDocId = 'inkdoc_$nodeId';
    final firstPageWidth = descriptor.pages.isNotEmpty
        ? descriptor.pages.first.width
        : 595.28;
    final firstPageHeight = descriptor.pages.isNotEmpty
        ? descriptor.pages.first.height
        : 841.89;

    await inkDao.createDocument(
      InkDocumentsCompanion.insert(
        id: inkDocId,
        nodeId: nodeId,
        defaultPageWidth: Value(firstPageWidth),
        defaultPageHeight: Value(firstPageHeight),
        defaultTemplate: const Value('blank'),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 6. Scaffold an ink_page for each PDF page
    for (int i = 0; i < descriptor.pages.length; i++) {
      final page = descriptor.pages[i];
      final pageId = 'page_pdf_${pdfDocId}_${i + 1}';
      await inkDao.createPage(
        InkPagesCompanion.insert(
          id: pageId,
          documentId: inkDocId,
          pageNumber: i + 1,
          width: Value(page.width),
          height: Value(page.height),
          templateType: const Value('blank'),
          templateSpacing: const Value(28.35),
          pdfDocumentId: Value(pdfDocId),
          pdfSourceHash: Value(casHash),
          pdfPageIndex: Value(i),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    return nodeId;
  }

  /// Retrieves the PDF metadata entry associated with [nodeId], if any.
  Future<PdfDocumentEntry?> getPdfDocumentForNode(String nodeId) {
    return inkDao.getPdfDocumentForNode(nodeId);
  }

  /// Retrieves a PDF metadata entry by its primary key [pdfId].
  Future<PdfDocumentEntry?> getPdfDocument(String pdfId) {
    return inkDao.getPdfDocument(pdfId);
  }

  /// Reads the raw PDF bytes from CAS storage using [casHash].
  Future<Uint8List> getOriginalPdfBytes(String casHash) {
    return blobStorage.readBlob(casHash);
  }

  /// Resolves the absolute filesystem path to a stored PDF blob.
  Future<String> getPdfFilePath(String casHash) {
    return blobStorage.getBlobPath(casHash);
  }
}
