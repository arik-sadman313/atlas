import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_quill/flutter_quill.dart';

import '../../../../core/storage/blob_storage_service.dart';
import '../../../handwriting/data/serializers/ink_binary_serializer.dart';
import '../../../handwriting/data/serializers/ink_json_serializer.dart';
import '../../../handwriting/domain/models/atlas_ink_document.dart';
import '../../domain/models/document_embed_models.dart';

class DocumentContentService {
  final BlobStorageService blobStorage;

  DocumentContentService({required this.blobStorage});

  /// Loads a [Document] from CAS storage by [contentHash].
  /// If [contentHash] is null or the blob cannot be found/parsed, returns a blank document.
  Future<Document> loadDocument(
    String? contentHash, {
    String? defaultTitle,
  }) async {
    if (contentHash != null && contentHash.isNotEmpty) {
      try {
        final bytes = await blobStorage.readBlob(contentHash);
        if (bytes.isNotEmpty) {
          final jsonStr = utf8.decode(bytes);
          final decoded = jsonDecode(jsonStr);
          if (decoded is List) {
            return Document.fromJson(decoded);
          } else if (decoded is Map<String, dynamic> &&
              decoded.containsKey('ops')) {
            return Document.fromJson(decoded['ops'] as List);
          }
        }
      } catch (_) {
        // Fall back to blank document on corruption
      }
    }

    return createDefaultDocument(title: defaultTitle);
  }

  /// Creates a standard default blank document.
  Document createDefaultDocument({String? title}) {
    final doc = Document();
    if (title != null && title.isNotEmpty) {
      doc.insert(0, '$title\n');
      doc.format(0, title.length, Attribute.h1);
    }
    return doc;
  }

  /// Serializes [document] to JSON bytes and saves it to CAS storage.
  /// Returns the SHA-256 [contentHash].
  Future<String> saveDocument(Document document) async {
    final deltaJson = document.toDelta().toJson();
    final jsonStr = jsonEncode(deltaJson);
    final bytes = Uint8List.fromList(utf8.encode(jsonStr));
    final hash = await blobStorage.writeBlob(bytes);
    return hash;
  }

  // =========================================================================
  // Block Embed Factory & Helpers
  // =========================================================================

  /// Creates a Callout block embed.
  static BlockEmbed createCalloutEmbed({
    String? text,
    String? content,
    String icon = '💡',
    String colorHex = '#6366F1',
  }) {
    final embed = CalloutBlockEmbed.fromAttributes(
      text: content ?? text ?? '',
      content: content ?? text ?? '',
      icon: icon,
      colorHex: colorHex,
    );
    return BlockEmbed(CalloutBlockEmbed.calloutType, embed.data);
  }

  /// Creates an inline Vector Ink canvas block embed.
  static BlockEmbed createInkBlockEmbed({
    required String inkHash,
    double height = 260.0,
    double? width,
    String? inkDocId,
  }) {
    final embed = InkBlockEmbed.fromAttributes(
      inkHash: inkHash,
      inkDocId: inkDocId ?? inkHash,
      height: height,
      width: width,
    );
    return BlockEmbed(InkBlockEmbed.inkBlockType, embed.data);
  }

  /// Creates an inline SQLite database task block embed.
  static BlockEmbed createTaskEmbed({
    required String taskId,
    required String title,
    bool isCompleted = false,
    String priority = 'medium',
  }) {
    final embed = TaskBlockEmbed.fromAttributes(
      taskId: taskId,
      title: title,
      isCompleted: isCompleted,
      priority: priority,
    );
    return BlockEmbed(TaskBlockEmbed.taskBlockType, embed.data);
  }

  /// Creates a horizontal divider embed.
  static BlockEmbed createDividerEmbed() {
    return const BlockEmbed(DividerBlockEmbed.dividerType, 'hr');
  }

  // =========================================================================
  // Ink Block CAS Persistence
  // =========================================================================

  /// Serializes an inline ink sketch document into CAS as portable vector strokes (`.atlas_ink`).
  /// Returns the content hash.
  Future<String> saveInkBlockDrawing(
    AtlasInkDocument doc, {
    String? fileName,
  }) async {
    final bytes = InkBinarySerializer.serialize(doc);
    final hash = await blobStorage.writeBlob(
      bytes,
      fileName: fileName ?? 'sketch_${doc.documentId}.atlas_ink',
      mimeType: 'application/vnd.atlas.ink',
    );
    return hash;
  }

  /// Loads an inline ink sketch document from CAS storage by [inkHash].
  Future<AtlasInkDocument> loadInkBlockDrawing(
    String inkHash, {
    String documentId = 'inline_sketch',
    double width = 760.0,
    double height = 240.0,
  }) async {
    if (inkHash.isEmpty) {
      return AtlasInkDocument.empty(
        documentId: documentId,
        pageNumber: 1,
        width: width,
        height: height,
      );
    }

    try {
      final bytes = await blobStorage.readBlob(inkHash);
      if (bytes.length >= 8 &&
          bytes[0] == 0x41 &&
          bytes[1] == 0x54 &&
          bytes[2] == 0x4C &&
          bytes[3] == 0x41) {
        return InkBinarySerializer.deserialize(bytes);
      } else {
        return InkJsonSerializer.deserializeFromBytes(bytes);
      }
    } catch (_) {
      return AtlasInkDocument.empty(
        documentId: documentId,
        pageNumber: 1,
        width: width,
        height: height,
      );
    }
  }

