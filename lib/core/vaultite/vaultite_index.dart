import 'vaultite_link_parser.dart';
import 'vaultite_models.dart';
import 'vaultite_section_scanner.dart';

/// In-memory graph and knowledge index for Vaultite.
///
/// Indexes:
/// - Vault items (Markdown notes, handwritten notebooks, sketches).
/// - Path, title, and alias resolution.
/// - Bidirectional links (Forward links & Backlinks).
/// - Unlinked mentions across notes.
/// - Tags taxonomy.
class VaultiteIndex {
  final Map<String, VaultiteItem> _items = {};
  final Map<String, List<VaultiteLink>> _forwardLinks = {};
  final Map<String, List<VaultiteBacklink>> _backlinks = {};
  final Map<String, Set<String>> _tagsToItemIds = {};

  /// All indexed items.
  List<VaultiteItem> get items => _items.values.toList();

  /// Total count of items in the vault.
  int get count => _items.length;

  /// Clear all index entries.
  void clear() {
    _items.clear();
    _forwardLinks.clear();
    _backlinks.clear();
    _tagsToItemIds.clear();
  }

  /// Registers or updates a [VaultiteItem] in the index and rebuilds its link graph.
  void registerItem(VaultiteItem item) {
    _items[item.id] = item;
    _rebuildGraph();
  }

  /// Removes an item by [id] from the index.
  void removeItem(String id) {
    _items.remove(id);
    _rebuildGraph();
  }

  /// Bulk indexes a list of [items].
  void setAll(List<VaultiteItem> items) {
    _items.clear();
    for (final it in items) {
      _items[it.id] = it;
    }
    _rebuildGraph();
  }

  /// Rebuilds the forward link and backlink graph across all registered items.
  void _rebuildGraph() {
    _forwardLinks.clear();
    _backlinks.clear();
    _tagsToItemIds.clear();

    // 1. Extract forward links and tags for each item
    for (final item in _items.values) {
      final links = VaultiteLinkParser.extractLinks(item.body);
      _forwardLinks[item.id] = links;

      final scanResult = VaultiteSectionScanner.scan(item.body);
      final combinedTags = <String>{...item.tags, ...scanResult.inlineTags};

      for (final tag in combinedTags) {
        _tagsToItemIds.putIfAbsent(tag, () => <String>{}).add(item.id);
      }
    }

    // 2. Resolve links to targets and populate backlinks
    for (final source in _items.values) {
      final outgoing = _forwardLinks[source.id] ?? const [];

      for (final link in outgoing) {
        final targetItem = resolve(link.target, fromPath: source.path);
        if (targetItem != null) {
          final lines = source.body.split('\n');
          final contextLine = link.line < lines.length
              ? lines[link.line].trim()
              : source.title;

          final backlink = VaultiteBacklink(
            sourceNodeId: source.id,
            sourceTitle: source.title,
            sourceKind: source.kind,
            contextLine: contextLine,
            isEmbed: link.isEmbed,
            heading: link.heading,
            blockId: link.blockId,
          );

          _backlinks.putIfAbsent(targetItem.id, () => []).add(backlink);
        }
      }
    }
  }

  /// Resolves a link [target] (e.g. `[[Architecture]]` or `[[notes/ideas]]` or `[[alias]]`)
  /// to the matching [VaultiteItem], if any.
  VaultiteItem? resolve(String target, {String? fromPath}) {
    final cleanTarget = target
        .split('#')
        .first
        .split('^')
        .first
        .trim()
        .toLowerCase();
    if (cleanTarget.isEmpty) return null;

    // 1. Direct ID match
    if (_items.containsKey(cleanTarget)) {
      return _items[cleanTarget];
    }

    // 2. Exact or lowercase path match
    for (final it in _items.values) {
      final p = it.path.toLowerCase();
      if (p == cleanTarget || p == '$cleanTarget.md') {
        return it;
      }
    }

    // 3. Exact or lowercase title match
    for (final it in _items.values) {
      if (it.title.toLowerCase() == cleanTarget) {
        return it;
      }
    }

    // 4. Alias match
    for (final it in _items.values) {
      for (final alias in it.aliases) {
        if (alias.toLowerCase() == cleanTarget) {
          return it;
        }
      }
    }

    // 5. Basename without directory match
    for (final it in _items.values) {
      final base = it.path
          .split('/')
          .last
          .replaceAll(RegExp(r'\.md$', caseSensitive: false), '');
      if (base.toLowerCase() == cleanTarget) {
        return it;
      }
    }

    return null;
  }

  /// Retrieves a VaultiteItem by its ID.
  VaultiteItem? getItem(String id) => _items[id];

  /// Index operator shorthand for [getItem].
  VaultiteItem? operator [](String id) => _items[id];

  /// Returns all forward links originating from [nodeId].
  List<VaultiteLink> getForwardLinks(String nodeId) {
    return _forwardLinks[nodeId] ?? const [];
  }

  /// Returns all backlinks pointing to [nodeId].
  List<VaultiteBacklink> getBacklinks(String nodeId) {
    return _backlinks[nodeId] ?? const [];
  }

  /// Finds unlinked mentions of [targetId] in other vault notes.
  /// An unlinked mention is an appearance of the note's title or alias in prose
  /// that is not enclosed within `[[...]]`.
  List<VaultiteMention> getUnlinkedMentions(String targetId) {
    final target = _items[targetId];
    if (target == null) return const [];

    final targetNames = <String>{
      target.title,
      ...target.aliases,
    }.where((s) => s.trim().length >= 3).toList();

    if (targetNames.isEmpty) return const [];

    final mentions = <VaultiteMention>[];

    for (final source in _items.values) {
      if (source.id == targetId) continue;

      // Extract existing linked targets in this source to avoid duplicate reports
      final linkedTargets = (_forwardLinks[source.id] ?? const [])
          .map((l) => l.target.toLowerCase())
          .toSet();

      final lines = source.body.split('\n');

      for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
        final line = lines[lineIndex];
        if (line.trim().isEmpty) continue;

        for (final name in targetNames) {
          if (line.toLowerCase().contains(name.toLowerCase())) {
            // Ensure not already bracketed in [[name]]
            final bracketed = '[[${name.toLowerCase()}';
            if (!line.toLowerCase().contains(bracketed) &&
                !linkedTargets.contains(name.toLowerCase())) {
              mentions.add(
                VaultiteMention(
                  sourceNodeId: source.id,
                  sourceTitle: source.title,
                  sourceKind: source.kind,
                  contextLine: line.trim(),
                  matchedText: name,
                ),
              );
              break; // one mention per line is sufficient
            }
          }
        }
      }
    }

    return mentions;
  }

  /// Returns all unique tags found across frontmatter and inline text.
  Set<String> getAllTags() => _tagsToItemIds.keys.toSet();

  /// Gets all items with [tag].
  List<VaultiteItem> getItemsByTag(String tag) {
    final cleanTag = tag.replaceAll('#', '').trim();
    final ids = _tagsToItemIds[cleanTag] ?? const {};
    return ids.map((id) => _items[id]).whereType<VaultiteItem>().toList();
  }

  /// Searches items by query across titles, tags, and content snippets.
  List<VaultiteItem> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return items;

    return items.where((it) {
      if (it.title.toLowerCase().contains(q)) return true;
      if (it.tags.any((t) => t.toLowerCase().contains(q))) return true;
      if (it.aliases.any((a) => a.toLowerCase().contains(q))) return true;
      if (it.body.toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }
}
