import 'package:atlas/core/vaultite/vaultite_index.dart';
import 'package:atlas/core/vaultite/vaultite_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VaultiteIndex', () {
    test(
      'resolves items by exact title, alias, path, and case-insensitively',
      () {
        final index = VaultiteIndex();

        final note1 = VaultiteItem(
          id: 'note_arch',
          title: 'System Architecture',
          path: 'System Architecture.md',
          aliases: const ['SysArch', 'Architecture Doc'],
          body: 'Core foundations.',
        );

        final notebook1 = VaultiteItem(
          id: 'nb_sketches',
          title: 'Hardware Sketches',
          path: 'Hardware Sketches.atlas.md',
          kind: VaultiteKind.notebook,
          aliases: const ['Sketches'],
          body: 'Handwritten notes on circuits.',
        );

        index.setAll([note1, notebook1]);

        // Exact title
        expect(index.resolve('System Architecture')?.id, 'note_arch');

        // Lowercase title
        expect(index.resolve('system architecture')?.id, 'note_arch');

        // Alias
        expect(index.resolve('SysArch')?.id, 'note_arch');
        expect(index.resolve('Architecture Doc')?.id, 'note_arch');

        // Handwritten Notebook by title & alias
        expect(index.resolve('Hardware Sketches')?.id, 'nb_sketches');
        expect(index.resolve('Sketches')?.id, 'nb_sketches');

        // With heading anchor
        expect(index.resolve('System Architecture#Storage')?.id, 'note_arch');
      },
    );

    test('rebuilds bidirectional link graph between notes and handwritten notebooks', () {
      final index = VaultiteIndex();

      final docA = VaultiteItem(
        id: 'doc_a',
        title: 'Project Roadmap',
        path: 'Project Roadmap.md',
        body: '''
Discussing milestones.
See [[Hardware Sketches]] for initial designs.
Also check [[Backend Spec#API]].
''',
      );

      final notebookB = VaultiteItem(
        id: 'nb_b',
        title: 'Hardware Sketches',
        path: 'Hardware Sketches.atlas.md',
        kind: VaultiteKind.notebook,
        body: 'Handwritten sticky note pointing to [[Project Roadmap]].',
      );

      final docC = VaultiteItem(
        id: 'doc_c',
        title: 'Backend Spec',
        path: 'Backend Spec.md',
        body: '# API\nREST and gRPC endpoints.',
      );

      index.setAll([docA, notebookB, docC]);

      // Forward links from docA
      final forwardA = index.getForwardLinks('doc_a');
      expect(forwardA.length, 2);
      expect(forwardA.map((l) => l.target), contains('Hardware Sketches'));
      expect(forwardA.map((l) => l.target), contains('Backend Spec'));

      // Backlinks to Hardware Sketches (should include docA)
      final backlinksToNotebook = index.getBacklinks('nb_b');
      expect(backlinksToNotebook.length, 1);
      expect(backlinksToNotebook.first.sourceNodeId, 'doc_a');
      expect(backlinksToNotebook.first.sourceTitle, 'Project Roadmap');

      // Backlinks to Project Roadmap (should include notebookB!)
      final backlinksToDocA = index.getBacklinks('doc_a');
      expect(backlinksToDocA.length, 1);
      expect(backlinksToDocA.first.sourceNodeId, 'nb_b');
      expect(backlinksToDocA.first.sourceTitle, 'Hardware Sketches');
      expect(backlinksToDocA.first.sourceKind, VaultiteKind.notebook);
    });

    test('detects unlinked mentions of note titles in prose', () {
      final index = VaultiteIndex();

      final docConcept = VaultiteItem(
        id: 'doc_concept',
        title: 'Quantum Ledger',
        path: 'Quantum Ledger.md',
        body: 'Core ledger description.',
      );

      final docArticle = VaultiteItem(
        id: 'doc_article',
        title: 'Weekly Review',
        path: 'Weekly Review.md',
        body: '''
This week we researched Quantum Ledger extensively.
Already linked note is [[Some Other Note]].
''',
      );

      index.setAll([docConcept, docArticle]);

      final mentions = index.getUnlinkedMentions('doc_concept');
      expect(mentions.length, 1);
      expect(mentions.first.sourceNodeId, 'doc_article');
      expect(mentions.first.matchedText, 'Quantum Ledger');
      expect(
        mentions.first.contextLine,
        contains('Quantum Ledger extensively'),
      );
    });
  });
}
