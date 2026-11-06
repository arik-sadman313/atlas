import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

QueryExecutor connect({
  bool inMemory = false,
  String dbName = 'atlas.db',
  File? overrideFile,
}) {
  if (inMemory) {
    return NativeDatabase.memory(
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
      },
    );
  }

  if (overrideFile != null) {
    return NativeDatabase.createInBackground(
      overrideFile,
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
        rawDb.execute('PRAGMA journal_mode = WAL;');
        rawDb.execute('PRAGMA synchronous = NORMAL;');
        rawDb.execute('PRAGMA busy_timeout = 5000;');
      },
    );
  }

  return LazyDatabase(() async {
    final Directory baseFolder;
    if (Platform.isLinux) {
      baseFolder = await getApplicationSupportDirectory();
    } else {
      baseFolder = await getApplicationDocumentsDirectory();
    }

    final atlasDir = Directory(p.join(baseFolder.path, 'atlas'));
    if (!atlasDir.existsSync()) {
      atlasDir.createSync(recursive: true);
    }
    final file = File(p.join(atlasDir.path, dbName));

    return NativeDatabase.createInBackground(
      file,
      setup: (rawDb) {
        rawDb.execute('PRAGMA foreign_keys = ON;');
        rawDb.execute('PRAGMA journal_mode = WAL;');
        rawDb.execute('PRAGMA synchronous = NORMAL;');
        rawDb.execute('PRAGMA busy_timeout = 5000;');
      },
    );
  });
}
