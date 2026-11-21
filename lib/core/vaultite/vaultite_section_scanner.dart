/// Information about a Markdown section heading.
class VaultiteHeading {
  final int level;
  final String text;
  final int line;

  const VaultiteHeading({
    required this.level,
    required this.text,
    required this.line,
  });

  @override
  String toString() => 'VaultiteHeading(H$level: "$text" at line $line)';
}

/// Information about a block anchor in Markdown (`^block-id`).
class VaultiteBlockRef {
  final String blockId;
  final String lineText;
  final int line;

  const VaultiteBlockRef({
    required this.blockId,
    required this.lineText,
    required this.line,
  });

  @override
  String toString() => 'VaultiteBlockRef(^$blockId at line $line)';
}

/// Scanner for headings, block anchors, and inline `#tags` in Markdown.
class VaultiteSectionScanner {
  static final RegExp headingPattern = RegExp(
    r'^ {0,3}(#{1,6})[ \t]+(.*?)(?:[ \t]+#+)?[ \t]*$',
  );
  static final RegExp blockIdPattern = RegExp(
    r'(?:^|[ \t])\^([A-Za-z0-9-]+)[ \t]*$',
  );
  static final RegExp inlineTagPattern = RegExp(
    r'(?:^|[ \t])#([a-zA-Z0-9_\-]+(?:\/[a-zA-Z0-9_\-]+)*)\b',
  );
  static final RegExp codeFencePattern = RegExp(r'^\s*(`{3,}|~{3,})');

  /// Scans [text] and returns all headings, block references, and inline tags.
  static ({
    List<VaultiteHeading> headings,
    List<VaultiteBlockRef> blockRefs,
    Set<String> inlineTags,
  })
  scan(String text) {
    final headings = <VaultiteHeading>[];
    final blockRefs = <VaultiteBlockRef>[];
    final tags = <String>{};

    if (text.isEmpty) {
      return (headings: headings, blockRefs: blockRefs, inlineTags: tags);
    }

    final lines = text.split('\n');
    String? currentFence;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final fenceMatch = codeFencePattern.firstMatch(line);

      if (fenceMatch != null) {
        final fenceDelim = fenceMatch.group(1)!;
        if (currentFence == null) {
          currentFence = fenceDelim[0];
        } else if (fenceDelim[0] == currentFence[0]) {
          currentFence = null;
        }
        continue;
      }

      if (currentFence != null) continue; // inside code block

      // 1. Heading check
      final headingMatch = headingPattern.firstMatch(line);
      if (headingMatch != null) {
        final level = headingMatch.group(1)!.length;
        final title = headingMatch.group(2)!.trim();
        headings.add(VaultiteHeading(level: level, text: title, line: i));
      }

      // 2. Block ID anchor check (^block-id at end of line)
      final blockMatch = blockIdPattern.firstMatch(line);
      if (blockMatch != null) {
        final id = blockMatch.group(1)!;
        blockRefs.add(VaultiteBlockRef(blockId: id, lineText: line, line: i));
      }

      // 3. Inline tag check (e.g. #productivity, #project/alpha)
      // Must not match headings (headings start with # )
      if (headingMatch == null) {
        for (final tm in inlineTagPattern.allMatches(line)) {
          final tag = tm.group(1)?.trim();
          if (tag != null &&
              tag.isNotEmpty &&
              !tag.startsWith(RegExp(r'^[0-9]+$'))) {
            tags.add(tag);
          }
        }
      }
    }

    return (headings: headings, blockRefs: blockRefs, inlineTags: tags);
  }
}
