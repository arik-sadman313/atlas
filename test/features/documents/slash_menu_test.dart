import 'package:atlas/features/documents/presentation/widgets/slash_menu/slash_command_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Slash Menu Trigger, Filtering & Traversal Tests', () {
    late List<SlashCommandItem> sampleCommands;
    String? executedId;
    bool dismissed = false;

    setUp(() {
      executedId = null;
      dismissed = false;
      sampleCommands = [
        SlashCommandItem(
          id: 'text',
          label: 'Plain Text',
          description: 'Regular paragraph text',
          icon: Icons.text_fields,
          keywords: const ['text', 'plain', 'p'],
          category: SlashCommandCategory.text,
          onExecute: () => executedId = 'text',
        ),
        SlashCommandItem(
          id: 'h1',
          label: 'Heading 1',
          description: 'Large heading',
          icon: Icons.title,
          keywords: const ['h1', 'heading 1', '#'],
          category: SlashCommandCategory.text,
          onExecute: () => executedId = 'h1',
        ),
        SlashCommandItem(
          id: 'h2',
          label: 'Heading 2',
          description: 'Medium heading',
          icon: Icons.format_size,
          keywords: const ['h2', 'heading 2', '##'],
          category: SlashCommandCategory.text,
          onExecute: () => executedId = 'h2',
        ),
        SlashCommandItem(
          id: 'todo',
          label: 'To-Do Task',
          description: 'Checkbox task item',
          icon: Icons.check_box_outlined,
          keywords: const ['todo', 'task', 'checklist'],
          category: SlashCommandCategory.lists,
          onExecute: () => executedId = 'todo',
        ),
        SlashCommandItem(
          id: 'callout',
          label: 'Callout Box',
          description: 'Card with accent tint and icon',
          icon: Icons.info_outline,
          keywords: const ['callout', 'box', 'alert', 'info'],
          category: SlashCommandCategory.containers,
          onExecute: () => executedId = 'callout',
        ),
        SlashCommandItem(
          id: 'ink',
          label: 'Vector Ink Canvas',
          description: 'Inline vector drawing canvas',
          icon: Icons.gesture,
          keywords: const ['ink', 'draw', 'sketch', 'canvas'],
          category: SlashCommandCategory.embeds,
          onExecute: () => executedId = 'ink',
        ),
      ];
    });

    test('Slash trigger condition evaluation logic', () {
      // Valid triggers: start of line or preceded by space
      bool isValidSlashTrigger(String linePrefix, int slashIndex) {
        if (slashIndex == -1) return false;
        final isAtLineStart = slashIndex == 0;
        final isPrecededBySpace =
            slashIndex > 0 && linePrefix[slashIndex - 1] == ' ';
        return isAtLineStart || isPrecededBySpace;
      }

      expect(isValidSlashTrigger('/todo', 0), isTrue);
      expect(isValidSlashTrigger('hello /ink', 6), isTrue);
      expect(isValidSlashTrigger('http://localhost', 6), isFalse); // mid-word
      expect(isValidSlashTrigger('word/slash', 4), isFalse); // mid-word
    });

    test('Live query filtering matches /h2, /todo, /call, and /ink', () {
      final h2Matches = sampleCommands.where((c) => c.matches('h2')).toList();
      expect(h2Matches.length, 1);
      expect(h2Matches.first.id, 'h2');

      final todoMatches = sampleCommands
          .where((c) => c.matches('todo'))
          .toList();
      expect(todoMatches.length, 1);
      expect(todoMatches.first.id, 'todo');

      final callMatches = sampleCommands
          .where((c) => c.matches('call'))
          .toList();
      expect(callMatches.length, 1);
      expect(callMatches.first.id, 'callout');

      final inkMatches = sampleCommands.where((c) => c.matches('ink')).toList();
      expect(inkMatches.length, 1);
      expect(inkMatches.first.id, 'ink');
    });

    testWidgets(
      'Keyboard traversal with ArrowDown/ArrowUp and execution with Enter',
      (tester) async {
        final menuKey = GlobalKey<SlashCommandMenuState>();

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SlashCommandMenu(
                key: menuKey,
                query: '',
                items: sampleCommands,
                onDismiss: () => dismissed = true,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(menuKey.currentState?.selectedIndex, 0);

        // Down arrow selects next
        menuKey.currentState?.selectNext();
        await tester.pump();
        expect(menuKey.currentState?.selectedIndex, 1);

        // Up arrow selects previous
        menuKey.currentState?.selectPrevious();
        await tester.pump();
        expect(menuKey.currentState?.selectedIndex, 0);

        // Execute selected command
        menuKey.currentState?.executeSelected();
        expect(executedId, 'text');
      },
    );

    testWidgets('Direct tap on menu item executes command', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlashCommandMenu(
              query: 'call',
              items: sampleCommands,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final calloutItem = find.text('Callout Box');
      expect(calloutItem, findsOneWidget);

      await tester.tap(calloutItem);
      await tester.pumpAndSettle();

      expect(executedId, 'callout');
      expect(dismissed, isFalse);
    });
  });
}
