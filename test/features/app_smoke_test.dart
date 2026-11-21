import 'dart:io';

import 'package:flutter/material.dart';
import 'package:atlas/app/atlas_app.dart';
import 'package:atlas/app/providers.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/router/app_router.dart';
import 'package:atlas/core/router/routes.dart';
import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late Directory tempDir;
  late CasStorageService storage;

  setUp(() async {
    db = AppDatabase.inMemory();
    await db.workspacesDao.getOrCreateDefaultWorkspace();
    tempDir = Directory.systemTemp.createTempSync('atlas_smoke_');
    storage = CasStorageService(rootDirectory: tempDir);
  });

  tearDown(() async {
    await db.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('AtlasApp renders dashboard and navigation shell', (
    tester,
  ) async {
    final defaultWs = await db.workspacesDao.getOrCreateDefaultWorkspace();
    final router = createAppRouter(initialLocation: AtlasRoutes.dashboard);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          blobStorageServiceProvider.overrideWithValue(storage),
          appRouterProvider.overrideWithValue(router),
          currentWorkspaceProvider.overrideWith(
            (ref) => Future.value(defaultWs),
          ),
        ],
        child: AtlasApp(routerOverride: router),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Dashboard header rendered
    expect(find.text('Workspace Overview'), findsOneWidget);
    expect(find.text('Personal Workspace'), findsWidgets);

    // Verify navigation destinations
    expect(find.text('Notebooks'), findsWidgets);
    expect(find.textContaining('Documents'), findsWidgets);
    expect(find.text('Tasks'), findsWidgets);

    // Clean up and advance time to flush any scheduled Stream cancellation timers
    await tester.pumpWidget(const SizedBox());
    router.dispose();
    await tester.pump(const Duration(milliseconds: 100));
  });
}
