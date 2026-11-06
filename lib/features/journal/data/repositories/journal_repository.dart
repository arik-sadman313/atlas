import 'package:drift/drift.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/database/daos/habits_dao.dart';
import '../../../../core/database/daos/journal_dao.dart';
import '../../../../core/database/daos/nodes_dao.dart';
import '../../../../core/storage/blob_storage_service.dart';
import '../../../documents/data/services/document_content_service.dart';

class JournalRepository {
  final JournalDao journalDao;
  final NodesDao nodesDao;
  final BlobStorageService blobStorage;
  final Uuid uuid;

  JournalRepository({
    required this.journalDao,
    required this.nodesDao,
    required this.blobStorage,
    Uuid? uuid,
  }) : uuid = uuid ?? const Uuid();

  Future<JournalEntryData?> findEntryByDate(
    String workspaceId,
    String journalDate,
  ) {
    return journalDao.findEntryByDate(workspaceId, journalDate);
  }

  Stream<JournalEntryData?> watchEntryByDate(
    String workspaceId,
    String journalDate,
  ) {
    return journalDao.watchEntryByDate(workspaceId, journalDate);
  }

  Future<JournalEntryData?> findEntryByNodeId(String nodeId) {
    return journalDao.findEntryByNodeId(nodeId);
  }

  Stream<JournalEntryData?> watchEntryByNodeId(String nodeId) {
    return journalDao.watchEntryByNodeId(nodeId);
  }

  Stream<List<JournalEntryData>> watchRecentEntries(
    String workspaceId, {
    int limit = 7,
  }) {
    return journalDao.watchRecentJournalEntries(workspaceId, limit: limit);
  }

  /// Finds or creates today's journal document.
  /// If none exists for [today] (or today's local date), it creates a standard
  /// rich-text node, pre-populates CAS with structured reflection sections,
  /// creates a journal_entry linking record, and returns the nodeId.
  Future<String> getOrCreateTodayJournalNode(
    String workspaceId, {
    DateTime? today,
    String? mood,
  }) async {
    final effectiveDate = today ?? DateTime.now();
    final dateStr = HabitsDao.formatDate(effectiveDate);

    final existing = await journalDao.findEntryByDate(workspaceId, dateStr);
    if (existing != null) {
      if (mood != null && mood != existing.mood) {
        await journalDao.updateJournalEntry(
          JournalEntriesCompanion(
            id: Value(existing.id),
            mood: Value(mood),
            updatedAt: Value(DateTime.now()),
          ),
        );
      }
      return existing.nodeId;
    }

    // Auto-scaffold new journal document
    final nodeId = uuid.v4();
    final now = DateTime.now();
    final formattedDate = DateFormat('EEEE, MMMM d, y').format(effectiveDate);
    final title = 'Journal: $formattedDate';

    // Build structured starter document
    final starterDeltaJson = [
      {
        'insert': '$title\n',
        'attributes': {'header': 1},
      },
      {'insert': '\n'},
      {
        'insert': 'Daily Focus\n',
        'attributes': {'header': 2},
      },
      {'insert': '\n'},
      {
        'insert': 'Key Wins\n',
        'attributes': {'header': 2},
      },
      {'insert': '\n'},
      {
        'insert': 'Reflections\n',
        'attributes': {'header': 2},
      },
      {'insert': '\n'},
    ];

    final doc = Document.fromJson(starterDeltaJson);
    final contentService = DocumentContentService(blobStorage: blobStorage);
    final contentHash = await contentService.saveDocument(doc);

    // Insert node
    await nodesDao.createNode(
      NodesCompanion.insert(
        id: nodeId,
        workspaceId: workspaceId,
        type: 'document',
        title: title,
        contentHash: Value(contentHash),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Insert journal entry record
    await journalDao.createJournalEntry(
      JournalEntriesCompanion.insert(
        id: uuid.v4(),
        workspaceId: workspaceId,
        nodeId: nodeId,
        journalDate: dateStr,
        mood: Value(mood),
        createdAt: now,
        updatedAt: now,
      ),
    );

    return nodeId;
  }

  Future<bool> updateMood(String entryId, String? mood) {
    return journalDao.updateJournalEntry(
      JournalEntriesCompanion(
        id: Value(entryId),
        mood: Value(mood),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteEntry(String entryId) {
    return journalDao.deleteJournalEntry(entryId);
  }
}

