import 'package:drift/drift.dart';

@DataClassName('SyncHistoryEntry')
class SyncHistory extends Table {
  TextColumn get id => text()();
  DateTimeColumn get syncStartedAt => dateTime()();
  DateTimeColumn get syncCompletedAt => dateTime().nullable()();
  TextColumn get syncType => text()(); // 'vault_export' | 'vault_import' | 'folder_sync' | 'changeset_apply'
  TextColumn get status => text()(); // 'in_progress' | 'completed' | 'failed'
  IntColumn get recordsExported => integer().withDefault(const Constant(0))();
  IntColumn get recordsImported => integer().withDefault(const Constant(0))();
  IntColumn get blobsTransferred => integer().withDefault(const Constant(0))();
  TextColumn get errorMessage => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
