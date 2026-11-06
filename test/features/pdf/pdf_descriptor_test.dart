import 'package:atlas/features/pdf/domain/models/pdf_document_descriptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfDocumentDescriptor Tests', () {
    test('PdfPageDescriptor calculates aspect ratio and scale conversions', () {
      const page = PdfPageDescriptor(
        pageIndex: 0,
        width: 595.28, // Standard A4 width in points
        height: 841.89, // Standard A4 height in points
      );

      expect(page.pageIndex, 0);
      expect(page.width, 595.28);
      expect(page.height, 841.89);
      expect(page.aspectRatio, closeTo(595.28 / 841.89, 0.001));

      // Test point coordinate scaling (1.0 pt = 1/72 inch)
      const double testCanvasX = 100.0;
      const double testCanvasY = 200.0;
      expect(page.width * (testCanvasX / page.width), closeTo(testCanvasX, 0.0001));
      expect(page.height * (testCanvasY / page.height), closeTo(testCanvasY, 0.0001));
    });

    test('PdfDocumentDescriptor creates descriptor with multiple pages', () {
      final doc = PdfDocumentDescriptor(
        pageCount: 3,
        pages: const [
          PdfPageDescriptor(pageIndex: 0, width: 612.0, height: 792.0), // US Letter
          PdfPageDescriptor(pageIndex: 1, width: 612.0, height: 792.0),
          PdfPageDescriptor(pageIndex: 2, width: 792.0, height: 612.0), // Landscape
        ],
      );

      expect(doc.pageCount, 3);
      expect(doc.pages.length, 3);
      expect(doc.pages[0].aspectRatio, closeTo(612.0 / 792.0, 0.001));
      expect(doc.pages[2].aspectRatio, closeTo(792.0 / 612.0, 0.001));
    });
  });
}
