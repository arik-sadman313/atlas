import 'dart:io';

import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/settings/presentation/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsScreen Sync & Portability UI Tests', () {
    late AppDatabase db;
    late Directory tempDir;
    late CasStorageService blobStorage;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'atlas_device_id': 'atlas-client-test-uuid-1234',
        'atlas_device_name': 'Test Workstation',
        'atlas_sync_directory_path': '/mock/sync/folder',
      });

      db = AppDatabase.inMemory();
      await db.workspacesDao.getOrCreateDefaultWorkspace();
      tempDir = Directory.systemTemp.createTempSync('atlas_settings_test_');
      blobStorage = CasStorageService(rootDirectory: tempDir);
    });

    tearDown(() async {
      await db.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    testWidgets(
      'renders device identity, sync controls, vault actions, bulk export, and storage breakdown',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              appDatabaseProvider.overrideWithValue(db),
              blobStorageServiceProvider.overrideWithValue(blobStorage),
              syncHistoryStreamProvider.overrideWith(
                (ref) => Stream.value([
                  SyncHistoryEntry(
                    id: 'sync-1',
                    syncStartedAt: DateTime.now().toUtc(),
                    syncCompletedAt: DateTime.now().toUtc(),
                    syncType: 'folder_sync',
                    status: 'COMPLETED',
                    recordsExported: 4,
                    recordsImported: 2,
                    blobsTransferred: 1,
                    errorMessage: null,
                  ),
                ]),
              ),
            ],
            child: const MaterialApp(home: SettingsScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verify Headers & Sections
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('DEVICE IDENTITY'), findsOneWidget);
        expect(find.text('LOCAL-FIRST SYNCHRONIZATION'), findsOneWidget);
        expect(find.text('VAULT ARCHIVE (.atlas_vault)'), findsOneWidget);
        expect(find.text('DATA PORTABILITY & BULK EXPORT'), findsOneWidget);
        expect(find.text('STORAGE BREAKDOWN & METRICS'), findsOneWidget);

        // 2. Verify Device Identity
        expect(find.text('Test Workstation'), findsOneWidget);
        expect(find.text('atlas-client-test-uuid-1234'), findsOneWidget);

        // 3. Verify Sync Controls
        expect(find.text('/mock/sync/folder'), findsOneWidget);
        expect(find.text('Sync Now'), findsOneWidget);
        expect(find.text('Choose Folder'), findsOneWidget);
        expect(find.text('Clear'), findsOneWidget);

        // 4. Verify Vault Archive Controls
        expect(find.text('Export Full Vault (.atlas_vault)'), findsOneWidget);
        expect(find.text('Restore Vault (.atlas_vault)'), findsOneWidget);

        // 5. Verify Bulk Export Controls
        expect(find.text('Export Notes to Markdown (.zip)'), findsOneWidget);
        expect(find.text('Export Notebooks to PDF (.zip)'), findsOneWidget);

        // 6. Verify Storage Metrics Section
        expect(find.text('SQLite Database'), findsOneWidget);
        expect(find.text('Content-Addressable Storage (CAS)'), findsOneWidget);
        expect(find.text('Total Vault Storage'), findsOneWidget);
      },
    );
  });
}
