import 'package:atlas/core/vaultite/vaultite_section_scanner.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VaultiteSectionScanner', () {
    test('extracts ATX headings with levels and line indices', () {
      const text = '''
# Main Header
Paragraph here.
## Sub Section A
Content A.
### Detailed Spec
More info.
''';
      final scan = VaultiteSectionScanner.scan(text);

      expect(scan.headings.length, 3);
      expect(scan.headings[0].level, 1);
      expect(scan.headings[0].text, 'Main Header');
      expect(scan.headings[0].line, 0);

      expect(scan.headings[1].level, 2);
      expect(scan.headings[1].text, 'Sub Section A');
      expect(scan.headings[1].line, 2);

      expect(scan.headings[2].level, 3);
      expect(scan.headings[2].text, 'Detailed Spec');
      expect(scan.headings[2].line, 4);
    });

    test('extracts block reference anchors ^block-id', () {
      const text = '''
Key finding from research ^finding-1
Another regular paragraph.
Specific conclusion sentence. ^conclusion-alpha
''';
      final scan = VaultiteSectionScanner.scan(text);

      expect(scan.blockRefs.length, 2);
      expect(scan.blockRefs[0].blockId, 'finding-1');
      expect(scan.blockRefs[0].line, 0);

      expect(scan.blockRefs[1].blockId, 'conclusion-alpha');
      expect(scan.blockRefs[1].line, 2);
    });

    test('extracts inline tags and nested tags', () {
      const text = '''
This note relates to #productivity and #deep-work.
Nested tag example: #project/alpha/milestone-1.
```python
# this is a python comment, not an inline tag
```
''';
      final scan = VaultiteSectionScanner.scan(text);

      expect(scan.inlineTags, contains('productivity'));
      expect(scan.inlineTags, contains('deep-work'));
      expect(scan.inlineTags, contains('project/alpha/milestone-1'));
      expect(scan.inlineTags.length, 3);
    });
  });
}
