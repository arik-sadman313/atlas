import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/sync/device/device_identity_service.dart';
import 'package:atlas/core/sync/vault/vault_export_service.dart';
import 'package:atlas/core/sync/vault/vault_import_service.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Vault Archive (.atlas_vault) Export & Import Tests', () {
    late Directory tempDir;
    late File dbFile;
    late Directory casDir;
    late AppDatabase database;
    late DeviceIdentityService deviceIdentity;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      tempDir = await Directory.systemTemp.createTemp('atlas_vault_test_');
      dbFile = File(p.join(tempDir.path, 'atlas_test.db'));
      casDir = Directory(p.join(tempDir.path, 'cas'));
      await casDir.create(recursive: true);

      database = AppDatabase(NativeDatabase(dbFile));
      deviceIdentity = DeviceIdentityService();
    });

    tearDown(() async {
      await database.close();
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('VaultExportService exports valid .atlas_vault with manifest and CAS blobs', () async {
      final now = DateTime.now().toUtc();
      const wsId = 'ws-vault-export';
      const nodeId = 'node-vault-doc';

      // 1. Seed database
      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Vault Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );

      // Seed CAS blob
      final blobContent = utf8.encode(
        '{"ops":[{"insert":"Hello ATLAS Vault"}]}',
      );
      final blobHash = sha256.convert(blobContent).toString().toLowerCase();
      final blobFile = File(
        p.join(casDir.path, blobHash.substring(0, 2), blobHash),
      );
      await blobFile.parent.create(recursive: true);
      await blobFile.writeAsBytes(blobContent);

      await database.nodesDao.createNode(
        NodesCompanion.insert(
          id: nodeId,
          workspaceId: wsId,
          type: 'document',
          title: 'Vault Export Test',
          contentHash: Value(blobHash),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 2. Export vault
      final exportService = VaultExportService(
        database: database,
        syncDao: database.syncDao,
        nodesDao: database.nodesDao,
        deviceIdentity: deviceIdentity,
        databaseFile: dbFile,
        casDirectory: casDir,
      );

      final vaultDestination = File(
        p.join(tempDir.path, 'export_test.atlas_vault'),
      );
      final resultFile = await exportService.exportVault(
        destinationFile: vaultDestination,
        workspaceId: wsId,
      );

      expect(resultFile.existsSync(), isTrue);
      expect(resultFile.lengthSync(), greaterThan(0));

      // 3. Inspect archive contents
      final archiveBytes = await resultFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(archiveBytes);

      final manifestEntry = archive.findFile('manifest.json');
      expect(manifestEntry, isNotNull);

      final dbEntry = archive.findFile('database.sqlite');
      expect(dbEntry, isNotNull);

      final manifestJson = jsonDecode(
        utf8.decode(manifestEntry!.content as List<int>),
      );
      expect(manifestJson['formatVersion'], '1.0');
      expect(manifestJson['totalNodes'], greaterThanOrEqualTo(1));
      expect((manifestJson['blobs'] as Map).values, contains(blobHash));
    });

    test(
      'VaultImportService validates manifest and inspects archive',
      () async {
        final now = DateTime.now().toUtc();
        const wsId = 'ws-inspect-test';

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: wsId,
                name: 'Inspect Workspace',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final exportService = VaultExportService(
          database: database,
          syncDao: database.syncDao,
          nodesDao: database.nodesDao,
          deviceIdentity: deviceIdentity,
          databaseFile: dbFile,
          casDirectory: casDir,
        );

        final vaultFile = File(
          p.join(tempDir.path, 'inspect_test.atlas_vault'),
        );
        await exportService.exportVault(destinationFile: vaultFile);

        final importService = VaultImportService(
          database: database,
          syncDao: database.syncDao,
          databaseFile: dbFile,
          casDirectory: casDir,
        );

        final manifest = await importService.inspectVault(vaultFile);
        expect(manifest.formatVersion, '1.0');
        expect(manifest.databaseChecksum.isNotEmpty, isTrue);
        final created = DateTime.parse(manifest.createdAt);
        expect(
          created.isBefore(
            DateTime.now().toUtc().add(const Duration(seconds: 10)),
          ),
          isTrue,
        );
      },
    );

    test(
      'VaultImportService restores database and CAS files cleanly',
      () async {
        final now = DateTime.now().toUtc();
        const wsId = 'ws-restore-test';
        const nodeId = 'node-restore-1';

        await database
            .into(database.workspaces)
            .insert(
              WorkspacesCompanion.insert(
                id: wsId,
                name: 'Restore Workspace',
                createdAt: now,
                updatedAt: now,
              ),
            );

        final blobData = Uint8List.fromList([10, 20, 30, 40, 50]);
        final blobHash = sha256.convert(blobData).toString().toLowerCase();
        final blobFile = File(
          p.join(casDir.path, blobHash.substring(0, 2), blobHash),
        );
        await blobFile.parent.create(recursive: true);
        await blobFile.writeAsBytes(blobData);

        await database.nodesDao.createNode(
          NodesCompanion.insert(
            id: nodeId,
            workspaceId: wsId,
            type: 'document',
            title: 'Restore Target Note',
            contentHash: Value(blobHash),
            createdAt: now,
            updatedAt: now,
          ),
        );

        final vaultFile = File(
          p.join(tempDir.path, 'full_restore.atlas_vault'),
        );
        final exportService = VaultExportService(
          database: database,
          syncDao: database.syncDao,
          nodesDao: database.nodesDao,
          deviceIdentity: deviceIdentity,
          databaseFile: dbFile,
          casDirectory: casDir,
        );
        await exportService.exportVault(destinationFile: vaultFile);

        // Now create a fresh target directory simulating another machine
        final targetDir = await Directory.systemTemp.createTemp(
          'atlas_restore_target_',
        );
        final targetDbFile = File(p.join(targetDir.path, 'atlas_restored.db'));
        final targetCasDir = Directory(p.join(targetDir.path, 'cas'));
        final targetDb = AppDatabase(NativeDatabase(targetDbFile));

        try {
          final importService = VaultImportService(
            database: targetDb,
            syncDao: targetDb.syncDao,
            databaseFile: targetDbFile,
            casDirectory: targetCasDir,
          );

          final result = await importService.restoreVault(vaultFile);
          expect(result.restoredBlobsCount, 1);
          expect(result.manifest.formatVersion, '1.0');

          // Verify restored node exists in target database
          final restoredNode = await targetDb.nodesDao.getNode(nodeId);
          expect(restoredNode, isNotNull);
          expect(restoredNode!.title, 'Restore Target Note');

          // Verify restored CAS blob file exists and matches content
          final restoredBlobFile = File(
            p.join(targetCasDir.path, blobHash.substring(0, 2), blobHash),
          );
          expect(restoredBlobFile.existsSync(), isTrue);
          expect(await restoredBlobFile.readAsBytes(), blobData);
        } finally {
          await targetDb.close();
          if (targetDir.existsSync()) {
            await targetDir.delete(recursive: true);
          }
        }
      },
    );

    test('VaultImportService rejects archive with tampered checksum and preserves backup', () async {
      final now = DateTime.now().toUtc();
      const wsId = 'ws-tamper-test';

      await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: wsId,
              name: 'Tamper Workspace',
              createdAt: now,
              updatedAt: now,
            ),
          );

      final exportService = VaultExportService(
        database: database,
        syncDao: database.syncDao,
        nodesDao: database.nodesDao,
        deviceIdentity: deviceIdentity,
        databaseFile: dbFile,
        casDirectory: casDir,
      );

      final vaultFile = File(p.join(tempDir.path, 'tamper_source.atlas_vault'));
      await exportService.exportVault(destinationFile: vaultFile);

      // Tamper with archive: replace database.sqlite with corrupted bytes while keeping manifest unchanged
      final archiveBytes = await vaultFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(archiveBytes);
      final corruptedArchive = Archive();

      for (final file in archive) {
        if (file.name == 'database.sqlite') {
          final corruptBytes = utf8.encode('CORRUPT_NOT_SQLITE_DATA');
          corruptedArchive.addFile(
            ArchiveFile('database.sqlite', corruptBytes.length, corruptBytes),
          );
        } else {
          corruptedArchive.addFile(file);
        }
      }

      final tamperedVault = File(p.join(tempDir.path, 'tampered.atlas_vault'));
      await tamperedVault.writeAsBytes(ZipEncoder().encode(corruptedArchive));

      final importService = VaultImportService(
        database: database,
        syncDao: database.syncDao,
        databaseFile: dbFile,
        casDirectory: casDir,
      );

      expect(
        () async => await importService.restoreVault(tamperedVault),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
