import 'package:atlas/features/documents/domain/parser/wiki_link_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WikiLinkParser', () {
    test('extracts standard [[Note Title]] wiki-links', () {
      const text = 'Check out [[Design Systems]] and [[Milestone 3 Roadmap]].';
      final matches = WikiLinkParser.extractLinks(text);

      expect(matches.length, 2);
      expect(matches[0].targetTitle, 'Design Systems');
      expect(matches[0].displayText, 'Design Systems');
      expect(matches[0].raw, '[[Design Systems]]');
      expect(matches[0].start, 10);
      expect(matches[0].end, 28);

      expect(matches[1].targetTitle, 'Milestone 3 Roadmap');
      expect(matches[1].displayText, 'Milestone 3 Roadmap');
    });

    test('extracts [[Target|Alias]] wiki-links with custom display text', () {
      const text = 'Refer to [[Project Atlas Architecture|Atlas Arch]] for details.';
      final matches = WikiLinkParser.extractLinks(text);

      expect(matches.length, 1);
      expect(matches[0].targetTitle, 'Project Atlas Architecture');
      expect(matches[0].displayText, 'Atlas Arch');
      expect(matches[0].raw, '[[Project Atlas Architecture|Atlas Arch]]');
    });

    test('handles whitespace trimming inside brackets', () {
      const text = 'Look at [[   Trimmed Note   |   Custom Label   ]].';
      final matches = WikiLinkParser.extractLinks(text);

      expect(matches.length, 1);
      expect(matches[0].targetTitle, 'Trimmed Note');
      expect(matches[0].displayText, 'Custom Label');
    });

    test('ignores empty or malformed brackets', () {
      const text = 'Empty [[]] or single [Link] or unclosed [[Unclosed Note.';
      final matches = WikiLinkParser.extractLinks(text);

      expect(matches, isEmpty);
    });

    test('extractTargetTitles returns unique set of target titles', () {
      const text = '[[Atlas]] is great. Read [[Atlas]] again, and [[Overview]].';
      final titles = WikiLinkParser.extractTargetTitles(text);

      expect(titles, {'Atlas', 'Overview'});
    });

    test('detectOpenQuery identifies uncompleted query at cursor position', () {
      expect(WikiLinkParser.detectOpenQuery('Hello [[Pro', 11), 'Pro');
      expect(WikiLinkParser.detectOpenQuery('Hello [[', 8), '');
      expect(WikiLinkParser.detectOpenQuery('Hello [[Closed]] and more', 16), null);
      expect(WikiLinkParser.detectOpenQuery('Hello world', 5), null);
      expect(WikiLinkParser.detectOpenQuery('Hello [[Line\nBreak', 15), null);
    });
  });
}
