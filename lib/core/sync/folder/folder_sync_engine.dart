import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';

import '../../database/app_database.dart';
import '../../database/daos/sync_dao.dart';
import '../device/device_identity_service.dart';
import 'changeset_model.dart';
import 'client_info_model.dart';

class SyncResult {
  final bool success;
  final int recordsExported;
  final int recordsImported;
  final int blobsTransferred;
  final int conflictsResolved;
  final String? errorMessage;

  const SyncResult({
    required this.success,
    this.recordsExported = 0,
    this.recordsImported = 0,
    this.blobsTransferred = 0,
    this.conflictsResolved = 0,
    this.errorMessage,
  });
}

class FolderSyncEngine {
  final AppDatabase database;
  final SyncDao syncDao;
  final DeviceIdentityService deviceIdentity;
  final Directory casDirectory;
  final Directory? overrideSyncDirectory;
  final Uuid _uuid;

  FolderSyncEngine({
    required this.database,
    required this.syncDao,
    required this.deviceIdentity,
    required this.casDirectory,
    this.overrideSyncDirectory,
    Uuid? uuid,
  }) : _uuid = uuid ?? const Uuid();

  /// Resolves the active sync folder.
  Future<Directory?> getSyncDirectory() async {
    if (overrideSyncDirectory != null) return overrideSyncDirectory;
    final path = await deviceIdentity.getSyncDirectoryPath();
    if (path == null || path.isEmpty) return null;
    final dir = Directory(path);
    return dir.existsSync() ? dir : null;
  }

