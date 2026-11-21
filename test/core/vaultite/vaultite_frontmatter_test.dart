import 'package:atlas/core/vaultite/vaultite_frontmatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('VaultiteFrontmatter', () {
    test('parses Obsidian frontmatter and separates body', () {
      const markdown = '''---
title: Project Vision
kind: idea
status: exploring
tags:
  - architecture
  - mobile
aliases:
  - Vision
  - Atlas Vision
source: claude
---

# Project Overview

This is the main proposal body.
''';

      final (props, body) = VaultiteFrontmatter.parse(markdown);

      expect(props['title'], 'Project Vision');
      expect(props['kind'], 'idea');
      expect(props['status'], 'exploring');
      expect(props['source'], 'claude');
      expect(props['tags'], ['architecture', 'mobile']);
      expect(props['aliases'], ['Vision', 'Atlas Vision']);

      expect(body, contains('# Project Overview'));
      expect(body, contains('This is the main proposal body.'));
    });

    test(
      'extractTags handles both list and comma-separated string formats',
      () {
        expect(VaultiteFrontmatter.extractTags(['#ai', '#notes']), [
          'ai',
          'notes',
        ]);
        expect(VaultiteFrontmatter.extractTags('design, ux, mobile'), [
          'design',
          'ux',
          'mobile',
        ]);
        expect(VaultiteFrontmatter.extractTags(null), isEmpty);
      },
    );

    test(
      'render formats clean YAML frontmatter and preserves markdown body',
      () {
        final properties = {
          'title': 'Sprint Review',
          'kind': 'note',
          'status': 'done',
          'tags': ['sprint', 'retro'],
          'aliases': ['Retro 42'],
        };
        const body = 'Discussed velocity and release cycle.';

        final rendered = VaultiteFrontmatter.render(properties, body);

        expect(rendered, startsWith('---\n'));
        expect(rendered, contains('title: Sprint Review'));
        expect(rendered, contains('kind: note'));
        expect(rendered, contains('status: done'));
        expect(rendered, contains('- sprint'));
        expect(rendered, contains('- retro'));
        expect(
          rendered,
          contains('---\n\nDiscussed velocity and release cycle.'),
        );
      },
    );

    test(
      'setProperty updates single property without corrupting other properties',
      () {
        const markdown = '''---
title: Initial Title
status: seed
---

Body text.
''';

        final updated = VaultiteFrontmatter.setProperty(
          markdown,
          'status',
          'done',
        );
        final (props, body) = VaultiteFrontmatter.parse(updated);

        expect(props['title'], 'Initial Title');
        expect(props['status'], 'done');
        expect(body, 'Body text.');
      },
    );

    test('removeProperty safely deletes a property from header', () {
      const markdown = '''---
title: Note
deprecatedKey: obsolete
---

Body.
''';

      final cleaned = VaultiteFrontmatter.removeProperty(
        markdown,
        'deprecatedKey',
      );
      final (props, body) = VaultiteFrontmatter.parse(cleaned);

      expect(props.containsKey('deprecatedKey'), isFalse);
      expect(props['title'], 'Note');
      expect(body, 'Body.');
    });
  });
}
