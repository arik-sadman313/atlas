import 'vaultite_models.dart';

/// Full Obsidian & Vaultite link and embed parser.
///
/// Supports:
/// - Standard wiki links: `[[Target]]`
/// - Aliased links: `[[Target|Custom Display]]`
/// - Section/Heading anchors: `[[Target#Section]]` or `[[Target#Section|Alias]]`
/// - Block references: `[[Target#^block_id]]` or `[[Target#^block_id|Alias]]`
/// - Embeds: `![[Target]]`, `![[Notebook#Page 1]]`, `![[Drawing]]`
/// - Markdown image links: `![alt](image.png)`
/// - Code fence exclusion (ignores links inside code blocks and inline code).
class VaultiteLinkParser {
  /// Regular expression matching Obsidian / Vaultite links & embeds:
  /// Group 1: `!` if embed
  /// Group 2: Target note / file path
  /// Group 3: Optional `#heading` or `#^block`
  /// Group 4: Optional `|alias`
  static final RegExp linkPattern = RegExp(
    r'(!)?\[\[([^\[\]\r\n|#^]+)(?:#(\^?[^\[\]\r\n|]+))?(?:\|([^\[\]\r\n]+))?\]\]',
  );

  /// Matches inline code spans: `...`
  static final RegExp inlineCodePattern = RegExp(r'`+[^`\r\n]+`+');

  /// Code fence opening or closing pattern: ``` or ~~~
  static final RegExp codeFencePattern = RegExp(r'^\s*(`{3,}|~{3,})');

  /// Extracts all [VaultiteLink] instances from [text], excluding code fences.
  static List<VaultiteLink> extractLinks(String text) {
    if (text.isEmpty || (!text.contains('[[') && !text.contains('!['))) {
      return const [];
    }

    final links = <VaultiteLink>[];
    final lines = text.split('\n');

    String? currentFence;
    int lineStartOffset = 0;

    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      final fenceMatch = codeFencePattern.firstMatch(line);

      // Check code fence toggle
      if (fenceMatch != null) {
        final fenceDelim = fenceMatch.group(1)!;
        if (currentFence == null) {
          currentFence = fenceDelim[0]; // '`' or '~'
        } else if (fenceDelim[0] == currentFence[0]) {
          currentFence = null; // Closed fence
        }
        lineStartOffset += line.length + 1;
        continue;
      }

      // If inside code fence, skip searching for links in this line
      if (currentFence != null) {
        lineStartOffset += line.length + 1;
        continue;
      }

      // Find inline code spans to exclude
      final inlineCodeSpans = <(int, int)>[];
      for (final m in inlineCodePattern.allMatches(line)) {
        inlineCodeSpans.add((m.start, m.end));
      }

      // Find all wiki links in current line
      for (final match in linkPattern.allMatches(line)) {
        // Verify not inside inline code
        final inCode = inlineCodeSpans.any(
          (span) => match.start >= span.$1 && match.end <= span.$2,
        );
        if (inCode) continue;

        final isEmbed = match.group(1) == '!';
        final target = match.group(2)?.trim() ?? '';
        if (target.isEmpty) continue;

        final anchor = match.group(3)?.trim();
        String? heading;
        String? blockId;

        if (anchor != null && anchor.isNotEmpty) {
          if (anchor.startsWith('^')) {
            blockId = anchor.substring(1);
          } else {
            heading = anchor;
          }
        }

        final alias = match.group(4)?.trim();

        links.add(
          VaultiteLink(
            raw: match.group(0)!,
            target: target,
            alias: alias,
            heading: heading,
            blockId: blockId,
            isEmbed: isEmbed,
            line: lineIndex,
            start: lineStartOffset + match.start,
            end: lineStartOffset + match.end,
          ),
        );
      }

      lineStartOffset += line.length + 1;
    }

    return links;
  }

  /// Extracts unique target names/titles from [text].
  static Set<String> extractTargetTitles(String text) {
    if (text.isEmpty) return const {};
    final links = extractLinks(text);
    return links.map((l) => l.target).toSet();
  }

  /// Extracts only embedded notebook / sketch links from [text].
  /// Matches `![[Notebook Title]]` or `![[Notebook Title#Page 2]]`.
  static List<VaultiteLink> extractEmbeds(String text) {
    return extractLinks(text).where((l) => l.isEmbed).toList();
  }

  /// Checks if [text] before [cursorPosition] ends with an open `[[` or `![[` trigger
  /// and returns the uncompleted query string, or null if not currently typing a link.
  static ({String query, bool isEmbed})? detectOpenQuery(
    String text,
    int cursorPosition,
  ) {
    if (cursorPosition <= 0 || cursorPosition > text.length) return null;
    final textBeforeCursor = text.substring(0, cursorPosition);
    final lastDoubleBracket = textBeforeCursor.lastIndexOf('[[');
    if (lastDoubleBracket == -1) return null;

    final afterDoubleBracket = textBeforeCursor.substring(
      lastDoubleBracket + 2,
    );
    // If there is a closing bracket or newline between [[ and cursor, it's closed or invalid
    if (afterDoubleBracket.contains(']]') ||
        afterDoubleBracket.contains('\n') ||
        afterDoubleBracket.contains('\r')) {
      return null;
    }

    final isEmbed =
        lastDoubleBracket > 0 && textBeforeCursor[lastDoubleBracket - 1] == '!';

    return (query: afterDoubleBracket, isEmbed: isEmbed);
  }
}
