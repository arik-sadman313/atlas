import 'package:drift/drift.dart';

import 'ink_documents_table.dart';
import 'pdf_documents_table.dart';

@DataClassName('InkPageEntry')
class InkPages extends Table {
  TextColumn get id => text()();
  TextColumn get documentId =>
      text().references(InkDocuments, #id, onDelete: KeyAction.cascade)();
  IntColumn get pageNumber => integer()();
  RealColumn get width => real().withDefault(const Constant(1600.0))();
  RealColumn get height => real().withDefault(const Constant(2200.0))();
  TextColumn get templateType =>
      text().withDefault(const Constant('dot_grid_5mm'))();
  RealColumn get templateSpacing => real().withDefault(const Constant(28.35))();
  IntColumn get backgroundColor =>
      integer().withDefault(const Constant(4294967295))();
  TextColumn get pdfDocumentId => text().nullable().references(
    PdfDocuments,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get pdfSourceHash => text().nullable()();
  IntColumn get pdfPageIndex => integer().nullable()();
  TextColumn get rawPencilkitHash => text().nullable()();
  TextColumn get portableInkHash => text().nullable()();
  TextColumn get previewPngHash => text().nullable()();
  TextColumn get ocrText => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
