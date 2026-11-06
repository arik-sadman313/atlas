import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

class AtlasChangeset {
  final String deviceId;
  final int sequence;
  final DateTime timestamp;
  final List<Map<String, dynamic>> workspaces;
  final List<Map<String, dynamic>> nodes;
  final List<Map<String, dynamic>> nodeLinks;
  final List<Map<String, dynamic>> tags;
  final List<Map<String, dynamic>> nodeTags;
  final List<Map<String, dynamic>> inkPages;
  final List<Map<String, dynamic>> pdfDocuments;
  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> tasks;
  final List<Map<String, dynamic>> calendarEvents;
  final List<Map<String, dynamic>> habits;
  final List<Map<String, dynamic>> habitLogs;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> journalEntries;
  final List<String> referencedBlobHashes;

  const AtlasChangeset({
    required this.deviceId,
    required this.sequence,
    required this.timestamp,
    this.workspaces = const [],
    this.nodes = const [],
    this.nodeLinks = const [],
    this.tags = const [],
    this.nodeTags = const [],
    this.inkPages = const [],
    this.pdfDocuments = const [],
    this.projects = const [],
    this.tasks = const [],
    this.calendarEvents = const [],
    this.habits = const [],
    this.habitLogs = const [],
    this.goals = const [],
    this.journalEntries = const [],
    this.referencedBlobHashes = const [],
  });

  bool get isEmpty =>
      workspaces.isEmpty &&
      nodes.isEmpty &&
      nodeLinks.isEmpty &&
      tags.isEmpty &&
      nodeTags.isEmpty &&
      inkPages.isEmpty &&
      pdfDocuments.isEmpty &&
      projects.isEmpty &&
      tasks.isEmpty &&
      calendarEvents.isEmpty &&
      habits.isEmpty &&
      habitLogs.isEmpty &&
      goals.isEmpty &&
      journalEntries.isEmpty;

  int get totalRecordsCount =>
      workspaces.length +
      nodes.length +
      nodeLinks.length +
      tags.length +
      nodeTags.length +
      inkPages.length +
      pdfDocuments.length +
      projects.length +
      tasks.length +
      calendarEvents.length +
      habits.length +
      habitLogs.length +
      goals.length +
      journalEntries.length;

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'sequence': sequence,
    'timestamp': timestamp.toUtc().toIso8601String(),
    'workspaces': workspaces,
    'nodes': nodes,
    'nodeLinks': nodeLinks,
    'tags': tags,
    'nodeTags': nodeTags,
    'inkPages': inkPages,
    'pdfDocuments': pdfDocuments,
    'projects': projects,
    'tasks': tasks,
    'calendarEvents': calendarEvents,
    'habits': habits,
    'habitLogs': habitLogs,
    'goals': goals,
    'journalEntries': journalEntries,
    'referencedBlobHashes': referencedBlobHashes,
  };

  factory AtlasChangeset.fromJson(Map<String, dynamic> json) {
    return AtlasChangeset(
      deviceId: json['deviceId']?.toString() ?? '',
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      timestamp:
          DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now().toUtc(),
      workspaces: _castList(json['workspaces']),
      nodes: _castList(json['nodes']),
      nodeLinks: _castList(json['nodeLinks']),
      tags: _castList(json['tags']),
      nodeTags: _castList(json['nodeTags']),
      inkPages: _castList(json['inkPages']),
      pdfDocuments: _castList(json['pdfDocuments']),
      projects: _castList(json['projects']),
      tasks: _castList(json['tasks']),
      calendarEvents: _castList(json['calendarEvents']),
      habits: _castList(json['habits']),
      habitLogs: _castList(json['habitLogs']),
      goals: _castList(json['goals']),
      journalEntries: _castList(json['journalEntries']),
      referencedBlobHashes:
          (json['referencedBlobHashes'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  static List<Map<String, dynamic>> _castList(dynamic list) {
    if (list is List) {
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    }
    return [];
  }

  Uint8List encodeCompressed() {
    final jsonStr = jsonEncode(toJson());
    final rawBytes = utf8.encode(jsonStr);
    final compressed = GZipEncoder().encode(rawBytes);
    return Uint8List.fromList(compressed);
  }

  static AtlasChangeset decodeCompressed(Uint8List compressedBytes) {
    List<int> rawBytes;
    try {
      rawBytes = GZipDecoder().decodeBytes(compressedBytes);
    } catch (_) {
      rawBytes = compressedBytes; // fallback to uncompressed if plain JSON
    }
    final jsonStr = utf8.decode(rawBytes);
    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AtlasChangeset.fromJson(json);
  }
}
