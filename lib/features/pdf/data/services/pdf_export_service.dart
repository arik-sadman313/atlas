import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/ink_dao.dart';
import '../../../../core/storage/blob_storage_service.dart';
import '../../../handwriting/data/repositories/ink_repository.dart';
import '../../../handwriting/domain/models/atlas_ink_document.dart';
import '../../../handwriting/presentation/widgets/ink_document_painter.dart';
import 'pdf_rendering_service.dart';

class PdfExportService {
  final InkDao inkDao;
  final BlobStorageService blobStorage;
  final PdfRenderingService pdfRenderingService;
  final InkRepository inkRepo;

  PdfExportService({
    required this.inkDao,
    required this.blobStorage,
    required this.pdfRenderingService,
    required this.inkRepo,
  });

  /// High-level method to export a notebook by its [documentId].
  Future<File> exportNotebookToPdf({
    required String documentId,
    required String title,
    String? outputDirectory,
    double rasterScale = 2.0,
  }) async {
    final pages = await inkDao.getPagesForDocument(documentId);
    final sanitizedTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final dir = outputDirectory ?? Directory.systemTemp.path;
    final outputPath = '$dir/$sanitizedTitle.pdf';

    return exportNotebookToFile(
      outputPath: outputPath,
      pages: pages,
      inkRepo: inkRepo,
      blobStorage: blobStorage,
      pdfRenderingService: pdfRenderingService,
      rasterScale: rasterScale,
    );
  }

  /// Exports an entire multi-page notebook (with background stationery or PDF pages
  /// and overlaid vector ink strokes) as a standard PDF file byte buffer.
  static Future<Uint8List> exportNotebookPagesToPdf({
    required List<InkPageEntry> pages,
    required InkRepository inkRepo,
    required BlobStorageService blobStorage,
    required PdfRenderingService pdfRenderingService,
    double rasterScale = 2.0,
  }) async {
    final pdf = pw.Document();

    for (final page in pages) {
      final inkDoc = await inkRepo.loadPageDrawing(page);
      Uint8List? backgroundRasterBytes;

      // 1. If page is an annotation of a PDF, fetch background raster
      if (page.pdfSourceHash != null && page.pdfPageIndex != null) {
        try {
          final pdfBytes = await blobStorage.readBlob(page.pdfSourceHash!);
          backgroundRasterBytes = await pdfRenderingService
              .renderBytesPageToImage(
                bytes: pdfBytes,
                pageIndex: page.pdfPageIndex!,
                scale: rasterScale,
              );
        } catch (_) {
          backgroundRasterBytes = null;
        }
      }

      // 2. Composite background + ink strokes into a single high-resolution image
      final compositeBytes = await renderCompositePageImage(
        page: page,
        inkDoc: inkDoc,
        backgroundImageBytes: backgroundRasterBytes,
        scale: rasterScale,
      );

      // 3. Add to PDF document matching page dimensions
      final pageFormat = PdfPageFormat(page.width, page.height, marginAll: 0);

      final pdfImage = pw.MemoryImage(compositeBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          build: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Image(pdfImage, fit: pw.BoxFit.fill),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Exports the notebook directly to a specified filesystem [outputPath].
  static Future<File> exportNotebookToFile({
    required String outputPath,
    required List<InkPageEntry> pages,
    required InkRepository inkRepo,
    required BlobStorageService blobStorage,
    required PdfRenderingService pdfRenderingService,
    double rasterScale = 2.0,
  }) async {
    final bytes = await exportNotebookPagesToPdf(
      pages: pages,
      inkRepo: inkRepo,
      blobStorage: blobStorage,
      pdfRenderingService: pdfRenderingService,
      rasterScale: rasterScale,
    );
    final file = File(outputPath);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  /// Offscreen software rasterizer combining background paper/PDF and ink strokes.
  static Future<Uint8List> renderCompositePageImage({
    required InkPageEntry page,
    required AtlasInkDocument inkDoc,
    Uint8List? backgroundImageBytes,
    double scale = 2.0,
  }) async {
    final widthPx = (page.width * scale).round();
    final heightPx = (page.height * scale).round();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Scale canvas to match target raster resolution
    canvas.scale(scale, scale);

    final size = Size(page.width, page.height);

    // 1. Draw Background: either PDF page raster or paper template
    if (backgroundImageBytes != null && backgroundImageBytes.isNotEmpty) {
      final codec = await ui.instantiateImageCodec(backgroundImageBytes);
      final frame = await codec.getNextFrame();
      final bgImg = frame.image;

      canvas.drawImageRect(
        bgImg,
        Rect.fromLTWH(0, 0, bgImg.width.toDouble(), bgImg.height.toDouble()),
        Rect.fromLTWH(0, 0, page.width, page.height),
        Paint()..filterQuality = FilterQuality.high,
      );
    } else {
      PaperPatternPainter.paintPattern(
        canvas,
        size,
        page.templateType,
        Color(page.backgroundColor),
        spacing: page.templateSpacing,
      );
    }

    // 2. Draw Ink Strokes using InkDocumentPainter (drawBackground = false)
    final painter = InkDocumentPainter(document: inkDoc, drawBackground: false);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(widthPx, heightPx);
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
