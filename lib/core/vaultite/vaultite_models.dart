enum VaultiteKind {
  note,
  idea,
  handwriting,
  notebook,
  sketch,
  journal;

  String toJson() => name;

  static VaultiteKind fromString(String? val) {
    if (val == null) return VaultiteKind.note;
    final lower = val.toLowerCase().trim();
    switch (lower) {
      case 'handwriting':
      case 'ink':
        return VaultiteKind.handwriting;
      case 'notebook':
        return VaultiteKind.notebook;
      case 'sketch':
      case 'drawing':
        return VaultiteKind.sketch;
      case 'idea':
        return VaultiteKind.idea;
      case 'journal':
      case 'daily':
        return VaultiteKind.journal;
      case 'note':
      default:
        return VaultiteKind.note;
    }
  }

  bool get isHandwritten =>
      this == VaultiteKind.handwriting ||
      this == VaultiteKind.notebook ||
      this == VaultiteKind.sketch;
}

enum VaultiteStatus {
  seed,
  exploring,
  parked,
  done;

  String toJson() => name;

  static VaultiteStatus? fromString(String? val) {
    if (val == null) return null;
    final lower = val.toLowerCase().trim();
    for (final s in VaultiteStatus.values) {
      if (s.name == lower) return s;
    }
    return null;
  }
}

class VaultiteLink {
  final String raw;
  final String target;
  final String? alias;
  final String? heading;
  final String? blockId;
  final bool isEmbed;
  final int line;
  final int start;
  final int end;

  const VaultiteLink({
    required this.raw,
    required this.target,
    this.alias,
    this.heading,
    this.blockId,
    this.isEmbed = false,
    this.line = 0,
    required this.start,
    required this.end,
  });

  String get displayText =>
      (alias != null && alias!.isNotEmpty) ? alias! : target;

  bool get isBlockRef => blockId != null && blockId!.isNotEmpty;
  bool get isHeadingRef => heading != null && heading!.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VaultiteLink &&
          runtimeType == other.runtimeType &&
          raw == other.raw &&
          target == other.target &&
          alias == other.alias &&
          heading == other.heading &&
          blockId == other.blockId &&
          isEmbed == other.isEmbed;

  @override
  int get hashCode =>
      raw.hashCode ^
      target.hashCode ^
      (alias?.hashCode ?? 0) ^
      (heading?.hashCode ?? 0) ^
      (blockId?.hashCode ?? 0) ^
      isEmbed.hashCode;

  @override
  String toString() =>
      'VaultiteLink(target: $target, isEmbed: $isEmbed, alias: $alias, heading: $heading, blockId: $blockId)';
}

class VaultiteBacklink {
  final String sourceNodeId;
  final String sourceTitle;
  final VaultiteKind sourceKind;
  final String contextLine;
  final bool isEmbed;
  final String? heading;
  final String? blockId;

  const VaultiteBacklink({
    required this.sourceNodeId,
    required this.sourceTitle,
    required this.sourceKind,
    required this.contextLine,
    this.isEmbed = false,
    this.heading,
    this.blockId,
  });
}

class VaultiteMention {
  final String sourceNodeId;
  final String sourceTitle;
  final VaultiteKind sourceKind;
  final String contextLine;
  final String matchedText;

  const VaultiteMention({
    required this.sourceNodeId,
    required this.sourceTitle,
    required this.sourceKind,
    required this.contextLine,
    required this.matchedText,
  });
}

class VaultiteItem {
  final String id;
  final String title;
  final String path;
  final VaultiteKind kind;
  final VaultiteStatus? status;
  final List<String> tags;
  final List<String> aliases;
  final DateTime? created;
  final DateTime? updated;
  final String? source; // AI provenance e.g. "human", "claude", "agent"
  final Map<String, dynamic> properties;
  final String body;
  final String? handwritingDocumentId;
  final int? pageCount;

  const VaultiteItem({
    required this.id,
    required this.title,
    required this.path,
    this.kind = VaultiteKind.note,
    this.status,
    this.tags = const [],
    this.aliases = const [],
    this.created,
    this.updated,
    this.source,
    this.properties = const {},
    this.body = '',
    this.handwritingDocumentId,
    this.pageCount,
  });

  bool get isHandwritten => kind.isHandwritten || handwritingDocumentId != null;

  VaultiteItem copyWith({
    String? id,
    String? title,
    String? path,
    VaultiteKind? kind,
    VaultiteStatus? status,
    List<String>? tags,
    List<String>? aliases,
    DateTime? created,
    DateTime? updated,
    String? source,
    Map<String, dynamic>? properties,
    String? body,
    String? handwritingDocumentId,
    int? pageCount,
  }) {
    return VaultiteItem(
      id: id ?? this.id,
      title: title ?? this.title,
      path: path ?? this.path,
      kind: kind ?? this.kind,
      status: status ?? this.status,
      tags: tags ?? this.tags,
      aliases: aliases ?? this.aliases,
      created: created ?? this.created,
      updated: updated ?? this.updated,
      source: source ?? this.source,
      properties: properties ?? this.properties,
      body: body ?? this.body,
      handwritingDocumentId:
          handwritingDocumentId ?? this.handwritingDocumentId,
      pageCount: pageCount ?? this.pageCount,
    );
  }
}
