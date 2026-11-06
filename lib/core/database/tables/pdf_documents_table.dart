import 'package:drift/drift.dart';

import 'nodes_table.dart';

@DataClassName('PdfDocumentEntry')
class PdfDocuments extends Table {
  TextColumn get id => text()();
  TextColumn get nodeId =>
      text().references(Nodes, #id, onDelete: KeyAction.cascade)();
  TextColumn get casHash => text()();
  TextColumn get fileName => text()();
  IntColumn get fileSizeBytes => integer()();
  IntColumn get pageCount => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
