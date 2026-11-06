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
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get clientModifiedAt =>
      dateTime().withDefault(currentDateAndTime)();
  TextColumn get modifiedDeviceId =>
      text().withDefault(const Constant('local'))();
  IntColumn get syncVersion => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}