  // =========================================================================
  // Block Extraction & Plain Text
  // =========================================================================

  /// Extracts all [CalloutBlockEmbed] instances from a [Document].
  static List<CalloutBlockEmbed> extractCallouts(Document document) {
    final results = <CalloutBlockEmbed>[];
    for (final op in document.toDelta().toList()) {
      if (op.data is Map) {
        final map = op.data as Map;
        if (map.containsKey(CalloutBlockEmbed.calloutType)) {
          results.add(
            CalloutBlockEmbed.fromData(map[CalloutBlockEmbed.calloutType]),
          );
        } else if (map.containsKey(BlockEmbed.customType)) {
          final custom = map[BlockEmbed.customType];
          try {
            final parsed = jsonDecode(custom.toString());
            if (parsed is Map &&
                parsed.containsKey(CalloutBlockEmbed.calloutType)) {
              results.add(
                CalloutBlockEmbed.fromData(
                  parsed[CalloutBlockEmbed.calloutType],
                ),
              );
            }
          } catch (_) {}
        }
      }
    }
    return results;
  }

  /// Extracts all [InkBlockEmbed] instances from a [Document].
  static List<InkBlockEmbed> extractInkBlocks(Document document) {
    final results = <InkBlockEmbed>[];
    for (final op in document.toDelta().toList()) {
      if (op.data is Map) {
        final map = op.data as Map;
        if (map.containsKey(InkBlockEmbed.inkBlockType)) {
          results.add(InkBlockEmbed.fromData(map[InkBlockEmbed.inkBlockType]));
        } else if (map.containsKey(BlockEmbed.customType)) {
          final custom = map[BlockEmbed.customType];
          try {
            final parsed = jsonDecode(custom.toString());
            if (parsed is Map &&
                parsed.containsKey(InkBlockEmbed.inkBlockType)) {
              results.add(
                InkBlockEmbed.fromData(parsed[InkBlockEmbed.inkBlockType]),
              );
            }
          } catch (_) {}
        }
      }
    }
    return results;
  }

  /// Extracts all [TaskBlockEmbed] instances from a [Document].
  static List<TaskBlockEmbed> extractTasks(Document document) {
    final results = <TaskBlockEmbed>[];
    for (final op in document.toDelta().toList()) {
      if (op.data is Map) {
        final map = op.data as Map;
        if (map.containsKey(TaskBlockEmbed.taskBlockType)) {
          results.add(
            TaskBlockEmbed.fromData(map[TaskBlockEmbed.taskBlockType]),
          );
        } else if (map.containsKey(BlockEmbed.customType)) {
          final custom = map[BlockEmbed.customType];
          try {
            final parsed = jsonDecode(custom.toString());
            if (parsed is Map &&
                parsed.containsKey(TaskBlockEmbed.taskBlockType)) {
              results.add(
                TaskBlockEmbed.fromData(parsed[TaskBlockEmbed.taskBlockType]),
              );
            }
          } catch (_) {}
        }
      }
    }
    return results;
  }

  /// Extracts all plain text from [document] for search indexing and link extraction.
  /// Also includes text inside Callout boxes and tasks.
  static String extractPlainText(Document document) {
    final buffer = StringBuffer();
    for (final op in document.toDelta().toList()) {
      if (op.data is String) {
        buffer.write(op.data);
      } else if (op.data is Map) {
        final map = op.data as Map;
        if (map.containsKey(CalloutBlockEmbed.calloutType)) {
          final callout = CalloutBlockEmbed.fromData(
            map[CalloutBlockEmbed.calloutType],
          );
          if (callout.text.isNotEmpty) {
            buffer.write(' ${callout.text} ');
          }
        } else if (map.containsKey(TaskBlockEmbed.taskBlockType)) {
          final task = TaskBlockEmbed.fromData(
            map[TaskBlockEmbed.taskBlockType],
          );
          if (task.title.isNotEmpty) {
            buffer.write(' ${task.title} ');
          }
        } else if (map.containsKey(BlockEmbed.customType)) {
          final customStr = map[BlockEmbed.customType]?.toString() ?? '';
          try {
            final parsed = jsonDecode(customStr);
            if (parsed is Map) {
              if (parsed.containsKey(CalloutBlockEmbed.calloutType)) {
                final callout = CalloutBlockEmbed.fromData(
                  parsed[CalloutBlockEmbed.calloutType],
                );
                if (callout.text.isNotEmpty) {
                  buffer.write(' ${callout.text} ');
                }
              } else if (parsed.containsKey(TaskBlockEmbed.taskBlockType)) {
                final task = TaskBlockEmbed.fromData(
                  parsed[TaskBlockEmbed.taskBlockType],
                );
                if (task.title.isNotEmpty) {
                  buffer.write(' ${task.title} ');
                }
              }
            }
          } catch (_) {}
        }
      }
    }
    return buffer.toString();
  }
}
