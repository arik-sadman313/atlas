class WikiLinkMatch {
  final String raw;
  final String targetTitle;
  final String displayText;
  final int start;
  final int end;

  const WikiLinkMatch({
    required this.raw,
    required this.targetTitle,
    required this.displayText,
    required this.start,
    required this.end,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WikiLinkMatch &&
          runtimeType == other.runtimeType &&
          raw == other.raw &&
          targetTitle == other.targetTitle &&
          displayText == other.displayText &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode =>
      raw.hashCode ^
      targetTitle.hashCode ^
      displayText.hashCode ^
      start.hashCode ^
      end.hashCode;

  @override
  String toString() =>
      'WikiLinkMatch(raw: $raw, target: $targetTitle, display: $displayText, $start..$end)';
}

class WikiLinkParser {
  /// Regular expression matching Obsidian/Roam-style wiki-links:
  /// `[[Target Note]]` or `[[Target Note|Custom Display Text]]`
  static final RegExp wikiLinkPattern = RegExp(
    r'\[\[([^\[\]\|\r\n]+)(?:\|([^\[\]\r\n]+))?\]\]',
  );

  /// Extracts all valid [WikiLinkMatch] instances from the given [text].
  static List<WikiLinkMatch> extractLinks(String text) {
    if (text.isEmpty) return const [];

    final matches = <WikiLinkMatch>[];
    for (final m in wikiLinkPattern.allMatches(text)) {
      final raw = m.group(0)!;
      final target = m.group(1)?.trim() ?? '';
      if (target.isEmpty) continue;

      final alias = m.group(2)?.trim();
      final display = (alias != null && alias.isNotEmpty) ? alias : target;

      matches.add(
        WikiLinkMatch(
          raw: raw,
          targetTitle: target,
          displayText: display,
          start: m.start,
          end: m.end,
        ),
      );
    }
    return matches;
  }

  /// Extracts a unique set of trimmed target titles from [text].
  static Set<String> extractTargetTitles(String text) {
    if (text.isEmpty) return const {};
    final links = extractLinks(text);
    return links.map((l) => l.targetTitle).toSet();
  }

  /// Checks if [text] ends with an open `[[` trigger that is currently being typed
  /// and returns the uncompleted query string, or null if not currently typing a wiki link.
  /// Example: "Hello [[Pro" -> "Pro"
  /// Example: "Hello [[Project X]]" -> null
  static String? detectOpenQuery(String text, int cursorPosition) {
    if (cursorPosition <= 0 || cursorPosition > text.length) return null;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastDoubleBracket = textBeforeCursor.lastIndexOf('[[');
    if (lastDoubleBracket == -1) return null;

    final afterDoubleBracket = textBeforeCursor.substring(lastDoubleBracket + 2);
    // If there is a closing bracket or newline between [[ and cursor, it's closed or invalid
    if (afterDoubleBracket.contains(']]') ||
        afterDoubleBracket.contains('\n') ||
        afterDoubleBracket.contains('\r')) {
      return null;
    }

    return afterDoubleBracket;
  }
}
