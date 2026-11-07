import 'package:atlas/features/documents/presentation/widgets/slash_command_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SlashCommandMenu Unit & Widget Tests', () {
    late List<SlashCommandItem> sampleCommands;
    String? lastExecutedId;
    bool wasDismissed = false;

    setUp(() {
      lastExecutedId = null;
      wasDismissed = false;
      sampleCommands = [
        SlashCommandItem(
          id: 'text',
          label: 'Plain Text',
          description: 'Regular text block',
          icon: Icons.text_fields,
          keywords: const ['text', 'plain', 'p'],
          category: SlashCommandCategory.text,
          onExecute: () => lastExecutedId = 'text',
        ),
        SlashCommandItem(
          id: 'h1',
          label: 'Heading 1',
          description: 'Large header',
          icon: Icons.title,
          keywords: const ['h1', 'heading 1', '#'],
          category: SlashCommandCategory.text,
          onExecute: () => lastExecutedId = 'h1',
        ),
        SlashCommandItem(
          id: 'h2',
          label: 'Heading 2',
          description: 'Medium header',
          icon: Icons.format_size,
          keywords: const ['h2', 'heading 2', '##'],
          category: SlashCommandCategory.text,
          onExecute: () => lastExecutedId = 'h2',
        ),
        SlashCommandItem(
          id: 'todo',
          label: 'To-Do Checklist',
          description: 'Track checklist tasks',
          icon: Icons.check_box_outlined,
          keywords: const ['todo', 'checklist', 'task', 'check'],
          category: SlashCommandCategory.lists,
          onExecute: () => lastExecutedId = 'todo',
        ),
        SlashCommandItem(
          id: 'callout',
          label: 'Callout Box',
          description: 'Stylized info container',
          icon: Icons.info_outline,
          keywords: const ['callout', 'box', 'alert', 'info'],
          category: SlashCommandCategory.containers,
          onExecute: () => lastExecutedId = 'callout',
        ),
        SlashCommandItem(
          id: 'ink',
          label: 'Vector Ink Canvas',
          description: 'Inline handwriting sketch',
          icon: Icons.gesture,
          keywords: const ['ink', 'draw', 'sketch', 'handwriting'],
          category: SlashCommandCategory.embeds,
          onExecute: () => lastExecutedId = 'ink',
        ),
      ];
    });

    test(
      'SlashCommandItem matches query by label, description, or keywords',
      () {
        final h2Item = sampleCommands.firstWhere((i) => i.id == 'h2');
        expect(h2Item.matches('h2'), isTrue);
        expect(h2Item.matches('heading'), isTrue);
        expect(h2Item.matches('medium'), isTrue);
        expect(h2Item.matches('##'), isTrue);
        expect(h2Item.matches('todo'), isFalse);

        final inkItem = sampleCommands.firstWhere((i) => i.id == 'ink');
        expect(inkItem.matches('ink'), isTrue);
        expect(inkItem.matches('sketch'), isTrue);
        expect(inkItem.matches('draw'), isTrue);
        expect(inkItem.matches('canvas'), isTrue);
      },
    );

    testWidgets('renders all items when query is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlashCommandMenu(
              query: '',
              items: sampleCommands,
              onDismiss: () => wasDismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('Insert Block'), findsOneWidget);
      expect(find.text('Plain Text'), findsOneWidget);
      expect(find.text('Heading 1'), findsOneWidget);
      expect(find.text('Heading 2'), findsOneWidget);
      expect(find.text('To-Do Checklist'), findsOneWidget);
      expect(find.text('Callout Box'), findsOneWidget);
      expect(find.text('Vector Ink Canvas'), findsOneWidget);
    });

    testWidgets('filters items dynamically by query', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlashCommandMenu(
              query: 'h2',
              items: sampleCommands,
              onDismiss: () => wasDismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('Matching "h2"'), findsOneWidget);
      expect(find.text('Heading 2'), findsOneWidget);
      expect(find.text('Heading 1'), findsNothing);
      expect(find.text('Callout Box'), findsNothing);
    });

    testWidgets('shows empty state when no items match query', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlashCommandMenu(
              query: 'nonexistent',
              items: sampleCommands,
              onDismiss: () => wasDismissed = true,
            ),
          ),
        ),
      );

      expect(find.text('No commands matching "/nonexistent"'), findsOneWidget);
    });

    testWidgets('tapping an item executes command action', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlashCommandMenu(
              query: '',
              items: sampleCommands,
              onDismiss: () => wasDismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Callout Box'));
      await tester.pump();

      expect(lastExecutedId, 'callout');
    });

    testWidgets('keyboard navigation wraps around and executes selected', (
      tester,
    ) async {
      final menuKey = GlobalKey<SlashCommandMenuState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlashCommandMenu(
              key: menuKey,
              query: '',
              items: sampleCommands,
              onDismiss: () => wasDismissed = true,
            ),
          ),
        ),
      );

      // Initially selected item is 0 ('Plain Text')
      menuKey.currentState?.executeSelected();
      expect(lastExecutedId, 'text');

      // Navigate down to 'Heading 1'
      menuKey.currentState?.selectNext();
      menuKey.currentState?.executeSelected();
      expect(lastExecutedId, 'h1');

      // Navigate up back to 'Plain Text'
      menuKey.currentState?.selectPrevious();
      menuKey.currentState?.executeSelected();
      expect(lastExecutedId, 'text');

      // Navigate up wraps around to last item ('Vector Ink Canvas')
      menuKey.currentState?.selectPrevious();
      menuKey.currentState?.executeSelected();
      expect(lastExecutedId, 'ink');

      // Navigate down wraps back to first item ('Plain Text')
      menuKey.currentState?.selectNext();
      menuKey.currentState?.executeSelected();
      expect(lastExecutedId, 'text');
    });

    testWidgets('calls onDismiss callback cleanly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SlashCommandMenu(
              query: '',
              items: sampleCommands,
              onDismiss: () => wasDismissed = true,
            ),
          ),
        ),
      );

      final state =
          tester.state<SlashCommandMenuState>(find.byType(SlashCommandMenu));
      state.widget.onDismiss();
      expect(wasDismissed, isTrue);
    });
  });
}
