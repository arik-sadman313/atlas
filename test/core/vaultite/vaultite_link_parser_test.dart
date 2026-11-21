import 'package:atlas/core/vaultite/vaultite_link_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VaultiteLinkParser', () {
    test('extracts heading anchors and aliases [[Note#Heading|Alias]]', () {
      const text =
          'See [[Architecture Guide#Data Storage|Storage Layer]] for details.';
      final links = VaultiteLinkParser.extractLinks(text);

      expect(links.length, 1);
      final l = links.first;
      expect(l.target, 'Architecture Guide');
      expect(l.heading, 'Data Storage');
      expect(l.alias, 'Storage Layer');
      expect(l.displayText, 'Storage Layer');
      expect(l.isHeadingRef, isTrue);
      expect(l.isEmbed, isFalse);
    });

    test('extracts block references [[Note#^block-123]]', () {
      const text = 'Quoting paragraph [[Meeting Notes#^summary-point]].';
      final links = VaultiteLinkParser.extractLinks(text);

      expect(links.length, 1);
      final l = links.first;
      expect(l.target, 'Meeting Notes');
      expect(l.blockId, 'summary-point');
      expect(l.isBlockRef, isTrue);
    });

    test('extracts embeds ![[Notebook Name#Page 1]] and ![[Sketch]]', () {
      const text = '''
Here is the inline drawing:
![[Architecture Notebook#Page 1]]
And an embedded note:
![[Summary Note]]
''';
      final links = VaultiteLinkParser.extractLinks(text);
      expect(links.length, 2);

      expect(links[0].target, 'Architecture Notebook');
      expect(links[0].heading, 'Page 1');
      expect(links[0].isEmbed, isTrue);

      expect(links[1].target, 'Summary Note');
      expect(links[1].isEmbed, isTrue);

      final embeds = VaultiteLinkParser.extractEmbeds(text);
      expect(embeds.length, 2);
    });

    test('ignores links inside code blocks and inline code spans', () {
      const text = '''
Here is valid [[Outside Link]].

```dart
// Code block should not parse [[Fake Link]]
final x = "[[Not A Link]]";
```

Also `inline code with [[Ignored Link]]` should be ignored.

Back to valid [[Final Link]].
''';
      final links = VaultiteLinkParser.extractLinks(text);

      expect(links.length, 2);
      expect(links[0].target, 'Outside Link');
      expect(links[1].target, 'Final Link');
    });

    test('detectOpenQuery distinguishes regular link from embed trigger', () {
      final normal = VaultiteLinkParser.detectOpenQuery('Check out [[Proj', 16);
      expect(normal, isNotNull);
      expect(normal!.query, 'Proj');
      expect(normal.isEmbed, isFalse);

      final embed = VaultiteLinkParser.detectOpenQuery('Embed ![[Draw', 13);
      expect(embed, isNotNull);
      expect(embed!.query, 'Draw');
      expect(embed.isEmbed, isTrue);
    });
  });
}
