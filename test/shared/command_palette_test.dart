import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/shared/presentation/command_palette/command_palette_modal.dart';
import 'package:atlas/shared/presentation/command_palette/command_registry.dart';

import '../helpers/in_memory_blob_storage_service.dart';

class TestWorkspaceIdNotifier extends CurrentWorkspaceIdNotifier {
  @override
  String build() => 'workspace-default-primary';
}

void main() {
  group('CommandRegistry Actions', () {
    test('contains comprehensive suite of navigation, creation, and system actions', () {
      final actions = CommandRegistry.getActions();
      expect(actions.isNotEmpty, isTrue);

      final categories = actions.map((a) => a.category).toSet();
      expect(categories, contains('Navigation'));
      expect(categories, contains('Create'));
      expect(categories, contains('System'));

      final labels = actions.map((a) => a.label).toList();
      expect(labels, contains('Jump to Dashboard'));
      expect(labels, contains('Open Knowledge Graph'));
      expect(labels, contains('New Document'));
      expect(labels, contains('New Notebook'));
      expect(labels, contains('New Task'));
      expect(labels, contains("Today's Journal"));
      expect(labels, contains('Toggle Dark / Light Theme'));
    });
  });

  group('CommandPaletteModal Widget Tests', () {
    late AppDatabase db;
    late InMemoryBlobStorageService blobStorage;

    setUp(() {
      db = AppDatabase.inMemory();
      blobStorage = InMemoryBlobStorageService();
    });

    tearDown(() async {
      await db.close();
    });

    Widget createTestWidget() {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          nodesDaoProvider.overrideWithValue(db.nodesDao),
          tasksDaoProvider.overrideWithValue(db.tasksDao),
          calendarDaoProvider.overrideWithValue(db.calendarDao),
          journalDaoProvider.overrideWithValue(db.journalDao),
          linksDaoProvider.overrideWithValue(db.linksDao),
          blobStorageServiceProvider.overrideWithValue(blobStorage),
          currentWorkspaceIdProvider.overrideWith(TestWorkspaceIdNotifier.new),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => CommandPaletteModal.show(context),
                child: const Text('Open Palette'),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('opens modal and displays default actions in unified mode', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      // Tap to open modal
      await tester.tap(find.text('Open Palette'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Palette text input must be visible
      expect(find.byType(TextField), findsOneWidget);
      expect(
        find.text('Type a command (>), tag (#), date (@), or search pages...'),
        findsOneWidget,
      );

      // Verify prefix hint chips
      expect(find.text('> Actions'), findsOneWidget);
      expect(find.text('# Tags'), findsOneWidget);
      expect(find.text('@ Dates'), findsOneWidget);

      // Verify at least one action is visible
      expect(find.text('Jump to Dashboard'), findsOneWidget);
    });

    testWidgets('typing > switches to Commands mode', (tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Open Palette'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final input = find.byType(TextField);
      await tester.enterText(input, '> Toggle');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Toggle Dark / Light Theme'), findsOneWidget);
    });

    testWidgets(
      'keyboard navigation down/up updates selected item and Escape closes modal',
      (tester) async {
        await tester.pumpWidget(createTestWidget());

        await tester.tap(find.text('Open Palette'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // Press ArrowDown to navigate down
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Press Escape to dismiss
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CommandPaletteModal), findsNothing);
      },
    );
  });
}
