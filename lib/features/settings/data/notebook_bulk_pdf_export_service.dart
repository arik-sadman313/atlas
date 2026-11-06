import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/ink_dao.dart';
import '../../../../core/storage/blob_storage_service.dart';
import '../../handwriting/data/repositories/ink_repository.dart';
import '../../pdf/data/services/pdf_export_service.dart';
import '../../pdf/data/services/pdf_rendering_service.dart';

/// Bulk exporter that compiles all notebooks and ink drawings in a workspace
/// into flattened, vector/raster composite standard PDF documents packaged in a ZIP archive.
class NotebookBulkPdfExportService {
  final AppDatabase database;
  final InkDao inkDao;
  final BlobStorageService blobStorage;
  final PdfRenderingService pdfRenderingService;
  final InkRepository inkRepo;

  NotebookBulkPdfExportService({
    required this.database,
    required this.inkDao,
    required this.blobStorage,
    required this.pdfRenderingService,
    required this.inkRepo,
  });

  /// Exports all notebooks in [workspaceId] as flattened PDF documents packaged inside a ZIP file.
  Future<File> exportWorkspaceNotebooksToZip({
    required String workspaceId,
    String? outputPath,
    double rasterScale = 2.0,
  }) async {
    final archive = Archive();

    // 1. Fetch all notebook nodes
    final notebooks =
        await (database.select(database.nodes)
              ..where(
                (tbl) =>
                    tbl.workspaceId.equals(workspaceId) &
                    tbl.type.equals('notebook') &
                    tbl.isDeleted.equals(false) &
                    tbl.deletedAt.isNull(),
              )
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();

    for (final notebook in notebooks) {
      final pages = await inkDao.getPagesForDocument(notebook.id);
      if (pages.isEmpty) {
        // Skip notebooks with no ink pages
        continue;
      }

      try {
        final pdfBytes = await PdfExportService.exportNotebookPagesToPdf(
          pages: pages,
          inkRepo: inkRepo,
          blobStorage: blobStorage,
          pdfRenderingService: pdfRenderingService,
          rasterScale: rasterScale,
        );

        final safeTitle = _sanitizeFilename(notebook.title);
        final shortId = notebook.id.length > 8
            ? notebook.id.substring(0, 8)
            : notebook.id;
        final filename = '${safeTitle}_$shortId.pdf';

        archive.addFile(ArchiveFile(filename, pdfBytes.length, pdfBytes));
      } catch (_) {
        // Skip single page rendering errors to complete bulk export
      }
    }

    final zipEncoder = ZipEncoder();
    final encodedZip = zipEncoder.encode(archive);

    final targetPath =
        outputPath ??
        '${Directory.systemTemp.path}/atlas_notebooks_pdf_export_${DateTime.now().millisecondsSinceEpoch}.zip';
    final zipFile = File(targetPath);
    await zipFile.writeAsBytes(encodedZip, flush: true);

    return zipFile;
  }

  String _sanitizeFilename(String title) {
    var sanitized = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (sanitized.isEmpty) {
      sanitized = 'Untitled_Notebook';
    }
    return sanitized;
  }
}
