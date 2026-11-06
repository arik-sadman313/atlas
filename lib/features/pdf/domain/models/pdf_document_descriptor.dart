class PdfPageDescriptor {
  /// 0-indexed page index within the PDF document
  final int pageIndex;

  /// Width in points (1 point = 1/72 inch)
  final double width;

  /// Height in points (1 point = 1/72 inch)
  final double height;

  const PdfPageDescriptor({
    required this.pageIndex,
    required this.width,
    required this.height,
  });

  double get aspectRatio => width / height;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PdfPageDescriptor &&
          runtimeType == other.runtimeType &&
          pageIndex == other.pageIndex &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => pageIndex.hashCode ^ width.hashCode ^ height.hashCode;
}

class PdfDocumentDescriptor {
  final String? filePath;
  final int pageCount;
  final List<PdfPageDescriptor> pages;

  const PdfDocumentDescriptor({
    this.filePath,
    required this.pageCount,
    required this.pages,
  });

  PdfPageDescriptor getPage(int index) {
    if (index < 0 || index >= pages.length) {
      throw RangeError.index(index, pages, 'pageIndex');
    }
    return pages[index];
  }
}