  /// Executes full two-way local-first synchronization.
  Future<SyncResult> sync() async {
    final syncDir = await getSyncDirectory();
    if (syncDir == null) {
      return const SyncResult(
        success: false,
        errorMessage: 'Sync directory not configured or does not exist',
      );
    }

    final syncId = _uuid.v4();
    await syncDao.startSync(id: syncId, syncType: 'folder_sync');

    try {
      final deviceId = await deviceIdentity.getOrCreateDeviceId();
      final deviceName = await deviceIdentity.getDeviceName();

      // 1. Ensure folder layout exists
      final clientsDir = Directory(p.join(syncDir.path, 'clients'));
      final blobsDir = Directory(p.join(syncDir.path, 'blobs'));
      final myClientDir = Directory(p.join(clientsDir.path, deviceId));
      final myChangesDir = Directory(p.join(myClientDir.path, 'changes'));

      if (!myChangesDir.existsSync()) {
        myChangesDir.createSync(recursive: true);
      }
      if (!blobsDir.existsSync()) {
        blobsDir.createSync(recursive: true);
      }

      int totalExported = 0;
      int totalImported = 0;
      int totalBlobs = 0;
      int totalConflicts = 0;

      // 2. EXPORT FLOW: Scan local mutations since last successful sync
      final lastSync =
          await syncDao.getLastSuccessfulSyncTime('folder_sync') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

      final mutatedNodes = await syncDao.getMutatedNodes(lastSync);
      final mutatedWorkspaces = await syncDao.getMutatedWorkspaces(lastSync);
      final mutatedLinks = await syncDao.getMutatedNodeLinks(lastSync);
      final mutatedTags = await syncDao.getMutatedTags(lastSync);
      final mutatedNodeTags = await syncDao.getMutatedNodeTags(lastSync);
      final mutatedPages = await syncDao.getMutatedInkPages(lastSync);
      final mutatedPdfs = await syncDao.getMutatedPdfDocuments(lastSync);
      final mutatedProjects = await syncDao.getMutatedProjects(lastSync);
      final mutatedTasks = await syncDao.getMutatedTasks(lastSync);
      final mutatedEvents = await syncDao.getMutatedCalendarEvents(lastSync);
      final mutatedHabits = await syncDao.getMutatedHabits(lastSync);
      final mutatedHabitLogs = await syncDao.getMutatedHabitLogs(lastSync);
      final mutatedGoals = await syncDao.getMutatedGoals(lastSync);
      final mutatedJournals = await syncDao.getMutatedJournalEntries(lastSync);

      // Collect referenced CAS blob hashes
      final referencedHashes = <String>{};
      for (final n in mutatedNodes) {
        if (n.contentHash != null && n.contentHash!.isNotEmpty) {
          referencedHashes.add(n.contentHash!);
        }
      }
      for (final p in mutatedPages) {
        if (p.portableInkHash != null && p.portableInkHash!.isNotEmpty) {
          referencedHashes.add(p.portableInkHash!);
        }
        if (p.rawPencilkitHash != null && p.rawPencilkitHash!.isNotEmpty) {
          referencedHashes.add(p.rawPencilkitHash!);
        }
        if (p.previewPngHash != null && p.previewPngHash!.isNotEmpty) {
          referencedHashes.add(p.previewPngHash!);
        }
      }
      for (final pdf in mutatedPdfs) {
        if (pdf.casHash.isNotEmpty) referencedHashes.add(pdf.casHash);
      }

      // Copy referenced blobs to [SyncDirectory]/blobs/[prefix]/[sha256]
      for (final hash in referencedHashes) {
        if (hash.length >= 2) {
          final prefix = hash.substring(0, 2);
          final localBlobFile = File(p.join(casDirectory.path, prefix, hash));
          if (localBlobFile.existsSync()) {
            final destBlobDir = Directory(p.join(blobsDir.path, prefix));
            if (!destBlobDir.existsSync()) {
              destBlobDir.createSync(recursive: true);
            }
            final destBlobFile = File(p.join(destBlobDir.path, hash));
            if (!destBlobFile.existsSync()) {
              await localBlobFile.copy(destBlobFile.path);
              totalBlobs++;
            }
          }
        }
      }

      // Check client info sequence
      final infoFile = File(p.join(myClientDir.path, 'info.json'));
      int currentSeq = 0;
      if (infoFile.existsSync()) {
        try {
          final infoJson = jsonDecode(await infoFile.readAsString());
          currentSeq = ClientInfo.fromJson(infoJson).lastSequence;
        } catch (_) {}
      }

      final hasMutations =
          mutatedWorkspaces.isNotEmpty ||
          mutatedNodes.isNotEmpty ||
          mutatedLinks.isNotEmpty ||
          mutatedTags.isNotEmpty ||
          mutatedNodeTags.isNotEmpty ||
          mutatedPages.isNotEmpty ||
          mutatedPdfs.isNotEmpty ||
          mutatedProjects.isNotEmpty ||
          mutatedTasks.isNotEmpty ||
          mutatedEvents.isNotEmpty ||
          mutatedHabits.isNotEmpty ||
          mutatedHabitLogs.isNotEmpty ||
          mutatedGoals.isNotEmpty ||
          mutatedJournals.isNotEmpty;

      if (hasMutations) {
        currentSeq++;
        final changeset = AtlasChangeset(
          deviceId: deviceId,
          sequence: currentSeq,
          timestamp: DateTime.now().toUtc(),
          workspaces: mutatedWorkspaces.map((e) => e.toJson()).toList(),
          nodes: mutatedNodes.map((e) => e.toJson()).toList(),
          nodeLinks: mutatedLinks.map((e) => e.toJson()).toList(),
          tags: mutatedTags.map((e) => e.toJson()).toList(),
          nodeTags: mutatedNodeTags.map((e) => e.toJson()).toList(),
          inkPages: mutatedPages.map((e) => e.toJson()).toList(),
          pdfDocuments: mutatedPdfs.map((e) => e.toJson()).toList(),
          projects: mutatedProjects.map((e) => e.toJson()).toList(),
          tasks: mutatedTasks.map((e) => e.toJson()).toList(),
          calendarEvents: mutatedEvents.map((e) => e.toJson()).toList(),
          habits: mutatedHabits.map((e) => e.toJson()).toList(),
          habitLogs: mutatedHabitLogs.map((e) => e.toJson()).toList(),
          goals: mutatedGoals.map((e) => e.toJson()).toList(),
          journalEntries: mutatedJournals.map((e) => e.toJson()).toList(),
          referencedBlobHashes: referencedHashes.toList(),
        );

        final nowIso = DateTime.now().toUtc().toIso8601String().replaceAll(
          ':',
          '-',
        );
        final changesetFile = File(
          p.join(myChangesDir.path, '${nowIso}_$currentSeq.atlas_changeset'),
        );
        await changesetFile.writeAsBytes(changeset.encodeCompressed());
        totalExported += changeset.totalRecordsCount;

        // Update info.json
        final updatedInfo = ClientInfo(
          deviceId: deviceId,
          deviceName: deviceName,
          lastActive: DateTime.now().toUtc(),
          lastSequence: currentSeq,
        );
        await infoFile.writeAsString(updatedInfo.encode());
      }

      // 3. INGEST FLOW: Scan other clients' changesets
      if (clientsDir.existsSync()) {
        final clientDirs = clientsDir.listSync().whereType<Directory>();
        for (final remoteClientDir in clientDirs) {
          final remoteDeviceId = p.basename(remoteClientDir.path);
          if (remoteDeviceId == deviceId) continue; // Skip own client

          final remoteChangesDir = Directory(
            p.join(remoteClientDir.path, 'changes'),
          );
          if (!remoteChangesDir.existsSync()) continue;

          final changeFiles =
              remoteChangesDir
                  .listSync()
                  .whereType<File>()
                  .where((f) => f.path.endsWith('.atlas_changeset'))
                  .toList()
                ..sort((a, b) => a.path.compareTo(b.path));

          for (final changeFile in changeFiles) {
            final compressedBytes = await changeFile.readAsBytes();
            final remoteChangeset = AtlasChangeset.decodeCompressed(
              compressedBytes,
            );

            // Copy any missing blobs from [syncDir]/blobs/ to local CAS
            for (final hash in remoteChangeset.referencedBlobHashes) {
              if (hash.length >= 2) {
                final prefix = hash.substring(0, 2);
                final sourceBlob = File(p.join(blobsDir.path, prefix, hash));
                final localBlob = File(p.join(casDirectory.path, prefix, hash));

                if (sourceBlob.existsSync() && !localBlob.existsSync()) {
                  if (!localBlob.parent.existsSync()) {
                    localBlob.parent.createSync(recursive: true);
                  }
                  await sourceBlob.copy(localBlob.path);
                  totalBlobs++;
                }
              }
            }

            // Ingest Workspaces
            for (final json in remoteChangeset.workspaces) {
              final item = WorkspaceEntry.fromJson(json);
              if (await syncDao.upsertRemoteWorkspace(item)) totalImported++;
            }

            // Ingest Nodes with Conflict Resolution & Non-Destructive Forking
            for (final json in remoteChangeset.nodes) {
              final incoming = NodeEntry.fromJson(json);
              final existing = await database.nodesDao.getNode(incoming.id);

              if (existing != null &&
                  !existing.isDeleted &&
                  !incoming.isDeleted &&
                  existing.deletedAt == null &&
                  incoming.deletedAt == null) {
                // Check if concurrent edit occurred within a 5-minute window
                final diff = incoming.clientModifiedAt
                    .difference(existing.clientModifiedAt)
                    .abs();
                final isConcurrent = diff <= const Duration(minutes: 5);
                final isContentDiffer =
                    incoming.contentHash != existing.contentHash;

                if (isConcurrent &&
                    isContentDiffer &&
                    (incoming.type == 'document' ||
                        incoming.type == 'notebook')) {
                  // Non-destructive fork!
                  final incomingIsNewer = incoming.clientModifiedAt.isAfter(
                    existing.clientModifiedAt,
                  );
                  final olderNode = incomingIsNewer ? existing : incoming;
                  final winnerNode = incomingIsNewer ? incoming : existing;

                  final dateFmt = DateFormat('yyyy-MM-dd HH:mm')
                      .format(DateTime.now());
                  final forkedTitle =
                      '${olderNode.title} (Sync Conflict $dateFmt)';
                  final forkedId = _uuid.v4();

                  await database.nodesDao.createNode(
                    NodesCompanion.insert(
                      id: forkedId,
                      workspaceId: olderNode.workspaceId,
                      type: olderNode.type,
                      title: forkedTitle,
                      contentHash: Value(olderNode.contentHash),
                      createdAt: DateTime.now().toUtc(),
                      updatedAt: DateTime.now().toUtc(),
                    ),
                  );

                  await syncDao.upsertRemoteNode(winnerNode);
                  totalConflicts++;
                  totalImported += 2;
                  continue;
                }
              }

              // Default Last-Write-Wins (LWW)
              if (await syncDao.upsertRemoteNode(incoming)) {
                totalImported++;
              }
            }

            // Ingest remaining entities
            for (final json in remoteChangeset.nodeLinks) {
              if (await syncDao.upsertRemoteNodeLink(
                NodeLinkEntry.fromJson(json),
              )) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.tags) {
              if (await syncDao.upsertRemoteTag(TagEntry.fromJson(json))) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.nodeTags) {
              if (await syncDao.upsertRemoteNodeTag(
                NodeTagEntry.fromJson(json),
              )) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.inkPages) {
              if (await syncDao.upsertRemoteInkPage(
                InkPageEntry.fromJson(json),
              )) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.pdfDocuments) {
              if (await syncDao.upsertRemotePdfDocument(
                PdfDocumentEntry.fromJson(json),
              )) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.projects) {
              if (await syncDao.upsertRemoteProject(
                ProjectEntry.fromJson(json),
              )) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.tasks) {
              if (await syncDao.upsertRemoteTask(TaskEntry.fromJson(json))) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.calendarEvents) {
              if (await syncDao.upsertRemoteCalendarEvent(
                CalendarEventEntry.fromJson(json),
              )) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.habits) {
              if (await syncDao.upsertRemoteHabit(HabitEntry.fromJson(json))) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.habitLogs) {
              if (await syncDao.upsertRemoteHabitLog(
                HabitLogEntry.fromJson(json),
              )) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.goals) {
              if (await syncDao.upsertRemoteGoal(GoalEntry.fromJson(json))) {
                totalImported++;
              }
            }
            for (final json in remoteChangeset.journalEntries) {
              if (await syncDao.upsertRemoteJournalEntry(
                JournalEntryData.fromJson(json),
              )) {
                totalImported++;
              }
            }
          }
        }
      }

      await syncDao.completeSync(
        id: syncId,
        recordsExported: totalExported,
        recordsImported: totalImported,
        blobsTransferred: totalBlobs,
      );

      return SyncResult(
        success: true,
        recordsExported: totalExported,
        recordsImported: totalImported,
        blobsTransferred: totalBlobs,
        conflictsResolved: totalConflicts,
      );
    } catch (e) {
      await syncDao.failSync(id: syncId, errorMessage: e.toString());
      return SyncResult(success: false, errorMessage: e.toString());
    }
  }
}
