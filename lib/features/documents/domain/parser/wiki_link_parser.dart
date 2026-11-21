import '../../../../core/vaultite/vaultite_link_parser.dart';

class WikiLinkMatch {
  final String raw;
  final String targetTitle;
  final String displayText;
  final int start;
  final int end;
  final String? heading;
  final String? blockId;
  final bool isEmbed;

  const WikiLinkMatch({
    required this.raw,
    required this.targetTitle,
    required this.displayText,
    required this.start,
    required this.end,
    this.heading,
    this.blockId,
    this.isEmbed = false,
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
          end == other.end &&
          heading == other.heading &&
          blockId == other.blockId &&
          isEmbed == other.isEmbed;

  @override
  int get hashCode =>
      raw.hashCode ^
      targetTitle.hashCode ^
      displayText.hashCode ^
      start.hashCode ^
      end.hashCode ^
      (heading?.hashCode ?? 0) ^
      (blockId?.hashCode ?? 0) ^
      isEmbed.hashCode;

  @override
  String toString() =>
      'WikiLinkMatch(raw: $raw, target: $targetTitle, display: $displayText, $start..$end)';
}

class WikiLinkParser {
  /// Regular expression matching Obsidian/Vaultite-style wiki-links:
  /// `[[Target Note]]` or `[[Target Note|Custom Display Text]]`
  static final RegExp wikiLinkPattern = VaultiteLinkParser.linkPattern;

  /// Extracts all valid [WikiLinkMatch] instances from the given [text].
  static List<WikiLinkMatch> extractLinks(String text) {
    final vLinks = VaultiteLinkParser.extractLinks(text);
    return vLinks.map((vl) {
      return WikiLinkMatch(
        raw: vl.raw,
        targetTitle: vl.target,
        displayText: vl.displayText,
        start: vl.start,
        end: vl.end,
        heading: vl.heading,
        blockId: vl.blockId,
        isEmbed: vl.isEmbed,
      );
    }).toList();
  }

  /// Extracts a unique set of trimmed target titles from [text].
  static Set<String> extractTargetTitles(String text) {
    return VaultiteLinkParser.extractTargetTitles(text);
  }

  /// Checks if [text] ends with an open `[[` trigger that is currently being typed
  /// and returns the uncompleted query string, or null if not currently typing a wiki link.
  /// Example: "Hello [[Pro" -> "Pro"
  /// Example: "Hello [[Project X]]" -> null
  static String? detectOpenQuery(String text, int cursorPosition) {
    final detected = VaultiteLinkParser.detectOpenQuery(text, cursorPosition);
    return detected?.query;
  }
}
