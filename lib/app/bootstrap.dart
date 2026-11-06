import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/database/app_database.dart';
import '../core/storage/cas_storage_service.dart';
import 'atlas_app.dart';
import 'providers.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Resolve application root directory per platform
  final Directory baseDirectory;
  if (Platform.isLinux) {
    baseDirectory = await getApplicationSupportDirectory();
  } else {
    baseDirectory = await getApplicationDocumentsDirectory();
  }

  final atlasDir = Directory(p.join(baseDirectory.path, 'atlas'));
  if (!atlasDir.existsSync()) {
    atlasDir.createSync(recursive: true);
  }

  // 2. Initialize Content-Addressable Storage (CAS)
  final blobsDir = Directory(p.join(atlasDir.path, 'blobs'));
  final blobStorage = CasStorageService(rootDirectory: blobsDir);

  // 3. Initialize SQLite Database via Drift
  final database = AppDatabase();

  // 4. Ensure default workspace exists
  await database.workspacesDao.getOrCreateDefaultWorkspace();

  // 5. Build Riverpod container with initialized infrastructure singletons
  final container = ProviderContainer(
    overrides: [
      appDatabaseProvider.overrideWithValue(database),
      blobStorageServiceProvider.overrideWithValue(blobStorage),
    ],
  );

  runApp(
    UncontrolledProviderScope(container: container, child: const AtlasApp()),
  );
}
