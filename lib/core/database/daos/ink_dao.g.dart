// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ink_dao.dart';

// ignore_for_file: type=lint
mixin _$InkDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $NodesTable get nodes => attachedDatabase.nodes;
  $InkDocumentsTable get inkDocuments => attachedDatabase.inkDocuments;
  $InkPagesTable get inkPages => attachedDatabase.inkPages;
  InkDaoManager get managers => InkDaoManager(this);
}

class InkDaoManager {
  final _$InkDaoMixin _db;
  InkDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db.attachedDatabase, _db.nodes);
  $$InkDocumentsTableTableManager get inkDocuments =>
      $$InkDocumentsTableTableManager(_db.attachedDatabase, _db.inkDocuments);
  $$InkPagesTableTableManager get inkPages =>
      $$InkPagesTableTableManager(_db.attachedDatabase, _db.inkPages);
}
