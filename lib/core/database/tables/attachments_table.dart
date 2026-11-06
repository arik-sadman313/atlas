import 'package:drift/drift.dart';

@DataClassName('AttachmentEntry')
class Attachments extends Table {
  TextColumn get sha256Hash => text()();
  TextColumn get relativePath => text()();
  TextColumn get fileName => text()();
  TextColumn get mimeType => text()();
  IntColumn get byteSize => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {sha256Hash};
}
