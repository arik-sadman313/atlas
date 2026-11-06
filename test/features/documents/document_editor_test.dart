import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/features/documents/presentation/document_editor_screen.dart';
import 'package:atlas/features/documents/presentation/widgets/backlinks_panel.dart';
import 'package:atlas/features/documents/presentation/widgets/wiki_link_dialog.dart';
import 'package:flutter/material.dart';
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
      await database.into(database.workspaces).insert(
        WorkspacesCompanion.insert(
          id: 'ws-test',
          name: 'Test Workspace',
          createdAt: now,
          updatedAt: now,
        ),
      );

      await database.into(database.nodes).insert(
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
          supportedLocales: const [
            Locale('en', ''),
          ],
          home: DocumentEditorScreen(documentId: documentId),
        ),
      );
    }

    testWidgets('renders document editor with title, toolbar, and backlinks panel', (tester) async {
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
    });

    testWidgets('editing document title updates UI and saves to database', (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      final titleFinder = find.byType(TextField);
      expect(titleFinder, findsOneWidget);

      await tester.enterText(titleFinder, 'Updated Architecture 2.0');
      await tester.pump();

      // Save document explicitly
      final state =
          tester.state<DocumentEditorScreenState>(find.byType(DocumentEditorScreen));
      await state.saveDocument();
      await tester.pump();

      final updatedNode = await database.nodesDao.getNode('doc-123');
      expect(updatedNode?.title, 'Updated Architecture 2.0');
      expect(updatedNode?.contentHash, isNotNull);

      // Dispose tree cleanly to drain Drift stream close timer
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('wiki-link action button opens WikiLinkDialog modal', (tester) async {
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
  });
}
