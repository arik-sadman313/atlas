class VaultTab {
  final String id;
  final String nodeId;
  final String title;
  final String type; // 'document' or 'notebook'
  final String path;
  final bool isDirty;

  const VaultTab({
    required this.id,
    required this.nodeId,
    required this.title,
    required this.type,
    required this.path,
    this.isDirty = false,
  });

  bool get isNotebook => type == 'notebook';
  bool get isDocument => type == 'document';

  VaultTab copyWith({
    String? title,
    String? path,
    bool? isDirty,
  }) {
    return VaultTab(
      id: id,
      nodeId: nodeId,
      title: title ?? this.title,
      type: type,
      path: path ?? this.path,
      isDirty: isDirty ?? this.isDirty,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultTab &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          nodeId == other.nodeId &&
          type == other.type &&
          isDirty == other.isDirty;

  @override
  int get hashCode => Object.hash(id, nodeId, type, isDirty);
}
