import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:pdfrx/pdfrx.dart';

import '../../domain/models/pdf_document_descriptor.dart';

abstract class PdfRenderingService {
  /// Opens a PDF from local filesystem [filePath] and inspects its metadata and dimensions.
  Future<PdfDocumentDescriptor> openFile(String filePath);

  /// Opens a PDF from in-memory [bytes] and inspects its metadata and dimensions.
  Future<PdfDocumentDescriptor> openBytes(Uint8List bytes);

  /// Renders a specific 0-indexed page from [filePath] into rasterized PNG bytes at [scale].
  Future<Uint8List?> renderPageToImage({
    required String filePath,
    required int pageIndex,
    double scale = 2.0,
  });

  /// Renders a specific 0-indexed page from [bytes] into rasterized PNG bytes at [scale].
  Future<Uint8List?> renderBytesPageToImage({
    required Uint8List bytes,
    required int pageIndex,
    double scale = 2.0,
  });
}

class PdfrxRenderingService implements PdfRenderingService {
  @override
  Future<PdfDocumentDescriptor> openFile(String filePath) async {
    final doc = await PdfDocument.openFile(filePath);
    final descriptors = <PdfPageDescriptor>[];
    for (int i = 0; i < doc.pages.length; i++) {
      final p = doc.pages[i];
      descriptors.add(
        PdfPageDescriptor(pageIndex: i, width: p.width, height: p.height),
      );
    }
    return PdfDocumentDescriptor(
      filePath: filePath,
      pageCount: doc.pages.length,
      pages: descriptors,
    );
  }

  @override
  Future<PdfDocumentDescriptor> openBytes(Uint8List bytes) async {
    final doc = await PdfDocument.openData(bytes);
    final descriptors = <PdfPageDescriptor>[];
    for (int i = 0; i < doc.pages.length; i++) {
      final p = doc.pages[i];
      descriptors.add(
        PdfPageDescriptor(pageIndex: i, width: p.width, height: p.height),
      );
    }
    return PdfDocumentDescriptor(
      pageCount: doc.pages.length,
      pages: descriptors,
    );
  }

  @override
  Future<Uint8List?> renderPageToImage({
    required String filePath,
    required int pageIndex,
    double scale = 2.0,
  }) async {
    final doc = await PdfDocument.openFile(filePath);
    if (pageIndex < 0 || pageIndex >= doc.pages.length) return null;
    final page = doc.pages[pageIndex];
    final targetWidth = (page.width * scale).round();
    final targetHeight = (page.height * scale).round();

    final pageImg = await page.render(width: targetWidth, height: targetHeight);
    if (pageImg == null) return null;

    final uiImg = await pageImg.createImage();
    final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  @override
  Future<Uint8List?> renderBytesPageToImage({
    required Uint8List bytes,
    required int pageIndex,
    double scale = 2.0,
  }) async {
    final doc = await PdfDocument.openData(bytes);
    if (pageIndex < 0 || pageIndex >= doc.pages.length) return null;
    final page = doc.pages[pageIndex];
    final targetWidth = (page.width * scale).round();
    final targetHeight = (page.height * scale).round();

    final pageImg = await page.render(width: targetWidth, height: targetHeight);
    if (pageImg == null) return null;

    final uiImg = await pageImg.createImage();
    final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }
}
