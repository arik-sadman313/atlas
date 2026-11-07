// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $WorkspacesTable extends Workspaces
    with TableInfo<$WorkspacesTable, WorkspaceEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkspacesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _settingsJsonMeta = const VerificationMeta(
    'settingsJson',
  );
  @override
  late final GeneratedColumn<String> settingsJson = GeneratedColumn<String>(
    'settings_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    settingsJson,
    createdAt,
    updatedAt,
    isDeleted,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workspaces';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkspaceEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('settings_json')) {
      context.handle(
        _settingsJsonMeta,
        settingsJson.isAcceptableOrUnknown(
          data['settings_json']!,
          _settingsJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkspaceEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkspaceEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      settingsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}settings_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $WorkspacesTable createAlias(String alias) {
    return $WorkspacesTable(attachedDatabase, alias);
  }
}

class WorkspaceEntry extends DataClass implements Insertable<WorkspaceEntry> {
  final String id;
  final String name;
  final String? icon;
  final String settingsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const WorkspaceEntry({
    required this.id,
    required this.name,
    this.icon,
    required this.settingsJson,
    required this.createdAt,
    required this.updatedAt,
    required this.isDeleted,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['settings_json'] = Variable<String>(settingsJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  WorkspacesCompanion toCompanion(bool nullToAbsent) {
    return WorkspacesCompanion(
      id: Value(id),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      settingsJson: Value(settingsJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      isDeleted: Value(isDeleted),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory WorkspaceEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkspaceEntry(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      settingsJson: serializer.fromJson<String>(json['settingsJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'settingsJson': serializer.toJson<String>(settingsJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  WorkspaceEntry copyWith({
    String? id,
    String? name,
    Value<String?> icon = const Value.absent(),
    String? settingsJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => WorkspaceEntry(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    settingsJson: settingsJson ?? this.settingsJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  WorkspaceEntry copyWithCompanion(WorkspacesCompanion data) {
    return WorkspaceEntry(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      settingsJson: data.settingsJson.present
          ? data.settingsJson.value
          : this.settingsJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkspaceEntry(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    icon,
    settingsJson,
    createdAt,
    updatedAt,
    isDeleted,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkspaceEntry &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.settingsJson == this.settingsJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.isDeleted == this.isDeleted &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class WorkspacesCompanion extends UpdateCompanion<WorkspaceEntry> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> icon;
  final Value<String> settingsJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<bool> isDeleted;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const WorkspacesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.settingsJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkspacesCompanion.insert({
    required String id,
    required String name,
    this.icon = const Value.absent(),
    this.settingsJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.isDeleted = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<WorkspaceEntry> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<String>? settingsJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<bool>? isDeleted,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (settingsJson != null) 'settings_json': settingsJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkspacesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? icon,
    Value<String>? settingsJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<bool>? isDeleted,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return WorkspacesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      settingsJson: settingsJson ?? this.settingsJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (settingsJson.present) {
      map['settings_json'] = Variable<String>(settingsJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkspacesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('settingsJson: $settingsJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodesTable extends Nodes with TableInfo<$NodesTable, NodeEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _coverImageHashMeta = const VerificationMeta(
    'coverImageHash',
  );
  @override
  late final GeneratedColumn<String> coverImageHash = GeneratedColumn<String>(
    'cover_image_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<double> sortOrder = GeneratedColumn<double>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _isFavoriteMeta = const VerificationMeta(
    'isFavorite',
  );
  @override
  late final GeneratedColumn<bool> isFavorite = GeneratedColumn<bool>(
    'is_favorite',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_favorite" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isPinnedMeta = const VerificationMeta(
    'isPinned',
  );
  @override
  late final GeneratedColumn<bool> isPinned = GeneratedColumn<bool>(
    'is_pinned',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_pinned" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _metadataJsonMeta = const VerificationMeta(
    'metadataJson',
  );
  @override
  late final GeneratedColumn<String> metadataJson = GeneratedColumn<String>(
    'metadata_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    parentId,
    type,
    title,
    icon,
    coverImageHash,
    contentHash,
    sortOrder,
    isFavorite,
    isPinned,
    isArchived,
    isDeleted,
    metadataJson,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('cover_image_hash')) {
      context.handle(
        _coverImageHashMeta,
        coverImageHash.isAcceptableOrUnknown(
          data['cover_image_hash']!,
          _coverImageHashMeta,
        ),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('is_favorite')) {
      context.handle(
        _isFavoriteMeta,
        isFavorite.isAcceptableOrUnknown(data['is_favorite']!, _isFavoriteMeta),
      );
    }
    if (data.containsKey('is_pinned')) {
      context.handle(
        _isPinnedMeta,
        isPinned.isAcceptableOrUnknown(data['is_pinned']!, _isPinnedMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('metadata_json')) {
      context.handle(
        _metadataJsonMeta,
        metadataJson.isAcceptableOrUnknown(
          data['metadata_json']!,
          _metadataJsonMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NodeEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      coverImageHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cover_image_hash'],
      ),
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sort_order'],
      )!,
      isFavorite: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_favorite'],
      )!,
      isPinned: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_pinned'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      metadataJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $NodesTable createAlias(String alias) {
    return $NodesTable(attachedDatabase, alias);
  }
}

class NodeEntry extends DataClass implements Insertable<NodeEntry> {
  final String id;
  final String workspaceId;
  final String? parentId;
  final String type;
  final String title;
  final String? icon;
  final String? coverImageHash;
  final String? contentHash;
  final double sortOrder;
  final bool isFavorite;
  final bool isPinned;
  final bool isArchived;
  final bool isDeleted;
  final String metadataJson;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const NodeEntry({
    required this.id,
    required this.workspaceId,
    this.parentId,
    required this.type,
    required this.title,
    this.icon,
    this.coverImageHash,
    this.contentHash,
    required this.sortOrder,
    required this.isFavorite,
    required this.isPinned,
    required this.isArchived,
    required this.isDeleted,
    required this.metadataJson,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    if (!nullToAbsent || coverImageHash != null) {
      map['cover_image_hash'] = Variable<String>(coverImageHash);
    }
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    map['sort_order'] = Variable<double>(sortOrder);
    map['is_favorite'] = Variable<bool>(isFavorite);
    map['is_pinned'] = Variable<bool>(isPinned);
    map['is_archived'] = Variable<bool>(isArchived);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['metadata_json'] = Variable<String>(metadataJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      type: Value(type),
      title: Value(title),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      coverImageHash: coverImageHash == null && nullToAbsent
          ? const Value.absent()
          : Value(coverImageHash),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
      sortOrder: Value(sortOrder),
      isFavorite: Value(isFavorite),
      isPinned: Value(isPinned),
      isArchived: Value(isArchived),
      isDeleted: Value(isDeleted),
      metadataJson: Value(metadataJson),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory NodeEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeEntry(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      icon: serializer.fromJson<String?>(json['icon']),
      coverImageHash: serializer.fromJson<String?>(json['coverImageHash']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
      sortOrder: serializer.fromJson<double>(json['sortOrder']),
      isFavorite: serializer.fromJson<bool>(json['isFavorite']),
      isPinned: serializer.fromJson<bool>(json['isPinned']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      metadataJson: serializer.fromJson<String>(json['metadataJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'parentId': serializer.toJson<String?>(parentId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'icon': serializer.toJson<String?>(icon),
      'coverImageHash': serializer.toJson<String?>(coverImageHash),
      'contentHash': serializer.toJson<String?>(contentHash),
      'sortOrder': serializer.toJson<double>(sortOrder),
      'isFavorite': serializer.toJson<bool>(isFavorite),
      'isPinned': serializer.toJson<bool>(isPinned),
      'isArchived': serializer.toJson<bool>(isArchived),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'metadataJson': serializer.toJson<String>(metadataJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  NodeEntry copyWith({
    String? id,
    String? workspaceId,
    Value<String?> parentId = const Value.absent(),
    String? type,
    String? title,
    Value<String?> icon = const Value.absent(),
    Value<String?> coverImageHash = const Value.absent(),
    Value<String?> contentHash = const Value.absent(),
    double? sortOrder,
    bool? isFavorite,
    bool? isPinned,
    bool? isArchived,
    bool? isDeleted,
    String? metadataJson,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => NodeEntry(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    parentId: parentId.present ? parentId.value : this.parentId,
    type: type ?? this.type,
    title: title ?? this.title,
    icon: icon.present ? icon.value : this.icon,
    coverImageHash: coverImageHash.present
        ? coverImageHash.value
        : this.coverImageHash,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
    sortOrder: sortOrder ?? this.sortOrder,
    isFavorite: isFavorite ?? this.isFavorite,
    isPinned: isPinned ?? this.isPinned,
    isArchived: isArchived ?? this.isArchived,
    isDeleted: isDeleted ?? this.isDeleted,
    metadataJson: metadataJson ?? this.metadataJson,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  NodeEntry copyWithCompanion(NodesCompanion data) {
    return NodeEntry(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      icon: data.icon.present ? data.icon.value : this.icon,
      coverImageHash: data.coverImageHash.present
          ? data.coverImageHash.value
          : this.coverImageHash,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isFavorite: data.isFavorite.present
          ? data.isFavorite.value
          : this.isFavorite,
      isPinned: data.isPinned.present ? data.isPinned.value : this.isPinned,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      metadataJson: data.metadataJson.present
          ? data.metadataJson.value
          : this.metadataJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeEntry(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('parentId: $parentId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coverImageHash: $coverImageHash, ')
          ..write('contentHash: $contentHash, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    parentId,
    type,
    title,
    icon,
    coverImageHash,
    contentHash,
    sortOrder,
    isFavorite,
    isPinned,
    isArchived,
    isDeleted,
    metadataJson,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeEntry &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.parentId == this.parentId &&
          other.type == this.type &&
          other.title == this.title &&
          other.icon == this.icon &&
          other.coverImageHash == this.coverImageHash &&
          other.contentHash == this.contentHash &&
          other.sortOrder == this.sortOrder &&
          other.isFavorite == this.isFavorite &&
          other.isPinned == this.isPinned &&
          other.isArchived == this.isArchived &&
          other.isDeleted == this.isDeleted &&
          other.metadataJson == this.metadataJson &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class NodesCompanion extends UpdateCompanion<NodeEntry> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String?> parentId;
  final Value<String> type;
  final Value<String> title;
  final Value<String?> icon;
  final Value<String?> coverImageHash;
  final Value<String?> contentHash;
  final Value<double> sortOrder;
  final Value<bool> isFavorite;
  final Value<bool> isPinned;
  final Value<bool> isArchived;
  final Value<bool> isDeleted;
  final Value<String> metadataJson;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const NodesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.parentId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.icon = const Value.absent(),
    this.coverImageHash = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.metadataJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodesCompanion.insert({
    required String id,
    required String workspaceId,
    this.parentId = const Value.absent(),
    required String type,
    required String title,
    this.icon = const Value.absent(),
    this.coverImageHash = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isFavorite = const Value.absent(),
    this.isPinned = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.metadataJson = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       type = Value(type),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NodeEntry> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? parentId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? icon,
    Expression<String>? coverImageHash,
    Expression<String>? contentHash,
    Expression<double>? sortOrder,
    Expression<bool>? isFavorite,
    Expression<bool>? isPinned,
    Expression<bool>? isArchived,
    Expression<bool>? isDeleted,
    Expression<String>? metadataJson,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (parentId != null) 'parent_id': parentId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (icon != null) 'icon': icon,
      if (coverImageHash != null) 'cover_image_hash': coverImageHash,
      if (contentHash != null) 'content_hash': contentHash,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isFavorite != null) 'is_favorite': isFavorite,
      if (isPinned != null) 'is_pinned': isPinned,
      if (isArchived != null) 'is_archived': isArchived,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (metadataJson != null) 'metadata_json': metadataJson,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodesCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String?>? parentId,
    Value<String>? type,
    Value<String>? title,
    Value<String?>? icon,
    Value<String?>? coverImageHash,
    Value<String?>? contentHash,
    Value<double>? sortOrder,
    Value<bool>? isFavorite,
    Value<bool>? isPinned,
    Value<bool>? isArchived,
    Value<bool>? isDeleted,
    Value<String>? metadataJson,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return NodesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      parentId: parentId ?? this.parentId,
      type: type ?? this.type,
      title: title ?? this.title,
      icon: icon ?? this.icon,
      coverImageHash: coverImageHash ?? this.coverImageHash,
      contentHash: contentHash ?? this.contentHash,
      sortOrder: sortOrder ?? this.sortOrder,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      metadataJson: metadataJson ?? this.metadataJson,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (coverImageHash.present) {
      map['cover_image_hash'] = Variable<String>(coverImageHash.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<double>(sortOrder.value);
    }
    if (isFavorite.present) {
      map['is_favorite'] = Variable<bool>(isFavorite.value);
    }
    if (isPinned.present) {
      map['is_pinned'] = Variable<bool>(isPinned.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (metadataJson.present) {
      map['metadata_json'] = Variable<String>(metadataJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('parentId: $parentId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('icon: $icon, ')
          ..write('coverImageHash: $coverImageHash, ')
          ..write('contentHash: $contentHash, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isFavorite: $isFavorite, ')
          ..write('isPinned: $isPinned, ')
          ..write('isArchived: $isArchived, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('metadataJson: $metadataJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodeBlocksTable extends NodeBlocks
    with TableInfo<$NodeBlocksTable, NodeBlockEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeBlocksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _parentBlockIdMeta = const VerificationMeta(
    'parentBlockId',
  );
  @override
  late final GeneratedColumn<String> parentBlockId = GeneratedColumn<String>(
    'parent_block_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES node_blocks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentJsonMeta = const VerificationMeta(
    'contentJson',
  );
  @override
  late final GeneratedColumn<String> contentJson = GeneratedColumn<String>(
    'content_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<double> sortOrder = GeneratedColumn<double>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nodeId,
    parentBlockId,
    type,
    contentJson,
    sortOrder,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_blocks';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeBlockEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('parent_block_id')) {
      context.handle(
        _parentBlockIdMeta,
        parentBlockId.isAcceptableOrUnknown(
          data['parent_block_id']!,
          _parentBlockIdMeta,
        ),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('content_json')) {
      context.handle(
        _contentJsonMeta,
        contentJson.isAcceptableOrUnknown(
          data['content_json']!,
          _contentJsonMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NodeBlockEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeBlockEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      parentBlockId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_block_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      contentJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_json'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NodeBlocksTable createAlias(String alias) {
    return $NodeBlocksTable(attachedDatabase, alias);
  }
}

class NodeBlockEntry extends DataClass implements Insertable<NodeBlockEntry> {
  final String id;
  final String nodeId;
  final String? parentBlockId;
  final String type;
  final String contentJson;
  final double sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  const NodeBlockEntry({
    required this.id,
    required this.nodeId,
    this.parentBlockId,
    required this.type,
    required this.contentJson,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['node_id'] = Variable<String>(nodeId);
    if (!nullToAbsent || parentBlockId != null) {
      map['parent_block_id'] = Variable<String>(parentBlockId);
    }
    map['type'] = Variable<String>(type);
    map['content_json'] = Variable<String>(contentJson);
    map['sort_order'] = Variable<double>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  NodeBlocksCompanion toCompanion(bool nullToAbsent) {
    return NodeBlocksCompanion(
      id: Value(id),
      nodeId: Value(nodeId),
      parentBlockId: parentBlockId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentBlockId),
      type: Value(type),
      contentJson: Value(contentJson),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NodeBlockEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeBlockEntry(
      id: serializer.fromJson<String>(json['id']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      parentBlockId: serializer.fromJson<String?>(json['parentBlockId']),
      type: serializer.fromJson<String>(json['type']),
      contentJson: serializer.fromJson<String>(json['contentJson']),
      sortOrder: serializer.fromJson<double>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nodeId': serializer.toJson<String>(nodeId),
      'parentBlockId': serializer.toJson<String?>(parentBlockId),
      'type': serializer.toJson<String>(type),
      'contentJson': serializer.toJson<String>(contentJson),
      'sortOrder': serializer.toJson<double>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  NodeBlockEntry copyWith({
    String? id,
    String? nodeId,
    Value<String?> parentBlockId = const Value.absent(),
    String? type,
    String? contentJson,
    double? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => NodeBlockEntry(
    id: id ?? this.id,
    nodeId: nodeId ?? this.nodeId,
    parentBlockId: parentBlockId.present
        ? parentBlockId.value
        : this.parentBlockId,
    type: type ?? this.type,
    contentJson: contentJson ?? this.contentJson,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NodeBlockEntry copyWithCompanion(NodeBlocksCompanion data) {
    return NodeBlockEntry(
      id: data.id.present ? data.id.value : this.id,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      parentBlockId: data.parentBlockId.present
          ? data.parentBlockId.value
          : this.parentBlockId,
      type: data.type.present ? data.type.value : this.type,
      contentJson: data.contentJson.present
          ? data.contentJson.value
          : this.contentJson,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeBlockEntry(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('parentBlockId: $parentBlockId, ')
          ..write('type: $type, ')
          ..write('contentJson: $contentJson, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nodeId,
    parentBlockId,
    type,
    contentJson,
    sortOrder,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeBlockEntry &&
          other.id == this.id &&
          other.nodeId == this.nodeId &&
          other.parentBlockId == this.parentBlockId &&
          other.type == this.type &&
          other.contentJson == this.contentJson &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NodeBlocksCompanion extends UpdateCompanion<NodeBlockEntry> {
  final Value<String> id;
  final Value<String> nodeId;
  final Value<String?> parentBlockId;
  final Value<String> type;
  final Value<String> contentJson;
  final Value<double> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const NodeBlocksCompanion({
    this.id = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.parentBlockId = const Value.absent(),
    this.type = const Value.absent(),
    this.contentJson = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodeBlocksCompanion.insert({
    required String id,
    required String nodeId,
    this.parentBlockId = const Value.absent(),
    required String type,
    this.contentJson = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nodeId = Value(nodeId),
       type = Value(type),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NodeBlockEntry> custom({
    Expression<String>? id,
    Expression<String>? nodeId,
    Expression<String>? parentBlockId,
    Expression<String>? type,
    Expression<String>? contentJson,
    Expression<double>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeId != null) 'node_id': nodeId,
      if (parentBlockId != null) 'parent_block_id': parentBlockId,
      if (type != null) 'type': type,
      if (contentJson != null) 'content_json': contentJson,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodeBlocksCompanion copyWith({
    Value<String>? id,
    Value<String>? nodeId,
    Value<String?>? parentBlockId,
    Value<String>? type,
    Value<String>? contentJson,
    Value<double>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return NodeBlocksCompanion(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      parentBlockId: parentBlockId ?? this.parentBlockId,
      type: type ?? this.type,
      contentJson: contentJson ?? this.contentJson,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (parentBlockId.present) {
      map['parent_block_id'] = Variable<String>(parentBlockId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (contentJson.present) {
      map['content_json'] = Variable<String>(contentJson.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<double>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeBlocksCompanion(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('parentBlockId: $parentBlockId, ')
          ..write('type: $type, ')
          ..write('contentJson: $contentJson, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AttachmentsTable extends Attachments
    with TableInfo<$AttachmentsTable, AttachmentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttachmentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sha256HashMeta = const VerificationMeta(
    'sha256Hash',
  );
  @override
  late final GeneratedColumn<String> sha256Hash = GeneratedColumn<String>(
    'sha256_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _relativePathMeta = const VerificationMeta(
    'relativePath',
  );
  @override
  late final GeneratedColumn<String> relativePath = GeneratedColumn<String>(
    'relative_path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _byteSizeMeta = const VerificationMeta(
    'byteSize',
  );
  @override
  late final GeneratedColumn<int> byteSize = GeneratedColumn<int>(
    'byte_size',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    sha256Hash,
    relativePath,
    fileName,
    mimeType,
    byteSize,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<AttachmentEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('sha256_hash')) {
      context.handle(
        _sha256HashMeta,
        sha256Hash.isAcceptableOrUnknown(data['sha256_hash']!, _sha256HashMeta),
      );
    } else if (isInserting) {
      context.missing(_sha256HashMeta);
    }
    if (data.containsKey('relative_path')) {
      context.handle(
        _relativePathMeta,
        relativePath.isAcceptableOrUnknown(
          data['relative_path']!,
          _relativePathMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_relativePathMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mimeTypeMeta);
    }
    if (data.containsKey('byte_size')) {
      context.handle(
        _byteSizeMeta,
        byteSize.isAcceptableOrUnknown(data['byte_size']!, _byteSizeMeta),
      );
    } else if (isInserting) {
      context.missing(_byteSizeMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sha256Hash};
  @override
  AttachmentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AttachmentEntry(
      sha256Hash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sha256_hash'],
      )!,
      relativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}relative_path'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      byteSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_size'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AttachmentsTable createAlias(String alias) {
    return $AttachmentsTable(attachedDatabase, alias);
  }
}

class AttachmentEntry extends DataClass implements Insertable<AttachmentEntry> {
  final String sha256Hash;
  final String relativePath;
  final String fileName;
  final String mimeType;
  final int byteSize;
  final DateTime createdAt;
  const AttachmentEntry({
    required this.sha256Hash,
    required this.relativePath,
    required this.fileName,
    required this.mimeType,
    required this.byteSize,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['sha256_hash'] = Variable<String>(sha256Hash);
    map['relative_path'] = Variable<String>(relativePath);
    map['file_name'] = Variable<String>(fileName);
    map['mime_type'] = Variable<String>(mimeType);
    map['byte_size'] = Variable<int>(byteSize);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      sha256Hash: Value(sha256Hash),
      relativePath: Value(relativePath),
      fileName: Value(fileName),
      mimeType: Value(mimeType),
      byteSize: Value(byteSize),
      createdAt: Value(createdAt),
    );
  }

  factory AttachmentEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AttachmentEntry(
      sha256Hash: serializer.fromJson<String>(json['sha256Hash']),
      relativePath: serializer.fromJson<String>(json['relativePath']),
      fileName: serializer.fromJson<String>(json['fileName']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      byteSize: serializer.fromJson<int>(json['byteSize']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sha256Hash': serializer.toJson<String>(sha256Hash),
      'relativePath': serializer.toJson<String>(relativePath),
      'fileName': serializer.toJson<String>(fileName),
      'mimeType': serializer.toJson<String>(mimeType),
      'byteSize': serializer.toJson<int>(byteSize),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AttachmentEntry copyWith({
    String? sha256Hash,
    String? relativePath,
    String? fileName,
    String? mimeType,
    int? byteSize,
    DateTime? createdAt,
  }) => AttachmentEntry(
    sha256Hash: sha256Hash ?? this.sha256Hash,
    relativePath: relativePath ?? this.relativePath,
    fileName: fileName ?? this.fileName,
    mimeType: mimeType ?? this.mimeType,
    byteSize: byteSize ?? this.byteSize,
    createdAt: createdAt ?? this.createdAt,
  );
  AttachmentEntry copyWithCompanion(AttachmentsCompanion data) {
    return AttachmentEntry(
      sha256Hash: data.sha256Hash.present
          ? data.sha256Hash.value
          : this.sha256Hash,
      relativePath: data.relativePath.present
          ? data.relativePath.value
          : this.relativePath,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      byteSize: data.byteSize.present ? data.byteSize.value : this.byteSize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentEntry(')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('relativePath: $relativePath, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    sha256Hash,
    relativePath,
    fileName,
    mimeType,
    byteSize,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AttachmentEntry &&
          other.sha256Hash == this.sha256Hash &&
          other.relativePath == this.relativePath &&
          other.fileName == this.fileName &&
          other.mimeType == this.mimeType &&
          other.byteSize == this.byteSize &&
          other.createdAt == this.createdAt);
}

class AttachmentsCompanion extends UpdateCompanion<AttachmentEntry> {
  final Value<String> sha256Hash;
  final Value<String> relativePath;
  final Value<String> fileName;
  final Value<String> mimeType;
  final Value<int> byteSize;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.sha256Hash = const Value.absent(),
    this.relativePath = const Value.absent(),
    this.fileName = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.byteSize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String sha256Hash,
    required String relativePath,
    required String fileName,
    required String mimeType,
    required int byteSize,
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : sha256Hash = Value(sha256Hash),
       relativePath = Value(relativePath),
       fileName = Value(fileName),
       mimeType = Value(mimeType),
       byteSize = Value(byteSize),
       createdAt = Value(createdAt);
  static Insertable<AttachmentEntry> custom({
    Expression<String>? sha256Hash,
    Expression<String>? relativePath,
    Expression<String>? fileName,
    Expression<String>? mimeType,
    Expression<int>? byteSize,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sha256Hash != null) 'sha256_hash': sha256Hash,
      if (relativePath != null) 'relative_path': relativePath,
      if (fileName != null) 'file_name': fileName,
      if (mimeType != null) 'mime_type': mimeType,
      if (byteSize != null) 'byte_size': byteSize,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? sha256Hash,
    Value<String>? relativePath,
    Value<String>? fileName,
    Value<String>? mimeType,
    Value<int>? byteSize,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      sha256Hash: sha256Hash ?? this.sha256Hash,
      relativePath: relativePath ?? this.relativePath,
      fileName: fileName ?? this.fileName,
      mimeType: mimeType ?? this.mimeType,
      byteSize: byteSize ?? this.byteSize,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sha256Hash.present) {
      map['sha256_hash'] = Variable<String>(sha256Hash.value);
    }
    if (relativePath.present) {
      map['relative_path'] = Variable<String>(relativePath.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (byteSize.present) {
      map['byte_size'] = Variable<int>(byteSize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('sha256Hash: $sha256Hash, ')
          ..write('relativePath: $relativePath, ')
          ..write('fileName: $fileName, ')
          ..write('mimeType: $mimeType, ')
          ..write('byteSize: $byteSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InkDocumentsTable extends InkDocuments
    with TableInfo<$InkDocumentsTable, InkDocumentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InkDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _defaultPageWidthMeta = const VerificationMeta(
    'defaultPageWidth',
  );
  @override
  late final GeneratedColumn<double> defaultPageWidth = GeneratedColumn<double>(
    'default_page_width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1600.0),
  );
  static const VerificationMeta _defaultPageHeightMeta = const VerificationMeta(
    'defaultPageHeight',
  );
  @override
  late final GeneratedColumn<double> defaultPageHeight =
      GeneratedColumn<double>(
        'default_page_height',
        aliasedName,
        false,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
        defaultValue: const Constant(2200.0),
      );
  static const VerificationMeta _defaultTemplateMeta = const VerificationMeta(
    'defaultTemplate',
  );
  @override
  late final GeneratedColumn<String> defaultTemplate = GeneratedColumn<String>(
    'default_template',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dot_grid_5mm'),
  );
  static const VerificationMeta _defaultBackgroundColorMeta =
      const VerificationMeta('defaultBackgroundColor');
  @override
  late final GeneratedColumn<int> defaultBackgroundColor = GeneratedColumn<int>(
    'default_background_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4294967295),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nodeId,
    defaultPageWidth,
    defaultPageHeight,
    defaultTemplate,
    defaultBackgroundColor,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ink_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<InkDocumentEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('default_page_width')) {
      context.handle(
        _defaultPageWidthMeta,
        defaultPageWidth.isAcceptableOrUnknown(
          data['default_page_width']!,
          _defaultPageWidthMeta,
        ),
      );
    }
    if (data.containsKey('default_page_height')) {
      context.handle(
        _defaultPageHeightMeta,
        defaultPageHeight.isAcceptableOrUnknown(
          data['default_page_height']!,
          _defaultPageHeightMeta,
        ),
      );
    }
    if (data.containsKey('default_template')) {
      context.handle(
        _defaultTemplateMeta,
        defaultTemplate.isAcceptableOrUnknown(
          data['default_template']!,
          _defaultTemplateMeta,
        ),
      );
    }
    if (data.containsKey('default_background_color')) {
      context.handle(
        _defaultBackgroundColorMeta,
        defaultBackgroundColor.isAcceptableOrUnknown(
          data['default_background_color']!,
          _defaultBackgroundColorMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InkDocumentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InkDocumentEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      defaultPageWidth: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_page_width'],
      )!,
      defaultPageHeight: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}default_page_height'],
      )!,
      defaultTemplate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_template'],
      )!,
      defaultBackgroundColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_background_color'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $InkDocumentsTable createAlias(String alias) {
    return $InkDocumentsTable(attachedDatabase, alias);
  }
}

class InkDocumentEntry extends DataClass
    implements Insertable<InkDocumentEntry> {
  final String id;
  final String nodeId;
  final double defaultPageWidth;
  final double defaultPageHeight;
  final String defaultTemplate;
  final int defaultBackgroundColor;
  final DateTime createdAt;
  final DateTime updatedAt;
  const InkDocumentEntry({
    required this.id,
    required this.nodeId,
    required this.defaultPageWidth,
    required this.defaultPageHeight,
    required this.defaultTemplate,
    required this.defaultBackgroundColor,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['node_id'] = Variable<String>(nodeId);
    map['default_page_width'] = Variable<double>(defaultPageWidth);
    map['default_page_height'] = Variable<double>(defaultPageHeight);
    map['default_template'] = Variable<String>(defaultTemplate);
    map['default_background_color'] = Variable<int>(defaultBackgroundColor);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  InkDocumentsCompanion toCompanion(bool nullToAbsent) {
    return InkDocumentsCompanion(
      id: Value(id),
      nodeId: Value(nodeId),
      defaultPageWidth: Value(defaultPageWidth),
      defaultPageHeight: Value(defaultPageHeight),
      defaultTemplate: Value(defaultTemplate),
      defaultBackgroundColor: Value(defaultBackgroundColor),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory InkDocumentEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InkDocumentEntry(
      id: serializer.fromJson<String>(json['id']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      defaultPageWidth: serializer.fromJson<double>(json['defaultPageWidth']),
      defaultPageHeight: serializer.fromJson<double>(json['defaultPageHeight']),
      defaultTemplate: serializer.fromJson<String>(json['defaultTemplate']),
      defaultBackgroundColor: serializer.fromJson<int>(
        json['defaultBackgroundColor'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nodeId': serializer.toJson<String>(nodeId),
      'defaultPageWidth': serializer.toJson<double>(defaultPageWidth),
      'defaultPageHeight': serializer.toJson<double>(defaultPageHeight),
      'defaultTemplate': serializer.toJson<String>(defaultTemplate),
      'defaultBackgroundColor': serializer.toJson<int>(defaultBackgroundColor),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  InkDocumentEntry copyWith({
    String? id,
    String? nodeId,
    double? defaultPageWidth,
    double? defaultPageHeight,
    String? defaultTemplate,
    int? defaultBackgroundColor,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => InkDocumentEntry(
    id: id ?? this.id,
    nodeId: nodeId ?? this.nodeId,
    defaultPageWidth: defaultPageWidth ?? this.defaultPageWidth,
    defaultPageHeight: defaultPageHeight ?? this.defaultPageHeight,
    defaultTemplate: defaultTemplate ?? this.defaultTemplate,
    defaultBackgroundColor:
        defaultBackgroundColor ?? this.defaultBackgroundColor,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  InkDocumentEntry copyWithCompanion(InkDocumentsCompanion data) {
    return InkDocumentEntry(
      id: data.id.present ? data.id.value : this.id,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      defaultPageWidth: data.defaultPageWidth.present
          ? data.defaultPageWidth.value
          : this.defaultPageWidth,
      defaultPageHeight: data.defaultPageHeight.present
          ? data.defaultPageHeight.value
          : this.defaultPageHeight,
      defaultTemplate: data.defaultTemplate.present
          ? data.defaultTemplate.value
          : this.defaultTemplate,
      defaultBackgroundColor: data.defaultBackgroundColor.present
          ? data.defaultBackgroundColor.value
          : this.defaultBackgroundColor,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InkDocumentEntry(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('defaultPageWidth: $defaultPageWidth, ')
          ..write('defaultPageHeight: $defaultPageHeight, ')
          ..write('defaultTemplate: $defaultTemplate, ')
          ..write('defaultBackgroundColor: $defaultBackgroundColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nodeId,
    defaultPageWidth,
    defaultPageHeight,
    defaultTemplate,
    defaultBackgroundColor,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InkDocumentEntry &&
          other.id == this.id &&
          other.nodeId == this.nodeId &&
          other.defaultPageWidth == this.defaultPageWidth &&
          other.defaultPageHeight == this.defaultPageHeight &&
          other.defaultTemplate == this.defaultTemplate &&
          other.defaultBackgroundColor == this.defaultBackgroundColor &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class InkDocumentsCompanion extends UpdateCompanion<InkDocumentEntry> {
  final Value<String> id;
  final Value<String> nodeId;
  final Value<double> defaultPageWidth;
  final Value<double> defaultPageHeight;
  final Value<String> defaultTemplate;
  final Value<int> defaultBackgroundColor;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const InkDocumentsCompanion({
    this.id = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.defaultPageWidth = const Value.absent(),
    this.defaultPageHeight = const Value.absent(),
    this.defaultTemplate = const Value.absent(),
    this.defaultBackgroundColor = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InkDocumentsCompanion.insert({
    required String id,
    required String nodeId,
    this.defaultPageWidth = const Value.absent(),
    this.defaultPageHeight = const Value.absent(),
    this.defaultTemplate = const Value.absent(),
    this.defaultBackgroundColor = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nodeId = Value(nodeId),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InkDocumentEntry> custom({
    Expression<String>? id,
    Expression<String>? nodeId,
    Expression<double>? defaultPageWidth,
    Expression<double>? defaultPageHeight,
    Expression<String>? defaultTemplate,
    Expression<int>? defaultBackgroundColor,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeId != null) 'node_id': nodeId,
      if (defaultPageWidth != null) 'default_page_width': defaultPageWidth,
      if (defaultPageHeight != null) 'default_page_height': defaultPageHeight,
      if (defaultTemplate != null) 'default_template': defaultTemplate,
      if (defaultBackgroundColor != null)
        'default_background_color': defaultBackgroundColor,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InkDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? nodeId,
    Value<double>? defaultPageWidth,
    Value<double>? defaultPageHeight,
    Value<String>? defaultTemplate,
    Value<int>? defaultBackgroundColor,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return InkDocumentsCompanion(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      defaultPageWidth: defaultPageWidth ?? this.defaultPageWidth,
      defaultPageHeight: defaultPageHeight ?? this.defaultPageHeight,
      defaultTemplate: defaultTemplate ?? this.defaultTemplate,
      defaultBackgroundColor:
          defaultBackgroundColor ?? this.defaultBackgroundColor,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (defaultPageWidth.present) {
      map['default_page_width'] = Variable<double>(defaultPageWidth.value);
    }
    if (defaultPageHeight.present) {
      map['default_page_height'] = Variable<double>(defaultPageHeight.value);
    }
    if (defaultTemplate.present) {
      map['default_template'] = Variable<String>(defaultTemplate.value);
    }
    if (defaultBackgroundColor.present) {
      map['default_background_color'] = Variable<int>(
        defaultBackgroundColor.value,
      );
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InkDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('defaultPageWidth: $defaultPageWidth, ')
          ..write('defaultPageHeight: $defaultPageHeight, ')
          ..write('defaultTemplate: $defaultTemplate, ')
          ..write('defaultBackgroundColor: $defaultBackgroundColor, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PdfDocumentsTable extends PdfDocuments
    with TableInfo<$PdfDocumentsTable, PdfDocumentEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PdfDocumentsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _casHashMeta = const VerificationMeta(
    'casHash',
  );
  @override
  late final GeneratedColumn<String> casHash = GeneratedColumn<String>(
    'cas_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileNameMeta = const VerificationMeta(
    'fileName',
  );
  @override
  late final GeneratedColumn<String> fileName = GeneratedColumn<String>(
    'file_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pageCountMeta = const VerificationMeta(
    'pageCount',
  );
  @override
  late final GeneratedColumn<int> pageCount = GeneratedColumn<int>(
    'page_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nodeId,
    casHash,
    fileName,
    fileSizeBytes,
    pageCount,
    createdAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pdf_documents';
  @override
  VerificationContext validateIntegrity(
    Insertable<PdfDocumentEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('cas_hash')) {
      context.handle(
        _casHashMeta,
        casHash.isAcceptableOrUnknown(data['cas_hash']!, _casHashMeta),
      );
    } else if (isInserting) {
      context.missing(_casHashMeta);
    }
    if (data.containsKey('file_name')) {
      context.handle(
        _fileNameMeta,
        fileName.isAcceptableOrUnknown(data['file_name']!, _fileNameMeta),
      );
    } else if (isInserting) {
      context.missing(_fileNameMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('page_count')) {
      context.handle(
        _pageCountMeta,
        pageCount.isAcceptableOrUnknown(data['page_count']!, _pageCountMeta),
      );
    } else if (isInserting) {
      context.missing(_pageCountMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PdfDocumentEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PdfDocumentEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      casHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cas_hash'],
      )!,
      fileName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}file_name'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      pageCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $PdfDocumentsTable createAlias(String alias) {
    return $PdfDocumentsTable(attachedDatabase, alias);
  }
}

class PdfDocumentEntry extends DataClass
    implements Insertable<PdfDocumentEntry> {
  final String id;
  final String nodeId;
  final String casHash;
  final String fileName;
  final int fileSizeBytes;
  final int pageCount;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const PdfDocumentEntry({
    required this.id,
    required this.nodeId,
    required this.casHash,
    required this.fileName,
    required this.fileSizeBytes,
    required this.pageCount,
    required this.createdAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['node_id'] = Variable<String>(nodeId);
    map['cas_hash'] = Variable<String>(casHash);
    map['file_name'] = Variable<String>(fileName);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['page_count'] = Variable<int>(pageCount);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  PdfDocumentsCompanion toCompanion(bool nullToAbsent) {
    return PdfDocumentsCompanion(
      id: Value(id),
      nodeId: Value(nodeId),
      casHash: Value(casHash),
      fileName: Value(fileName),
      fileSizeBytes: Value(fileSizeBytes),
      pageCount: Value(pageCount),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory PdfDocumentEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PdfDocumentEntry(
      id: serializer.fromJson<String>(json['id']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      casHash: serializer.fromJson<String>(json['casHash']),
      fileName: serializer.fromJson<String>(json['fileName']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      pageCount: serializer.fromJson<int>(json['pageCount']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'nodeId': serializer.toJson<String>(nodeId),
      'casHash': serializer.toJson<String>(casHash),
      'fileName': serializer.toJson<String>(fileName),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'pageCount': serializer.toJson<int>(pageCount),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  PdfDocumentEntry copyWith({
    String? id,
    String? nodeId,
    String? casHash,
    String? fileName,
    int? fileSizeBytes,
    int? pageCount,
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => PdfDocumentEntry(
    id: id ?? this.id,
    nodeId: nodeId ?? this.nodeId,
    casHash: casHash ?? this.casHash,
    fileName: fileName ?? this.fileName,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    pageCount: pageCount ?? this.pageCount,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  PdfDocumentEntry copyWithCompanion(PdfDocumentsCompanion data) {
    return PdfDocumentEntry(
      id: data.id.present ? data.id.value : this.id,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      casHash: data.casHash.present ? data.casHash.value : this.casHash,
      fileName: data.fileName.present ? data.fileName.value : this.fileName,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      pageCount: data.pageCount.present ? data.pageCount.value : this.pageCount,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PdfDocumentEntry(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('casHash: $casHash, ')
          ..write('fileName: $fileName, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('pageCount: $pageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    nodeId,
    casHash,
    fileName,
    fileSizeBytes,
    pageCount,
    createdAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PdfDocumentEntry &&
          other.id == this.id &&
          other.nodeId == this.nodeId &&
          other.casHash == this.casHash &&
          other.fileName == this.fileName &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.pageCount == this.pageCount &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class PdfDocumentsCompanion extends UpdateCompanion<PdfDocumentEntry> {
  final Value<String> id;
  final Value<String> nodeId;
  final Value<String> casHash;
  final Value<String> fileName;
  final Value<int> fileSizeBytes;
  final Value<int> pageCount;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const PdfDocumentsCompanion({
    this.id = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.casHash = const Value.absent(),
    this.fileName = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.pageCount = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PdfDocumentsCompanion.insert({
    required String id,
    required String nodeId,
    required String casHash,
    required String fileName,
    required int fileSizeBytes,
    required int pageCount,
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       nodeId = Value(nodeId),
       casHash = Value(casHash),
       fileName = Value(fileName),
       fileSizeBytes = Value(fileSizeBytes),
       pageCount = Value(pageCount),
       createdAt = Value(createdAt);
  static Insertable<PdfDocumentEntry> custom({
    Expression<String>? id,
    Expression<String>? nodeId,
    Expression<String>? casHash,
    Expression<String>? fileName,
    Expression<int>? fileSizeBytes,
    Expression<int>? pageCount,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nodeId != null) 'node_id': nodeId,
      if (casHash != null) 'cas_hash': casHash,
      if (fileName != null) 'file_name': fileName,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (pageCount != null) 'page_count': pageCount,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PdfDocumentsCompanion copyWith({
    Value<String>? id,
    Value<String>? nodeId,
    Value<String>? casHash,
    Value<String>? fileName,
    Value<int>? fileSizeBytes,
    Value<int>? pageCount,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return PdfDocumentsCompanion(
      id: id ?? this.id,
      nodeId: nodeId ?? this.nodeId,
      casHash: casHash ?? this.casHash,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      pageCount: pageCount ?? this.pageCount,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (casHash.present) {
      map['cas_hash'] = Variable<String>(casHash.value);
    }
    if (fileName.present) {
      map['file_name'] = Variable<String>(fileName.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (pageCount.present) {
      map['page_count'] = Variable<int>(pageCount.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PdfDocumentsCompanion(')
          ..write('id: $id, ')
          ..write('nodeId: $nodeId, ')
          ..write('casHash: $casHash, ')
          ..write('fileName: $fileName, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('pageCount: $pageCount, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $InkPagesTable extends InkPages
    with TableInfo<$InkPagesTable, InkPageEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $InkPagesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _documentIdMeta = const VerificationMeta(
    'documentId',
  );
  @override
  late final GeneratedColumn<String> documentId = GeneratedColumn<String>(
    'document_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES ink_documents (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _pageNumberMeta = const VerificationMeta(
    'pageNumber',
  );
  @override
  late final GeneratedColumn<int> pageNumber = GeneratedColumn<int>(
    'page_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<double> width = GeneratedColumn<double>(
    'width',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(1600.0),
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<double> height = GeneratedColumn<double>(
    'height',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(2200.0),
  );
  static const VerificationMeta _templateTypeMeta = const VerificationMeta(
    'templateType',
  );
  @override
  late final GeneratedColumn<String> templateType = GeneratedColumn<String>(
    'template_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('dot_grid_5mm'),
  );
  static const VerificationMeta _templateSpacingMeta = const VerificationMeta(
    'templateSpacing',
  );
  @override
  late final GeneratedColumn<double> templateSpacing = GeneratedColumn<double>(
    'template_spacing',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(28.35),
  );
  static const VerificationMeta _backgroundColorMeta = const VerificationMeta(
    'backgroundColor',
  );
  @override
  late final GeneratedColumn<int> backgroundColor = GeneratedColumn<int>(
    'background_color',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4294967295),
  );
  static const VerificationMeta _pdfDocumentIdMeta = const VerificationMeta(
    'pdfDocumentId',
  );
  @override
  late final GeneratedColumn<String> pdfDocumentId = GeneratedColumn<String>(
    'pdf_document_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES pdf_documents (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _pdfSourceHashMeta = const VerificationMeta(
    'pdfSourceHash',
  );
  @override
  late final GeneratedColumn<String> pdfSourceHash = GeneratedColumn<String>(
    'pdf_source_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pdfPageIndexMeta = const VerificationMeta(
    'pdfPageIndex',
  );
  @override
  late final GeneratedColumn<int> pdfPageIndex = GeneratedColumn<int>(
    'pdf_page_index',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _rawPencilkitHashMeta = const VerificationMeta(
    'rawPencilkitHash',
  );
  @override
  late final GeneratedColumn<String> rawPencilkitHash = GeneratedColumn<String>(
    'raw_pencilkit_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _portableInkHashMeta = const VerificationMeta(
    'portableInkHash',
  );
  @override
  late final GeneratedColumn<String> portableInkHash = GeneratedColumn<String>(
    'portable_ink_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _previewPngHashMeta = const VerificationMeta(
    'previewPngHash',
  );
  @override
  late final GeneratedColumn<String> previewPngHash = GeneratedColumn<String>(
    'preview_png_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _ocrTextMeta = const VerificationMeta(
    'ocrText',
  );
  @override
  late final GeneratedColumn<String> ocrText = GeneratedColumn<String>(
    'ocr_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    documentId,
    pageNumber,
    width,
    height,
    templateType,
    templateSpacing,
    backgroundColor,
    pdfDocumentId,
    pdfSourceHash,
    pdfPageIndex,
    rawPencilkitHash,
    portableInkHash,
    previewPngHash,
    ocrText,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ink_pages';
  @override
  VerificationContext validateIntegrity(
    Insertable<InkPageEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('document_id')) {
      context.handle(
        _documentIdMeta,
        documentId.isAcceptableOrUnknown(data['document_id']!, _documentIdMeta),
      );
    } else if (isInserting) {
      context.missing(_documentIdMeta);
    }
    if (data.containsKey('page_number')) {
      context.handle(
        _pageNumberMeta,
        pageNumber.isAcceptableOrUnknown(data['page_number']!, _pageNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_pageNumberMeta);
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('template_type')) {
      context.handle(
        _templateTypeMeta,
        templateType.isAcceptableOrUnknown(
          data['template_type']!,
          _templateTypeMeta,
        ),
      );
    }
    if (data.containsKey('template_spacing')) {
      context.handle(
        _templateSpacingMeta,
        templateSpacing.isAcceptableOrUnknown(
          data['template_spacing']!,
          _templateSpacingMeta,
        ),
      );
    }
    if (data.containsKey('background_color')) {
      context.handle(
        _backgroundColorMeta,
        backgroundColor.isAcceptableOrUnknown(
          data['background_color']!,
          _backgroundColorMeta,
        ),
      );
    }
    if (data.containsKey('pdf_document_id')) {
      context.handle(
        _pdfDocumentIdMeta,
        pdfDocumentId.isAcceptableOrUnknown(
          data['pdf_document_id']!,
          _pdfDocumentIdMeta,
        ),
      );
    }
    if (data.containsKey('pdf_source_hash')) {
      context.handle(
        _pdfSourceHashMeta,
        pdfSourceHash.isAcceptableOrUnknown(
          data['pdf_source_hash']!,
          _pdfSourceHashMeta,
        ),
      );
    }
    if (data.containsKey('pdf_page_index')) {
      context.handle(
        _pdfPageIndexMeta,
        pdfPageIndex.isAcceptableOrUnknown(
          data['pdf_page_index']!,
          _pdfPageIndexMeta,
        ),
      );
    }
    if (data.containsKey('raw_pencilkit_hash')) {
      context.handle(
        _rawPencilkitHashMeta,
        rawPencilkitHash.isAcceptableOrUnknown(
          data['raw_pencilkit_hash']!,
          _rawPencilkitHashMeta,
        ),
      );
    }
    if (data.containsKey('portable_ink_hash')) {
      context.handle(
        _portableInkHashMeta,
        portableInkHash.isAcceptableOrUnknown(
          data['portable_ink_hash']!,
          _portableInkHashMeta,
        ),
      );
    }
    if (data.containsKey('preview_png_hash')) {
      context.handle(
        _previewPngHashMeta,
        previewPngHash.isAcceptableOrUnknown(
          data['preview_png_hash']!,
          _previewPngHashMeta,
        ),
      );
    }
    if (data.containsKey('ocr_text')) {
      context.handle(
        _ocrTextMeta,
        ocrText.isAcceptableOrUnknown(data['ocr_text']!, _ocrTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  InkPageEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return InkPageEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      documentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}document_id'],
      )!,
      pageNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}page_number'],
      )!,
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}width'],
      )!,
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}height'],
      )!,
      templateType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_type'],
      )!,
      templateSpacing: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}template_spacing'],
      )!,
      backgroundColor: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}background_color'],
      )!,
      pdfDocumentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_document_id'],
      ),
      pdfSourceHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}pdf_source_hash'],
      ),
      pdfPageIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}pdf_page_index'],
      ),
      rawPencilkitHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}raw_pencilkit_hash'],
      ),
      portableInkHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}portable_ink_hash'],
      ),
      previewPngHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preview_png_hash'],
      ),
      ocrText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ocr_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $InkPagesTable createAlias(String alias) {
    return $InkPagesTable(attachedDatabase, alias);
  }
}

class InkPageEntry extends DataClass implements Insertable<InkPageEntry> {
  final String id;
  final String documentId;
  final int pageNumber;
  final double width;
  final double height;
  final String templateType;
  final double templateSpacing;
  final int backgroundColor;
  final String? pdfDocumentId;
  final String? pdfSourceHash;
  final int? pdfPageIndex;
  final String? rawPencilkitHash;
  final String? portableInkHash;
  final String? previewPngHash;
  final String? ocrText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const InkPageEntry({
    required this.id,
    required this.documentId,
    required this.pageNumber,
    required this.width,
    required this.height,
    required this.templateType,
    required this.templateSpacing,
    required this.backgroundColor,
    this.pdfDocumentId,
    this.pdfSourceHash,
    this.pdfPageIndex,
    this.rawPencilkitHash,
    this.portableInkHash,
    this.previewPngHash,
    this.ocrText,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['document_id'] = Variable<String>(documentId);
    map['page_number'] = Variable<int>(pageNumber);
    map['width'] = Variable<double>(width);
    map['height'] = Variable<double>(height);
    map['template_type'] = Variable<String>(templateType);
    map['template_spacing'] = Variable<double>(templateSpacing);
    map['background_color'] = Variable<int>(backgroundColor);
    if (!nullToAbsent || pdfDocumentId != null) {
      map['pdf_document_id'] = Variable<String>(pdfDocumentId);
    }
    if (!nullToAbsent || pdfSourceHash != null) {
      map['pdf_source_hash'] = Variable<String>(pdfSourceHash);
    }
    if (!nullToAbsent || pdfPageIndex != null) {
      map['pdf_page_index'] = Variable<int>(pdfPageIndex);
    }
    if (!nullToAbsent || rawPencilkitHash != null) {
      map['raw_pencilkit_hash'] = Variable<String>(rawPencilkitHash);
    }
    if (!nullToAbsent || portableInkHash != null) {
      map['portable_ink_hash'] = Variable<String>(portableInkHash);
    }
    if (!nullToAbsent || previewPngHash != null) {
      map['preview_png_hash'] = Variable<String>(previewPngHash);
    }
    if (!nullToAbsent || ocrText != null) {
      map['ocr_text'] = Variable<String>(ocrText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  InkPagesCompanion toCompanion(bool nullToAbsent) {
    return InkPagesCompanion(
      id: Value(id),
      documentId: Value(documentId),
      pageNumber: Value(pageNumber),
      width: Value(width),
      height: Value(height),
      templateType: Value(templateType),
      templateSpacing: Value(templateSpacing),
      backgroundColor: Value(backgroundColor),
      pdfDocumentId: pdfDocumentId == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfDocumentId),
      pdfSourceHash: pdfSourceHash == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfSourceHash),
      pdfPageIndex: pdfPageIndex == null && nullToAbsent
          ? const Value.absent()
          : Value(pdfPageIndex),
      rawPencilkitHash: rawPencilkitHash == null && nullToAbsent
          ? const Value.absent()
          : Value(rawPencilkitHash),
      portableInkHash: portableInkHash == null && nullToAbsent
          ? const Value.absent()
          : Value(portableInkHash),
      previewPngHash: previewPngHash == null && nullToAbsent
          ? const Value.absent()
          : Value(previewPngHash),
      ocrText: ocrText == null && nullToAbsent
          ? const Value.absent()
          : Value(ocrText),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory InkPageEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return InkPageEntry(
      id: serializer.fromJson<String>(json['id']),
      documentId: serializer.fromJson<String>(json['documentId']),
      pageNumber: serializer.fromJson<int>(json['pageNumber']),
      width: serializer.fromJson<double>(json['width']),
      height: serializer.fromJson<double>(json['height']),
      templateType: serializer.fromJson<String>(json['templateType']),
      templateSpacing: serializer.fromJson<double>(json['templateSpacing']),
      backgroundColor: serializer.fromJson<int>(json['backgroundColor']),
      pdfDocumentId: serializer.fromJson<String?>(json['pdfDocumentId']),
      pdfSourceHash: serializer.fromJson<String?>(json['pdfSourceHash']),
      pdfPageIndex: serializer.fromJson<int?>(json['pdfPageIndex']),
      rawPencilkitHash: serializer.fromJson<String?>(json['rawPencilkitHash']),
      portableInkHash: serializer.fromJson<String?>(json['portableInkHash']),
      previewPngHash: serializer.fromJson<String?>(json['previewPngHash']),
      ocrText: serializer.fromJson<String?>(json['ocrText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'documentId': serializer.toJson<String>(documentId),
      'pageNumber': serializer.toJson<int>(pageNumber),
      'width': serializer.toJson<double>(width),
      'height': serializer.toJson<double>(height),
      'templateType': serializer.toJson<String>(templateType),
      'templateSpacing': serializer.toJson<double>(templateSpacing),
      'backgroundColor': serializer.toJson<int>(backgroundColor),
      'pdfDocumentId': serializer.toJson<String?>(pdfDocumentId),
      'pdfSourceHash': serializer.toJson<String?>(pdfSourceHash),
      'pdfPageIndex': serializer.toJson<int?>(pdfPageIndex),
      'rawPencilkitHash': serializer.toJson<String?>(rawPencilkitHash),
      'portableInkHash': serializer.toJson<String?>(portableInkHash),
      'previewPngHash': serializer.toJson<String?>(previewPngHash),
      'ocrText': serializer.toJson<String?>(ocrText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  InkPageEntry copyWith({
    String? id,
    String? documentId,
    int? pageNumber,
    double? width,
    double? height,
    String? templateType,
    double? templateSpacing,
    int? backgroundColor,
    Value<String?> pdfDocumentId = const Value.absent(),
    Value<String?> pdfSourceHash = const Value.absent(),
    Value<int?> pdfPageIndex = const Value.absent(),
    Value<String?> rawPencilkitHash = const Value.absent(),
    Value<String?> portableInkHash = const Value.absent(),
    Value<String?> previewPngHash = const Value.absent(),
    Value<String?> ocrText = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => InkPageEntry(
    id: id ?? this.id,
    documentId: documentId ?? this.documentId,
    pageNumber: pageNumber ?? this.pageNumber,
    width: width ?? this.width,
    height: height ?? this.height,
    templateType: templateType ?? this.templateType,
    templateSpacing: templateSpacing ?? this.templateSpacing,
    backgroundColor: backgroundColor ?? this.backgroundColor,
    pdfDocumentId: pdfDocumentId.present
        ? pdfDocumentId.value
        : this.pdfDocumentId,
    pdfSourceHash: pdfSourceHash.present
        ? pdfSourceHash.value
        : this.pdfSourceHash,
    pdfPageIndex: pdfPageIndex.present ? pdfPageIndex.value : this.pdfPageIndex,
    rawPencilkitHash: rawPencilkitHash.present
        ? rawPencilkitHash.value
        : this.rawPencilkitHash,
    portableInkHash: portableInkHash.present
        ? portableInkHash.value
        : this.portableInkHash,
    previewPngHash: previewPngHash.present
        ? previewPngHash.value
        : this.previewPngHash,
    ocrText: ocrText.present ? ocrText.value : this.ocrText,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  InkPageEntry copyWithCompanion(InkPagesCompanion data) {
    return InkPageEntry(
      id: data.id.present ? data.id.value : this.id,
      documentId: data.documentId.present
          ? data.documentId.value
          : this.documentId,
      pageNumber: data.pageNumber.present
          ? data.pageNumber.value
          : this.pageNumber,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      templateType: data.templateType.present
          ? data.templateType.value
          : this.templateType,
      templateSpacing: data.templateSpacing.present
          ? data.templateSpacing.value
          : this.templateSpacing,
      backgroundColor: data.backgroundColor.present
          ? data.backgroundColor.value
          : this.backgroundColor,
      pdfDocumentId: data.pdfDocumentId.present
          ? data.pdfDocumentId.value
          : this.pdfDocumentId,
      pdfSourceHash: data.pdfSourceHash.present
          ? data.pdfSourceHash.value
          : this.pdfSourceHash,
      pdfPageIndex: data.pdfPageIndex.present
          ? data.pdfPageIndex.value
          : this.pdfPageIndex,
      rawPencilkitHash: data.rawPencilkitHash.present
          ? data.rawPencilkitHash.value
          : this.rawPencilkitHash,
      portableInkHash: data.portableInkHash.present
          ? data.portableInkHash.value
          : this.portableInkHash,
      previewPngHash: data.previewPngHash.present
          ? data.previewPngHash.value
          : this.previewPngHash,
      ocrText: data.ocrText.present ? data.ocrText.value : this.ocrText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('InkPageEntry(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('templateType: $templateType, ')
          ..write('templateSpacing: $templateSpacing, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('pdfDocumentId: $pdfDocumentId, ')
          ..write('pdfSourceHash: $pdfSourceHash, ')
          ..write('pdfPageIndex: $pdfPageIndex, ')
          ..write('rawPencilkitHash: $rawPencilkitHash, ')
          ..write('portableInkHash: $portableInkHash, ')
          ..write('previewPngHash: $previewPngHash, ')
          ..write('ocrText: $ocrText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    documentId,
    pageNumber,
    width,
    height,
    templateType,
    templateSpacing,
    backgroundColor,
    pdfDocumentId,
    pdfSourceHash,
    pdfPageIndex,
    rawPencilkitHash,
    portableInkHash,
    previewPngHash,
    ocrText,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is InkPageEntry &&
          other.id == this.id &&
          other.documentId == this.documentId &&
          other.pageNumber == this.pageNumber &&
          other.width == this.width &&
          other.height == this.height &&
          other.templateType == this.templateType &&
          other.templateSpacing == this.templateSpacing &&
          other.backgroundColor == this.backgroundColor &&
          other.pdfDocumentId == this.pdfDocumentId &&
          other.pdfSourceHash == this.pdfSourceHash &&
          other.pdfPageIndex == this.pdfPageIndex &&
          other.rawPencilkitHash == this.rawPencilkitHash &&
          other.portableInkHash == this.portableInkHash &&
          other.previewPngHash == this.previewPngHash &&
          other.ocrText == this.ocrText &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class InkPagesCompanion extends UpdateCompanion<InkPageEntry> {
  final Value<String> id;
  final Value<String> documentId;
  final Value<int> pageNumber;
  final Value<double> width;
  final Value<double> height;
  final Value<String> templateType;
  final Value<double> templateSpacing;
  final Value<int> backgroundColor;
  final Value<String?> pdfDocumentId;
  final Value<String?> pdfSourceHash;
  final Value<int?> pdfPageIndex;
  final Value<String?> rawPencilkitHash;
  final Value<String?> portableInkHash;
  final Value<String?> previewPngHash;
  final Value<String?> ocrText;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const InkPagesCompanion({
    this.id = const Value.absent(),
    this.documentId = const Value.absent(),
    this.pageNumber = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.templateType = const Value.absent(),
    this.templateSpacing = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.pdfDocumentId = const Value.absent(),
    this.pdfSourceHash = const Value.absent(),
    this.pdfPageIndex = const Value.absent(),
    this.rawPencilkitHash = const Value.absent(),
    this.portableInkHash = const Value.absent(),
    this.previewPngHash = const Value.absent(),
    this.ocrText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  InkPagesCompanion.insert({
    required String id,
    required String documentId,
    required int pageNumber,
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.templateType = const Value.absent(),
    this.templateSpacing = const Value.absent(),
    this.backgroundColor = const Value.absent(),
    this.pdfDocumentId = const Value.absent(),
    this.pdfSourceHash = const Value.absent(),
    this.pdfPageIndex = const Value.absent(),
    this.rawPencilkitHash = const Value.absent(),
    this.portableInkHash = const Value.absent(),
    this.previewPngHash = const Value.absent(),
    this.ocrText = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       documentId = Value(documentId),
       pageNumber = Value(pageNumber),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<InkPageEntry> custom({
    Expression<String>? id,
    Expression<String>? documentId,
    Expression<int>? pageNumber,
    Expression<double>? width,
    Expression<double>? height,
    Expression<String>? templateType,
    Expression<double>? templateSpacing,
    Expression<int>? backgroundColor,
    Expression<String>? pdfDocumentId,
    Expression<String>? pdfSourceHash,
    Expression<int>? pdfPageIndex,
    Expression<String>? rawPencilkitHash,
    Expression<String>? portableInkHash,
    Expression<String>? previewPngHash,
    Expression<String>? ocrText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (documentId != null) 'document_id': documentId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (templateType != null) 'template_type': templateType,
      if (templateSpacing != null) 'template_spacing': templateSpacing,
      if (backgroundColor != null) 'background_color': backgroundColor,
      if (pdfDocumentId != null) 'pdf_document_id': pdfDocumentId,
      if (pdfSourceHash != null) 'pdf_source_hash': pdfSourceHash,
      if (pdfPageIndex != null) 'pdf_page_index': pdfPageIndex,
      if (rawPencilkitHash != null) 'raw_pencilkit_hash': rawPencilkitHash,
      if (portableInkHash != null) 'portable_ink_hash': portableInkHash,
      if (previewPngHash != null) 'preview_png_hash': previewPngHash,
      if (ocrText != null) 'ocr_text': ocrText,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  InkPagesCompanion copyWith({
    Value<String>? id,
    Value<String>? documentId,
    Value<int>? pageNumber,
    Value<double>? width,
    Value<double>? height,
    Value<String>? templateType,
    Value<double>? templateSpacing,
    Value<int>? backgroundColor,
    Value<String?>? pdfDocumentId,
    Value<String?>? pdfSourceHash,
    Value<int?>? pdfPageIndex,
    Value<String?>? rawPencilkitHash,
    Value<String?>? portableInkHash,
    Value<String?>? previewPngHash,
    Value<String?>? ocrText,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return InkPagesCompanion(
      id: id ?? this.id,
      documentId: documentId ?? this.documentId,
      pageNumber: pageNumber ?? this.pageNumber,
      width: width ?? this.width,
      height: height ?? this.height,
      templateType: templateType ?? this.templateType,
      templateSpacing: templateSpacing ?? this.templateSpacing,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      pdfDocumentId: pdfDocumentId ?? this.pdfDocumentId,
      pdfSourceHash: pdfSourceHash ?? this.pdfSourceHash,
      pdfPageIndex: pdfPageIndex ?? this.pdfPageIndex,
      rawPencilkitHash: rawPencilkitHash ?? this.rawPencilkitHash,
      portableInkHash: portableInkHash ?? this.portableInkHash,
      previewPngHash: previewPngHash ?? this.previewPngHash,
      ocrText: ocrText ?? this.ocrText,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (documentId.present) {
      map['document_id'] = Variable<String>(documentId.value);
    }
    if (pageNumber.present) {
      map['page_number'] = Variable<int>(pageNumber.value);
    }
    if (width.present) {
      map['width'] = Variable<double>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<double>(height.value);
    }
    if (templateType.present) {
      map['template_type'] = Variable<String>(templateType.value);
    }
    if (templateSpacing.present) {
      map['template_spacing'] = Variable<double>(templateSpacing.value);
    }
    if (backgroundColor.present) {
      map['background_color'] = Variable<int>(backgroundColor.value);
    }
    if (pdfDocumentId.present) {
      map['pdf_document_id'] = Variable<String>(pdfDocumentId.value);
    }
    if (pdfSourceHash.present) {
      map['pdf_source_hash'] = Variable<String>(pdfSourceHash.value);
    }
    if (pdfPageIndex.present) {
      map['pdf_page_index'] = Variable<int>(pdfPageIndex.value);
    }
    if (rawPencilkitHash.present) {
      map['raw_pencilkit_hash'] = Variable<String>(rawPencilkitHash.value);
    }
    if (portableInkHash.present) {
      map['portable_ink_hash'] = Variable<String>(portableInkHash.value);
    }
    if (previewPngHash.present) {
      map['preview_png_hash'] = Variable<String>(previewPngHash.value);
    }
    if (ocrText.present) {
      map['ocr_text'] = Variable<String>(ocrText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('InkPagesCompanion(')
          ..write('id: $id, ')
          ..write('documentId: $documentId, ')
          ..write('pageNumber: $pageNumber, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('templateType: $templateType, ')
          ..write('templateSpacing: $templateSpacing, ')
          ..write('backgroundColor: $backgroundColor, ')
          ..write('pdfDocumentId: $pdfDocumentId, ')
          ..write('pdfSourceHash: $pdfSourceHash, ')
          ..write('pdfPageIndex: $pdfPageIndex, ')
          ..write('rawPencilkitHash: $rawPencilkitHash, ')
          ..write('portableInkHash: $portableInkHash, ')
          ..write('previewPngHash: $previewPngHash, ')
          ..write('ocrText: $ocrText, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodeLinksTable extends NodeLinks
    with TableInfo<$NodeLinksTable, NodeLinkEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNodeIdMeta = const VerificationMeta(
    'sourceNodeId',
  );
  @override
  late final GeneratedColumn<String> sourceNodeId = GeneratedColumn<String>(
    'source_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _targetNodeIdMeta = const VerificationMeta(
    'targetNodeId',
  );
  @override
  late final GeneratedColumn<String> targetNodeId = GeneratedColumn<String>(
    'target_node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _linkTextMeta = const VerificationMeta(
    'linkText',
  );
  @override
  late final GeneratedColumn<String> linkText = GeneratedColumn<String>(
    'link_text',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    sourceNodeId,
    targetNodeId,
    linkText,
    createdAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeLinkEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('source_node_id')) {
      context.handle(
        _sourceNodeIdMeta,
        sourceNodeId.isAcceptableOrUnknown(
          data['source_node_id']!,
          _sourceNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceNodeIdMeta);
    }
    if (data.containsKey('target_node_id')) {
      context.handle(
        _targetNodeIdMeta,
        targetNodeId.isAcceptableOrUnknown(
          data['target_node_id']!,
          _targetNodeIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetNodeIdMeta);
    }
    if (data.containsKey('link_text')) {
      context.handle(
        _linkTextMeta,
        linkText.isAcceptableOrUnknown(data['link_text']!, _linkTextMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NodeLinkEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeLinkEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sourceNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_node_id'],
      )!,
      targetNodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_node_id'],
      )!,
      linkText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}link_text'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $NodeLinksTable createAlias(String alias) {
    return $NodeLinksTable(attachedDatabase, alias);
  }
}

class NodeLinkEntry extends DataClass implements Insertable<NodeLinkEntry> {
  final String id;
  final String sourceNodeId;
  final String targetNodeId;
  final String? linkText;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const NodeLinkEntry({
    required this.id,
    required this.sourceNodeId,
    required this.targetNodeId,
    this.linkText,
    required this.createdAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['source_node_id'] = Variable<String>(sourceNodeId);
    map['target_node_id'] = Variable<String>(targetNodeId);
    if (!nullToAbsent || linkText != null) {
      map['link_text'] = Variable<String>(linkText);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  NodeLinksCompanion toCompanion(bool nullToAbsent) {
    return NodeLinksCompanion(
      id: Value(id),
      sourceNodeId: Value(sourceNodeId),
      targetNodeId: Value(targetNodeId),
      linkText: linkText == null && nullToAbsent
          ? const Value.absent()
          : Value(linkText),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory NodeLinkEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeLinkEntry(
      id: serializer.fromJson<String>(json['id']),
      sourceNodeId: serializer.fromJson<String>(json['sourceNodeId']),
      targetNodeId: serializer.fromJson<String>(json['targetNodeId']),
      linkText: serializer.fromJson<String?>(json['linkText']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sourceNodeId': serializer.toJson<String>(sourceNodeId),
      'targetNodeId': serializer.toJson<String>(targetNodeId),
      'linkText': serializer.toJson<String?>(linkText),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  NodeLinkEntry copyWith({
    String? id,
    String? sourceNodeId,
    String? targetNodeId,
    Value<String?> linkText = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => NodeLinkEntry(
    id: id ?? this.id,
    sourceNodeId: sourceNodeId ?? this.sourceNodeId,
    targetNodeId: targetNodeId ?? this.targetNodeId,
    linkText: linkText.present ? linkText.value : this.linkText,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  NodeLinkEntry copyWithCompanion(NodeLinksCompanion data) {
    return NodeLinkEntry(
      id: data.id.present ? data.id.value : this.id,
      sourceNodeId: data.sourceNodeId.present
          ? data.sourceNodeId.value
          : this.sourceNodeId,
      targetNodeId: data.targetNodeId.present
          ? data.targetNodeId.value
          : this.targetNodeId,
      linkText: data.linkText.present ? data.linkText.value : this.linkText,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeLinkEntry(')
          ..write('id: $id, ')
          ..write('sourceNodeId: $sourceNodeId, ')
          ..write('targetNodeId: $targetNodeId, ')
          ..write('linkText: $linkText, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    sourceNodeId,
    targetNodeId,
    linkText,
    createdAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeLinkEntry &&
          other.id == this.id &&
          other.sourceNodeId == this.sourceNodeId &&
          other.targetNodeId == this.targetNodeId &&
          other.linkText == this.linkText &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class NodeLinksCompanion extends UpdateCompanion<NodeLinkEntry> {
  final Value<String> id;
  final Value<String> sourceNodeId;
  final Value<String> targetNodeId;
  final Value<String?> linkText;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const NodeLinksCompanion({
    this.id = const Value.absent(),
    this.sourceNodeId = const Value.absent(),
    this.targetNodeId = const Value.absent(),
    this.linkText = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodeLinksCompanion.insert({
    required String id,
    required String sourceNodeId,
    required String targetNodeId,
    this.linkText = const Value.absent(),
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sourceNodeId = Value(sourceNodeId),
       targetNodeId = Value(targetNodeId),
       createdAt = Value(createdAt);
  static Insertable<NodeLinkEntry> custom({
    Expression<String>? id,
    Expression<String>? sourceNodeId,
    Expression<String>? targetNodeId,
    Expression<String>? linkText,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sourceNodeId != null) 'source_node_id': sourceNodeId,
      if (targetNodeId != null) 'target_node_id': targetNodeId,
      if (linkText != null) 'link_text': linkText,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodeLinksCompanion copyWith({
    Value<String>? id,
    Value<String>? sourceNodeId,
    Value<String>? targetNodeId,
    Value<String?>? linkText,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return NodeLinksCompanion(
      id: id ?? this.id,
      sourceNodeId: sourceNodeId ?? this.sourceNodeId,
      targetNodeId: targetNodeId ?? this.targetNodeId,
      linkText: linkText ?? this.linkText,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sourceNodeId.present) {
      map['source_node_id'] = Variable<String>(sourceNodeId.value);
    }
    if (targetNodeId.present) {
      map['target_node_id'] = Variable<String>(targetNodeId.value);
    }
    if (linkText.present) {
      map['link_text'] = Variable<String>(linkText.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeLinksCompanion(')
          ..write('id: $id, ')
          ..write('sourceNodeId: $sourceNodeId, ')
          ..write('targetNodeId: $targetNodeId, ')
          ..write('linkText: $linkText, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TagsTable extends Tags with TableInfo<$TagsTable, TagEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _colorMeta = const VerificationMeta('color');
  @override
  late final GeneratedColumn<int> color = GeneratedColumn<int>(
    'color',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    name,
    color,
    createdAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<TagEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('color')) {
      context.handle(
        _colorMeta,
        color.isAcceptableOrUnknown(data['color']!, _colorMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workspaceId, name},
  ];
  @override
  TagEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TagEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      color: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}color'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $TagsTable createAlias(String alias) {
    return $TagsTable(attachedDatabase, alias);
  }
}

class TagEntry extends DataClass implements Insertable<TagEntry> {
  final String id;
  final String workspaceId;
  final String name;
  final int? color;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const TagEntry({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.color,
    required this.createdAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || color != null) {
      map['color'] = Variable<int>(color);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  TagsCompanion toCompanion(bool nullToAbsent) {
    return TagsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      name: Value(name),
      color: color == null && nullToAbsent
          ? const Value.absent()
          : Value(color),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory TagEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TagEntry(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      name: serializer.fromJson<String>(json['name']),
      color: serializer.fromJson<int?>(json['color']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'color': serializer.toJson<int?>(color),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  TagEntry copyWith({
    String? id,
    String? workspaceId,
    String? name,
    Value<int?> color = const Value.absent(),
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => TagEntry(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    color: color.present ? color.value : this.color,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  TagEntry copyWithCompanion(TagsCompanion data) {
    return TagEntry(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      color: data.color.present ? data.color.value : this.color,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TagEntry(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    color,
    createdAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TagEntry &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.color == this.color &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class TagsCompanion extends UpdateCompanion<TagEntry> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<int?> color;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const TagsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.color = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TagsCompanion.insert({
    required String id,
    required String workspaceId,
    required String name,
    this.color = const Value.absent(),
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       name = Value(name),
       createdAt = Value(createdAt);
  static Insertable<TagEntry> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<int>? color,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (color != null) 'color': color,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TagsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? name,
    Value<int?>? color,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return TagsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (color.present) {
      map['color'] = Variable<int>(color.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('color: $color, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $NodeTagsTable extends NodeTags
    with TableInfo<$NodeTagsTable, NodeTagEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodeTagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tagIdMeta = const VerificationMeta('tagId');
  @override
  late final GeneratedColumn<String> tagId = GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    nodeId,
    tagId,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'node_tags';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeTagEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {nodeId, tagId};
  @override
  NodeTagEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeTagEntry(
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $NodeTagsTable createAlias(String alias) {
    return $NodeTagsTable(attachedDatabase, alias);
  }
}

class NodeTagEntry extends DataClass implements Insertable<NodeTagEntry> {
  final String nodeId;
  final String tagId;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const NodeTagEntry({
    required this.nodeId,
    required this.tagId,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['node_id'] = Variable<String>(nodeId);
    map['tag_id'] = Variable<String>(tagId);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  NodeTagsCompanion toCompanion(bool nullToAbsent) {
    return NodeTagsCompanion(
      nodeId: Value(nodeId),
      tagId: Value(tagId),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory NodeTagEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeTagEntry(
      nodeId: serializer.fromJson<String>(json['nodeId']),
      tagId: serializer.fromJson<String>(json['tagId']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'nodeId': serializer.toJson<String>(nodeId),
      'tagId': serializer.toJson<String>(tagId),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  NodeTagEntry copyWith({
    String? nodeId,
    String? tagId,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => NodeTagEntry(
    nodeId: nodeId ?? this.nodeId,
    tagId: tagId ?? this.tagId,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  NodeTagEntry copyWithCompanion(NodeTagsCompanion data) {
    return NodeTagEntry(
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      tagId: data.tagId.present ? data.tagId.value : this.tagId,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeTagEntry(')
          ..write('nodeId: $nodeId, ')
          ..write('tagId: $tagId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    nodeId,
    tagId,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeTagEntry &&
          other.nodeId == this.nodeId &&
          other.tagId == this.tagId &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class NodeTagsCompanion extends UpdateCompanion<NodeTagEntry> {
  final Value<String> nodeId;
  final Value<String> tagId;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const NodeTagsCompanion({
    this.nodeId = const Value.absent(),
    this.tagId = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodeTagsCompanion.insert({
    required String nodeId,
    required String tagId,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : nodeId = Value(nodeId),
       tagId = Value(tagId);
  static Insertable<NodeTagEntry> custom({
    Expression<String>? nodeId,
    Expression<String>? tagId,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (nodeId != null) 'node_id': nodeId,
      if (tagId != null) 'tag_id': tagId,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodeTagsCompanion copyWith({
    Value<String>? nodeId,
    Value<String>? tagId,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return NodeTagsCompanion(
      nodeId: nodeId ?? this.nodeId,
      tagId: tagId ?? this.tagId,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (tagId.present) {
      map['tag_id'] = Variable<String>(tagId.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodeTagsCompanion(')
          ..write('nodeId: $nodeId, ')
          ..write('tagId: $tagId, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProjectsTable extends Projects
    with TableInfo<$ProjectsTable, ProjectEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProjectsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 255,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#4F46E5'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    name,
    description,
    colorHex,
    icon,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'projects';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProjectEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProjectEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProjectEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $ProjectsTable createAlias(String alias) {
    return $ProjectsTable(attachedDatabase, alias);
  }
}

class ProjectEntry extends DataClass implements Insertable<ProjectEntry> {
  final String id;
  final String workspaceId;
  final String name;
  final String? description;
  final String colorHex;
  final String? icon;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const ProjectEntry({
    required this.id,
    required this.workspaceId,
    required this.name,
    this.description,
    required this.colorHex,
    this.icon,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['color_hex'] = Variable<String>(colorHex);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  ProjectsCompanion toCompanion(bool nullToAbsent) {
    return ProjectsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      colorHex: Value(colorHex),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory ProjectEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProjectEntry(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      icon: serializer.fromJson<String?>(json['icon']),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'colorHex': serializer.toJson<String>(colorHex),
      'icon': serializer.toJson<String?>(icon),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  ProjectEntry copyWith({
    String? id,
    String? workspaceId,
    String? name,
    Value<String?> description = const Value.absent(),
    String? colorHex,
    Value<String?> icon = const Value.absent(),
    bool? isArchived,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => ProjectEntry(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    colorHex: colorHex ?? this.colorHex,
    icon: icon.present ? icon.value : this.icon,
    isArchived: isArchived ?? this.isArchived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  ProjectEntry copyWithCompanion(ProjectsCompanion data) {
    return ProjectEntry(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      icon: data.icon.present ? data.icon.value : this.icon,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProjectEntry(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    description,
    colorHex,
    icon,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProjectEntry &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.name == this.name &&
          other.description == this.description &&
          other.colorHex == this.colorHex &&
          other.icon == this.icon &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class ProjectsCompanion extends UpdateCompanion<ProjectEntry> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> name;
  final Value<String?> description;
  final Value<String> colorHex;
  final Value<String?> icon;
  final Value<bool> isArchived;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const ProjectsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProjectsCompanion.insert({
    required String id,
    required String workspaceId,
    required String name,
    this.description = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       name = Value(name),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ProjectEntry> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? name,
    Expression<String>? description,
    Expression<String>? colorHex,
    Expression<String>? icon,
    Expression<bool>? isArchived,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (colorHex != null) 'color_hex': colorHex,
      if (icon != null) 'icon': icon,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProjectsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? name,
    Value<String?>? description,
    Value<String>? colorHex,
    Value<String?>? icon,
    Value<bool>? isArchived,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return ProjectsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      name: name ?? this.name,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProjectsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, TaskEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _projectIdMeta = const VerificationMeta(
    'projectId',
  );
  @override
  late final GeneratedColumn<String> projectId = GeneratedColumn<String>(
    'project_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES projects (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _parentTaskIdMeta = const VerificationMeta(
    'parentTaskId',
  );
  @override
  late final GeneratedColumn<String> parentTaskId = GeneratedColumn<String>(
    'parent_task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('todo'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<DateTime> dueDate = GeneratedColumn<DateTime>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _hasTimeMeta = const VerificationMeta(
    'hasTime',
  );
  @override
  late final GeneratedColumn<bool> hasTime = GeneratedColumn<bool>(
    'has_time',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("has_time" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceRuleMeta = const VerificationMeta(
    'recurrenceRule',
  );
  @override
  late final GeneratedColumn<String> recurrenceRule = GeneratedColumn<String>(
    'recurrence_rule',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderMinutesBeforeMeta =
      const VerificationMeta('reminderMinutesBefore');
  @override
  late final GeneratedColumn<int> reminderMinutesBefore = GeneratedColumn<int>(
    'reminder_minutes_before',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    projectId,
    nodeId,
    parentTaskId,
    title,
    description,
    isCompleted,
    status,
    priority,
    dueDate,
    hasTime,
    completedAt,
    recurrenceRule,
    reminderMinutesBefore,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<TaskEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('project_id')) {
      context.handle(
        _projectIdMeta,
        projectId.isAcceptableOrUnknown(data['project_id']!, _projectIdMeta),
      );
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('parent_task_id')) {
      context.handle(
        _parentTaskIdMeta,
        parentTaskId.isAcceptableOrUnknown(
          data['parent_task_id']!,
          _parentTaskIdMeta,
        ),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('has_time')) {
      context.handle(
        _hasTimeMeta,
        hasTime.isAcceptableOrUnknown(data['has_time']!, _hasTimeMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('recurrence_rule')) {
      context.handle(
        _recurrenceRuleMeta,
        recurrenceRule.isAcceptableOrUnknown(
          data['recurrence_rule']!,
          _recurrenceRuleMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minutes_before')) {
      context.handle(
        _reminderMinutesBeforeMeta,
        reminderMinutesBefore.isAcceptableOrUnknown(
          data['reminder_minutes_before']!,
          _reminderMinutesBeforeMeta,
        ),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TaskEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TaskEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      projectId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}project_id'],
      ),
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      ),
      parentTaskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_task_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due_date'],
      ),
      hasTime: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}has_time'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      recurrenceRule: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence_rule'],
      ),
      reminderMinutesBefore: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes_before'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class TaskEntry extends DataClass implements Insertable<TaskEntry> {
  final String id;
  final String workspaceId;
  final String? projectId;
  final String? nodeId;
  final String? parentTaskId;
  final String title;
  final String? description;
  final bool isCompleted;
  final String status;
  final int priority;
  final DateTime? dueDate;
  final bool hasTime;
  final DateTime? completedAt;
  final String? recurrenceRule;
  final int? reminderMinutesBefore;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const TaskEntry({
    required this.id,
    required this.workspaceId,
    this.projectId,
    this.nodeId,
    this.parentTaskId,
    required this.title,
    this.description,
    required this.isCompleted,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.hasTime,
    this.completedAt,
    this.recurrenceRule,
    this.reminderMinutesBefore,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    if (!nullToAbsent || projectId != null) {
      map['project_id'] = Variable<String>(projectId);
    }
    if (!nullToAbsent || nodeId != null) {
      map['node_id'] = Variable<String>(nodeId);
    }
    if (!nullToAbsent || parentTaskId != null) {
      map['parent_task_id'] = Variable<String>(parentTaskId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<int>(priority);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<DateTime>(dueDate);
    }
    map['has_time'] = Variable<bool>(hasTime);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    if (!nullToAbsent || recurrenceRule != null) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule);
    }
    if (!nullToAbsent || reminderMinutesBefore != null) {
      map['reminder_minutes_before'] = Variable<int>(reminderMinutesBefore);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      projectId: projectId == null && nullToAbsent
          ? const Value.absent()
          : Value(projectId),
      nodeId: nodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(nodeId),
      parentTaskId: parentTaskId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentTaskId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      isCompleted: Value(isCompleted),
      status: Value(status),
      priority: Value(priority),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      hasTime: Value(hasTime),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      recurrenceRule: recurrenceRule == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrenceRule),
      reminderMinutesBefore: reminderMinutesBefore == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderMinutesBefore),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory TaskEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TaskEntry(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      projectId: serializer.fromJson<String?>(json['projectId']),
      nodeId: serializer.fromJson<String?>(json['nodeId']),
      parentTaskId: serializer.fromJson<String?>(json['parentTaskId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<int>(json['priority']),
      dueDate: serializer.fromJson<DateTime?>(json['dueDate']),
      hasTime: serializer.fromJson<bool>(json['hasTime']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      recurrenceRule: serializer.fromJson<String?>(json['recurrenceRule']),
      reminderMinutesBefore: serializer.fromJson<int?>(
        json['reminderMinutesBefore'],
      ),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'projectId': serializer.toJson<String?>(projectId),
      'nodeId': serializer.toJson<String?>(nodeId),
      'parentTaskId': serializer.toJson<String?>(parentTaskId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<int>(priority),
      'dueDate': serializer.toJson<DateTime?>(dueDate),
      'hasTime': serializer.toJson<bool>(hasTime),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'recurrenceRule': serializer.toJson<String?>(recurrenceRule),
      'reminderMinutesBefore': serializer.toJson<int?>(reminderMinutesBefore),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  TaskEntry copyWith({
    String? id,
    String? workspaceId,
    Value<String?> projectId = const Value.absent(),
    Value<String?> nodeId = const Value.absent(),
    Value<String?> parentTaskId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    bool? isCompleted,
    String? status,
    int? priority,
    Value<DateTime?> dueDate = const Value.absent(),
    bool? hasTime,
    Value<DateTime?> completedAt = const Value.absent(),
    Value<String?> recurrenceRule = const Value.absent(),
    Value<int?> reminderMinutesBefore = const Value.absent(),
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => TaskEntry(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    projectId: projectId.present ? projectId.value : this.projectId,
    nodeId: nodeId.present ? nodeId.value : this.nodeId,
    parentTaskId: parentTaskId.present ? parentTaskId.value : this.parentTaskId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    isCompleted: isCompleted ?? this.isCompleted,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    hasTime: hasTime ?? this.hasTime,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    recurrenceRule: recurrenceRule.present
        ? recurrenceRule.value
        : this.recurrenceRule,
    reminderMinutesBefore: reminderMinutesBefore.present
        ? reminderMinutesBefore.value
        : this.reminderMinutesBefore,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  TaskEntry copyWithCompanion(TasksCompanion data) {
    return TaskEntry(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      projectId: data.projectId.present ? data.projectId.value : this.projectId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      parentTaskId: data.parentTaskId.present
          ? data.parentTaskId.value
          : this.parentTaskId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      hasTime: data.hasTime.present ? data.hasTime.value : this.hasTime,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      recurrenceRule: data.recurrenceRule.present
          ? data.recurrenceRule.value
          : this.recurrenceRule,
      reminderMinutesBefore: data.reminderMinutesBefore.present
          ? data.reminderMinutesBefore.value
          : this.reminderMinutesBefore,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TaskEntry(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('projectId: $projectId, ')
          ..write('nodeId: $nodeId, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('hasTime: $hasTime, ')
          ..write('completedAt: $completedAt, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    workspaceId,
    projectId,
    nodeId,
    parentTaskId,
    title,
    description,
    isCompleted,
    status,
    priority,
    dueDate,
    hasTime,
    completedAt,
    recurrenceRule,
    reminderMinutesBefore,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TaskEntry &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.projectId == this.projectId &&
          other.nodeId == this.nodeId &&
          other.parentTaskId == this.parentTaskId &&
          other.title == this.title &&
          other.description == this.description &&
          other.isCompleted == this.isCompleted &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.dueDate == this.dueDate &&
          other.hasTime == this.hasTime &&
          other.completedAt == this.completedAt &&
          other.recurrenceRule == this.recurrenceRule &&
          other.reminderMinutesBefore == this.reminderMinutesBefore &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class TasksCompanion extends UpdateCompanion<TaskEntry> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String?> projectId;
  final Value<String?> nodeId;
  final Value<String?> parentTaskId;
  final Value<String> title;
  final Value<String?> description;
  final Value<bool> isCompleted;
  final Value<String> status;
  final Value<int> priority;
  final Value<DateTime?> dueDate;
  final Value<bool> hasTime;
  final Value<DateTime?> completedAt;
  final Value<String?> recurrenceRule;
  final Value<int?> reminderMinutesBefore;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.projectId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String workspaceId,
    this.projectId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.parentTaskId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.hasTime = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.recurrenceRule = const Value.absent(),
    this.reminderMinutesBefore = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<TaskEntry> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? projectId,
    Expression<String>? nodeId,
    Expression<String>? parentTaskId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<bool>? isCompleted,
    Expression<String>? status,
    Expression<int>? priority,
    Expression<DateTime>? dueDate,
    Expression<bool>? hasTime,
    Expression<DateTime>? completedAt,
    Expression<String>? recurrenceRule,
    Expression<int>? reminderMinutesBefore,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (projectId != null) 'project_id': projectId,
      if (nodeId != null) 'node_id': nodeId,
      if (parentTaskId != null) 'parent_task_id': parentTaskId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (dueDate != null) 'due_date': dueDate,
      if (hasTime != null) 'has_time': hasTime,
      if (completedAt != null) 'completed_at': completedAt,
      if (recurrenceRule != null) 'recurrence_rule': recurrenceRule,
      if (reminderMinutesBefore != null)
        'reminder_minutes_before': reminderMinutesBefore,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String?>? projectId,
    Value<String?>? nodeId,
    Value<String?>? parentTaskId,
    Value<String>? title,
    Value<String?>? description,
    Value<bool>? isCompleted,
    Value<String>? status,
    Value<int>? priority,
    Value<DateTime?>? dueDate,
    Value<bool>? hasTime,
    Value<DateTime?>? completedAt,
    Value<String?>? recurrenceRule,
    Value<int?>? reminderMinutesBefore,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      projectId: projectId ?? this.projectId,
      nodeId: nodeId ?? this.nodeId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: dueDate ?? this.dueDate,
      hasTime: hasTime ?? this.hasTime,
      completedAt: completedAt ?? this.completedAt,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      reminderMinutesBefore:
          reminderMinutesBefore ?? this.reminderMinutesBefore,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (projectId.present) {
      map['project_id'] = Variable<String>(projectId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (parentTaskId.present) {
      map['parent_task_id'] = Variable<String>(parentTaskId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<DateTime>(dueDate.value);
    }
    if (hasTime.present) {
      map['has_time'] = Variable<bool>(hasTime.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (recurrenceRule.present) {
      map['recurrence_rule'] = Variable<String>(recurrenceRule.value);
    }
    if (reminderMinutesBefore.present) {
      map['reminder_minutes_before'] = Variable<int>(
        reminderMinutesBefore.value,
      );
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('projectId: $projectId, ')
          ..write('nodeId: $nodeId, ')
          ..write('parentTaskId: $parentTaskId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('dueDate: $dueDate, ')
          ..write('hasTime: $hasTime, ')
          ..write('completedAt: $completedAt, ')
          ..write('recurrenceRule: $recurrenceRule, ')
          ..write('reminderMinutesBefore: $reminderMinutesBefore, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CalendarEventsTable extends CalendarEvents
    with TableInfo<$CalendarEventsTable, CalendarEventEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CalendarEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 1000,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startTimeMeta = const VerificationMeta(
    'startTime',
  );
  @override
  late final GeneratedColumn<DateTime> startTime = GeneratedColumn<DateTime>(
    'start_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endTimeMeta = const VerificationMeta(
    'endTime',
  );
  @override
  late final GeneratedColumn<DateTime> endTime = GeneratedColumn<DateTime>(
    'end_time',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isAllDayMeta = const VerificationMeta(
    'isAllDay',
  );
  @override
  late final GeneratedColumn<bool> isAllDay = GeneratedColumn<bool>(
    'is_all_day',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_all_day" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _locationMeta = const VerificationMeta(
    'location',
  );
  @override
  late final GeneratedColumn<String> location = GeneratedColumn<String>(
    'location',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    taskId,
    nodeId,
    title,
    description,
    startTime,
    endTime,
    isAllDay,
    colorHex,
    location,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'calendar_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<CalendarEventEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('start_time')) {
      context.handle(
        _startTimeMeta,
        startTime.isAcceptableOrUnknown(data['start_time']!, _startTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_startTimeMeta);
    }
    if (data.containsKey('end_time')) {
      context.handle(
        _endTimeMeta,
        endTime.isAcceptableOrUnknown(data['end_time']!, _endTimeMeta),
      );
    } else if (isInserting) {
      context.missing(_endTimeMeta);
    }
    if (data.containsKey('is_all_day')) {
      context.handle(
        _isAllDayMeta,
        isAllDay.isAcceptableOrUnknown(data['is_all_day']!, _isAllDayMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('location')) {
      context.handle(
        _locationMeta,
        location.isAcceptableOrUnknown(data['location']!, _locationMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CalendarEventEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CalendarEventEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      ),
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      startTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_time'],
      )!,
      endTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_time'],
      )!,
      isAllDay: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_all_day'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      location: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}location'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $CalendarEventsTable createAlias(String alias) {
    return $CalendarEventsTable(attachedDatabase, alias);
  }
}

class CalendarEventEntry extends DataClass
    implements Insertable<CalendarEventEntry> {
  final String id;
  final String workspaceId;
  final String? taskId;
  final String? nodeId;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isAllDay;
  final String? colorHex;
  final String? location;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const CalendarEventEntry({
    required this.id,
    required this.workspaceId,
    this.taskId,
    this.nodeId,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.isAllDay,
    this.colorHex,
    this.location,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    if (!nullToAbsent || taskId != null) {
      map['task_id'] = Variable<String>(taskId);
    }
    if (!nullToAbsent || nodeId != null) {
      map['node_id'] = Variable<String>(nodeId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['start_time'] = Variable<DateTime>(startTime);
    map['end_time'] = Variable<DateTime>(endTime);
    map['is_all_day'] = Variable<bool>(isAllDay);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    if (!nullToAbsent || location != null) {
      map['location'] = Variable<String>(location);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  CalendarEventsCompanion toCompanion(bool nullToAbsent) {
    return CalendarEventsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      taskId: taskId == null && nullToAbsent
          ? const Value.absent()
          : Value(taskId),
      nodeId: nodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(nodeId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      startTime: Value(startTime),
      endTime: Value(endTime),
      isAllDay: Value(isAllDay),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      location: location == null && nullToAbsent
          ? const Value.absent()
          : Value(location),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory CalendarEventEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CalendarEventEntry(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      taskId: serializer.fromJson<String?>(json['taskId']),
      nodeId: serializer.fromJson<String?>(json['nodeId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      startTime: serializer.fromJson<DateTime>(json['startTime']),
      endTime: serializer.fromJson<DateTime>(json['endTime']),
      isAllDay: serializer.fromJson<bool>(json['isAllDay']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      location: serializer.fromJson<String?>(json['location']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'taskId': serializer.toJson<String?>(taskId),
      'nodeId': serializer.toJson<String?>(nodeId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'startTime': serializer.toJson<DateTime>(startTime),
      'endTime': serializer.toJson<DateTime>(endTime),
      'isAllDay': serializer.toJson<bool>(isAllDay),
      'colorHex': serializer.toJson<String?>(colorHex),
      'location': serializer.toJson<String?>(location),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  CalendarEventEntry copyWith({
    String? id,
    String? workspaceId,
    Value<String?> taskId = const Value.absent(),
    Value<String?> nodeId = const Value.absent(),
    String? title,
    Value<String?> description = const Value.absent(),
    DateTime? startTime,
    DateTime? endTime,
    bool? isAllDay,
    Value<String?> colorHex = const Value.absent(),
    Value<String?> location = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => CalendarEventEntry(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    taskId: taskId.present ? taskId.value : this.taskId,
    nodeId: nodeId.present ? nodeId.value : this.nodeId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    isAllDay: isAllDay ?? this.isAllDay,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    location: location.present ? location.value : this.location,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  CalendarEventEntry copyWithCompanion(CalendarEventsCompanion data) {
    return CalendarEventEntry(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      startTime: data.startTime.present ? data.startTime.value : this.startTime,
      endTime: data.endTime.present ? data.endTime.value : this.endTime,
      isAllDay: data.isAllDay.present ? data.isAllDay.value : this.isAllDay,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      location: data.location.present ? data.location.value : this.location,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventEntry(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('taskId: $taskId, ')
          ..write('nodeId: $nodeId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('colorHex: $colorHex, ')
          ..write('location: $location, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    taskId,
    nodeId,
    title,
    description,
    startTime,
    endTime,
    isAllDay,
    colorHex,
    location,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CalendarEventEntry &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.taskId == this.taskId &&
          other.nodeId == this.nodeId &&
          other.title == this.title &&
          other.description == this.description &&
          other.startTime == this.startTime &&
          other.endTime == this.endTime &&
          other.isAllDay == this.isAllDay &&
          other.colorHex == this.colorHex &&
          other.location == this.location &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class CalendarEventsCompanion extends UpdateCompanion<CalendarEventEntry> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String?> taskId;
  final Value<String?> nodeId;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime> startTime;
  final Value<DateTime> endTime;
  final Value<bool> isAllDay;
  final Value<String?> colorHex;
  final Value<String?> location;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const CalendarEventsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.taskId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.startTime = const Value.absent(),
    this.endTime = const Value.absent(),
    this.isAllDay = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.location = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CalendarEventsCompanion.insert({
    required String id,
    required String workspaceId,
    this.taskId = const Value.absent(),
    this.nodeId = const Value.absent(),
    required String title,
    this.description = const Value.absent(),
    required DateTime startTime,
    required DateTime endTime,
    this.isAllDay = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.location = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       title = Value(title),
       startTime = Value(startTime),
       endTime = Value(endTime),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CalendarEventEntry> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? taskId,
    Expression<String>? nodeId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? startTime,
    Expression<DateTime>? endTime,
    Expression<bool>? isAllDay,
    Expression<String>? colorHex,
    Expression<String>? location,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (taskId != null) 'task_id': taskId,
      if (nodeId != null) 'node_id': nodeId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (isAllDay != null) 'is_all_day': isAllDay,
      if (colorHex != null) 'color_hex': colorHex,
      if (location != null) 'location': location,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CalendarEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String?>? taskId,
    Value<String?>? nodeId,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime>? startTime,
    Value<DateTime>? endTime,
    Value<bool>? isAllDay,
    Value<String?>? colorHex,
    Value<String?>? location,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return CalendarEventsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      taskId: taskId ?? this.taskId,
      nodeId: nodeId ?? this.nodeId,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isAllDay: isAllDay ?? this.isAllDay,
      colorHex: colorHex ?? this.colorHex,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (startTime.present) {
      map['start_time'] = Variable<DateTime>(startTime.value);
    }
    if (endTime.present) {
      map['end_time'] = Variable<DateTime>(endTime.value);
    }
    if (isAllDay.present) {
      map['is_all_day'] = Variable<bool>(isAllDay.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (location.present) {
      map['location'] = Variable<String>(location.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CalendarEventsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('taskId: $taskId, ')
          ..write('nodeId: $nodeId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('startTime: $startTime, ')
          ..write('endTime: $endTime, ')
          ..write('isAllDay: $isAllDay, ')
          ..write('colorHex: $colorHex, ')
          ..write('location: $location, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitsTable extends Habits with TableInfo<$HabitsTable, HabitEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('#4CAF50'),
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('daily'),
  );
  static const VerificationMeta _targetCountPerPeriodMeta =
      const VerificationMeta('targetCountPerPeriod');
  @override
  late final GeneratedColumn<int> targetCountPerPeriod = GeneratedColumn<int>(
    'target_count_per_period',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isArchivedMeta = const VerificationMeta(
    'isArchived',
  );
  @override
  late final GeneratedColumn<bool> isArchived = GeneratedColumn<bool>(
    'is_archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    title,
    description,
    colorHex,
    icon,
    frequency,
    targetCountPerPeriod,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    }
    if (data.containsKey('target_count_per_period')) {
      context.handle(
        _targetCountPerPeriodMeta,
        targetCountPerPeriod.isAcceptableOrUnknown(
          data['target_count_per_period']!,
          _targetCountPerPeriodMeta,
        ),
      );
    }
    if (data.containsKey('is_archived')) {
      context.handle(
        _isArchivedMeta,
        isArchived.isAcceptableOrUnknown(data['is_archived']!, _isArchivedMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  HabitEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      targetCountPerPeriod: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_count_per_period'],
      )!,
      isArchived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_archived'],
      )!,
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class HabitEntry extends DataClass implements Insertable<HabitEntry> {
  final String id;
  final String workspaceId;
  final String title;
  final String? description;
  final String colorHex;
  final String? icon;
  final String frequency;
  final int targetCountPerPeriod;
  final bool isArchived;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const HabitEntry({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description,
    required this.colorHex,
    this.icon,
    required this.frequency,
    required this.targetCountPerPeriod,
    required this.isArchived,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['color_hex'] = Variable<String>(colorHex);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['frequency'] = Variable<String>(frequency);
    map['target_count_per_period'] = Variable<int>(targetCountPerPeriod);
    map['is_archived'] = Variable<bool>(isArchived);
    map['sort_order'] = Variable<int>(sortOrder);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      colorHex: Value(colorHex),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      frequency: Value(frequency),
      targetCountPerPeriod: Value(targetCountPerPeriod),
      isArchived: Value(isArchived),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory HabitEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitEntry(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      colorHex: serializer.fromJson<String>(json['colorHex']),
      icon: serializer.fromJson<String?>(json['icon']),
      frequency: serializer.fromJson<String>(json['frequency']),
      targetCountPerPeriod: serializer.fromJson<int>(
        json['targetCountPerPeriod'],
      ),
      isArchived: serializer.fromJson<bool>(json['isArchived']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'colorHex': serializer.toJson<String>(colorHex),
      'icon': serializer.toJson<String?>(icon),
      'frequency': serializer.toJson<String>(frequency),
      'targetCountPerPeriod': serializer.toJson<int>(targetCountPerPeriod),
      'isArchived': serializer.toJson<bool>(isArchived),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  HabitEntry copyWith({
    String? id,
    String? workspaceId,
    String? title,
    Value<String?> description = const Value.absent(),
    String? colorHex,
    Value<String?> icon = const Value.absent(),
    String? frequency,
    int? targetCountPerPeriod,
    bool? isArchived,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => HabitEntry(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    colorHex: colorHex ?? this.colorHex,
    icon: icon.present ? icon.value : this.icon,
    frequency: frequency ?? this.frequency,
    targetCountPerPeriod: targetCountPerPeriod ?? this.targetCountPerPeriod,
    isArchived: isArchived ?? this.isArchived,
    sortOrder: sortOrder ?? this.sortOrder,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  HabitEntry copyWithCompanion(HabitsCompanion data) {
    return HabitEntry(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      icon: data.icon.present ? data.icon.value : this.icon,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      targetCountPerPeriod: data.targetCountPerPeriod.present
          ? data.targetCountPerPeriod.value
          : this.targetCountPerPeriod,
      isArchived: data.isArchived.present
          ? data.isArchived.value
          : this.isArchived,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitEntry(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('frequency: $frequency, ')
          ..write('targetCountPerPeriod: $targetCountPerPeriod, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    title,
    description,
    colorHex,
    icon,
    frequency,
    targetCountPerPeriod,
    isArchived,
    sortOrder,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitEntry &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.title == this.title &&
          other.description == this.description &&
          other.colorHex == this.colorHex &&
          other.icon == this.icon &&
          other.frequency == this.frequency &&
          other.targetCountPerPeriod == this.targetCountPerPeriod &&
          other.isArchived == this.isArchived &&
          other.sortOrder == this.sortOrder &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class HabitsCompanion extends UpdateCompanion<HabitEntry> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> title;
  final Value<String?> description;
  final Value<String> colorHex;
  final Value<String?> icon;
  final Value<String> frequency;
  final Value<int> targetCountPerPeriod;
  final Value<bool> isArchived;
  final Value<int> sortOrder;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.frequency = const Value.absent(),
    this.targetCountPerPeriod = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitsCompanion.insert({
    required String id,
    required String workspaceId,
    required String title,
    this.description = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.icon = const Value.absent(),
    this.frequency = const Value.absent(),
    this.targetCountPerPeriod = const Value.absent(),
    this.isArchived = const Value.absent(),
    this.sortOrder = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<HabitEntry> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<String>? colorHex,
    Expression<String>? icon,
    Expression<String>? frequency,
    Expression<int>? targetCountPerPeriod,
    Expression<bool>? isArchived,
    Expression<int>? sortOrder,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (colorHex != null) 'color_hex': colorHex,
      if (icon != null) 'icon': icon,
      if (frequency != null) 'frequency': frequency,
      if (targetCountPerPeriod != null)
        'target_count_per_period': targetCountPerPeriod,
      if (isArchived != null) 'is_archived': isArchived,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? title,
    Value<String?>? description,
    Value<String>? colorHex,
    Value<String?>? icon,
    Value<String>? frequency,
    Value<int>? targetCountPerPeriod,
    Value<bool>? isArchived,
    Value<int>? sortOrder,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      description: description ?? this.description,
      colorHex: colorHex ?? this.colorHex,
      icon: icon ?? this.icon,
      frequency: frequency ?? this.frequency,
      targetCountPerPeriod: targetCountPerPeriod ?? this.targetCountPerPeriod,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (targetCountPerPeriod.present) {
      map['target_count_per_period'] = Variable<int>(
        targetCountPerPeriod.value,
      );
    }
    if (isArchived.present) {
      map['is_archived'] = Variable<bool>(isArchived.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('colorHex: $colorHex, ')
          ..write('icon: $icon, ')
          ..write('frequency: $frequency, ')
          ..write('targetCountPerPeriod: $targetCountPerPeriod, ')
          ..write('isArchived: $isArchived, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HabitLogsTable extends HabitLogs
    with TableInfo<$HabitLogsTable, HabitLogEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitLogsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _habitIdMeta = const VerificationMeta(
    'habitId',
  );
  @override
  late final GeneratedColumn<String> habitId = GeneratedColumn<String>(
    'habit_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES habits (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _logDateMeta = const VerificationMeta(
    'logDate',
  );
  @override
  late final GeneratedColumn<String> logDate = GeneratedColumn<String>(
    'log_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedCountMeta = const VerificationMeta(
    'completedCount',
  );
  @override
  late final GeneratedColumn<int> completedCount = GeneratedColumn<int>(
    'completed_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    habitId,
    logDate,
    completedCount,
    isCompleted,
    createdAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habit_logs';
  @override
  VerificationContext validateIntegrity(
    Insertable<HabitLogEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('habit_id')) {
      context.handle(
        _habitIdMeta,
        habitId.isAcceptableOrUnknown(data['habit_id']!, _habitIdMeta),
      );
    } else if (isInserting) {
      context.missing(_habitIdMeta);
    }
    if (data.containsKey('log_date')) {
      context.handle(
        _logDateMeta,
        logDate.isAcceptableOrUnknown(data['log_date']!, _logDateMeta),
      );
    } else if (isInserting) {
      context.missing(_logDateMeta);
    }
    if (data.containsKey('completed_count')) {
      context.handle(
        _completedCountMeta,
        completedCount.isAcceptableOrUnknown(
          data['completed_count']!,
          _completedCountMeta,
        ),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {habitId, logDate},
  ];
  @override
  HabitLogEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HabitLogEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      habitId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}habit_id'],
      )!,
      logDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}log_date'],
      )!,
      completedCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_count'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $HabitLogsTable createAlias(String alias) {
    return $HabitLogsTable(attachedDatabase, alias);
  }
}

class HabitLogEntry extends DataClass implements Insertable<HabitLogEntry> {
  final String id;
  final String habitId;
  final String logDate;
  final int completedCount;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const HabitLogEntry({
    required this.id,
    required this.habitId,
    required this.logDate,
    required this.completedCount,
    required this.isCompleted,
    required this.createdAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['habit_id'] = Variable<String>(habitId);
    map['log_date'] = Variable<String>(logDate);
    map['completed_count'] = Variable<int>(completedCount);
    map['is_completed'] = Variable<bool>(isCompleted);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  HabitLogsCompanion toCompanion(bool nullToAbsent) {
    return HabitLogsCompanion(
      id: Value(id),
      habitId: Value(habitId),
      logDate: Value(logDate),
      completedCount: Value(completedCount),
      isCompleted: Value(isCompleted),
      createdAt: Value(createdAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory HabitLogEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HabitLogEntry(
      id: serializer.fromJson<String>(json['id']),
      habitId: serializer.fromJson<String>(json['habitId']),
      logDate: serializer.fromJson<String>(json['logDate']),
      completedCount: serializer.fromJson<int>(json['completedCount']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'habitId': serializer.toJson<String>(habitId),
      'logDate': serializer.toJson<String>(logDate),
      'completedCount': serializer.toJson<int>(completedCount),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  HabitLogEntry copyWith({
    String? id,
    String? habitId,
    String? logDate,
    int? completedCount,
    bool? isCompleted,
    DateTime? createdAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => HabitLogEntry(
    id: id ?? this.id,
    habitId: habitId ?? this.habitId,
    logDate: logDate ?? this.logDate,
    completedCount: completedCount ?? this.completedCount,
    isCompleted: isCompleted ?? this.isCompleted,
    createdAt: createdAt ?? this.createdAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  HabitLogEntry copyWithCompanion(HabitLogsCompanion data) {
    return HabitLogEntry(
      id: data.id.present ? data.id.value : this.id,
      habitId: data.habitId.present ? data.habitId.value : this.habitId,
      logDate: data.logDate.present ? data.logDate.value : this.logDate,
      completedCount: data.completedCount.present
          ? data.completedCount.value
          : this.completedCount,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogEntry(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('logDate: $logDate, ')
          ..write('completedCount: $completedCount, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    habitId,
    logDate,
    completedCount,
    isCompleted,
    createdAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HabitLogEntry &&
          other.id == this.id &&
          other.habitId == this.habitId &&
          other.logDate == this.logDate &&
          other.completedCount == this.completedCount &&
          other.isCompleted == this.isCompleted &&
          other.createdAt == this.createdAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class HabitLogsCompanion extends UpdateCompanion<HabitLogEntry> {
  final Value<String> id;
  final Value<String> habitId;
  final Value<String> logDate;
  final Value<int> completedCount;
  final Value<bool> isCompleted;
  final Value<DateTime> createdAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const HabitLogsCompanion({
    this.id = const Value.absent(),
    this.habitId = const Value.absent(),
    this.logDate = const Value.absent(),
    this.completedCount = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HabitLogsCompanion.insert({
    required String id,
    required String habitId,
    required String logDate,
    this.completedCount = const Value.absent(),
    this.isCompleted = const Value.absent(),
    required DateTime createdAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       habitId = Value(habitId),
       logDate = Value(logDate),
       createdAt = Value(createdAt);
  static Insertable<HabitLogEntry> custom({
    Expression<String>? id,
    Expression<String>? habitId,
    Expression<String>? logDate,
    Expression<int>? completedCount,
    Expression<bool>? isCompleted,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (habitId != null) 'habit_id': habitId,
      if (logDate != null) 'log_date': logDate,
      if (completedCount != null) 'completed_count': completedCount,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (createdAt != null) 'created_at': createdAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HabitLogsCompanion copyWith({
    Value<String>? id,
    Value<String>? habitId,
    Value<String>? logDate,
    Value<int>? completedCount,
    Value<bool>? isCompleted,
    Value<DateTime>? createdAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return HabitLogsCompanion(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      logDate: logDate ?? this.logDate,
      completedCount: completedCount ?? this.completedCount,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (habitId.present) {
      map['habit_id'] = Variable<String>(habitId.value);
    }
    if (logDate.present) {
      map['log_date'] = Variable<String>(logDate.value);
    }
    if (completedCount.present) {
      map['completed_count'] = Variable<int>(completedCount.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitLogsCompanion(')
          ..write('id: $id, ')
          ..write('habitId: $habitId, ')
          ..write('logDate: $logDate, ')
          ..write('completedCount: $completedCount, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $GoalsTable extends Goals with TableInfo<$GoalsTable, GoalEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $GoalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 500,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetDateMeta = const VerificationMeta(
    'targetDate',
  );
  @override
  late final GeneratedColumn<DateTime> targetDate = GeneratedColumn<DateTime>(
    'target_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('in_progress'),
  );
  static const VerificationMeta _colorHexMeta = const VerificationMeta(
    'colorHex',
  );
  @override
  late final GeneratedColumn<String> colorHex = GeneratedColumn<String>(
    'color_hex',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    title,
    description,
    targetDate,
    status,
    colorHex,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'goals';
  @override
  VerificationContext validateIntegrity(
    Insertable<GoalEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('target_date')) {
      context.handle(
        _targetDateMeta,
        targetDate.isAcceptableOrUnknown(data['target_date']!, _targetDateMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('color_hex')) {
      context.handle(
        _colorHexMeta,
        colorHex.isAcceptableOrUnknown(data['color_hex']!, _colorHexMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  GoalEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return GoalEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      targetDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}target_date'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      colorHex: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}color_hex'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $GoalsTable createAlias(String alias) {
    return $GoalsTable(attachedDatabase, alias);
  }
}

class GoalEntry extends DataClass implements Insertable<GoalEntry> {
  final String id;
  final String workspaceId;
  final String title;
  final String? description;
  final DateTime? targetDate;
  final String status;
  final String? colorHex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const GoalEntry({
    required this.id,
    required this.workspaceId,
    required this.title,
    this.description,
    this.targetDate,
    required this.status,
    this.colorHex,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    if (!nullToAbsent || targetDate != null) {
      map['target_date'] = Variable<DateTime>(targetDate);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || colorHex != null) {
      map['color_hex'] = Variable<String>(colorHex);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  GoalsCompanion toCompanion(bool nullToAbsent) {
    return GoalsCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      title: Value(title),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      targetDate: targetDate == null && nullToAbsent
          ? const Value.absent()
          : Value(targetDate),
      status: Value(status),
      colorHex: colorHex == null && nullToAbsent
          ? const Value.absent()
          : Value(colorHex),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory GoalEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return GoalEntry(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      title: serializer.fromJson<String>(json['title']),
      description: serializer.fromJson<String?>(json['description']),
      targetDate: serializer.fromJson<DateTime?>(json['targetDate']),
      status: serializer.fromJson<String>(json['status']),
      colorHex: serializer.fromJson<String?>(json['colorHex']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'title': serializer.toJson<String>(title),
      'description': serializer.toJson<String?>(description),
      'targetDate': serializer.toJson<DateTime?>(targetDate),
      'status': serializer.toJson<String>(status),
      'colorHex': serializer.toJson<String?>(colorHex),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  GoalEntry copyWith({
    String? id,
    String? workspaceId,
    String? title,
    Value<String?> description = const Value.absent(),
    Value<DateTime?> targetDate = const Value.absent(),
    String? status,
    Value<String?> colorHex = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => GoalEntry(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    title: title ?? this.title,
    description: description.present ? description.value : this.description,
    targetDate: targetDate.present ? targetDate.value : this.targetDate,
    status: status ?? this.status,
    colorHex: colorHex.present ? colorHex.value : this.colorHex,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  GoalEntry copyWithCompanion(GoalsCompanion data) {
    return GoalEntry(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      title: data.title.present ? data.title.value : this.title,
      description: data.description.present
          ? data.description.value
          : this.description,
      targetDate: data.targetDate.present
          ? data.targetDate.value
          : this.targetDate,
      status: data.status.present ? data.status.value : this.status,
      colorHex: data.colorHex.present ? data.colorHex.value : this.colorHex,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('GoalEntry(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('targetDate: $targetDate, ')
          ..write('status: $status, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    title,
    description,
    targetDate,
    status,
    colorHex,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GoalEntry &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.title == this.title &&
          other.description == this.description &&
          other.targetDate == this.targetDate &&
          other.status == this.status &&
          other.colorHex == this.colorHex &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class GoalsCompanion extends UpdateCompanion<GoalEntry> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> title;
  final Value<String?> description;
  final Value<DateTime?> targetDate;
  final Value<String> status;
  final Value<String?> colorHex;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const GoalsCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.title = const Value.absent(),
    this.description = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.status = const Value.absent(),
    this.colorHex = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  GoalsCompanion.insert({
    required String id,
    required String workspaceId,
    required String title,
    this.description = const Value.absent(),
    this.targetDate = const Value.absent(),
    this.status = const Value.absent(),
    this.colorHex = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       title = Value(title),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<GoalEntry> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? title,
    Expression<String>? description,
    Expression<DateTime>? targetDate,
    Expression<String>? status,
    Expression<String>? colorHex,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (title != null) 'title': title,
      if (description != null) 'description': description,
      if (targetDate != null) 'target_date': targetDate,
      if (status != null) 'status': status,
      if (colorHex != null) 'color_hex': colorHex,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  GoalsCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? title,
    Value<String?>? description,
    Value<DateTime?>? targetDate,
    Value<String>? status,
    Value<String?>? colorHex,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return GoalsCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      description: description ?? this.description,
      targetDate: targetDate ?? this.targetDate,
      status: status ?? this.status,
      colorHex: colorHex ?? this.colorHex,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (targetDate.present) {
      map['target_date'] = Variable<DateTime>(targetDate.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (colorHex.present) {
      map['color_hex'] = Variable<String>(colorHex.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('GoalsCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('title: $title, ')
          ..write('description: $description, ')
          ..write('targetDate: $targetDate, ')
          ..write('status: $status, ')
          ..write('colorHex: $colorHex, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $JournalEntriesTable extends JournalEntries
    with TableInfo<$JournalEntriesTable, JournalEntryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $JournalEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _workspaceIdMeta = const VerificationMeta(
    'workspaceId',
  );
  @override
  late final GeneratedColumn<String> workspaceId = GeneratedColumn<String>(
    'workspace_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workspaces (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES nodes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _journalDateMeta = const VerificationMeta(
    'journalDate',
  );
  @override
  late final GeneratedColumn<String> journalDate = GeneratedColumn<String>(
    'journal_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<String> mood = GeneratedColumn<String>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _clientModifiedAtMeta = const VerificationMeta(
    'clientModifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> clientModifiedAt =
      GeneratedColumn<DateTime>(
        'client_modified_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: currentDateAndTime,
      );
  static const VerificationMeta _modifiedDeviceIdMeta = const VerificationMeta(
    'modifiedDeviceId',
  );
  @override
  late final GeneratedColumn<String> modifiedDeviceId = GeneratedColumn<String>(
    'modified_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('local'),
  );
  static const VerificationMeta _syncVersionMeta = const VerificationMeta(
    'syncVersion',
  );
  @override
  late final GeneratedColumn<int> syncVersion = GeneratedColumn<int>(
    'sync_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    workspaceId,
    nodeId,
    journalDate,
    mood,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'journal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<JournalEntryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('workspace_id')) {
      context.handle(
        _workspaceIdMeta,
        workspaceId.isAcceptableOrUnknown(
          data['workspace_id']!,
          _workspaceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_workspaceIdMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nodeIdMeta);
    }
    if (data.containsKey('journal_date')) {
      context.handle(
        _journalDateMeta,
        journalDate.isAcceptableOrUnknown(
          data['journal_date']!,
          _journalDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_journalDateMeta);
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('client_modified_at')) {
      context.handle(
        _clientModifiedAtMeta,
        clientModifiedAt.isAcceptableOrUnknown(
          data['client_modified_at']!,
          _clientModifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('modified_device_id')) {
      context.handle(
        _modifiedDeviceIdMeta,
        modifiedDeviceId.isAcceptableOrUnknown(
          data['modified_device_id']!,
          _modifiedDeviceIdMeta,
        ),
      );
    }
    if (data.containsKey('sync_version')) {
      context.handle(
        _syncVersionMeta,
        syncVersion.isAcceptableOrUnknown(
          data['sync_version']!,
          _syncVersionMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {workspaceId, journalDate},
  ];
  @override
  JournalEntryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return JournalEntryData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      workspaceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}workspace_id'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      )!,
      journalDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}journal_date'],
      )!,
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mood'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      clientModifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}client_modified_at'],
      )!,
      modifiedDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}modified_device_id'],
      )!,
      syncVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sync_version'],
      )!,
    );
  }

  @override
  $JournalEntriesTable createAlias(String alias) {
    return $JournalEntriesTable(attachedDatabase, alias);
  }
}

class JournalEntryData extends DataClass
    implements Insertable<JournalEntryData> {
  final String id;
  final String workspaceId;
  final String nodeId;
  final String journalDate;
  final String? mood;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;
  final DateTime clientModifiedAt;
  final String modifiedDeviceId;
  final int syncVersion;
  const JournalEntryData({
    required this.id,
    required this.workspaceId,
    required this.nodeId,
    required this.journalDate,
    this.mood,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
    required this.clientModifiedAt,
    required this.modifiedDeviceId,
    required this.syncVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['workspace_id'] = Variable<String>(workspaceId);
    map['node_id'] = Variable<String>(nodeId);
    map['journal_date'] = Variable<String>(journalDate);
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<String>(mood);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    map['client_modified_at'] = Variable<DateTime>(clientModifiedAt);
    map['modified_device_id'] = Variable<String>(modifiedDeviceId);
    map['sync_version'] = Variable<int>(syncVersion);
    return map;
  }

  JournalEntriesCompanion toCompanion(bool nullToAbsent) {
    return JournalEntriesCompanion(
      id: Value(id),
      workspaceId: Value(workspaceId),
      nodeId: Value(nodeId),
      journalDate: Value(journalDate),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      clientModifiedAt: Value(clientModifiedAt),
      modifiedDeviceId: Value(modifiedDeviceId),
      syncVersion: Value(syncVersion),
    );
  }

  factory JournalEntryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return JournalEntryData(
      id: serializer.fromJson<String>(json['id']),
      workspaceId: serializer.fromJson<String>(json['workspaceId']),
      nodeId: serializer.fromJson<String>(json['nodeId']),
      journalDate: serializer.fromJson<String>(json['journalDate']),
      mood: serializer.fromJson<String?>(json['mood']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      clientModifiedAt: serializer.fromJson<DateTime>(json['clientModifiedAt']),
      modifiedDeviceId: serializer.fromJson<String>(json['modifiedDeviceId']),
      syncVersion: serializer.fromJson<int>(json['syncVersion']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'workspaceId': serializer.toJson<String>(workspaceId),
      'nodeId': serializer.toJson<String>(nodeId),
      'journalDate': serializer.toJson<String>(journalDate),
      'mood': serializer.toJson<String?>(mood),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'clientModifiedAt': serializer.toJson<DateTime>(clientModifiedAt),
      'modifiedDeviceId': serializer.toJson<String>(modifiedDeviceId),
      'syncVersion': serializer.toJson<int>(syncVersion),
    };
  }

  JournalEntryData copyWith({
    String? id,
    String? workspaceId,
    String? nodeId,
    String? journalDate,
    Value<String?> mood = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    DateTime? clientModifiedAt,
    String? modifiedDeviceId,
    int? syncVersion,
  }) => JournalEntryData(
    id: id ?? this.id,
    workspaceId: workspaceId ?? this.workspaceId,
    nodeId: nodeId ?? this.nodeId,
    journalDate: journalDate ?? this.journalDate,
    mood: mood.present ? mood.value : this.mood,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
    modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
    syncVersion: syncVersion ?? this.syncVersion,
  );
  JournalEntryData copyWithCompanion(JournalEntriesCompanion data) {
    return JournalEntryData(
      id: data.id.present ? data.id.value : this.id,
      workspaceId: data.workspaceId.present
          ? data.workspaceId.value
          : this.workspaceId,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      journalDate: data.journalDate.present
          ? data.journalDate.value
          : this.journalDate,
      mood: data.mood.present ? data.mood.value : this.mood,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      clientModifiedAt: data.clientModifiedAt.present
          ? data.clientModifiedAt.value
          : this.clientModifiedAt,
      modifiedDeviceId: data.modifiedDeviceId.present
          ? data.modifiedDeviceId.value
          : this.modifiedDeviceId,
      syncVersion: data.syncVersion.present
          ? data.syncVersion.value
          : this.syncVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntryData(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('nodeId: $nodeId, ')
          ..write('journalDate: $journalDate, ')
          ..write('mood: $mood, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    nodeId,
    journalDate,
    mood,
    createdAt,
    updatedAt,
    deletedAt,
    clientModifiedAt,
    modifiedDeviceId,
    syncVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is JournalEntryData &&
          other.id == this.id &&
          other.workspaceId == this.workspaceId &&
          other.nodeId == this.nodeId &&
          other.journalDate == this.journalDate &&
          other.mood == this.mood &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.deletedAt == this.deletedAt &&
          other.clientModifiedAt == this.clientModifiedAt &&
          other.modifiedDeviceId == this.modifiedDeviceId &&
          other.syncVersion == this.syncVersion);
}

class JournalEntriesCompanion extends UpdateCompanion<JournalEntryData> {
  final Value<String> id;
  final Value<String> workspaceId;
  final Value<String> nodeId;
  final Value<String> journalDate;
  final Value<String?> mood;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<DateTime?> deletedAt;
  final Value<DateTime> clientModifiedAt;
  final Value<String> modifiedDeviceId;
  final Value<int> syncVersion;
  final Value<int> rowid;
  const JournalEntriesCompanion({
    this.id = const Value.absent(),
    this.workspaceId = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.journalDate = const Value.absent(),
    this.mood = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  JournalEntriesCompanion.insert({
    required String id,
    required String workspaceId,
    required String nodeId,
    required String journalDate,
    this.mood = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.deletedAt = const Value.absent(),
    this.clientModifiedAt = const Value.absent(),
    this.modifiedDeviceId = const Value.absent(),
    this.syncVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       workspaceId = Value(workspaceId),
       nodeId = Value(nodeId),
       journalDate = Value(journalDate),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<JournalEntryData> custom({
    Expression<String>? id,
    Expression<String>? workspaceId,
    Expression<String>? nodeId,
    Expression<String>? journalDate,
    Expression<String>? mood,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<DateTime>? deletedAt,
    Expression<DateTime>? clientModifiedAt,
    Expression<String>? modifiedDeviceId,
    Expression<int>? syncVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (workspaceId != null) 'workspace_id': workspaceId,
      if (nodeId != null) 'node_id': nodeId,
      if (journalDate != null) 'journal_date': journalDate,
      if (mood != null) 'mood': mood,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (clientModifiedAt != null) 'client_modified_at': clientModifiedAt,
      if (modifiedDeviceId != null) 'modified_device_id': modifiedDeviceId,
      if (syncVersion != null) 'sync_version': syncVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  JournalEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? workspaceId,
    Value<String>? nodeId,
    Value<String>? journalDate,
    Value<String?>? mood,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<DateTime?>? deletedAt,
    Value<DateTime>? clientModifiedAt,
    Value<String>? modifiedDeviceId,
    Value<int>? syncVersion,
    Value<int>? rowid,
  }) {
    return JournalEntriesCompanion(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      nodeId: nodeId ?? this.nodeId,
      journalDate: journalDate ?? this.journalDate,
      mood: mood ?? this.mood,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      clientModifiedAt: clientModifiedAt ?? this.clientModifiedAt,
      modifiedDeviceId: modifiedDeviceId ?? this.modifiedDeviceId,
      syncVersion: syncVersion ?? this.syncVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (workspaceId.present) {
      map['workspace_id'] = Variable<String>(workspaceId.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (journalDate.present) {
      map['journal_date'] = Variable<String>(journalDate.value);
    }
    if (mood.present) {
      map['mood'] = Variable<String>(mood.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (clientModifiedAt.present) {
      map['client_modified_at'] = Variable<DateTime>(clientModifiedAt.value);
    }
    if (modifiedDeviceId.present) {
      map['modified_device_id'] = Variable<String>(modifiedDeviceId.value);
    }
    if (syncVersion.present) {
      map['sync_version'] = Variable<int>(syncVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('JournalEntriesCompanion(')
          ..write('id: $id, ')
          ..write('workspaceId: $workspaceId, ')
          ..write('nodeId: $nodeId, ')
          ..write('journalDate: $journalDate, ')
          ..write('mood: $mood, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('clientModifiedAt: $clientModifiedAt, ')
          ..write('modifiedDeviceId: $modifiedDeviceId, ')
          ..write('syncVersion: $syncVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncHistoryTable extends SyncHistory
    with TableInfo<$SyncHistoryTable, SyncHistoryEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _syncStartedAtMeta = const VerificationMeta(
    'syncStartedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncStartedAt =
      GeneratedColumn<DateTime>(
        'sync_started_at',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _syncCompletedAtMeta = const VerificationMeta(
    'syncCompletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> syncCompletedAt =
      GeneratedColumn<DateTime>(
        'sync_completed_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _syncTypeMeta = const VerificationMeta(
    'syncType',
  );
  @override
  late final GeneratedColumn<String> syncType = GeneratedColumn<String>(
    'sync_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordsExportedMeta = const VerificationMeta(
    'recordsExported',
  );
  @override
  late final GeneratedColumn<int> recordsExported = GeneratedColumn<int>(
    'records_exported',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _recordsImportedMeta = const VerificationMeta(
    'recordsImported',
  );
  @override
  late final GeneratedColumn<int> recordsImported = GeneratedColumn<int>(
    'records_imported',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _blobsTransferredMeta = const VerificationMeta(
    'blobsTransferred',
  );
  @override
  late final GeneratedColumn<int> blobsTransferred = GeneratedColumn<int>(
    'blobs_transferred',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    syncStartedAt,
    syncCompletedAt,
    syncType,
    status,
    recordsExported,
    recordsImported,
    blobsTransferred,
    errorMessage,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncHistoryEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sync_started_at')) {
      context.handle(
        _syncStartedAtMeta,
        syncStartedAt.isAcceptableOrUnknown(
          data['sync_started_at']!,
          _syncStartedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_syncStartedAtMeta);
    }
    if (data.containsKey('sync_completed_at')) {
      context.handle(
        _syncCompletedAtMeta,
        syncCompletedAt.isAcceptableOrUnknown(
          data['sync_completed_at']!,
          _syncCompletedAtMeta,
        ),
      );
    }
    if (data.containsKey('sync_type')) {
      context.handle(
        _syncTypeMeta,
        syncType.isAcceptableOrUnknown(data['sync_type']!, _syncTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_syncTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('records_exported')) {
      context.handle(
        _recordsExportedMeta,
        recordsExported.isAcceptableOrUnknown(
          data['records_exported']!,
          _recordsExportedMeta,
        ),
      );
    }
    if (data.containsKey('records_imported')) {
      context.handle(
        _recordsImportedMeta,
        recordsImported.isAcceptableOrUnknown(
          data['records_imported']!,
          _recordsImportedMeta,
        ),
      );
    }
    if (data.containsKey('blobs_transferred')) {
      context.handle(
        _blobsTransferredMeta,
        blobsTransferred.isAcceptableOrUnknown(
          data['blobs_transferred']!,
          _blobsTransferredMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncHistoryEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncHistoryEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      syncStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sync_started_at'],
      )!,
      syncCompletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}sync_completed_at'],
      ),
      syncType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      recordsExported: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}records_exported'],
      )!,
      recordsImported: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}records_imported'],
      )!,
      blobsTransferred: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}blobs_transferred'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
    );
  }

  @override
  $SyncHistoryTable createAlias(String alias) {
    return $SyncHistoryTable(attachedDatabase, alias);
  }
}

class SyncHistoryEntry extends DataClass
    implements Insertable<SyncHistoryEntry> {
  final String id;
  final DateTime syncStartedAt;
  final DateTime? syncCompletedAt;
  final String syncType;
  final String status;
  final int recordsExported;
  final int recordsImported;
  final int blobsTransferred;
  final String? errorMessage;
  const SyncHistoryEntry({
    required this.id,
    required this.syncStartedAt,
    this.syncCompletedAt,
    required this.syncType,
    required this.status,
    required this.recordsExported,
    required this.recordsImported,
    required this.blobsTransferred,
    this.errorMessage,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sync_started_at'] = Variable<DateTime>(syncStartedAt);
    if (!nullToAbsent || syncCompletedAt != null) {
      map['sync_completed_at'] = Variable<DateTime>(syncCompletedAt);
    }
    map['sync_type'] = Variable<String>(syncType);
    map['status'] = Variable<String>(status);
    map['records_exported'] = Variable<int>(recordsExported);
    map['records_imported'] = Variable<int>(recordsImported);
    map['blobs_transferred'] = Variable<int>(blobsTransferred);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    return map;
  }

  SyncHistoryCompanion toCompanion(bool nullToAbsent) {
    return SyncHistoryCompanion(
      id: Value(id),
      syncStartedAt: Value(syncStartedAt),
      syncCompletedAt: syncCompletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(syncCompletedAt),
      syncType: Value(syncType),
      status: Value(status),
      recordsExported: Value(recordsExported),
      recordsImported: Value(recordsImported),
      blobsTransferred: Value(blobsTransferred),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
    );
  }

  factory SyncHistoryEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncHistoryEntry(
      id: serializer.fromJson<String>(json['id']),
      syncStartedAt: serializer.fromJson<DateTime>(json['syncStartedAt']),
      syncCompletedAt: serializer.fromJson<DateTime?>(json['syncCompletedAt']),
      syncType: serializer.fromJson<String>(json['syncType']),
      status: serializer.fromJson<String>(json['status']),
      recordsExported: serializer.fromJson<int>(json['recordsExported']),
      recordsImported: serializer.fromJson<int>(json['recordsImported']),
      blobsTransferred: serializer.fromJson<int>(json['blobsTransferred']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'syncStartedAt': serializer.toJson<DateTime>(syncStartedAt),
      'syncCompletedAt': serializer.toJson<DateTime?>(syncCompletedAt),
      'syncType': serializer.toJson<String>(syncType),
      'status': serializer.toJson<String>(status),
      'recordsExported': serializer.toJson<int>(recordsExported),
      'recordsImported': serializer.toJson<int>(recordsImported),
      'blobsTransferred': serializer.toJson<int>(blobsTransferred),
      'errorMessage': serializer.toJson<String?>(errorMessage),
    };
  }

  SyncHistoryEntry copyWith({
    String? id,
    DateTime? syncStartedAt,
    Value<DateTime?> syncCompletedAt = const Value.absent(),
    String? syncType,
    String? status,
    int? recordsExported,
    int? recordsImported,
    int? blobsTransferred,
    Value<String?> errorMessage = const Value.absent(),
  }) => SyncHistoryEntry(
    id: id ?? this.id,
    syncStartedAt: syncStartedAt ?? this.syncStartedAt,
    syncCompletedAt: syncCompletedAt.present
        ? syncCompletedAt.value
        : this.syncCompletedAt,
    syncType: syncType ?? this.syncType,
    status: status ?? this.status,
    recordsExported: recordsExported ?? this.recordsExported,
    recordsImported: recordsImported ?? this.recordsImported,
    blobsTransferred: blobsTransferred ?? this.blobsTransferred,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
  );
  SyncHistoryEntry copyWithCompanion(SyncHistoryCompanion data) {
    return SyncHistoryEntry(
      id: data.id.present ? data.id.value : this.id,
      syncStartedAt: data.syncStartedAt.present
          ? data.syncStartedAt.value
          : this.syncStartedAt,
      syncCompletedAt: data.syncCompletedAt.present
          ? data.syncCompletedAt.value
          : this.syncCompletedAt,
      syncType: data.syncType.present ? data.syncType.value : this.syncType,
      status: data.status.present ? data.status.value : this.status,
      recordsExported: data.recordsExported.present
          ? data.recordsExported.value
          : this.recordsExported,
      recordsImported: data.recordsImported.present
          ? data.recordsImported.value
          : this.recordsImported,
      blobsTransferred: data.blobsTransferred.present
          ? data.blobsTransferred.value
          : this.blobsTransferred,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncHistoryEntry(')
          ..write('id: $id, ')
          ..write('syncStartedAt: $syncStartedAt, ')
          ..write('syncCompletedAt: $syncCompletedAt, ')
          ..write('syncType: $syncType, ')
          ..write('status: $status, ')
          ..write('recordsExported: $recordsExported, ')
          ..write('recordsImported: $recordsImported, ')
          ..write('blobsTransferred: $blobsTransferred, ')
          ..write('errorMessage: $errorMessage')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    syncStartedAt,
    syncCompletedAt,
    syncType,
    status,
    recordsExported,
    recordsImported,
    blobsTransferred,
    errorMessage,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncHistoryEntry &&
          other.id == this.id &&
          other.syncStartedAt == this.syncStartedAt &&
          other.syncCompletedAt == this.syncCompletedAt &&
          other.syncType == this.syncType &&
          other.status == this.status &&
          other.recordsExported == this.recordsExported &&
          other.recordsImported == this.recordsImported &&
          other.blobsTransferred == this.blobsTransferred &&
          other.errorMessage == this.errorMessage);
}

class SyncHistoryCompanion extends UpdateCompanion<SyncHistoryEntry> {
  final Value<String> id;
  final Value<DateTime> syncStartedAt;
  final Value<DateTime?> syncCompletedAt;
  final Value<String> syncType;
  final Value<String> status;
  final Value<int> recordsExported;
  final Value<int> recordsImported;
  final Value<int> blobsTransferred;
  final Value<String?> errorMessage;
  final Value<int> rowid;
  const SyncHistoryCompanion({
    this.id = const Value.absent(),
    this.syncStartedAt = const Value.absent(),
    this.syncCompletedAt = const Value.absent(),
    this.syncType = const Value.absent(),
    this.status = const Value.absent(),
    this.recordsExported = const Value.absent(),
    this.recordsImported = const Value.absent(),
    this.blobsTransferred = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncHistoryCompanion.insert({
    required String id,
    required DateTime syncStartedAt,
    this.syncCompletedAt = const Value.absent(),
    required String syncType,
    required String status,
    this.recordsExported = const Value.absent(),
    this.recordsImported = const Value.absent(),
    this.blobsTransferred = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       syncStartedAt = Value(syncStartedAt),
       syncType = Value(syncType),
       status = Value(status);
  static Insertable<SyncHistoryEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? syncStartedAt,
    Expression<DateTime>? syncCompletedAt,
    Expression<String>? syncType,
    Expression<String>? status,
    Expression<int>? recordsExported,
    Expression<int>? recordsImported,
    Expression<int>? blobsTransferred,
    Expression<String>? errorMessage,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (syncStartedAt != null) 'sync_started_at': syncStartedAt,
      if (syncCompletedAt != null) 'sync_completed_at': syncCompletedAt,
      if (syncType != null) 'sync_type': syncType,
      if (status != null) 'status': status,
      if (recordsExported != null) 'records_exported': recordsExported,
      if (recordsImported != null) 'records_imported': recordsImported,
      if (blobsTransferred != null) 'blobs_transferred': blobsTransferred,
      if (errorMessage != null) 'error_message': errorMessage,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncHistoryCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? syncStartedAt,
    Value<DateTime?>? syncCompletedAt,
    Value<String>? syncType,
    Value<String>? status,
    Value<int>? recordsExported,
    Value<int>? recordsImported,
    Value<int>? blobsTransferred,
    Value<String?>? errorMessage,
    Value<int>? rowid,
  }) {
    return SyncHistoryCompanion(
      id: id ?? this.id,
      syncStartedAt: syncStartedAt ?? this.syncStartedAt,
      syncCompletedAt: syncCompletedAt ?? this.syncCompletedAt,
      syncType: syncType ?? this.syncType,
      status: status ?? this.status,
      recordsExported: recordsExported ?? this.recordsExported,
      recordsImported: recordsImported ?? this.recordsImported,
      blobsTransferred: blobsTransferred ?? this.blobsTransferred,
      errorMessage: errorMessage ?? this.errorMessage,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (syncStartedAt.present) {
      map['sync_started_at'] = Variable<DateTime>(syncStartedAt.value);
    }
    if (syncCompletedAt.present) {
      map['sync_completed_at'] = Variable<DateTime>(syncCompletedAt.value);
    }
    if (syncType.present) {
      map['sync_type'] = Variable<String>(syncType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (recordsExported.present) {
      map['records_exported'] = Variable<int>(recordsExported.value);
    }
    if (recordsImported.present) {
      map['records_imported'] = Variable<int>(recordsImported.value);
    }
    if (blobsTransferred.present) {
      map['blobs_transferred'] = Variable<int>(blobsTransferred.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncHistoryCompanion(')
          ..write('id: $id, ')
          ..write('syncStartedAt: $syncStartedAt, ')
          ..write('syncCompletedAt: $syncCompletedAt, ')
          ..write('syncType: $syncType, ')
          ..write('status: $status, ')
          ..write('recordsExported: $recordsExported, ')
          ..write('recordsImported: $recordsImported, ')
          ..write('blobsTransferred: $blobsTransferred, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorkspacesTable workspaces = $WorkspacesTable(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final $NodeBlocksTable nodeBlocks = $NodeBlocksTable(this);
  late final $AttachmentsTable attachments = $AttachmentsTable(this);
  late final $InkDocumentsTable inkDocuments = $InkDocumentsTable(this);
  late final $PdfDocumentsTable pdfDocuments = $PdfDocumentsTable(this);
  late final $InkPagesTable inkPages = $InkPagesTable(this);
  late final $NodeLinksTable nodeLinks = $NodeLinksTable(this);
  late final $TagsTable tags = $TagsTable(this);
  late final $NodeTagsTable nodeTags = $NodeTagsTable(this);
  late final $ProjectsTable projects = $ProjectsTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $CalendarEventsTable calendarEvents = $CalendarEventsTable(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $HabitLogsTable habitLogs = $HabitLogsTable(this);
  late final $GoalsTable goals = $GoalsTable(this);
  late final $JournalEntriesTable journalEntries = $JournalEntriesTable(this);
  late final $SyncHistoryTable syncHistory = $SyncHistoryTable(this);
  late final Index idxNodeLinksSource = Index(
    'idx_node_links_source',
    'CREATE INDEX idx_node_links_source ON node_links (source_node_id)',
  );
  late final Index idxNodeLinksTarget = Index(
    'idx_node_links_target',
    'CREATE INDEX idx_node_links_target ON node_links (target_node_id)',
  );
  late final WorkspacesDao workspacesDao = WorkspacesDao(this as AppDatabase);
  late final NodesDao nodesDao = NodesDao(this as AppDatabase);
  late final InkDao inkDao = InkDao(this as AppDatabase);
  late final LinksDao linksDao = LinksDao(this as AppDatabase);
  late final TasksDao tasksDao = TasksDao(this as AppDatabase);
  late final CalendarDao calendarDao = CalendarDao(this as AppDatabase);
  late final HabitsDao habitsDao = HabitsDao(this as AppDatabase);
  late final JournalDao journalDao = JournalDao(this as AppDatabase);
  late final SyncDao syncDao = SyncDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    workspaces,
    nodes,
    nodeBlocks,
    attachments,
    inkDocuments,
    pdfDocuments,
    inkPages,
    nodeLinks,
    tags,
    nodeTags,
    projects,
    tasks,
    calendarEvents,
    habits,
    habitLogs,
    goals,
    journalEntries,
    syncHistory,
    idxNodeLinksSource,
    idxNodeLinksTarget,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('nodes', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('node_blocks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'node_blocks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('node_blocks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ink_documents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('pdf_documents', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'ink_documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ink_pages', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'pdf_documents',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('ink_pages', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('node_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('node_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('node_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tags',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('node_tags', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('projects', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'projects',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('tasks', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('calendar_events', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('calendar_events', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('calendar_events', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habits', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'habits',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('habit_logs', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('goals', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workspaces',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('journal_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'nodes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('journal_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$WorkspacesTableCreateCompanionBuilder = WorkspacesCompanion Function({
  required String id,
  required String name,
  Value<String?> icon,
  Value<String> settingsJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<bool> isDeleted,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$WorkspacesTableUpdateCompanionBuilder = WorkspacesCompanion Function({
  Value<String> id,
  Value<String> name,
  Value<String?> icon,
  Value<String> settingsJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<bool> isDeleted,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$WorkspacesTableReferences
    extends BaseReferences<_$AppDatabase, $WorkspacesTable, WorkspaceEntry> {
  $$WorkspacesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$NodesTable, List<NodeEntry>> _nodesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.nodes,
    aliasName: 'workspaces__id__nodes__workspace_id',
  );

  $$NodesTableProcessedTableManager get nodesRefs {
    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TagsTable, List<TagEntry>> _tagsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tags,
    aliasName: 'workspaces__id__tags__workspace_id',
  );

  $$TagsTableProcessedTableManager get tagsRefs {
    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ProjectsTable, List<ProjectEntry>>
  _projectsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.projects,
    aliasName: 'workspaces__id__projects__workspace_id',
  );

  $$ProjectsTableProcessedTableManager get projectsRefs {
    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_projectsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<TaskEntry>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'workspaces__id__tasks__workspace_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CalendarEventsTable, List<CalendarEventEntry>>
  _calendarEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.calendarEvents,
    aliasName: 'workspaces__id__calendar_events__workspace_id',
  );

  $$CalendarEventsTableProcessedTableManager get calendarEventsRefs {
    final manager = $$CalendarEventsTableTableManager(
      $_db,
      $_db.calendarEvents,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_calendarEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$HabitsTable, List<HabitEntry>> _habitsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.habits,
    aliasName: 'workspaces__id__habits__workspace_id',
  );

  $$HabitsTableProcessedTableManager get habitsRefs {
    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$GoalsTable, List<GoalEntry>> _goalsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.goals,
    aliasName: 'workspaces__id__goals__workspace_id',
  );

  $$GoalsTableProcessedTableManager get goalsRefs {
    final manager = $$GoalsTableTableManager(
      $_db,
      $_db.goals,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_goalsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JournalEntriesTable, List<JournalEntryData>>
  _journalEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.journalEntries,
    aliasName: 'workspaces__id__journal_entries__workspace_id',
  );

  $$JournalEntriesTableProcessedTableManager get journalEntriesRefs {
    final manager = $$JournalEntriesTableTableManager(
      $_db,
      $_db.journalEntries,
    ).filter((f) => f.workspaceId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_journalEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkspacesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> nodesRefs(
    Expression<bool> Function($$NodesTableFilterComposer f) f,
  ) {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tagsRefs(
    Expression<bool> Function($$TagsTableFilterComposer f) f,
  ) {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> projectsRefs(
    Expression<bool> Function($$ProjectsTableFilterComposer f) f,
  ) {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> calendarEventsRefs(
    Expression<bool> Function($$CalendarEventsTableFilterComposer f) f,
  ) {
    final $$CalendarEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableFilterComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> habitsRefs(
    Expression<bool> Function($$HabitsTableFilterComposer f) f,
  ) {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> goalsRefs(
    Expression<bool> Function($$GoalsTableFilterComposer f) f,
  ) {
    final $$GoalsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableFilterComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> journalEntriesRefs(
    Expression<bool> Function($$JournalEntriesTableFilterComposer f) f,
  ) {
    final $$JournalEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journalEntries,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableFilterComposer(
            $db: $db,
            $table: $db.journalEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspacesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkspacesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkspacesTable> {
  $$WorkspacesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get settingsJson => $composableBuilder(
    column: $table.settingsJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  Expression<T> nodesRefs<T extends Object>(
    Expression<T> Function($$NodesTableAnnotationComposer a) f,
  ) {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tagsRefs<T extends Object>(
    Expression<T> Function($$TagsTableAnnotationComposer a) f,
  ) {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> projectsRefs<T extends Object>(
    Expression<T> Function($$ProjectsTableAnnotationComposer a) f,
  ) {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> calendarEventsRefs<T extends Object>(
    Expression<T> Function($$CalendarEventsTableAnnotationComposer a) f,
  ) {
    final $$CalendarEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> habitsRefs<T extends Object>(
    Expression<T> Function($$HabitsTableAnnotationComposer a) f,
  ) {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> goalsRefs<T extends Object>(
    Expression<T> Function($$GoalsTableAnnotationComposer a) f,
  ) {
    final $$GoalsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.goals,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$GoalsTableAnnotationComposer(
            $db: $db,
            $table: $db.goals,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> journalEntriesRefs<T extends Object>(
    Expression<T> Function($$JournalEntriesTableAnnotationComposer a) f,
  ) {
    final $$JournalEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journalEntries,
      getReferencedColumn: (t) => t.workspaceId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.journalEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkspacesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkspacesTable,
          WorkspaceEntry,
          $$WorkspacesTableFilterComposer,
          $$WorkspacesTableOrderingComposer,
          $$WorkspacesTableAnnotationComposer,
          $$WorkspacesTableCreateCompanionBuilder,
          $$WorkspacesTableUpdateCompanionBuilder,
          (WorkspaceEntry, $$WorkspacesTableReferences),
          WorkspaceEntry,
          PrefetchHooks Function({
            bool nodesRefs,
            bool tagsRefs,
            bool projectsRefs,
            bool tasksRefs,
            bool calendarEventsRefs,
            bool habitsRefs,
            bool goalsRefs,
            bool journalEntriesRefs,
          })
        > {
  $$WorkspacesTableTableManager(_$AppDatabase db, $WorkspacesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkspacesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkspacesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkspacesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String> settingsJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion(
                id: id,
                name: name,
                icon: icon,
                settingsJson: settingsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> icon = const Value.absent(),
                Value<String> settingsJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<bool> isDeleted = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkspacesCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                settingsJson: settingsJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                isDeleted: isDeleted,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkspacesTable, WorkspaceEntry>(table),
                  $$WorkspacesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                nodesRefs = false,
                tagsRefs = false,
                projectsRefs = false,
                tasksRefs = false,
                calendarEventsRefs = false,
                habitsRefs = false,
                goalsRefs = false,
                journalEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (nodesRefs) db.nodes,
                    if (tagsRefs) db.tags,
                    if (projectsRefs) db.projects,
                    if (tasksRefs) db.tasks,
                    if (calendarEventsRefs) db.calendarEvents,
                    if (habitsRefs) db.habits,
                    if (goalsRefs) db.goals,
                    if (journalEntriesRefs) db.journalEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (nodesRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkspaceEntry,
                          $WorkspacesTable,
                          NodeEntry,
                          $NodesTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._nodesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).nodesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'workspace_id',
                          typedResults: items,
                        ),
                      if (tagsRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkspaceEntry,
                          $WorkspacesTable,
                          TagEntry,
                          $TagsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._tagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).tagsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'workspace_id',
                          typedResults: items,
                        ),
                      if (projectsRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkspaceEntry,
                          $WorkspacesTable,
                          ProjectEntry,
                          $ProjectsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._projectsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).projectsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'workspace_id',
                          typedResults: items,
                        ),
                      if (tasksRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkspaceEntry,
                          $WorkspacesTable,
                          TaskEntry,
                          $TasksTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).tasksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'workspace_id',
                          typedResults: items,
                        ),
                      if (calendarEventsRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkspaceEntry,
                          $WorkspacesTable,
                          CalendarEventEntry,
                          $CalendarEventsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._calendarEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).calendarEventsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'workspace_id',
                          typedResults: items,
                        ),
                      if (habitsRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkspaceEntry,
                          $WorkspacesTable,
                          HabitEntry,
                          $HabitsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._habitsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).habitsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'workspace_id',
                          typedResults: items,
                        ),
                      if (goalsRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkspaceEntry,
                          $WorkspacesTable,
                          GoalEntry,
                          $GoalsTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._goalsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).goalsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'workspace_id',
                          typedResults: items,
                        ),
                      if (journalEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          WorkspaceEntry,
                          $WorkspacesTable,
                          JournalEntryData,
                          $JournalEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$WorkspacesTableReferences
                              ._journalEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorkspacesTableReferences(
                                db,
                                table,
                                p0,
                              ).journalEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'workspace_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorkspacesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkspacesTable,
      WorkspaceEntry,
      $$WorkspacesTableFilterComposer,
      $$WorkspacesTableOrderingComposer,
      $$WorkspacesTableAnnotationComposer,
      $$WorkspacesTableCreateCompanionBuilder,
      $$WorkspacesTableUpdateCompanionBuilder,
      (WorkspaceEntry, $$WorkspacesTableReferences),
      WorkspaceEntry,
      PrefetchHooks Function({
        bool nodesRefs,
        bool tagsRefs,
        bool projectsRefs,
        bool tasksRefs,
        bool calendarEventsRefs,
        bool habitsRefs,
        bool goalsRefs,
        bool journalEntriesRefs,
      })
    >;
typedef $$NodesTableCreateCompanionBuilder = NodesCompanion Function({
  required String id,
  required String workspaceId,
  Value<String?> parentId,
  required String type,
  required String title,
  Value<String?> icon,
  Value<String?> coverImageHash,
  Value<String?> contentHash,
  Value<double> sortOrder,
  Value<bool> isFavorite,
  Value<bool> isPinned,
  Value<bool> isArchived,
  Value<bool> isDeleted,
  Value<String> metadataJson,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$NodesTableUpdateCompanionBuilder = NodesCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String?> parentId,
  Value<String> type,
  Value<String> title,
  Value<String?> icon,
  Value<String?> coverImageHash,
  Value<String?> contentHash,
  Value<double> sortOrder,
  Value<bool> isFavorite,
  Value<bool> isPinned,
  Value<bool> isArchived,
  Value<bool> isDeleted,
  Value<String> metadataJson,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$NodesTableReferences
    extends BaseReferences<_$AppDatabase, $NodesTable, NodeEntry> {
  $$NodesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('nodes__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NodesTable _parentIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('nodes__parent_id__nodes__id');

  $$NodesTableProcessedTableManager? get parentId {
    final $_column = $_itemColumn<String>('parent_id');
    if ($_column == null) return null;
    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$NodeBlocksTable, List<NodeBlockEntry>>
  _nodeBlocksRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nodeBlocks,
    aliasName: 'nodes__id__node_blocks__node_id',
  );

  $$NodeBlocksTableProcessedTableManager get nodeBlocksRefs {
    final manager = $$NodeBlocksTableTableManager(
      $_db,
      $_db.nodeBlocks,
    ).filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodeBlocksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$InkDocumentsTable, List<InkDocumentEntry>>
  _inkDocumentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inkDocuments,
    aliasName: 'nodes__id__ink_documents__node_id',
  );

  $$InkDocumentsTableProcessedTableManager get inkDocumentsRefs {
    final manager = $$InkDocumentsTableTableManager(
      $_db,
      $_db.inkDocuments,
    ).filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inkDocumentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$PdfDocumentsTable, List<PdfDocumentEntry>>
  _pdfDocumentsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.pdfDocuments,
    aliasName: 'nodes__id__pdf_documents__node_id',
  );

  $$PdfDocumentsTableProcessedTableManager get pdfDocumentsRefs {
    final manager = $$PdfDocumentsTableTableManager(
      $_db,
      $_db.pdfDocuments,
    ).filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_pdfDocumentsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NodeLinksTable, List<NodeLinkEntry>>
  _outgoingLinksTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nodeLinks,
    aliasName: 'nodes__id__node_links__source_node_id',
  );

  $$NodeLinksTableProcessedTableManager get outgoingLinks {
    final manager = $$NodeLinksTableTableManager(
      $_db,
      $_db.nodeLinks,
    ).filter((f) => f.sourceNodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_outgoingLinksTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NodeLinksTable, List<NodeLinkEntry>>
  _incomingLinksTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nodeLinks,
    aliasName: 'nodes__id__node_links__target_node_id',
  );

  $$NodeLinksTableProcessedTableManager get incomingLinks {
    final manager = $$NodeLinksTableTableManager(
      $_db,
      $_db.nodeLinks,
    ).filter((f) => f.targetNodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_incomingLinksTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$NodeTagsTable, List<NodeTagEntry>>
  _nodeTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nodeTags,
    aliasName: 'nodes__id__node_tags__node_id',
  );

  $$NodeTagsTableProcessedTableManager get nodeTagsRefs {
    final manager = $$NodeTagsTableTableManager(
      $_db,
      $_db.nodeTags,
    ).filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodeTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<TaskEntry>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'nodes__id__tasks__node_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$CalendarEventsTable, List<CalendarEventEntry>>
  _calendarEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.calendarEvents,
    aliasName: 'nodes__id__calendar_events__node_id',
  );

  $$CalendarEventsTableProcessedTableManager get calendarEventsRefs {
    final manager = $$CalendarEventsTableTableManager(
      $_db,
      $_db.calendarEvents,
    ).filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_calendarEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$JournalEntriesTable, List<JournalEntryData>>
  _journalEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.journalEntries,
    aliasName: 'nodes__id__journal_entries__node_id',
  );

  $$JournalEntriesTableProcessedTableManager get journalEntriesRefs {
    final manager = $$JournalEntriesTableTableManager(
      $_db,
      $_db.journalEntries,
    ).filter((f) => f.nodeId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_journalEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$NodesTableFilterComposer extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get coverImageHash => $composableBuilder(
    column: $table.coverImageHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableFilterComposer get parentId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> nodeBlocksRefs(
    Expression<bool> Function($$NodeBlocksTableFilterComposer f) f,
  ) {
    final $$NodeBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeBlocks,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeBlocksTableFilterComposer(
            $db: $db,
            $table: $db.nodeBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> inkDocumentsRefs(
    Expression<bool> Function($$InkDocumentsTableFilterComposer f) f,
  ) {
    final $$InkDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inkDocuments,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.inkDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> pdfDocumentsRefs(
    Expression<bool> Function($$PdfDocumentsTableFilterComposer f) f,
  ) {
    final $$PdfDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pdfDocuments,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PdfDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.pdfDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> outgoingLinks(
    Expression<bool> Function($$NodeLinksTableFilterComposer f) f,
  ) {
    final $$NodeLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeLinks,
      getReferencedColumn: (t) => t.sourceNodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeLinksTableFilterComposer(
            $db: $db,
            $table: $db.nodeLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> incomingLinks(
    Expression<bool> Function($$NodeLinksTableFilterComposer f) f,
  ) {
    final $$NodeLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeLinks,
      getReferencedColumn: (t) => t.targetNodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeLinksTableFilterComposer(
            $db: $db,
            $table: $db.nodeLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> nodeTagsRefs(
    Expression<bool> Function($$NodeTagsTableFilterComposer f) f,
  ) {
    final $$NodeTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeTags,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTagsTableFilterComposer(
            $db: $db,
            $table: $db.nodeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> calendarEventsRefs(
    Expression<bool> Function($$CalendarEventsTableFilterComposer f) f,
  ) {
    final $$CalendarEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableFilterComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> journalEntriesRefs(
    Expression<bool> Function($$JournalEntriesTableFilterComposer f) f,
  ) {
    final $$JournalEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journalEntries,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableFilterComposer(
            $db: $db,
            $table: $db.journalEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NodesTableOrderingComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get coverImageHash => $composableBuilder(
    column: $table.coverImageHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isPinned => $composableBuilder(
    column: $table.isPinned,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableOrderingComposer get parentId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodesTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodesTable> {
  $$NodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get coverImageHash => $composableBuilder(
    column: $table.coverImageHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isFavorite => $composableBuilder(
    column: $table.isFavorite,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isPinned =>
      $composableBuilder(column: $table.isPinned, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get metadataJson => $composableBuilder(
    column: $table.metadataJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableAnnotationComposer get parentId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> nodeBlocksRefs<T extends Object>(
    Expression<T> Function($$NodeBlocksTableAnnotationComposer a) f,
  ) {
    final $$NodeBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeBlocks,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> inkDocumentsRefs<T extends Object>(
    Expression<T> Function($$InkDocumentsTableAnnotationComposer a) f,
  ) {
    final $$InkDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inkDocuments,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.inkDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> pdfDocumentsRefs<T extends Object>(
    Expression<T> Function($$PdfDocumentsTableAnnotationComposer a) f,
  ) {
    final $$PdfDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.pdfDocuments,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PdfDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.pdfDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> outgoingLinks<T extends Object>(
    Expression<T> Function($$NodeLinksTableAnnotationComposer a) f,
  ) {
    final $$NodeLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeLinks,
      getReferencedColumn: (t) => t.sourceNodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> incomingLinks<T extends Object>(
    Expression<T> Function($$NodeLinksTableAnnotationComposer a) f,
  ) {
    final $$NodeLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeLinks,
      getReferencedColumn: (t) => t.targetNodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> nodeTagsRefs<T extends Object>(
    Expression<T> Function($$NodeTagsTableAnnotationComposer a) f,
  ) {
    final $$NodeTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeTags,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> calendarEventsRefs<T extends Object>(
    Expression<T> Function($$CalendarEventsTableAnnotationComposer a) f,
  ) {
    final $$CalendarEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> journalEntriesRefs<T extends Object>(
    Expression<T> Function($$JournalEntriesTableAnnotationComposer a) f,
  ) {
    final $$JournalEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.journalEntries,
      getReferencedColumn: (t) => t.nodeId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$JournalEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.journalEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$NodesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodesTable,
          NodeEntry,
          $$NodesTableFilterComposer,
          $$NodesTableOrderingComposer,
          $$NodesTableAnnotationComposer,
          $$NodesTableCreateCompanionBuilder,
          $$NodesTableUpdateCompanionBuilder,
          (NodeEntry, $$NodesTableReferences),
          NodeEntry,
          PrefetchHooks Function({
            bool workspaceId,
            bool parentId,
            bool nodeBlocksRefs,
            bool inkDocumentsRefs,
            bool pdfDocumentsRefs,
            bool outgoingLinks,
            bool incomingLinks,
            bool nodeTagsRefs,
            bool tasksRefs,
            bool calendarEventsRefs,
            bool journalEntriesRefs,
          })
        > {
  $$NodesTableTableManager(_$AppDatabase db, $NodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String?> coverImageHash = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<double> sortOrder = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion(
                id: id,
                workspaceId: workspaceId,
                parentId: parentId,
                type: type,
                title: title,
                icon: icon,
                coverImageHash: coverImageHash,
                contentHash: contentHash,
                sortOrder: sortOrder,
                isFavorite: isFavorite,
                isPinned: isPinned,
                isArchived: isArchived,
                isDeleted: isDeleted,
                metadataJson: metadataJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                Value<String?> parentId = const Value.absent(),
                required String type,
                required String title,
                Value<String?> icon = const Value.absent(),
                Value<String?> coverImageHash = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<double> sortOrder = const Value.absent(),
                Value<bool> isFavorite = const Value.absent(),
                Value<bool> isPinned = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> metadataJson = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                parentId: parentId,
                type: type,
                title: title,
                icon: icon,
                coverImageHash: coverImageHash,
                contentHash: contentHash,
                sortOrder: sortOrder,
                isFavorite: isFavorite,
                isPinned: isPinned,
                isArchived: isArchived,
                isDeleted: isDeleted,
                metadataJson: metadataJson,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodesTable, NodeEntry>(table),
                  $$NodesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspaceId = false,
                parentId = false,
                nodeBlocksRefs = false,
                inkDocumentsRefs = false,
                pdfDocumentsRefs = false,
                outgoingLinks = false,
                incomingLinks = false,
                nodeTagsRefs = false,
                tasksRefs = false,
                calendarEventsRefs = false,
                journalEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (nodeBlocksRefs) db.nodeBlocks,
                    if (inkDocumentsRefs) db.inkDocuments,
                    if (pdfDocumentsRefs) db.pdfDocuments,
                    if (outgoingLinks) db.nodeLinks,
                    if (incomingLinks) db.nodeLinks,
                    if (nodeTagsRefs) db.nodeTags,
                    if (tasksRefs) db.tasks,
                    if (calendarEventsRefs) db.calendarEvents,
                    if (journalEntriesRefs) db.journalEntries,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.workspaceId,
                            referencedTable: $$NodesTableReferences
                                ._workspaceIdTable(db),
                            referencedColumn: $$NodesTableReferences
                                ._workspaceIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (parentId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentId,
                            referencedTable: $$NodesTableReferences
                                ._parentIdTable(db),
                            referencedColumn: $$NodesTableReferences
                                ._parentIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (nodeBlocksRefs)
                        await $_getPrefetchedDataByColumns<
                          NodeEntry,
                          $NodesTable,
                          NodeBlockEntry,
                          $NodeBlocksTable
                        >(
                          currentTable: table,
                          referencedTable: $$NodesTableReferences
                              ._nodeBlocksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NodesTableReferences(
                                db,
                                table,
                                p0,
                              ).nodeBlocksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'node_id',
                          typedResults: items,
                        ),
                      if (inkDocumentsRefs)
                        await $_getPrefetchedDataByColumns<
                          NodeEntry,
                          $NodesTable,
                          InkDocumentEntry,
                          $InkDocumentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$NodesTableReferences
                              ._inkDocumentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NodesTableReferences(
                                db,
                                table,
                                p0,
                              ).inkDocumentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'node_id',
                          typedResults: items,
                        ),
                      if (pdfDocumentsRefs)
                        await $_getPrefetchedDataByColumns<
                          NodeEntry,
                          $NodesTable,
                          PdfDocumentEntry,
                          $PdfDocumentsTable
                        >(
                          currentTable: table,
                          referencedTable: $$NodesTableReferences
                              ._pdfDocumentsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NodesTableReferences(
                                db,
                                table,
                                p0,
                              ).pdfDocumentsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'node_id',
                          typedResults: items,
                        ),
                      if (outgoingLinks)
                        await $_getPrefetchedDataByColumns<
                          NodeEntry,
                          $NodesTable,
                          NodeLinkEntry,
                          $NodeLinksTable
                        >(
                          currentTable: table,
                          referencedTable: $$NodesTableReferences
                              ._outgoingLinksTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NodesTableReferences(
                                db,
                                table,
                                p0,
                              ).outgoingLinks,
                          currentColumn: 'id',
                          referencedColumn: 'source_node_id',
                          typedResults: items,
                        ),
                      if (incomingLinks)
                        await $_getPrefetchedDataByColumns<
                          NodeEntry,
                          $NodesTable,
                          NodeLinkEntry,
                          $NodeLinksTable
                        >(
                          currentTable: table,
                          referencedTable: $$NodesTableReferences
                              ._incomingLinksTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NodesTableReferences(
                                db,
                                table,
                                p0,
                              ).incomingLinks,
                          currentColumn: 'id',
                          referencedColumn: 'target_node_id',
                          typedResults: items,
                        ),
                      if (nodeTagsRefs)
                        await $_getPrefetchedDataByColumns<
                          NodeEntry,
                          $NodesTable,
                          NodeTagEntry,
                          $NodeTagsTable
                        >(
                          currentTable: table,
                          referencedTable: $$NodesTableReferences
                              ._nodeTagsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NodesTableReferences(
                                db,
                                table,
                                p0,
                              ).nodeTagsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'node_id',
                          typedResults: items,
                        ),
                      if (tasksRefs)
                        await $_getPrefetchedDataByColumns<
                          NodeEntry,
                          $NodesTable,
                          TaskEntry,
                          $TasksTable
                        >(
                          currentTable: table,
                          referencedTable: $$NodesTableReferences
                              ._tasksRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NodesTableReferences(db, table, p0).tasksRefs,
                          currentColumn: 'id',
                          referencedColumn: 'node_id',
                          typedResults: items,
                        ),
                      if (calendarEventsRefs)
                        await $_getPrefetchedDataByColumns<
                          NodeEntry,
                          $NodesTable,
                          CalendarEventEntry,
                          $CalendarEventsTable
                        >(
                          currentTable: table,
                          referencedTable: $$NodesTableReferences
                              ._calendarEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NodesTableReferences(
                                db,
                                table,
                                p0,
                              ).calendarEventsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'node_id',
                          typedResults: items,
                        ),
                      if (journalEntriesRefs)
                        await $_getPrefetchedDataByColumns<
                          NodeEntry,
                          $NodesTable,
                          JournalEntryData,
                          $JournalEntriesTable
                        >(
                          currentTable: table,
                          referencedTable: $$NodesTableReferences
                              ._journalEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$NodesTableReferences(
                                db,
                                table,
                                p0,
                              ).journalEntriesRefs,
                          currentColumn: 'id',
                          referencedColumn: 'node_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$NodesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodesTable,
      NodeEntry,
      $$NodesTableFilterComposer,
      $$NodesTableOrderingComposer,
      $$NodesTableAnnotationComposer,
      $$NodesTableCreateCompanionBuilder,
      $$NodesTableUpdateCompanionBuilder,
      (NodeEntry, $$NodesTableReferences),
      NodeEntry,
      PrefetchHooks Function({
        bool workspaceId,
        bool parentId,
        bool nodeBlocksRefs,
        bool inkDocumentsRefs,
        bool pdfDocumentsRefs,
        bool outgoingLinks,
        bool incomingLinks,
        bool nodeTagsRefs,
        bool tasksRefs,
        bool calendarEventsRefs,
        bool journalEntriesRefs,
      })
    >;
typedef $$NodeBlocksTableCreateCompanionBuilder = NodeBlocksCompanion Function({
  required String id,
  required String nodeId,
  Value<String?> parentBlockId,
  required String type,
  Value<String> contentJson,
  Value<double> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<int> rowid,
});
typedef $$NodeBlocksTableUpdateCompanionBuilder = NodeBlocksCompanion Function({
  Value<String> id,
  Value<String> nodeId,
  Value<String?> parentBlockId,
  Value<String> type,
  Value<String> contentJson,
  Value<double> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<int> rowid,
});

final class $$NodeBlocksTableReferences
    extends BaseReferences<_$AppDatabase, $NodeBlocksTable, NodeBlockEntry> {
  $$NodeBlocksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NodesTable _nodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('node_blocks__node_id__nodes__id');

  $$NodesTableProcessedTableManager get nodeId {
    final $_column = $_itemColumn<String>('node_id')!;

    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NodeBlocksTable _parentBlockIdTable(_$AppDatabase db) => db.nodeBlocks
      .createAlias('node_blocks__parent_block_id__node_blocks__id');

  $$NodeBlocksTableProcessedTableManager? get parentBlockId {
    final $_column = $_itemColumn<String>('parent_block_id');
    if ($_column == null) return null;
    final manager = $$NodeBlocksTableTableManager(
      $_db,
      $_db.nodeBlocks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentBlockIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NodeBlocksTableFilterComposer
    extends Composer<_$AppDatabase, $NodeBlocksTable> {
  $$NodeBlocksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NodesTableFilterComposer get nodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodeBlocksTableFilterComposer get parentBlockId {
    final $$NodeBlocksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentBlockId,
      referencedTable: $db.nodeBlocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeBlocksTableFilterComposer(
            $db: $db,
            $table: $db.nodeBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeBlocksTableOrderingComposer
    extends Composer<_$AppDatabase, $NodeBlocksTable> {
  $$NodeBlocksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NodesTableOrderingComposer get nodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodeBlocksTableOrderingComposer get parentBlockId {
    final $$NodeBlocksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentBlockId,
      referencedTable: $db.nodeBlocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeBlocksTableOrderingComposer(
            $db: $db,
            $table: $db.nodeBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeBlocksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodeBlocksTable> {
  $$NodeBlocksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get contentJson => $composableBuilder(
    column: $table.contentJson,
    builder: (column) => column,
  );

  GeneratedColumn<double> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$NodesTableAnnotationComposer get nodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodeBlocksTableAnnotationComposer get parentBlockId {
    final $$NodeBlocksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentBlockId,
      referencedTable: $db.nodeBlocks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeBlocksTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeBlocks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeBlocksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodeBlocksTable,
          NodeBlockEntry,
          $$NodeBlocksTableFilterComposer,
          $$NodeBlocksTableOrderingComposer,
          $$NodeBlocksTableAnnotationComposer,
          $$NodeBlocksTableCreateCompanionBuilder,
          $$NodeBlocksTableUpdateCompanionBuilder,
          (NodeBlockEntry, $$NodeBlocksTableReferences),
          NodeBlockEntry,
          PrefetchHooks Function({bool nodeId, bool parentBlockId})
        > {
  $$NodeBlocksTableTableManager(_$AppDatabase db, $NodeBlocksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeBlocksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodeBlocksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodeBlocksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String?> parentBlockId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> contentJson = const Value.absent(),
                Value<double> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeBlocksCompanion(
                id: id,
                nodeId: nodeId,
                parentBlockId: parentBlockId,
                type: type,
                contentJson: contentJson,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nodeId,
                Value<String?> parentBlockId = const Value.absent(),
                required String type,
                Value<String> contentJson = const Value.absent(),
                Value<double> sortOrder = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => NodeBlocksCompanion.insert(
                id: id,
                nodeId: nodeId,
                parentBlockId: parentBlockId,
                type: type,
                contentJson: contentJson,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodeBlocksTable, NodeBlockEntry>(table),
                  $$NodeBlocksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({nodeId = false, parentBlockId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (nodeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.nodeId,
                        referencedTable: $$NodeBlocksTableReferences
                            ._nodeIdTable(db),
                        referencedColumn: $$NodeBlocksTableReferences
                            ._nodeIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (parentBlockId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.parentBlockId,
                        referencedTable: $$NodeBlocksTableReferences
                            ._parentBlockIdTable(db),
                        referencedColumn: $$NodeBlocksTableReferences
                            ._parentBlockIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NodeBlocksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodeBlocksTable,
      NodeBlockEntry,
      $$NodeBlocksTableFilterComposer,
      $$NodeBlocksTableOrderingComposer,
      $$NodeBlocksTableAnnotationComposer,
      $$NodeBlocksTableCreateCompanionBuilder,
      $$NodeBlocksTableUpdateCompanionBuilder,
      (NodeBlockEntry, $$NodeBlocksTableReferences),
      NodeBlockEntry,
      PrefetchHooks Function({bool nodeId, bool parentBlockId})
    >;
typedef $$AttachmentsTableCreateCompanionBuilder =
    AttachmentsCompanion Function({
      required String sha256Hash,
      required String relativePath,
      required String fileName,
      required String mimeType,
      required int byteSize,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$AttachmentsTableUpdateCompanionBuilder =
    AttachmentsCompanion Function({
      Value<String> sha256Hash,
      Value<String> relativePath,
      Value<String> fileName,
      Value<String> mimeType,
      Value<int> byteSize,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AttachmentsTableFilterComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttachmentsTableOrderingComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get byteSize => $composableBuilder(
    column: $table.byteSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttachmentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AttachmentsTable> {
  $$AttachmentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sha256Hash => $composableBuilder(
    column: $table.sha256Hash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get relativePath => $composableBuilder(
    column: $table.relativePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get byteSize =>
      $composableBuilder(column: $table.byteSize, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AttachmentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AttachmentsTable,
          AttachmentEntry,
          $$AttachmentsTableFilterComposer,
          $$AttachmentsTableOrderingComposer,
          $$AttachmentsTableAnnotationComposer,
          $$AttachmentsTableCreateCompanionBuilder,
          $$AttachmentsTableUpdateCompanionBuilder,
          (
            AttachmentEntry,
            BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentEntry>,
          ),
          AttachmentEntry,
          PrefetchHooks Function()
        > {
  $$AttachmentsTableTableManager(_$AppDatabase db, $AttachmentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttachmentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttachmentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttachmentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> sha256Hash = const Value.absent(),
                Value<String> relativePath = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int> byteSize = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion(
                sha256Hash: sha256Hash,
                relativePath: relativePath,
                fileName: fileName,
                mimeType: mimeType,
                byteSize: byteSize,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String sha256Hash,
                required String relativePath,
                required String fileName,
                required String mimeType,
                required int byteSize,
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => AttachmentsCompanion.insert(
                sha256Hash: sha256Hash,
                relativePath: relativePath,
                fileName: fileName,
                mimeType: mimeType,
                byteSize: byteSize,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttachmentsTable, AttachmentEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $AttachmentsTable,
                    AttachmentEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AttachmentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AttachmentsTable,
      AttachmentEntry,
      $$AttachmentsTableFilterComposer,
      $$AttachmentsTableOrderingComposer,
      $$AttachmentsTableAnnotationComposer,
      $$AttachmentsTableCreateCompanionBuilder,
      $$AttachmentsTableUpdateCompanionBuilder,
      (
        AttachmentEntry,
        BaseReferences<_$AppDatabase, $AttachmentsTable, AttachmentEntry>,
      ),
      AttachmentEntry,
      PrefetchHooks Function()
    >;
typedef $$InkDocumentsTableCreateCompanionBuilder =
    InkDocumentsCompanion Function({
      required String id,
      required String nodeId,
      Value<double> defaultPageWidth,
      Value<double> defaultPageHeight,
      Value<String> defaultTemplate,
      Value<int> defaultBackgroundColor,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$InkDocumentsTableUpdateCompanionBuilder =
    InkDocumentsCompanion Function({
      Value<String> id,
      Value<String> nodeId,
      Value<double> defaultPageWidth,
      Value<double> defaultPageHeight,
      Value<String> defaultTemplate,
      Value<int> defaultBackgroundColor,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$InkDocumentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $InkDocumentsTable, InkDocumentEntry> {
  $$InkDocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NodesTable _nodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('ink_documents__node_id__nodes__id');

  $$NodesTableProcessedTableManager get nodeId {
    final $_column = $_itemColumn<String>('node_id')!;

    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InkPagesTable, List<InkPageEntry>>
  _inkPagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inkPages,
    aliasName: 'ink_documents__id__ink_pages__document_id',
  );

  $$InkPagesTableProcessedTableManager get inkPagesRefs {
    final manager = $$InkPagesTableTableManager(
      $_db,
      $_db.inkPages,
    ).filter((f) => f.documentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inkPagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$InkDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $InkDocumentsTable> {
  $$InkDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultPageWidth => $composableBuilder(
    column: $table.defaultPageWidth,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get defaultPageHeight => $composableBuilder(
    column: $table.defaultPageHeight,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultTemplate => $composableBuilder(
    column: $table.defaultTemplate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultBackgroundColor => $composableBuilder(
    column: $table.defaultBackgroundColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$NodesTableFilterComposer get nodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> inkPagesRefs(
    Expression<bool> Function($$InkPagesTableFilterComposer f) f,
  ) {
    final $$InkPagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inkPages,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkPagesTableFilterComposer(
            $db: $db,
            $table: $db.inkPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InkDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $InkDocumentsTable> {
  $$InkDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultPageWidth => $composableBuilder(
    column: $table.defaultPageWidth,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get defaultPageHeight => $composableBuilder(
    column: $table.defaultPageHeight,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultTemplate => $composableBuilder(
    column: $table.defaultTemplate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultBackgroundColor => $composableBuilder(
    column: $table.defaultBackgroundColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$NodesTableOrderingComposer get nodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InkDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $InkDocumentsTable> {
  $$InkDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<double> get defaultPageWidth => $composableBuilder(
    column: $table.defaultPageWidth,
    builder: (column) => column,
  );

  GeneratedColumn<double> get defaultPageHeight => $composableBuilder(
    column: $table.defaultPageHeight,
    builder: (column) => column,
  );

  GeneratedColumn<String> get defaultTemplate => $composableBuilder(
    column: $table.defaultTemplate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultBackgroundColor => $composableBuilder(
    column: $table.defaultBackgroundColor,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$NodesTableAnnotationComposer get nodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> inkPagesRefs<T extends Object>(
    Expression<T> Function($$InkPagesTableAnnotationComposer a) f,
  ) {
    final $$InkPagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inkPages,
      getReferencedColumn: (t) => t.documentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkPagesTableAnnotationComposer(
            $db: $db,
            $table: $db.inkPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$InkDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InkDocumentsTable,
          InkDocumentEntry,
          $$InkDocumentsTableFilterComposer,
          $$InkDocumentsTableOrderingComposer,
          $$InkDocumentsTableAnnotationComposer,
          $$InkDocumentsTableCreateCompanionBuilder,
          $$InkDocumentsTableUpdateCompanionBuilder,
          (InkDocumentEntry, $$InkDocumentsTableReferences),
          InkDocumentEntry,
          PrefetchHooks Function({bool nodeId, bool inkPagesRefs})
        > {
  $$InkDocumentsTableTableManager(_$AppDatabase db, $InkDocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InkDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InkDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InkDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<double> defaultPageWidth = const Value.absent(),
                Value<double> defaultPageHeight = const Value.absent(),
                Value<String> defaultTemplate = const Value.absent(),
                Value<int> defaultBackgroundColor = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InkDocumentsCompanion(
                id: id,
                nodeId: nodeId,
                defaultPageWidth: defaultPageWidth,
                defaultPageHeight: defaultPageHeight,
                defaultTemplate: defaultTemplate,
                defaultBackgroundColor: defaultBackgroundColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nodeId,
                Value<double> defaultPageWidth = const Value.absent(),
                Value<double> defaultPageHeight = const Value.absent(),
                Value<String> defaultTemplate = const Value.absent(),
                Value<int> defaultBackgroundColor = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => InkDocumentsCompanion.insert(
                id: id,
                nodeId: nodeId,
                defaultPageWidth: defaultPageWidth,
                defaultPageHeight: defaultPageHeight,
                defaultTemplate: defaultTemplate,
                defaultBackgroundColor: defaultBackgroundColor,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InkDocumentsTable, InkDocumentEntry>(table),
                  $$InkDocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({nodeId = false, inkPagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (inkPagesRefs) db.inkPages],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (nodeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.nodeId,
                        referencedTable: $$InkDocumentsTableReferences
                            ._nodeIdTable(db),
                        referencedColumn: $$InkDocumentsTableReferences
                            ._nodeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (inkPagesRefs)
                    await $_getPrefetchedDataByColumns<
                      InkDocumentEntry,
                      $InkDocumentsTable,
                      InkPageEntry,
                      $InkPagesTable
                    >(
                      currentTable: table,
                      referencedTable: $$InkDocumentsTableReferences
                          ._inkPagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$InkDocumentsTableReferences(
                            db,
                            table,
                            p0,
                          ).inkPagesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'document_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$InkDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InkDocumentsTable,
      InkDocumentEntry,
      $$InkDocumentsTableFilterComposer,
      $$InkDocumentsTableOrderingComposer,
      $$InkDocumentsTableAnnotationComposer,
      $$InkDocumentsTableCreateCompanionBuilder,
      $$InkDocumentsTableUpdateCompanionBuilder,
      (InkDocumentEntry, $$InkDocumentsTableReferences),
      InkDocumentEntry,
      PrefetchHooks Function({bool nodeId, bool inkPagesRefs})
    >;
typedef $$PdfDocumentsTableCreateCompanionBuilder =
    PdfDocumentsCompanion Function({
      required String id,
      required String nodeId,
      required String casHash,
      required String fileName,
      required int fileSizeBytes,
      required int pageCount,
      required DateTime createdAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> clientModifiedAt,
      Value<String> modifiedDeviceId,
      Value<int> syncVersion,
      Value<int> rowid,
    });
typedef $$PdfDocumentsTableUpdateCompanionBuilder =
    PdfDocumentsCompanion Function({
      Value<String> id,
      Value<String> nodeId,
      Value<String> casHash,
      Value<String> fileName,
      Value<int> fileSizeBytes,
      Value<int> pageCount,
      Value<DateTime> createdAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> clientModifiedAt,
      Value<String> modifiedDeviceId,
      Value<int> syncVersion,
      Value<int> rowid,
    });

final class $$PdfDocumentsTableReferences
    extends
        BaseReferences<_$AppDatabase, $PdfDocumentsTable, PdfDocumentEntry> {
  $$PdfDocumentsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NodesTable _nodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('pdf_documents__node_id__nodes__id');

  $$NodesTableProcessedTableManager get nodeId {
    final $_column = $_itemColumn<String>('node_id')!;

    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$InkPagesTable, List<InkPageEntry>>
  _inkPagesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.inkPages,
    aliasName: 'pdf_documents__id__ink_pages__pdf_document_id',
  );

  $$InkPagesTableProcessedTableManager get inkPagesRefs {
    final manager = $$InkPagesTableTableManager(
      $_db,
      $_db.inkPages,
    ).filter((f) => f.pdfDocumentId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_inkPagesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PdfDocumentsTableFilterComposer
    extends Composer<_$AppDatabase, $PdfDocumentsTable> {
  $$PdfDocumentsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get casHash => $composableBuilder(
    column: $table.casHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$NodesTableFilterComposer get nodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> inkPagesRefs(
    Expression<bool> Function($$InkPagesTableFilterComposer f) f,
  ) {
    final $$InkPagesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inkPages,
      getReferencedColumn: (t) => t.pdfDocumentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkPagesTableFilterComposer(
            $db: $db,
            $table: $db.inkPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PdfDocumentsTableOrderingComposer
    extends Composer<_$AppDatabase, $PdfDocumentsTable> {
  $$PdfDocumentsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get casHash => $composableBuilder(
    column: $table.casHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get fileName => $composableBuilder(
    column: $table.fileName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageCount => $composableBuilder(
    column: $table.pageCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$NodesTableOrderingComposer get nodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PdfDocumentsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PdfDocumentsTable> {
  $$PdfDocumentsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get casHash =>
      $composableBuilder(column: $table.casHash, builder: (column) => column);

  GeneratedColumn<String> get fileName =>
      $composableBuilder(column: $table.fileName, builder: (column) => column);

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pageCount =>
      $composableBuilder(column: $table.pageCount, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$NodesTableAnnotationComposer get nodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> inkPagesRefs<T extends Object>(
    Expression<T> Function($$InkPagesTableAnnotationComposer a) f,
  ) {
    final $$InkPagesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.inkPages,
      getReferencedColumn: (t) => t.pdfDocumentId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkPagesTableAnnotationComposer(
            $db: $db,
            $table: $db.inkPages,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PdfDocumentsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $PdfDocumentsTable,
          PdfDocumentEntry,
          $$PdfDocumentsTableFilterComposer,
          $$PdfDocumentsTableOrderingComposer,
          $$PdfDocumentsTableAnnotationComposer,
          $$PdfDocumentsTableCreateCompanionBuilder,
          $$PdfDocumentsTableUpdateCompanionBuilder,
          (PdfDocumentEntry, $$PdfDocumentsTableReferences),
          PdfDocumentEntry,
          PrefetchHooks Function({bool nodeId, bool inkPagesRefs})
        > {
  $$PdfDocumentsTableTableManager(_$AppDatabase db, $PdfDocumentsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PdfDocumentsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$PdfDocumentsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PdfDocumentsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> casHash = const Value.absent(),
                Value<String> fileName = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<int> pageCount = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PdfDocumentsCompanion(
                id: id,
                nodeId: nodeId,
                casHash: casHash,
                fileName: fileName,
                fileSizeBytes: fileSizeBytes,
                pageCount: pageCount,
                createdAt: createdAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String nodeId,
                required String casHash,
                required String fileName,
                required int fileSizeBytes,
                required int pageCount,
                required DateTime createdAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => PdfDocumentsCompanion.insert(
                id: id,
                nodeId: nodeId,
                casHash: casHash,
                fileName: fileName,
                fileSizeBytes: fileSizeBytes,
                pageCount: pageCount,
                createdAt: createdAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$PdfDocumentsTable, PdfDocumentEntry>(table),
                  $$PdfDocumentsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({nodeId = false, inkPagesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (inkPagesRefs) db.inkPages],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (nodeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.nodeId,
                        referencedTable: $$PdfDocumentsTableReferences
                            ._nodeIdTable(db),
                        referencedColumn: $$PdfDocumentsTableReferences
                            ._nodeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (inkPagesRefs)
                    await $_getPrefetchedDataByColumns<
                      PdfDocumentEntry,
                      $PdfDocumentsTable,
                      InkPageEntry,
                      $InkPagesTable
                    >(
                      currentTable: table,
                      referencedTable: $$PdfDocumentsTableReferences
                          ._inkPagesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$PdfDocumentsTableReferences(
                            db,
                            table,
                            p0,
                          ).inkPagesRefs,
                      currentColumn: 'id',
                      referencedColumn: 'pdf_document_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$PdfDocumentsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $PdfDocumentsTable,
      PdfDocumentEntry,
      $$PdfDocumentsTableFilterComposer,
      $$PdfDocumentsTableOrderingComposer,
      $$PdfDocumentsTableAnnotationComposer,
      $$PdfDocumentsTableCreateCompanionBuilder,
      $$PdfDocumentsTableUpdateCompanionBuilder,
      (PdfDocumentEntry, $$PdfDocumentsTableReferences),
      PdfDocumentEntry,
      PrefetchHooks Function({bool nodeId, bool inkPagesRefs})
    >;
typedef $$InkPagesTableCreateCompanionBuilder = InkPagesCompanion Function({
  required String id,
  required String documentId,
  required int pageNumber,
  Value<double> width,
  Value<double> height,
  Value<String> templateType,
  Value<double> templateSpacing,
  Value<int> backgroundColor,
  Value<String?> pdfDocumentId,
  Value<String?> pdfSourceHash,
  Value<int?> pdfPageIndex,
  Value<String?> rawPencilkitHash,
  Value<String?> portableInkHash,
  Value<String?> previewPngHash,
  Value<String?> ocrText,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$InkPagesTableUpdateCompanionBuilder = InkPagesCompanion Function({
  Value<String> id,
  Value<String> documentId,
  Value<int> pageNumber,
  Value<double> width,
  Value<double> height,
  Value<String> templateType,
  Value<double> templateSpacing,
  Value<int> backgroundColor,
  Value<String?> pdfDocumentId,
  Value<String?> pdfSourceHash,
  Value<int?> pdfPageIndex,
  Value<String?> rawPencilkitHash,
  Value<String?> portableInkHash,
  Value<String?> previewPngHash,
  Value<String?> ocrText,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$InkPagesTableReferences
    extends BaseReferences<_$AppDatabase, $InkPagesTable, InkPageEntry> {
  $$InkPagesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $InkDocumentsTable _documentIdTable(_$AppDatabase db) =>
      db.inkDocuments.createAlias('ink_pages__document_id__ink_documents__id');

  $$InkDocumentsTableProcessedTableManager get documentId {
    final $_column = $_itemColumn<String>('document_id')!;

    final manager = $$InkDocumentsTableTableManager(
      $_db,
      $_db.inkDocuments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_documentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $PdfDocumentsTable _pdfDocumentIdTable(_$AppDatabase db) => db
      .pdfDocuments
      .createAlias('ink_pages__pdf_document_id__pdf_documents__id');

  $$PdfDocumentsTableProcessedTableManager? get pdfDocumentId {
    final $_column = $_itemColumn<String>('pdf_document_id');
    if ($_column == null) return null;
    final manager = $$PdfDocumentsTableTableManager(
      $_db,
      $_db.pdfDocuments,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_pdfDocumentIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$InkPagesTableFilterComposer
    extends Composer<_$AppDatabase, $InkPagesTable> {
  $$InkPagesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get templateSpacing => $composableBuilder(
    column: $table.templateSpacing,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get pdfSourceHash => $composableBuilder(
    column: $table.pdfSourceHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pdfPageIndex => $composableBuilder(
    column: $table.pdfPageIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rawPencilkitHash => $composableBuilder(
    column: $table.rawPencilkitHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get portableInkHash => $composableBuilder(
    column: $table.portableInkHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get previewPngHash => $composableBuilder(
    column: $table.previewPngHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$InkDocumentsTableFilterComposer get documentId {
    final $$InkDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.inkDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.inkDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PdfDocumentsTableFilterComposer get pdfDocumentId {
    final $$PdfDocumentsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pdfDocumentId,
      referencedTable: $db.pdfDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PdfDocumentsTableFilterComposer(
            $db: $db,
            $table: $db.pdfDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InkPagesTableOrderingComposer
    extends Composer<_$AppDatabase, $InkPagesTable> {
  $$InkPagesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get templateSpacing => $composableBuilder(
    column: $table.templateSpacing,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get pdfSourceHash => $composableBuilder(
    column: $table.pdfSourceHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pdfPageIndex => $composableBuilder(
    column: $table.pdfPageIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rawPencilkitHash => $composableBuilder(
    column: $table.rawPencilkitHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get portableInkHash => $composableBuilder(
    column: $table.portableInkHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get previewPngHash => $composableBuilder(
    column: $table.previewPngHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get ocrText => $composableBuilder(
    column: $table.ocrText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$InkDocumentsTableOrderingComposer get documentId {
    final $$InkDocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.inkDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkDocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.inkDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PdfDocumentsTableOrderingComposer get pdfDocumentId {
    final $$PdfDocumentsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pdfDocumentId,
      referencedTable: $db.pdfDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PdfDocumentsTableOrderingComposer(
            $db: $db,
            $table: $db.pdfDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InkPagesTableAnnotationComposer
    extends Composer<_$AppDatabase, $InkPagesTable> {
  $$InkPagesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get pageNumber => $composableBuilder(
    column: $table.pageNumber,
    builder: (column) => column,
  );

  GeneratedColumn<double> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<double> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get templateType => $composableBuilder(
    column: $table.templateType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get templateSpacing => $composableBuilder(
    column: $table.templateSpacing,
    builder: (column) => column,
  );

  GeneratedColumn<int> get backgroundColor => $composableBuilder(
    column: $table.backgroundColor,
    builder: (column) => column,
  );

  GeneratedColumn<String> get pdfSourceHash => $composableBuilder(
    column: $table.pdfSourceHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get pdfPageIndex => $composableBuilder(
    column: $table.pdfPageIndex,
    builder: (column) => column,
  );

  GeneratedColumn<String> get rawPencilkitHash => $composableBuilder(
    column: $table.rawPencilkitHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get portableInkHash => $composableBuilder(
    column: $table.portableInkHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get previewPngHash => $composableBuilder(
    column: $table.previewPngHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get ocrText =>
      $composableBuilder(column: $table.ocrText, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$InkDocumentsTableAnnotationComposer get documentId {
    final $$InkDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.documentId,
      referencedTable: $db.inkDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$InkDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.inkDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$PdfDocumentsTableAnnotationComposer get pdfDocumentId {
    final $$PdfDocumentsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.pdfDocumentId,
      referencedTable: $db.pdfDocuments,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$PdfDocumentsTableAnnotationComposer(
            $db: $db,
            $table: $db.pdfDocuments,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$InkPagesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $InkPagesTable,
          InkPageEntry,
          $$InkPagesTableFilterComposer,
          $$InkPagesTableOrderingComposer,
          $$InkPagesTableAnnotationComposer,
          $$InkPagesTableCreateCompanionBuilder,
          $$InkPagesTableUpdateCompanionBuilder,
          (InkPageEntry, $$InkPagesTableReferences),
          InkPageEntry,
          PrefetchHooks Function({bool documentId, bool pdfDocumentId})
        > {
  $$InkPagesTableTableManager(_$AppDatabase db, $InkPagesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$InkPagesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$InkPagesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$InkPagesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> documentId = const Value.absent(),
                Value<int> pageNumber = const Value.absent(),
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<String> templateType = const Value.absent(),
                Value<double> templateSpacing = const Value.absent(),
                Value<int> backgroundColor = const Value.absent(),
                Value<String?> pdfDocumentId = const Value.absent(),
                Value<String?> pdfSourceHash = const Value.absent(),
                Value<int?> pdfPageIndex = const Value.absent(),
                Value<String?> rawPencilkitHash = const Value.absent(),
                Value<String?> portableInkHash = const Value.absent(),
                Value<String?> previewPngHash = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InkPagesCompanion(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                width: width,
                height: height,
                templateType: templateType,
                templateSpacing: templateSpacing,
                backgroundColor: backgroundColor,
                pdfDocumentId: pdfDocumentId,
                pdfSourceHash: pdfSourceHash,
                pdfPageIndex: pdfPageIndex,
                rawPencilkitHash: rawPencilkitHash,
                portableInkHash: portableInkHash,
                previewPngHash: previewPngHash,
                ocrText: ocrText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String documentId,
                required int pageNumber,
                Value<double> width = const Value.absent(),
                Value<double> height = const Value.absent(),
                Value<String> templateType = const Value.absent(),
                Value<double> templateSpacing = const Value.absent(),
                Value<int> backgroundColor = const Value.absent(),
                Value<String?> pdfDocumentId = const Value.absent(),
                Value<String?> pdfSourceHash = const Value.absent(),
                Value<int?> pdfPageIndex = const Value.absent(),
                Value<String?> rawPencilkitHash = const Value.absent(),
                Value<String?> portableInkHash = const Value.absent(),
                Value<String?> previewPngHash = const Value.absent(),
                Value<String?> ocrText = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => InkPagesCompanion.insert(
                id: id,
                documentId: documentId,
                pageNumber: pageNumber,
                width: width,
                height: height,
                templateType: templateType,
                templateSpacing: templateSpacing,
                backgroundColor: backgroundColor,
                pdfDocumentId: pdfDocumentId,
                pdfSourceHash: pdfSourceHash,
                pdfPageIndex: pdfPageIndex,
                rawPencilkitHash: rawPencilkitHash,
                portableInkHash: portableInkHash,
                previewPngHash: previewPngHash,
                ocrText: ocrText,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$InkPagesTable, InkPageEntry>(table),
                  $$InkPagesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({documentId = false, pdfDocumentId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (documentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.documentId,
                        referencedTable: $$InkPagesTableReferences
                            ._documentIdTable(db),
                        referencedColumn: $$InkPagesTableReferences
                            ._documentIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (pdfDocumentId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.pdfDocumentId,
                        referencedTable: $$InkPagesTableReferences
                            ._pdfDocumentIdTable(db),
                        referencedColumn: $$InkPagesTableReferences
                            ._pdfDocumentIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$InkPagesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $InkPagesTable,
      InkPageEntry,
      $$InkPagesTableFilterComposer,
      $$InkPagesTableOrderingComposer,
      $$InkPagesTableAnnotationComposer,
      $$InkPagesTableCreateCompanionBuilder,
      $$InkPagesTableUpdateCompanionBuilder,
      (InkPageEntry, $$InkPagesTableReferences),
      InkPageEntry,
      PrefetchHooks Function({bool documentId, bool pdfDocumentId})
    >;
typedef $$NodeLinksTableCreateCompanionBuilder = NodeLinksCompanion Function({
  required String id,
  required String sourceNodeId,
  required String targetNodeId,
  Value<String?> linkText,
  required DateTime createdAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$NodeLinksTableUpdateCompanionBuilder = NodeLinksCompanion Function({
  Value<String> id,
  Value<String> sourceNodeId,
  Value<String> targetNodeId,
  Value<String?> linkText,
  Value<DateTime> createdAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$NodeLinksTableReferences
    extends BaseReferences<_$AppDatabase, $NodeLinksTable, NodeLinkEntry> {
  $$NodeLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NodesTable _sourceNodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('node_links__source_node_id__nodes__id');

  $$NodesTableProcessedTableManager get sourceNodeId {
    final $_column = $_itemColumn<String>('source_node_id')!;

    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sourceNodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NodesTable _targetNodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('node_links__target_node_id__nodes__id');

  $$NodesTableProcessedTableManager get targetNodeId {
    final $_column = $_itemColumn<String>('target_node_id')!;

    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_targetNodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NodeLinksTableFilterComposer
    extends Composer<_$AppDatabase, $NodeLinksTable> {
  $$NodeLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get linkText => $composableBuilder(
    column: $table.linkText,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$NodesTableFilterComposer get sourceNodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceNodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableFilterComposer get targetNodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetNodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $NodeLinksTable> {
  $$NodeLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get linkText => $composableBuilder(
    column: $table.linkText,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$NodesTableOrderingComposer get sourceNodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceNodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableOrderingComposer get targetNodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetNodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodeLinksTable> {
  $$NodeLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get linkText =>
      $composableBuilder(column: $table.linkText, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$NodesTableAnnotationComposer get sourceNodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sourceNodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableAnnotationComposer get targetNodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.targetNodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodeLinksTable,
          NodeLinkEntry,
          $$NodeLinksTableFilterComposer,
          $$NodeLinksTableOrderingComposer,
          $$NodeLinksTableAnnotationComposer,
          $$NodeLinksTableCreateCompanionBuilder,
          $$NodeLinksTableUpdateCompanionBuilder,
          (NodeLinkEntry, $$NodeLinksTableReferences),
          NodeLinkEntry,
          PrefetchHooks Function({bool sourceNodeId, bool targetNodeId})
        > {
  $$NodeLinksTableTableManager(_$AppDatabase db, $NodeLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodeLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodeLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> sourceNodeId = const Value.absent(),
                Value<String> targetNodeId = const Value.absent(),
                Value<String?> linkText = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeLinksCompanion(
                id: id,
                sourceNodeId: sourceNodeId,
                targetNodeId: targetNodeId,
                linkText: linkText,
                createdAt: createdAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String sourceNodeId,
                required String targetNodeId,
                Value<String?> linkText = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeLinksCompanion.insert(
                id: id,
                sourceNodeId: sourceNodeId,
                targetNodeId: targetNodeId,
                linkText: linkText,
                createdAt: createdAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodeLinksTable, NodeLinkEntry>(table),
                  $$NodeLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({sourceNodeId = false, targetNodeId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (sourceNodeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sourceNodeId,
                            referencedTable: $$NodeLinksTableReferences
                                ._sourceNodeIdTable(db),
                            referencedColumn: $$NodeLinksTableReferences
                                ._sourceNodeIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (targetNodeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.targetNodeId,
                            referencedTable: $$NodeLinksTableReferences
                                ._targetNodeIdTable(db),
                            referencedColumn: $$NodeLinksTableReferences
                                ._targetNodeIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$NodeLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodeLinksTable,
      NodeLinkEntry,
      $$NodeLinksTableFilterComposer,
      $$NodeLinksTableOrderingComposer,
      $$NodeLinksTableAnnotationComposer,
      $$NodeLinksTableCreateCompanionBuilder,
      $$NodeLinksTableUpdateCompanionBuilder,
      (NodeLinkEntry, $$NodeLinksTableReferences),
      NodeLinkEntry,
      PrefetchHooks Function({bool sourceNodeId, bool targetNodeId})
    >;
typedef $$TagsTableCreateCompanionBuilder = TagsCompanion Function({
  required String id,
  required String workspaceId,
  required String name,
  Value<int?> color,
  required DateTime createdAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$TagsTableUpdateCompanionBuilder = TagsCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> name,
  Value<int?> color,
  Value<DateTime> createdAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$TagsTableReferences
    extends BaseReferences<_$AppDatabase, $TagsTable, TagEntry> {
  $$TagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('tags__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$NodeTagsTable, List<NodeTagEntry>>
  _nodeTagsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.nodeTags,
    aliasName: 'tags__id__node_tags__tag_id',
  );

  $$NodeTagsTableProcessedTableManager get nodeTagsRefs {
    final manager = $$NodeTagsTableTableManager(
      $_db,
      $_db.nodeTags,
    ).filter((f) => f.tagId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_nodeTagsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TagsTableFilterComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> nodeTagsRefs(
    Expression<bool> Function($$NodeTagsTableFilterComposer f) f,
  ) {
    final $$NodeTagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTagsTableFilterComposer(
            $db: $db,
            $table: $db.nodeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableOrderingComposer extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get color => $composableBuilder(
    column: $table.color,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TagsTable> {
  $$TagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get color =>
      $composableBuilder(column: $table.color, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> nodeTagsRefs<T extends Object>(
    Expression<T> Function($$NodeTagsTableAnnotationComposer a) f,
  ) {
    final $$NodeTagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.nodeTags,
      getReferencedColumn: (t) => t.tagId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodeTagsTableAnnotationComposer(
            $db: $db,
            $table: $db.nodeTags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TagsTable,
          TagEntry,
          $$TagsTableFilterComposer,
          $$TagsTableOrderingComposer,
          $$TagsTableAnnotationComposer,
          $$TagsTableCreateCompanionBuilder,
          $$TagsTableUpdateCompanionBuilder,
          (TagEntry, $$TagsTableReferences),
          TagEntry,
          PrefetchHooks Function({bool workspaceId, bool nodeTagsRefs})
        > {
  $$TagsTableTableManager(_$AppDatabase db, $TagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int?> color = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion(
                id: id,
                workspaceId: workspaceId,
                name: name,
                color: color,
                createdAt: createdAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String name,
                Value<int?> color = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TagsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                name: name,
                color: color,
                createdAt: createdAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TagsTable, TagEntry>(table),
                  $$TagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false, nodeTagsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (nodeTagsRefs) db.nodeTags],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workspaceId,
                        referencedTable: $$TagsTableReferences
                            ._workspaceIdTable(db),
                        referencedColumn: $$TagsTableReferences
                            ._workspaceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (nodeTagsRefs)
                    await $_getPrefetchedDataByColumns<
                      TagEntry,
                      $TagsTable,
                      NodeTagEntry,
                      $NodeTagsTable
                    >(
                      currentTable: table,
                      referencedTable: $$TagsTableReferences._nodeTagsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$TagsTableReferences(db, table, p0).nodeTagsRefs,
                      currentColumn: 'id',
                      referencedColumn: 'tag_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TagsTable,
      TagEntry,
      $$TagsTableFilterComposer,
      $$TagsTableOrderingComposer,
      $$TagsTableAnnotationComposer,
      $$TagsTableCreateCompanionBuilder,
      $$TagsTableUpdateCompanionBuilder,
      (TagEntry, $$TagsTableReferences),
      TagEntry,
      PrefetchHooks Function({bool workspaceId, bool nodeTagsRefs})
    >;
typedef $$NodeTagsTableCreateCompanionBuilder = NodeTagsCompanion Function({
  required String nodeId,
  required String tagId,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$NodeTagsTableUpdateCompanionBuilder = NodeTagsCompanion Function({
  Value<String> nodeId,
  Value<String> tagId,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$NodeTagsTableReferences
    extends BaseReferences<_$AppDatabase, $NodeTagsTable, NodeTagEntry> {
  $$NodeTagsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $NodesTable _nodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('node_tags__node_id__nodes__id');

  $$NodesTableProcessedTableManager get nodeId {
    final $_column = $_itemColumn<String>('node_id')!;

    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TagsTable _tagIdTable(_$AppDatabase db) =>
      db.tags.createAlias('node_tags__tag_id__tags__id');

  $$TagsTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = $$TagsTableTableManager(
      $_db,
      $_db.tags,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$NodeTagsTableFilterComposer
    extends Composer<_$AppDatabase, $NodeTagsTable> {
  $$NodeTagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$NodesTableFilterComposer get nodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableFilterComposer get tagId {
    final $$TagsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableFilterComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeTagsTableOrderingComposer
    extends Composer<_$AppDatabase, $NodeTagsTable> {
  $$NodeTagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$NodesTableOrderingComposer get nodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableOrderingComposer get tagId {
    final $$TagsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableOrderingComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeTagsTableAnnotationComposer
    extends Composer<_$AppDatabase, $NodeTagsTable> {
  $$NodeTagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$NodesTableAnnotationComposer get nodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TagsTableAnnotationComposer get tagId {
    final $$TagsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: $db.tags,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TagsTableAnnotationComposer(
            $db: $db,
            $table: $db.tags,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$NodeTagsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $NodeTagsTable,
          NodeTagEntry,
          $$NodeTagsTableFilterComposer,
          $$NodeTagsTableOrderingComposer,
          $$NodeTagsTableAnnotationComposer,
          $$NodeTagsTableCreateCompanionBuilder,
          $$NodeTagsTableUpdateCompanionBuilder,
          (NodeTagEntry, $$NodeTagsTableReferences),
          NodeTagEntry,
          PrefetchHooks Function({bool nodeId, bool tagId})
        > {
  $$NodeTagsTableTableManager(_$AppDatabase db, $NodeTagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodeTagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodeTagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodeTagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> nodeId = const Value.absent(),
                Value<String> tagId = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeTagsCompanion(
                nodeId: nodeId,
                tagId: tagId,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String nodeId,
                required String tagId,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodeTagsCompanion.insert(
                nodeId: nodeId,
                tagId: tagId,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodeTagsTable, NodeTagEntry>(table),
                  $$NodeTagsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({nodeId = false, tagId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (nodeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.nodeId,
                        referencedTable: $$NodeTagsTableReferences._nodeIdTable(
                          db,
                        ),
                        referencedColumn: $$NodeTagsTableReferences
                            ._nodeIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (tagId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.tagId,
                        referencedTable: $$NodeTagsTableReferences._tagIdTable(
                          db,
                        ),
                        referencedColumn: $$NodeTagsTableReferences
                            ._tagIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$NodeTagsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $NodeTagsTable,
      NodeTagEntry,
      $$NodeTagsTableFilterComposer,
      $$NodeTagsTableOrderingComposer,
      $$NodeTagsTableAnnotationComposer,
      $$NodeTagsTableCreateCompanionBuilder,
      $$NodeTagsTableUpdateCompanionBuilder,
      (NodeTagEntry, $$NodeTagsTableReferences),
      NodeTagEntry,
      PrefetchHooks Function({bool nodeId, bool tagId})
    >;
typedef $$ProjectsTableCreateCompanionBuilder = ProjectsCompanion Function({
  required String id,
  required String workspaceId,
  required String name,
  Value<String?> description,
  Value<String> colorHex,
  Value<String?> icon,
  Value<bool> isArchived,
  Value<int> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$ProjectsTableUpdateCompanionBuilder = ProjectsCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> name,
  Value<String?> description,
  Value<String> colorHex,
  Value<String?> icon,
  Value<bool> isArchived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$ProjectsTableReferences
    extends BaseReferences<_$AppDatabase, $ProjectsTable, ProjectEntry> {
  $$ProjectsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('projects__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$TasksTable, List<TaskEntry>> _tasksRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.tasks,
    aliasName: 'projects__id__tasks__project_id',
  );

  $$TasksTableProcessedTableManager get tasksRefs {
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.projectId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_tasksRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ProjectsTableFilterComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> tasksRefs(
    Expression<bool> Function($$TasksTableFilterComposer f) f,
  ) {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ProjectsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProjectsTable> {
  $$ProjectsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> tasksRefs<T extends Object>(
    Expression<T> Function($$TasksTableAnnotationComposer a) f,
  ) {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.projectId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ProjectsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProjectsTable,
          ProjectEntry,
          $$ProjectsTableFilterComposer,
          $$ProjectsTableOrderingComposer,
          $$ProjectsTableAnnotationComposer,
          $$ProjectsTableCreateCompanionBuilder,
          $$ProjectsTableUpdateCompanionBuilder,
          (ProjectEntry, $$ProjectsTableReferences),
          ProjectEntry,
          PrefetchHooks Function({bool workspaceId, bool tasksRefs})
        > {
  $$ProjectsTableTableManager(_$AppDatabase db, $ProjectsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProjectsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProjectsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProjectsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion(
                id: id,
                workspaceId: workspaceId,
                name: name,
                description: description,
                colorHex: colorHex,
                icon: icon,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProjectsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                name: name,
                description: description,
                colorHex: colorHex,
                icon: icon,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProjectsTable, ProjectEntry>(table),
                  $$ProjectsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false, tasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (tasksRefs) db.tasks],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workspaceId,
                        referencedTable: $$ProjectsTableReferences
                            ._workspaceIdTable(db),
                        referencedColumn: $$ProjectsTableReferences
                            ._workspaceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [
                  if (tasksRefs)
                    await $_getPrefetchedDataByColumns<
                      ProjectEntry,
                      $ProjectsTable,
                      TaskEntry,
                      $TasksTable
                    >(
                      currentTable: table,
                      referencedTable: $$ProjectsTableReferences
                          ._tasksRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$ProjectsTableReferences(db, table, p0).tasksRefs,
                      currentColumn: 'id',
                      referencedColumn: 'project_id',
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$ProjectsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProjectsTable,
      ProjectEntry,
      $$ProjectsTableFilterComposer,
      $$ProjectsTableOrderingComposer,
      $$ProjectsTableAnnotationComposer,
      $$ProjectsTableCreateCompanionBuilder,
      $$ProjectsTableUpdateCompanionBuilder,
      (ProjectEntry, $$ProjectsTableReferences),
      ProjectEntry,
      PrefetchHooks Function({bool workspaceId, bool tasksRefs})
    >;
typedef $$TasksTableCreateCompanionBuilder = TasksCompanion Function({
  required String id,
  required String workspaceId,
  Value<String?> projectId,
  Value<String?> nodeId,
  Value<String?> parentTaskId,
  required String title,
  Value<String?> description,
  Value<bool> isCompleted,
  Value<String> status,
  Value<int> priority,
  Value<DateTime?> dueDate,
  Value<bool> hasTime,
  Value<DateTime?> completedAt,
  Value<String?> recurrenceRule,
  Value<int?> reminderMinutesBefore,
  Value<int> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$TasksTableUpdateCompanionBuilder = TasksCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String?> projectId,
  Value<String?> nodeId,
  Value<String?> parentTaskId,
  Value<String> title,
  Value<String?> description,
  Value<bool> isCompleted,
  Value<String> status,
  Value<int> priority,
  Value<DateTime?> dueDate,
  Value<bool> hasTime,
  Value<DateTime?> completedAt,
  Value<String?> recurrenceRule,
  Value<int?> reminderMinutesBefore,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, TaskEntry> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('tasks__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ProjectsTable _projectIdTable(_$AppDatabase db) =>
      db.projects.createAlias('tasks__project_id__projects__id');

  $$ProjectsTableProcessedTableManager? get projectId {
    final $_column = $_itemColumn<String>('project_id');
    if ($_column == null) return null;
    final manager = $$ProjectsTableTableManager(
      $_db,
      $_db.projects,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_projectIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NodesTable _nodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('tasks__node_id__nodes__id');

  $$NodesTableProcessedTableManager? get nodeId {
    final $_column = $_itemColumn<String>('node_id');
    if ($_column == null) return null;
    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TasksTable _parentTaskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('tasks__parent_task_id__tasks__id');

  $$TasksTableProcessedTableManager? get parentTaskId {
    final $_column = $_itemColumn<String>('parent_task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_parentTaskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$CalendarEventsTable, List<CalendarEventEntry>>
  _calendarEventsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.calendarEvents,
    aliasName: 'tasks__id__calendar_events__task_id',
  );

  $$CalendarEventsTableProcessedTableManager get calendarEventsRefs {
    final manager = $$CalendarEventsTableTableManager(
      $_db,
      $_db.calendarEvents,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_calendarEventsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get hasTime => $composableBuilder(
    column: $table.hasTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProjectsTableFilterComposer get projectId {
    final $$ProjectsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableFilterComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableFilterComposer get nodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get parentTaskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> calendarEventsRefs(
    Expression<bool> Function($$CalendarEventsTableFilterComposer f) f,
  ) {
    final $$CalendarEventsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableFilterComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get hasTime => $composableBuilder(
    column: $table.hasTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProjectsTableOrderingComposer get projectId {
    final $$ProjectsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableOrderingComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableOrderingComposer get nodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get parentTaskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<DateTime> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get hasTime =>
      $composableBuilder(column: $table.hasTime, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get recurrenceRule => $composableBuilder(
    column: $table.recurrenceRule,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinutesBefore => $composableBuilder(
    column: $table.reminderMinutesBefore,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ProjectsTableAnnotationComposer get projectId {
    final $$ProjectsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.projectId,
      referencedTable: $db.projects,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ProjectsTableAnnotationComposer(
            $db: $db,
            $table: $db.projects,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableAnnotationComposer get nodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get parentTaskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.parentTaskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> calendarEventsRefs<T extends Object>(
    Expression<T> Function($$CalendarEventsTableAnnotationComposer a) f,
  ) {
    final $$CalendarEventsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.calendarEvents,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CalendarEventsTableAnnotationComposer(
            $db: $db,
            $table: $db.calendarEvents,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          TaskEntry,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (TaskEntry, $$TasksTableReferences),
          TaskEntry,
          PrefetchHooks Function({
            bool workspaceId,
            bool projectId,
            bool nodeId,
            bool parentTaskId,
            bool calendarEventsRefs,
          })
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String?> projectId = const Value.absent(),
                Value<String?> nodeId = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> hasTime = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<int?> reminderMinutesBefore = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                workspaceId: workspaceId,
                projectId: projectId,
                nodeId: nodeId,
                parentTaskId: parentTaskId,
                title: title,
                description: description,
                isCompleted: isCompleted,
                status: status,
                priority: priority,
                dueDate: dueDate,
                hasTime: hasTime,
                completedAt: completedAt,
                recurrenceRule: recurrenceRule,
                reminderMinutesBefore: reminderMinutesBefore,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                Value<String?> projectId = const Value.absent(),
                Value<String?> nodeId = const Value.absent(),
                Value<String?> parentTaskId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<DateTime?> dueDate = const Value.absent(),
                Value<bool> hasTime = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<String?> recurrenceRule = const Value.absent(),
                Value<int?> reminderMinutesBefore = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                projectId: projectId,
                nodeId: nodeId,
                parentTaskId: parentTaskId,
                title: title,
                description: description,
                isCompleted: isCompleted,
                status: status,
                priority: priority,
                dueDate: dueDate,
                hasTime: hasTime,
                completedAt: completedAt,
                recurrenceRule: recurrenceRule,
                reminderMinutesBefore: reminderMinutesBefore,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TasksTable, TaskEntry>(table),
                  $$TasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                workspaceId = false,
                projectId = false,
                nodeId = false,
                parentTaskId = false,
                calendarEventsRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (calendarEventsRefs) db.calendarEvents,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.workspaceId,
                            referencedTable: $$TasksTableReferences
                                ._workspaceIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._workspaceIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (projectId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.projectId,
                            referencedTable: $$TasksTableReferences
                                ._projectIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._projectIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (nodeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.nodeId,
                            referencedTable: $$TasksTableReferences
                                ._nodeIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._nodeIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (parentTaskId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.parentTaskId,
                            referencedTable: $$TasksTableReferences
                                ._parentTaskIdTable(db),
                            referencedColumn: $$TasksTableReferences
                                ._parentTaskIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (calendarEventsRefs)
                        await $_getPrefetchedDataByColumns<
                          TaskEntry,
                          $TasksTable,
                          CalendarEventEntry,
                          $CalendarEventsTable
                        >(
                          currentTable: table,
                          referencedTable: $$TasksTableReferences
                              ._calendarEventsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$TasksTableReferences(
                                db,
                                table,
                                p0,
                              ).calendarEventsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'task_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      TaskEntry,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (TaskEntry, $$TasksTableReferences),
      TaskEntry,
      PrefetchHooks Function({
        bool workspaceId,
        bool projectId,
        bool nodeId,
        bool parentTaskId,
        bool calendarEventsRefs,
      })
    >;
typedef $$CalendarEventsTableCreateCompanionBuilder =
    CalendarEventsCompanion Function({
      required String id,
      required String workspaceId,
      Value<String?> taskId,
      Value<String?> nodeId,
      required String title,
      Value<String?> description,
      required DateTime startTime,
      required DateTime endTime,
      Value<bool> isAllDay,
      Value<String?> colorHex,
      Value<String?> location,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> clientModifiedAt,
      Value<String> modifiedDeviceId,
      Value<int> syncVersion,
      Value<int> rowid,
    });
typedef $$CalendarEventsTableUpdateCompanionBuilder =
    CalendarEventsCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String?> taskId,
      Value<String?> nodeId,
      Value<String> title,
      Value<String?> description,
      Value<DateTime> startTime,
      Value<DateTime> endTime,
      Value<bool> isAllDay,
      Value<String?> colorHex,
      Value<String?> location,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> clientModifiedAt,
      Value<String> modifiedDeviceId,
      Value<int> syncVersion,
      Value<int> rowid,
    });

final class $$CalendarEventsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $CalendarEventsTable,
          CalendarEventEntry
        > {
  $$CalendarEventsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) => db.workspaces
      .createAlias('calendar_events__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('calendar_events__task_id__tasks__id');

  $$TasksTableProcessedTableManager? get taskId {
    final $_column = $_itemColumn<String>('task_id');
    if ($_column == null) return null;
    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NodesTable _nodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('calendar_events__node_id__nodes__id');

  $$NodesTableProcessedTableManager? get nodeId {
    final $_column = $_itemColumn<String>('node_id');
    if ($_column == null) return null;
    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$CalendarEventsTableFilterComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableFilterComposer get nodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startTime => $composableBuilder(
    column: $table.startTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endTime => $composableBuilder(
    column: $table.endTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isAllDay => $composableBuilder(
    column: $table.isAllDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get location => $composableBuilder(
    column: $table.location,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableOrderingComposer get nodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CalendarEventsTable> {
  $$CalendarEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get startTime =>
      $composableBuilder(column: $table.startTime, builder: (column) => column);

  GeneratedColumn<DateTime> get endTime =>
      $composableBuilder(column: $table.endTime, builder: (column) => column);

  GeneratedColumn<bool> get isAllDay =>
      $composableBuilder(column: $table.isAllDay, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get location =>
      $composableBuilder(column: $table.location, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableAnnotationComposer get nodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$CalendarEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CalendarEventsTable,
          CalendarEventEntry,
          $$CalendarEventsTableFilterComposer,
          $$CalendarEventsTableOrderingComposer,
          $$CalendarEventsTableAnnotationComposer,
          $$CalendarEventsTableCreateCompanionBuilder,
          $$CalendarEventsTableUpdateCompanionBuilder,
          (CalendarEventEntry, $$CalendarEventsTableReferences),
          CalendarEventEntry,
          PrefetchHooks Function({bool workspaceId, bool taskId, bool nodeId})
        > {
  $$CalendarEventsTableTableManager(
    _$AppDatabase db,
    $CalendarEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CalendarEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CalendarEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CalendarEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String?> taskId = const Value.absent(),
                Value<String?> nodeId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime> startTime = const Value.absent(),
                Value<DateTime> endTime = const Value.absent(),
                Value<bool> isAllDay = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<String?> location = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion(
                id: id,
                workspaceId: workspaceId,
                taskId: taskId,
                nodeId: nodeId,
                title: title,
                description: description,
                startTime: startTime,
                endTime: endTime,
                isAllDay: isAllDay,
                colorHex: colorHex,
                location: location,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                Value<String?> taskId = const Value.absent(),
                Value<String?> nodeId = const Value.absent(),
                required String title,
                Value<String?> description = const Value.absent(),
                required DateTime startTime,
                required DateTime endTime,
                Value<bool> isAllDay = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<String?> location = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CalendarEventsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                taskId: taskId,
                nodeId: nodeId,
                title: title,
                description: description,
                startTime: startTime,
                endTime: endTime,
                isAllDay: isAllDay,
                colorHex: colorHex,
                location: location,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CalendarEventsTable, CalendarEventEntry>(table),
                  $$CalendarEventsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workspaceId = false, taskId = false, nodeId = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.workspaceId,
                            referencedTable: $$CalendarEventsTableReferences
                                ._workspaceIdTable(db),
                            referencedColumn: $$CalendarEventsTableReferences
                                ._workspaceIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (taskId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.taskId,
                            referencedTable: $$CalendarEventsTableReferences
                                ._taskIdTable(db),
                            referencedColumn: $$CalendarEventsTableReferences
                                ._taskIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (nodeId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.nodeId,
                            referencedTable: $$CalendarEventsTableReferences
                                ._nodeIdTable(db),
                            referencedColumn: $$CalendarEventsTableReferences
                                ._nodeIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [];
                  },
                );
              },
        ),
      );
}

typedef $$CalendarEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CalendarEventsTable,
      CalendarEventEntry,
      $$CalendarEventsTableFilterComposer,
      $$CalendarEventsTableOrderingComposer,
      $$CalendarEventsTableAnnotationComposer,
      $$CalendarEventsTableCreateCompanionBuilder,
      $$CalendarEventsTableUpdateCompanionBuilder,
      (CalendarEventEntry, $$CalendarEventsTableReferences),
      CalendarEventEntry,
      PrefetchHooks Function({bool workspaceId, bool taskId, bool nodeId})
    >;
typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  required String id,
  required String workspaceId,
  required String title,
  Value<String?> description,
  Value<String> colorHex,
  Value<String?> icon,
  Value<String> frequency,
  Value<int> targetCountPerPeriod,
  Value<bool> isArchived,
  Value<int> sortOrder,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> title,
  Value<String?> description,
  Value<String> colorHex,
  Value<String?> icon,
  Value<String> frequency,
  Value<int> targetCountPerPeriod,
  Value<bool> isArchived,
  Value<int> sortOrder,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$HabitsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitsTable, HabitEntry> {
  $$HabitsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('habits__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$HabitLogsTable, List<HabitLogEntry>>
  _habitLogsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.habitLogs,
    aliasName: 'habits__id__habit_logs__habit_id',
  );

  $$HabitLogsTableProcessedTableManager get habitLogsRefs {
    final manager = $$HabitLogsTableTableManager(
      $_db,
      $_db.habitLogs,
    ).filter((f) => f.habitId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_habitLogsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$HabitsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetCountPerPeriod => $composableBuilder(
    column: $table.targetCountPerPeriod,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> habitLogsRefs(
    Expression<bool> Function($$HabitLogsTableFilterComposer f) f,
  ) {
    final $$HabitLogsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitLogsTableFilterComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetCountPerPeriod => $composableBuilder(
    column: $table.targetCountPerPeriod,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<int> get targetCountPerPeriod => $composableBuilder(
    column: $table.targetCountPerPeriod,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isArchived => $composableBuilder(
    column: $table.isArchived,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> habitLogsRefs<T extends Object>(
    Expression<T> Function($$HabitLogsTableAnnotationComposer a) f,
  ) {
    final $$HabitLogsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.habitLogs,
      getReferencedColumn: (t) => t.habitId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitLogsTableAnnotationComposer(
            $db: $db,
            $table: $db.habitLogs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitsTable,
          HabitEntry,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (HabitEntry, $$HabitsTableReferences),
          HabitEntry,
          PrefetchHooks Function({bool workspaceId, bool habitLogsRefs})
        > {
  $$HabitsTableTableManager(_$AppDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int> targetCountPerPeriod = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                workspaceId: workspaceId,
                title: title,
                description: description,
                colorHex: colorHex,
                icon: icon,
                frequency: frequency,
                targetCountPerPeriod: targetCountPerPeriod,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<String> colorHex = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<int> targetCountPerPeriod = const Value.absent(),
                Value<bool> isArchived = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                title: title,
                description: description,
                colorHex: colorHex,
                icon: icon,
                frequency: frequency,
                targetCountPerPeriod: targetCountPerPeriod,
                isArchived: isArchived,
                sortOrder: sortOrder,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitsTable, HabitEntry>(table),
                  $$HabitsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({workspaceId = false, habitLogsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (habitLogsRefs) db.habitLogs],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (workspaceId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.workspaceId,
                            referencedTable: $$HabitsTableReferences
                                ._workspaceIdTable(db),
                            referencedColumn: $$HabitsTableReferences
                                ._workspaceIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (habitLogsRefs)
                        await $_getPrefetchedDataByColumns<
                          HabitEntry,
                          $HabitsTable,
                          HabitLogEntry,
                          $HabitLogsTable
                        >(
                          currentTable: table,
                          referencedTable: $$HabitsTableReferences
                              ._habitLogsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$HabitsTableReferences(
                                db,
                                table,
                                p0,
                              ).habitLogsRefs,
                          currentColumn: 'id',
                          referencedColumn: 'habit_id',
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitsTable,
      HabitEntry,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (HabitEntry, $$HabitsTableReferences),
      HabitEntry,
      PrefetchHooks Function({bool workspaceId, bool habitLogsRefs})
    >;
typedef $$HabitLogsTableCreateCompanionBuilder = HabitLogsCompanion Function({
  required String id,
  required String habitId,
  required String logDate,
  Value<int> completedCount,
  Value<bool> isCompleted,
  required DateTime createdAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$HabitLogsTableUpdateCompanionBuilder = HabitLogsCompanion Function({
  Value<String> id,
  Value<String> habitId,
  Value<String> logDate,
  Value<int> completedCount,
  Value<bool> isCompleted,
  Value<DateTime> createdAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$HabitLogsTableReferences
    extends BaseReferences<_$AppDatabase, $HabitLogsTable, HabitLogEntry> {
  $$HabitLogsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $HabitsTable _habitIdTable(_$AppDatabase db) =>
      db.habits.createAlias('habit_logs__habit_id__habits__id');

  $$HabitsTableProcessedTableManager get habitId {
    final $_column = $_itemColumn<String>('habit_id')!;

    final manager = $$HabitsTableTableManager(
      $_db,
      $_db.habits,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_habitIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$HabitLogsTableFilterComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$HabitsTableFilterComposer get habitId {
    final $$HabitsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableFilterComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableOrderingComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get logDate => $composableBuilder(
    column: $table.logDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$HabitsTableOrderingComposer get habitId {
    final $$HabitsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableOrderingComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableAnnotationComposer
    extends Composer<_$AppDatabase, $HabitLogsTable> {
  $$HabitLogsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get logDate =>
      $composableBuilder(column: $table.logDate, builder: (column) => column);

  GeneratedColumn<int> get completedCount => $composableBuilder(
    column: $table.completedCount,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$HabitsTableAnnotationComposer get habitId {
    final $$HabitsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.habitId,
      referencedTable: $db.habits,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$HabitsTableAnnotationComposer(
            $db: $db,
            $table: $db.habits,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$HabitLogsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HabitLogsTable,
          HabitLogEntry,
          $$HabitLogsTableFilterComposer,
          $$HabitLogsTableOrderingComposer,
          $$HabitLogsTableAnnotationComposer,
          $$HabitLogsTableCreateCompanionBuilder,
          $$HabitLogsTableUpdateCompanionBuilder,
          (HabitLogEntry, $$HabitLogsTableReferences),
          HabitLogEntry,
          PrefetchHooks Function({bool habitId})
        > {
  $$HabitLogsTableTableManager(_$AppDatabase db, $HabitLogsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitLogsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitLogsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitLogsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> habitId = const Value.absent(),
                Value<String> logDate = const Value.absent(),
                Value<int> completedCount = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitLogsCompanion(
                id: id,
                habitId: habitId,
                logDate: logDate,
                completedCount: completedCount,
                isCompleted: isCompleted,
                createdAt: createdAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String habitId,
                required String logDate,
                Value<int> completedCount = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HabitLogsCompanion.insert(
                id: id,
                habitId: habitId,
                logDate: logDate,
                completedCount: completedCount,
                isCompleted: isCompleted,
                createdAt: createdAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitLogsTable, HabitLogEntry>(table),
                  $$HabitLogsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({habitId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (habitId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.habitId,
                        referencedTable: $$HabitLogsTableReferences
                            ._habitIdTable(db),
                        referencedColumn: $$HabitLogsTableReferences
                            ._habitIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$HabitLogsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HabitLogsTable,
      HabitLogEntry,
      $$HabitLogsTableFilterComposer,
      $$HabitLogsTableOrderingComposer,
      $$HabitLogsTableAnnotationComposer,
      $$HabitLogsTableCreateCompanionBuilder,
      $$HabitLogsTableUpdateCompanionBuilder,
      (HabitLogEntry, $$HabitLogsTableReferences),
      HabitLogEntry,
      PrefetchHooks Function({bool habitId})
    >;
typedef $$GoalsTableCreateCompanionBuilder = GoalsCompanion Function({
  required String id,
  required String workspaceId,
  required String title,
  Value<String?> description,
  Value<DateTime?> targetDate,
  Value<String> status,
  Value<String?> colorHex,
  required DateTime createdAt,
  required DateTime updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});
typedef $$GoalsTableUpdateCompanionBuilder = GoalsCompanion Function({
  Value<String> id,
  Value<String> workspaceId,
  Value<String> title,
  Value<String?> description,
  Value<DateTime?> targetDate,
  Value<String> status,
  Value<String?> colorHex,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<DateTime?> deletedAt,
  Value<DateTime> clientModifiedAt,
  Value<String> modifiedDeviceId,
  Value<int> syncVersion,
  Value<int> rowid,
});

final class $$GoalsTableReferences
    extends BaseReferences<_$AppDatabase, $GoalsTable, GoalEntry> {
  $$GoalsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) =>
      db.workspaces.createAlias('goals__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$GoalsTableFilterComposer extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalsTableOrderingComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get colorHex => $composableBuilder(
    column: $table.colorHex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $GoalsTable> {
  $$GoalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get targetDate => $composableBuilder(
    column: $table.targetDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get colorHex =>
      $composableBuilder(column: $table.colorHex, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$GoalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $GoalsTable,
          GoalEntry,
          $$GoalsTableFilterComposer,
          $$GoalsTableOrderingComposer,
          $$GoalsTableAnnotationComposer,
          $$GoalsTableCreateCompanionBuilder,
          $$GoalsTableUpdateCompanionBuilder,
          (GoalEntry, $$GoalsTableReferences),
          GoalEntry,
          PrefetchHooks Function({bool workspaceId})
        > {
  $$GoalsTableTableManager(_$AppDatabase db, $GoalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$GoalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$GoalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$GoalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion(
                id: id,
                workspaceId: workspaceId,
                title: title,
                description: description,
                targetDate: targetDate,
                status: status,
                colorHex: colorHex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String title,
                Value<String?> description = const Value.absent(),
                Value<DateTime?> targetDate = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> colorHex = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => GoalsCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                title: title,
                description: description,
                targetDate: targetDate,
                status: status,
                colorHex: colorHex,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$GoalsTable, GoalEntry>(table),
                  $$GoalsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workspaceId,
                        referencedTable: $$GoalsTableReferences
                            ._workspaceIdTable(db),
                        referencedColumn: $$GoalsTableReferences
                            ._workspaceIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$GoalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $GoalsTable,
      GoalEntry,
      $$GoalsTableFilterComposer,
      $$GoalsTableOrderingComposer,
      $$GoalsTableAnnotationComposer,
      $$GoalsTableCreateCompanionBuilder,
      $$GoalsTableUpdateCompanionBuilder,
      (GoalEntry, $$GoalsTableReferences),
      GoalEntry,
      PrefetchHooks Function({bool workspaceId})
    >;
typedef $$JournalEntriesTableCreateCompanionBuilder =
    JournalEntriesCompanion Function({
      required String id,
      required String workspaceId,
      required String nodeId,
      required String journalDate,
      Value<String?> mood,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> clientModifiedAt,
      Value<String> modifiedDeviceId,
      Value<int> syncVersion,
      Value<int> rowid,
    });
typedef $$JournalEntriesTableUpdateCompanionBuilder =
    JournalEntriesCompanion Function({
      Value<String> id,
      Value<String> workspaceId,
      Value<String> nodeId,
      Value<String> journalDate,
      Value<String?> mood,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<DateTime?> deletedAt,
      Value<DateTime> clientModifiedAt,
      Value<String> modifiedDeviceId,
      Value<int> syncVersion,
      Value<int> rowid,
    });

final class $$JournalEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $JournalEntriesTable, JournalEntryData> {
  $$JournalEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkspacesTable _workspaceIdTable(_$AppDatabase db) => db.workspaces
      .createAlias('journal_entries__workspace_id__workspaces__id');

  $$WorkspacesTableProcessedTableManager get workspaceId {
    final $_column = $_itemColumn<String>('workspace_id')!;

    final manager = $$WorkspacesTableTableManager(
      $_db,
      $_db.workspaces,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workspaceIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $NodesTable _nodeIdTable(_$AppDatabase db) =>
      db.nodes.createAlias('journal_entries__node_id__nodes__id');

  $$NodesTableProcessedTableManager get nodeId {
    final $_column = $_itemColumn<String>('node_id')!;

    final manager = $$NodesTableTableManager(
      $_db,
      $_db.nodes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_nodeIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$JournalEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get journalDate => $composableBuilder(
    column: $table.journalDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkspacesTableFilterComposer get workspaceId {
    final $$WorkspacesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableFilterComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableFilterComposer get nodeId {
    final $$NodesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableFilterComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JournalEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get journalDate => $composableBuilder(
    column: $table.journalDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkspacesTableOrderingComposer get workspaceId {
    final $$WorkspacesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableOrderingComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableOrderingComposer get nodeId {
    final $$NodesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableOrderingComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JournalEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $JournalEntriesTable> {
  $$JournalEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get journalDate => $composableBuilder(
    column: $table.journalDate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get clientModifiedAt => $composableBuilder(
    column: $table.clientModifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get modifiedDeviceId => $composableBuilder(
    column: $table.modifiedDeviceId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get syncVersion => $composableBuilder(
    column: $table.syncVersion,
    builder: (column) => column,
  );

  $$WorkspacesTableAnnotationComposer get workspaceId {
    final $$WorkspacesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workspaceId,
      referencedTable: $db.workspaces,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkspacesTableAnnotationComposer(
            $db: $db,
            $table: $db.workspaces,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$NodesTableAnnotationComposer get nodeId {
    final $$NodesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.nodeId,
      referencedTable: $db.nodes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$NodesTableAnnotationComposer(
            $db: $db,
            $table: $db.nodes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$JournalEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $JournalEntriesTable,
          JournalEntryData,
          $$JournalEntriesTableFilterComposer,
          $$JournalEntriesTableOrderingComposer,
          $$JournalEntriesTableAnnotationComposer,
          $$JournalEntriesTableCreateCompanionBuilder,
          $$JournalEntriesTableUpdateCompanionBuilder,
          (JournalEntryData, $$JournalEntriesTableReferences),
          JournalEntryData,
          PrefetchHooks Function({bool workspaceId, bool nodeId})
        > {
  $$JournalEntriesTableTableManager(
    _$AppDatabase db,
    $JournalEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$JournalEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$JournalEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$JournalEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> workspaceId = const Value.absent(),
                Value<String> nodeId = const Value.absent(),
                Value<String> journalDate = const Value.absent(),
                Value<String?> mood = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalEntriesCompanion(
                id: id,
                workspaceId: workspaceId,
                nodeId: nodeId,
                journalDate: journalDate,
                mood: mood,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String workspaceId,
                required String nodeId,
                required String journalDate,
                Value<String?> mood = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<DateTime> clientModifiedAt = const Value.absent(),
                Value<String> modifiedDeviceId = const Value.absent(),
                Value<int> syncVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => JournalEntriesCompanion.insert(
                id: id,
                workspaceId: workspaceId,
                nodeId: nodeId,
                journalDate: journalDate,
                mood: mood,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                clientModifiedAt: clientModifiedAt,
                modifiedDeviceId: modifiedDeviceId,
                syncVersion: syncVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$JournalEntriesTable, JournalEntryData>(table),
                  $$JournalEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workspaceId = false, nodeId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workspaceId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.workspaceId,
                        referencedTable: $$JournalEntriesTableReferences
                            ._workspaceIdTable(db),
                        referencedColumn: $$JournalEntriesTableReferences
                            ._workspaceIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (nodeId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.nodeId,
                        referencedTable: $$JournalEntriesTableReferences
                            ._nodeIdTable(db),
                        referencedColumn: $$JournalEntriesTableReferences
                            ._nodeIdTable(db)
                            .id,
                      ) as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$JournalEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $JournalEntriesTable,
      JournalEntryData,
      $$JournalEntriesTableFilterComposer,
      $$JournalEntriesTableOrderingComposer,
      $$JournalEntriesTableAnnotationComposer,
      $$JournalEntriesTableCreateCompanionBuilder,
      $$JournalEntriesTableUpdateCompanionBuilder,
      (JournalEntryData, $$JournalEntriesTableReferences),
      JournalEntryData,
      PrefetchHooks Function({bool workspaceId, bool nodeId})
    >;
typedef $$SyncHistoryTableCreateCompanionBuilder =
    SyncHistoryCompanion Function({
      required String id,
      required DateTime syncStartedAt,
      Value<DateTime?> syncCompletedAt,
      required String syncType,
      required String status,
      Value<int> recordsExported,
      Value<int> recordsImported,
      Value<int> blobsTransferred,
      Value<String?> errorMessage,
      Value<int> rowid,
    });
typedef $$SyncHistoryTableUpdateCompanionBuilder =
    SyncHistoryCompanion Function({
      Value<String> id,
      Value<DateTime> syncStartedAt,
      Value<DateTime?> syncCompletedAt,
      Value<String> syncType,
      Value<String> status,
      Value<int> recordsExported,
      Value<int> recordsImported,
      Value<int> blobsTransferred,
      Value<String?> errorMessage,
      Value<int> rowid,
    });

class $$SyncHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $SyncHistoryTable> {
  $$SyncHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncStartedAt => $composableBuilder(
    column: $table.syncStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get syncCompletedAt => $composableBuilder(
    column: $table.syncCompletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncType => $composableBuilder(
    column: $table.syncType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordsExported => $composableBuilder(
    column: $table.recordsExported,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordsImported => $composableBuilder(
    column: $table.recordsImported,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get blobsTransferred => $composableBuilder(
    column: $table.blobsTransferred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncHistoryTable> {
  $$SyncHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncStartedAt => $composableBuilder(
    column: $table.syncStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get syncCompletedAt => $composableBuilder(
    column: $table.syncCompletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncType => $composableBuilder(
    column: $table.syncType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordsExported => $composableBuilder(
    column: $table.recordsExported,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordsImported => $composableBuilder(
    column: $table.recordsImported,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get blobsTransferred => $composableBuilder(
    column: $table.blobsTransferred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncHistoryTable> {
  $$SyncHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get syncStartedAt => $composableBuilder(
    column: $table.syncStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get syncCompletedAt => $composableBuilder(
    column: $table.syncCompletedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get syncType =>
      $composableBuilder(column: $table.syncType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get recordsExported => $composableBuilder(
    column: $table.recordsExported,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordsImported => $composableBuilder(
    column: $table.recordsImported,
    builder: (column) => column,
  );

  GeneratedColumn<int> get blobsTransferred => $composableBuilder(
    column: $table.blobsTransferred,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );
}

class $$SyncHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncHistoryTable,
          SyncHistoryEntry,
          $$SyncHistoryTableFilterComposer,
          $$SyncHistoryTableOrderingComposer,
          $$SyncHistoryTableAnnotationComposer,
          $$SyncHistoryTableCreateCompanionBuilder,
          $$SyncHistoryTableUpdateCompanionBuilder,
          (
            SyncHistoryEntry,
            BaseReferences<_$AppDatabase, $SyncHistoryTable, SyncHistoryEntry>,
          ),
          SyncHistoryEntry,
          PrefetchHooks Function()
        > {
  $$SyncHistoryTableTableManager(_$AppDatabase db, $SyncHistoryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncHistoryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> syncStartedAt = const Value.absent(),
                Value<DateTime?> syncCompletedAt = const Value.absent(),
                Value<String> syncType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> recordsExported = const Value.absent(),
                Value<int> recordsImported = const Value.absent(),
                Value<int> blobsTransferred = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncHistoryCompanion(
                id: id,
                syncStartedAt: syncStartedAt,
                syncCompletedAt: syncCompletedAt,
                syncType: syncType,
                status: status,
                recordsExported: recordsExported,
                recordsImported: recordsImported,
                blobsTransferred: blobsTransferred,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime syncStartedAt,
                Value<DateTime?> syncCompletedAt = const Value.absent(),
                required String syncType,
                required String status,
                Value<int> recordsExported = const Value.absent(),
                Value<int> recordsImported = const Value.absent(),
                Value<int> blobsTransferred = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncHistoryCompanion.insert(
                id: id,
                syncStartedAt: syncStartedAt,
                syncCompletedAt: syncCompletedAt,
                syncType: syncType,
                status: status,
                recordsExported: recordsExported,
                recordsImported: recordsImported,
                blobsTransferred: blobsTransferred,
                errorMessage: errorMessage,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SyncHistoryTable, SyncHistoryEntry>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $SyncHistoryTable,
                    SyncHistoryEntry
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncHistoryTable,
      SyncHistoryEntry,
      $$SyncHistoryTableFilterComposer,
      $$SyncHistoryTableOrderingComposer,
      $$SyncHistoryTableAnnotationComposer,
      $$SyncHistoryTableCreateCompanionBuilder,
      $$SyncHistoryTableUpdateCompanionBuilder,
      (
        SyncHistoryEntry,
        BaseReferences<_$AppDatabase, $SyncHistoryTable, SyncHistoryEntry>,
      ),
      SyncHistoryEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorkspacesTableTableManager get workspaces =>
      $$WorkspacesTableTableManager(_db, _db.workspaces);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
  $$NodeBlocksTableTableManager get nodeBlocks =>
      $$NodeBlocksTableTableManager(_db, _db.nodeBlocks);
  $$AttachmentsTableTableManager get attachments =>
      $$AttachmentsTableTableManager(_db, _db.attachments);
  $$InkDocumentsTableTableManager get inkDocuments =>
      $$InkDocumentsTableTableManager(_db, _db.inkDocuments);
  $$PdfDocumentsTableTableManager get pdfDocuments =>
      $$PdfDocumentsTableTableManager(_db, _db.pdfDocuments);
  $$InkPagesTableTableManager get inkPages =>
      $$InkPagesTableTableManager(_db, _db.inkPages);
  $$NodeLinksTableTableManager get nodeLinks =>
      $$NodeLinksTableTableManager(_db, _db.nodeLinks);
  $$TagsTableTableManager get tags => $$TagsTableTableManager(_db, _db.tags);
  $$NodeTagsTableTableManager get nodeTags =>
      $$NodeTagsTableTableManager(_db, _db.nodeTags);
  $$ProjectsTableTableManager get projects =>
      $$ProjectsTableTableManager(_db, _db.projects);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$CalendarEventsTableTableManager get calendarEvents =>
      $$CalendarEventsTableTableManager(_db, _db.calendarEvents);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$HabitLogsTableTableManager get habitLogs =>
      $$HabitLogsTableTableManager(_db, _db.habitLogs);
  $$GoalsTableTableManager get goals =>
      $$GoalsTableTableManager(_db, _db.goals);
  $$JournalEntriesTableTableManager get journalEntries =>
      $$JournalEntriesTableTableManager(_db, _db.journalEntries);
  $$SyncHistoryTableTableManager get syncHistory =>
      $$SyncHistoryTableTableManager(_db, _db.syncHistory);
}
