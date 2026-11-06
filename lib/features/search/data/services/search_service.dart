import 'dart:convert';

import 'package:intl/intl.dart';

import '../../../../core/database/daos/calendar_dao.dart';
import '../../../../core/database/daos/journal_dao.dart';
import '../../../../core/database/daos/links_dao.dart';
import '../../../../core/database/daos/nodes_dao.dart';
import '../../../../core/database/daos/tasks_dao.dart';
import '../../../../core/storage/blob_storage_service.dart';
import '../../domain/models/search_result_item.dart';
import 'search_scorer.dart';

class SearchService {
  final NodesDao nodesDao;
  final TasksDao tasksDao;
  final CalendarDao calendarDao;
  final JournalDao journalDao;
  final LinksDao linksDao;
  final BlobStorageService blobStorage;

  SearchService({
    required this.nodesDao,
    required this.tasksDao,
    required this.calendarDao,
    required this.journalDao,
    required this.linksDao,
    required this.blobStorage,
  });

  /// Executes multi-entity search across the entire workspace.
  Future<List<SearchResultItem>> search(
    String workspaceId,
    String query, {
    SearchFilter filter = SearchFilter.all,
    int limit = 50,
  }) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) return [];

    final results = <SearchResultItem>[];
    final now = DateTime.now();

    // 1. Search Nodes (Documents & Notebooks)
    if (filter == SearchFilter.all ||
        filter == SearchFilter.document ||
        filter == SearchFilter.notebook) {
      final nodes = await nodesDao.getAllNodes(workspaceId);

      for (final node in nodes) {
        final isNotebook = node.type == 'notebook';
        if (filter == SearchFilter.document && isNotebook) continue;
        if (filter == SearchFilter.notebook && !isNotebook) continue;

        String? bodyText;
        if (node.contentHash != null && node.contentHash!.isNotEmpty) {
          try {
            final bytes = await blobStorage.readBlob(node.contentHash!);
            if (bytes.isNotEmpty) {
              final jsonStr = utf8.decode(bytes);
              final decoded = jsonDecode(jsonStr);
              bodyText = _extractPlainTextFromDelta(decoded);
            }
          } catch (_) {
            // Gracefully ignore CAS parsing issues
          }
        }

        final score = SearchScorer.computeScore(
          query: cleanQuery,
          title: node.title,
          content: bodyText,
          updatedAt: node.updatedAt,
          now: now,
        );

        if (score > 0.0) {
          final snippet = SearchScorer.extractSnippet(bodyText, cleanQuery);
          results.add(
            SearchResultItem(
              id: node.id,
              title: node.title,
              subtitle: isNotebook ? 'Notebook' : 'Document',
              snippet: snippet,
              type: isNotebook
                  ? SearchEntityType.notebook
                  : SearchEntityType.document,
              route: isNotebook
                  ? '/notebooks/${node.id}'
                  : '/documents/${node.id}',
              score: score,
              updatedAt: node.updatedAt,
              parentBreadcrumb: isNotebook ? 'Notebooks' : 'Documents',
              matchedTerms: [cleanQuery],
            ),
          );
        }
      }
    }

    // 2. Search Tasks
    if (filter == SearchFilter.all || filter == SearchFilter.task) {
      final tasks = await tasksDao.getTasksForWorkspace(workspaceId);
      final projects = await tasksDao.getProjects(workspaceId);
      final projectMap = {for (final p in projects) p.id: p.name};

      for (final task in tasks) {
        final projectName = task.projectId != null
            ? projectMap[task.projectId]
            : null;

        final score = SearchScorer.computeScore(
          query: cleanQuery,
          title: task.title,
          content: task.description,
          tagOrProject: projectName,
          updatedAt: task.updatedAt,
          now: now,
        );

        if (score > 0.0) {
          final snippet = SearchScorer.extractSnippet(
            task.description,
            cleanQuery,
          );
          final priorityLabel = 'P${task.priority}';
          final statusLabel = task.isCompleted ? 'Completed' : 'Pending';

          results.add(
            SearchResultItem(
              id: task.id,
              title: task.title,
              subtitle: projectName != null
                  ? '$statusLabel · $priorityLabel · $projectName'
                  : '$statusLabel · $priorityLabel',
              snippet: snippet,
              type: SearchEntityType.task,
              route: '/tasks',
              score: score,
              updatedAt: task.updatedAt,
              parentBreadcrumb: projectName ?? 'Tasks',
              matchedTerms: [cleanQuery],
            ),
          );
        }
      }
    }

    // 3. Search Calendar Events
    if (filter == SearchFilter.all || filter == SearchFilter.calendar) {
      final events = await calendarDao.watchAllEvents(workspaceId).first;

      for (final event in events) {
        final score = SearchScorer.computeScore(
          query: cleanQuery,
          title: event.title,
          content: event.description != null
              ? '${event.description!} ${event.location ?? ""}'
              : event.location,
          updatedAt: event.updatedAt,
          now: now,
        );

        if (score > 0.0) {
          final timeStr = DateFormat.yMMMd().add_jm().format(event.startTime);
          final snippet = SearchScorer.extractSnippet(
            event.description,
            cleanQuery,
          );

          results.add(
            SearchResultItem(
              id: event.id,
              title: event.title,
              subtitle: 'Event on $timeStr',
              snippet: snippet,
              type: SearchEntityType.calendarEvent,
              route: '/calendar',
              score: score,
              updatedAt: event.updatedAt,
              parentBreadcrumb: event.location ?? 'Calendar',
              matchedTerms: [cleanQuery],
            ),
          );
        }
      }
    }

    // 4. Search Daily Journal Entries
    if (filter == SearchFilter.all || filter == SearchFilter.journal) {
      final journals = await journalDao.getRecentJournalEntries(
        workspaceId,
        limit: 100,
      );

      for (final journal in journals) {
        final node = await nodesDao.getNode(journal.nodeId);
        if (node == null) continue;

        String? bodyText;
        if (node.contentHash != null && node.contentHash!.isNotEmpty) {
          try {
            final bytes = await blobStorage.readBlob(node.contentHash!);
            if (bytes.isNotEmpty) {
              final jsonStr = utf8.decode(bytes);
              bodyText = _extractPlainTextFromDelta(jsonDecode(jsonStr));
            }
          } catch (_) {}
        }

        final score = SearchScorer.computeScore(
          query: cleanQuery,
          title: 'Journal: ${journal.journalDate}',
          content: bodyText,
          tagOrProject: journal.mood,
          updatedAt: journal.updatedAt,
          now: now,
        );

        if (score > 0.0) {
          final snippet = SearchScorer.extractSnippet(bodyText, cleanQuery);
          results.add(
            SearchResultItem(
              id: journal.id,
              title: 'Journal: ${journal.journalDate}',
              subtitle: journal.mood != null
                  ? 'Mood: ${journal.mood}'
                  : 'Daily Reflection',
              snippet: snippet,
              type: SearchEntityType.journal,
              route: '/documents/${journal.nodeId}',
              score: score,
              updatedAt: journal.updatedAt,
              parentBreadcrumb: 'Journal',
              matchedTerms: [cleanQuery],
            ),
          );
        }
      }
    }

    // 5. Search Tags
    if (filter == SearchFilter.all) {
      final tags = await linksDao.getAllTagsForWorkspace(workspaceId);
      for (final tag in tags) {
        final score = SearchScorer.computeScore(
          query: cleanQuery,
          title: '#${tag.name}',
          updatedAt: tag.createdAt,
          now: now,
        );

        if (score > 0.0) {
          results.add(
            SearchResultItem(
              id: tag.id,
              title: '#${tag.name}',
              subtitle: 'Workspace Tag',
              type: SearchEntityType.tag,
              route: '/graph',
              score: score,
              updatedAt: tag.createdAt,
              parentBreadcrumb: 'Taxonomy',
              matchedTerms: [cleanQuery],
            ),
          );
        }
      }
    }

    // Sort descending by relevance score
    results.sort((a, b) => b.score.compareTo(a.score));

    if (results.length > limit) {
      return results.sublist(0, limit);
    }
    return results;
  }

  static String _extractPlainTextFromDelta(dynamic deltaJson) {
    final buffer = StringBuffer();
    List ops = [];
    if (deltaJson is List) {
      ops = deltaJson;
    } else if (deltaJson is Map && deltaJson['ops'] is List) {
      ops = deltaJson['ops'] as List;
    }

    for (final op in ops) {
      if (op is Map && op['insert'] is String) {
        buffer.write(op['insert']);
      }
    }
    return buffer.toString();
  }
}
