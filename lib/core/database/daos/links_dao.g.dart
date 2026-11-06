// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'links_dao.dart';

// ignore_for_file: type=lint
mixin _$LinksDaoMixin on DatabaseAccessor<AppDatabase> {
  $WorkspacesTable get workspaces => attachedDatabase.workspaces;
  $NodesTable get nodes => attachedDatabase.nodes;
  $NodeLinksTable get nodeLinks => attachedDatabase.nodeLinks;
  $TagsTable get tags => attachedDatabase.tags;
  $NodeTagsTable get nodeTags => attachedDatabase.nodeTags;
  LinksDaoManager get managers => LinksDaoManager(this);
}

class LinksDaoManager {
  final _$LinksDaoMixin _db;
  LinksDaoManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db.attachedDatabase, _db.workspaces);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db.attachedDatabase, _db.nodes);
  $$NodeLinksTableTableManager get nodeLinks =>
      $$NodeLinksTableTableManager(_db.attachedDatabase, _db.nodeLinks);
  $$TagsTableTableManager get tags =>
      $$TagsTableTableManager(_db.attachedDatabase, _db.tags);
  $$NodeTagsTableTableManager get nodeTags =>
      $$NodeTagsTableTableManager(_db.attachedDatabase, _db.nodeTags);
}
