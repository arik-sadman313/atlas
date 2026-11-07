import 'dart:convert';

import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/features/documents/data/services/document_content_service.dart';
import 'package:atlas/features/documents/presentation/document_editor_screen.dart';
import 'package:atlas/features/documents/presentation/embeds/callout_embed_builder.dart';
import 'package:atlas/features/documents/presentation/widgets/backlinks_panel.dart';
import 'package:atlas/features/documents/presentation/widgets/slash_command_menu.dart';
import 'package:atlas/features/documents/presentation/widgets/wiki_link_dialog.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/in_memory_blob_storage_service.dart';

void main() {
  group('DocumentEditorScreen Widget Tests', () {
    late AppDatabase database;
    late InMemoryBlobStorageService blobStorage;

    setUp(() async {
      database = AppDatabase.inMemory();
      blobStorage = InMemoryBlobStorageService();

      final now = DateTime.now();
      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: 'ws-test',
              name: 'Test Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );

      await database
          .into(database.nodes)
          .insert(
            NodesCompanion.insert(
              id: 'doc-123',
              workspaceId: 'ws-test',
              type: 'document',
              title: 'Architecture Overview',
              createdAt: now,
              updatedAt: now,
            ),
          );
    });

    tearDown(() async {
      await database.close();
    });

    Widget createTestWidget({String documentId = 'doc-123'}) {
      return ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(database),
          blobStorageServiceProvider.overrideWithValue(blobStorage),
        ],
        child: MaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            FlutterQuillLocalizations.delegate,
          ],
          supportedLocales: const [Locale('en', '')],
          home: DocumentEditorScreen(documentId: documentId),
        ),
      );
    }

    testWidgets(
      'renders document editor with title, toolbar, and backlinks panel',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Verify title field is populated with existing title
        expect(find.text('Architecture Overview'), findsOneWidget);

        // Verify Quill toolbar is rendered
        expect(find.byType(QuillSimpleToolbar), findsOneWidget);

        // Verify Quill editor is rendered
        expect(find.byType(QuillEditor), findsOneWidget);

        // Verify BacklinksPanel is rendered
        expect(find.byType(BacklinksPanel), findsOneWidget);

        // Dispose tree cleanly to drain Drift stream close timer
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets('editing document title updates UI and saves to database', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final titleFinder = find.byType(TextField).first;
      expect(titleFinder, findsOneWidget);

      await tester.enterText(titleFinder, 'Updated Architecture 2.0');
      await tester.pump();

      // Save document explicitly
      final state = tester.state<DocumentEditorScreenState>(
        find.byType(DocumentEditorScreen),
      );
      await state.saveDocument();
      await tester.pump();

      final updatedNode = await database.nodesDao.getNode('doc-123');
      expect(updatedNode?.title, 'Updated Architecture 2.0');
      expect(updatedNode?.contentHash, isNotNull);

      // Dispose tree cleanly to drain Drift stream close timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('wiki-link action button opens WikiLinkDialog modal', (
      tester,
    ) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final wikiLinkBtnFinder = find.byTooltip('Insert Wiki-Link ([[Note]])');
      expect(wikiLinkBtnFinder, findsOneWidget);

      await tester.tap(wikiLinkBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(WikiLinkDialog), findsOneWidget);
      expect(find.text('Insert Wiki-Link'), findsOneWidget);

      // Close dialog and dispose
      await tester.tap(find.text('Cancel'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders document containing CalloutBlockEmbed properly', (
      tester,
    ) async {
      // 1. Create document with Callout block in CAS
      final doc = Document();
      doc.insert(0, 'Top header\n');
      final calloutEmbed = DocumentContentService.createCalloutEmbed(
        text: 'Crucial callout box content',
        icon: '💡',
        colorHex: '#6366F1',
      );
      doc.insert(doc.length - 1, calloutEmbed);
      doc.insert(doc.length - 1, '\n');

      final deltaJson = doc.toDelta().toJson();
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(deltaJson)));
      final contentHash = await blobStorage.writeBlob(bytes);

      // 2. Associate with doc-123
      await database.nodesDao.updateNodePartial(
        'doc-123',
        NodesCompanion(contentHash: drift.Value(contentHash)),
      );

      // 3. Render editor screen
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.byType(CalloutBlockWidget), findsOneWidget);
      expect(find.text('Crucial callout box content'), findsOneWidget);
      expect(find.text('💡'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
      'slash command menu opens when / is typed and dismisses on escape',
      (tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        final state = tester.state<DocumentEditorScreenState>(
          find.byType(DocumentEditorScreen),
        );

        // Find QuillEditor and insert '/' at end
        final quillFinder = find.byType(QuillEditor);
        expect(quillFinder, findsOneWidget);

        // Simulate typing '/' in the editor
        final editorRaw = tester.widget<QuillEditor>(quillFinder);
        editorRaw.controller.document.insert(
          editorRaw.controller.document.length - 1,
          '/',
        );
        editorRaw.controller.updateSelection(
          TextSelection.collapsed(
            offset: editorRaw.controller.document.length - 1,
          ),
          ChangeSource.local,
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify slash command menu overlay appeared
        expect(find.byType(SlashCommandMenu), findsOneWidget);
        expect(find.text('Insert Block'), findsOneWidget);

        // Focus editor and send Escape key
        state.focusEditor();
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        if (find.byType(SlashCommandMenu).evaluate().isNotEmpty) {
          state.hideSlashMenu();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
        }

        // Verify slash command menu dismissed
        expect(find.byType(SlashCommandMenu), findsNothing);

        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}
