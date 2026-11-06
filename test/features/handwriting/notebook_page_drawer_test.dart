import 'dart:io';

import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/handwriting/presentation/widgets/notebook_page_drawer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotebookPageDrawer Widget Tests', () {
    late Directory tempDir;
    late CasStorageService storage;
    final now = DateTime.now();

    final pages = [
      InkPageEntry(
        id: 'p-1',
        documentId: 'doc-1',
        pageNumber: 1,
        width: 600.0,
        height: 800.0,
        templateType: 'ruled',
        templateSpacing: 28.35,
        backgroundColor: 0xFFFFFFFF,
        createdAt: now,
        updatedAt: now,
      ),
      InkPageEntry(
        id: 'p-2',
        documentId: 'doc-1',
        pageNumber: 2,
        width: 600.0,
        height: 800.0,
        templateType: 'grid',
        templateSpacing: 20.0,
        backgroundColor: 0xFFFFFFFF,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('atlas_drawer_test_');
      storage = CasStorageService(rootDirectory: tempDir);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Widget buildDrawer({
      required int currentPageIndex,
      required ValueChanged<int> onPageSelected,
      required VoidCallback onAddPage,
      required ValueChanged<int> onInsertPageBelow,
      required ValueChanged<int> onDuplicatePage,
      required ValueChanged<int> onDeletePage,
      required void Function(int, int) onMovePage,
      required void Function(int, String) onChangeTemplate,
    }) {
      return ProviderScope(
        overrides: [
          blobStorageServiceProvider.overrideWithValue(storage),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NotebookPageDrawer(
              pages: pages,
              currentPageIndex: currentPageIndex,
              onPageSelected: onPageSelected,
              onAddPage: onAddPage,
              onInsertPageBelow: onInsertPageBelow,
              onDuplicatePage: onDuplicatePage,
              onDeletePage: onDeletePage,
              onMovePage: onMovePage,
              onChangeTemplate: onChangeTemplate,
            ),
          ),
        ),
      );
    }

    testWidgets('renders drawer header, pages list, and add page action',
        (tester) async {
      await tester.pumpWidget(
        buildDrawer(
          currentPageIndex: 0,
          onPageSelected: (_) {},
          onAddPage: () {},
          onInsertPageBelow: (_) {},
          onDuplicatePage: (_) {},
          onDeletePage: (_) {},
          onMovePage: (_, _) {},
          onChangeTemplate: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      // Verify header
      expect(find.text('Pages (2)'), findsOneWidget);
      expect(find.byIcon(Icons.note_add_outlined), findsWidgets);

      // Verify page cards
      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsOneWidget);
    });

    testWidgets('tapping page item calls onPageSelected callback',
        (tester) async {
      int? selectedIndex;

      await tester.pumpWidget(
        buildDrawer(
          currentPageIndex: 0,
          onPageSelected: (idx) => selectedIndex = idx,
          onAddPage: () {},
          onInsertPageBelow: (_) {},
          onDuplicatePage: (_) {},
          onDeletePage: (_) {},
          onMovePage: (_, _) {},
          onChangeTemplate: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Page 2'));
      await tester.pumpAndSettle();

      expect(selectedIndex, 1);
    });

    testWidgets('tapping add page button invokes onAddPage callback',
        (tester) async {
      bool addPageCalled = false;

      await tester.pumpWidget(
        buildDrawer(
          currentPageIndex: 0,
          onPageSelected: (_) {},
          onAddPage: () => addPageCalled = true,
          onInsertPageBelow: (_) {},
          onDuplicatePage: (_) {},
          onDeletePage: (_) {},
          onMovePage: (_, _) {},
          onChangeTemplate: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      // Tap header add button
      await tester.tap(find.byTooltip('Add Page at End'));
      await tester.pumpAndSettle();

      expect(addPageCalled, isTrue);
    });

    testWidgets('opening page options menu shows action items',
        (tester) async {
      int? insertBelowIndex;

      await tester.pumpWidget(
        buildDrawer(
          currentPageIndex: 0,
          onPageSelected: (_) {},
          onAddPage: () {},
          onInsertPageBelow: (idx) => insertBelowIndex = idx,
          onDuplicatePage: (_) {},
          onDeletePage: (_) {},
          onMovePage: (_, _) {},
          onChangeTemplate: (_, _) {},
        ),
      );
      await tester.pumpAndSettle();

      // Tap options menu on Page 1
      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      expect(find.text('Insert Below'), findsOneWidget);
      expect(find.text('Duplicate'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);

      await tester.tap(find.text('Insert Below'));
      await tester.pumpAndSettle();

      expect(insertBelowIndex, 0);
    });
  });
}
