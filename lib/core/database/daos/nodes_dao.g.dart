// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'nodes_dao.dart';

// ignore_for_file: type=lint
mixin _$NodesDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $NodesTable get nodes => attachedDatabase.nodes;
  $NodeBlocksTable get nodeBlocks => attachedDatabase.nodeBlocks;
  NodesDaoManager get managers => NodesDaoManager(this);
}

class NodesDaoManager {
  final _$NodesDaoMixin _db;
  NodesDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db.attachedDatabase, _db.nodes);
  $$NodeBlocksTableTableManager get nodeBlocks =>
      $$NodeBlocksTableTableManager(_db.attachedDatabase, _db.nodeBlocks);
}
