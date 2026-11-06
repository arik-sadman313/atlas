import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart';
import '../../../../core/storage/blob_storage_service.dart';

/// Service responsible for bulk exporting workspace documents into standard Markdown (.md)
/// files with YAML frontmatter, Obsidian [[WikiLinks]], and referenced CAS image assets.
class MarkdownExportService {
  final AppDatabase database;
  final BlobStorageService blobStorage;

  MarkdownExportService({required this.database, required this.blobStorage});

  /// Exports all document nodes for [workspaceId] into a single ZIP archive.
  /// Returns the generated [File].
  Future<File> exportWorkspaceToMarkdownZip({
    required String workspaceId,
    String? outputPath,
  }) async {
    final archive = Archive();
    final exportedImages = <String>{};

    // 1. Fetch all active document nodes in workspace
    final nodes =
        await (database.select(database.nodes)
              ..where(
                (tbl) =>
                    tbl.workspaceId.equals(workspaceId) &
                    tbl.type.equals('document') &
                    tbl.isDeleted.equals(false) &
                    tbl.deletedAt.isNull(),
              )
              ..orderBy([
                (tbl) => OrderingTerm(
                  expression: tbl.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ]))
            .get();

    // 2. Fetch tags for each node
    for (var i = 0; i < nodes.length; i++) {
      final node = nodes[i];

      // Fetch node tags
      final tagRows =
          await (database.select(database.nodeTags).join([
                innerJoin(
                  database.tags,
                  database.tags.id.equalsExp(database.nodeTags.tagId),
                ),
              ])..where(
                database.nodeTags.nodeId.equals(node.id) &
                    database.nodeTags.deletedAt.isNull() &
                    database.tags.deletedAt.isNull(),
              ))
              .get();

      final tagNames = tagRows
          .map((r) => r.readTable(database.tags).name)
          .toList();

      // Convert content to Markdown
      final (markdownBody, imageHashes) = await _convertNodeContentToMarkdown(
        node.contentHash,
      );

      // Add referenced CAS images to archive
      for (final hash in imageHashes) {
        if (!exportedImages.contains(hash)) {
          try {
            final imageBytes = await blobStorage.readBlob(hash);
            if (imageBytes.isNotEmpty) {
              final ext = _detectImageExtension(imageBytes);
              archive.addFile(
                ArchiveFile('assets/$hash.$ext', imageBytes.length, imageBytes),
              );
              exportedImages.add(hash);
            }
          } catch (_) {
            // Blob missing or unreadable - continue without blocking export
          }
        }
      }

      // Build YAML frontmatter
      final frontmatter = _buildFrontmatter(node: node, tags: tagNames);

      final fullMarkdown = '$frontmatter\n\n$markdownBody\n';
      final markdownBytes = Uint8List.fromList(utf8.encode(fullMarkdown));

      // Sanitize filename and prevent collisions
      final safeTitle = _sanitizeFilename(node.title);
      final filename =
          '${safeTitle}_${node.id.substring(0, node.id.length > 8 ? 8 : node.id.length)}.md';

      archive.addFile(
        ArchiveFile(filename, markdownBytes.length, markdownBytes),
      );
    }

    // 3. Compress into ZIP archive
    final zipEncoder = ZipEncoder();
    final encodedZip = zipEncoder.encode(archive);

    final targetPath =
        outputPath ??
        '${Directory.systemTemp.path}/atlas_markdown_export_${DateTime.now().millisecondsSinceEpoch}.zip';
    final zipFile = File(targetPath);
    await zipFile.writeAsBytes(encodedZip, flush: true);

    return zipFile;
  }

  /// Converts Delta JSON in CAS to Markdown text and extracts image references.
  Future<(String, Set<String>)> _convertNodeContentToMarkdown(
    String? contentHash,
  ) async {
    final imageHashes = <String>{};

    if (contentHash == null || contentHash.isEmpty) {
      return ('', imageHashes);
    }

    try {
      final bytes = await blobStorage.readBlob(contentHash);
      if (bytes.isEmpty) return ('', imageHashes);

      final jsonStr = utf8.decode(bytes);
      final decoded = jsonDecode(jsonStr);

      List<dynamic>? ops;
      if (decoded is List) {
        ops = decoded;
      } else if (decoded is Map<String, dynamic> && decoded['ops'] is List) {
        ops = decoded['ops'] as List<dynamic>;
      }

      if (ops == null || ops.isEmpty) {
        return (jsonStr, imageHashes);
      }

      final markdown = _convertDeltaOpsToMarkdown(ops, imageHashes);
      return (markdown, imageHashes);
    } catch (_) {
      return ('', imageHashes);
    }
  }

  /// Converts Quill Delta ops into standard Markdown.
  String _convertDeltaOpsToMarkdown(
    List<dynamic> ops,
    Set<String> imageHashes,
  ) {
    final lines = <_DeltaLine>[];
    var currentLine = _DeltaLine();

    for (final op in ops) {
      if (op is! Map<String, dynamic>) continue;
      final insert = op['insert'];
      final attrs = op['attributes'] as Map<String, dynamic>?;

      if (insert is Map<String, dynamic>) {
        // Embed object
        if (insert.containsKey('image')) {
          final imgUrl = insert['image'].toString();
          final cleanHash = _extractImageHash(imgUrl);
          imageHashes.add(cleanHash);
          currentLine.spans.add(
            _DeltaSpan(text: '', imageHash: cleanHash, attributes: attrs),
          );
        }
      } else if (insert is String) {
        final parts = insert.split('\n');
        for (var i = 0; i < parts.length; i++) {
          final part = parts[i];
          if (part.isNotEmpty) {
            currentLine.spans.add(_DeltaSpan(text: part, attributes: attrs));
          }

          // If not the last part, a newline was encountered
          if (i < parts.length - 1) {
            currentLine.lineAttributes = attrs;
            lines.add(currentLine);
            currentLine = _DeltaLine();
          }
        }
      }
    }

    if (currentLine.spans.isNotEmpty) {
      lines.add(currentLine);
    }

    // Render lines to Markdown
    final buffer = StringBuffer();
    bool inCodeBlock = false;

    for (final line in lines) {
      final lineAttrs = line.lineAttributes ?? {};
      final isCodeBlock = lineAttrs['code-block'] == true;

      // Handle code block transitions
      if (isCodeBlock && !inCodeBlock) {
        buffer.writeln('```');
        inCodeBlock = true;
      } else if (!isCodeBlock && inCodeBlock) {
        buffer.writeln('```');
        inCodeBlock = false;
      }

      if (inCodeBlock) {
        final lineText = line.spans.map((s) => s.text).join();
        buffer.writeln(lineText);
        continue;
      }

      // Determine line prefix
      String prefix = '';
      if (lineAttrs['header'] == 1) {
        prefix = '# ';
      } else if (lineAttrs['header'] == 2) {
        prefix = '## ';
      } else if (lineAttrs['header'] == 3) {
        prefix = '### ';
      } else if (lineAttrs['list'] == 'bullet') {
        prefix = '- ';
      } else if (lineAttrs['list'] == 'ordered') {
        prefix = '1. ';
      } else if (lineAttrs['list'] == 'checked') {
        prefix = '- [x] ';
      } else if (lineAttrs['list'] == 'unchecked') {
        prefix = '- [ ] ';
      } else if (lineAttrs['blockquote'] == true) {
        prefix = '> ';
      }

      buffer.write(prefix);

      for (final span in line.spans) {
        if (span.imageHash != null) {
          buffer.write('![image](assets/${span.imageHash}.png)');
          continue;
        }

        var text = span.text;
        final attrs = span.attributes;
        if (attrs == null || attrs.isEmpty) {
          buffer.write(text);
          continue;
        }

        // Inline formatting
        if (attrs['code'] == true) {
          text = '`$text`';
        }
        if (attrs['bold'] == true && attrs['italic'] == true) {
          text = '***$text***';
        } else if (attrs['bold'] == true) {
          text = '**$text**';
        } else if (attrs['italic'] == true) {
          text = '*$text*';
        }
        if (attrs['strike'] == true) {
          text = '~~$text~~';
        }
        if (attrs['link'] != null) {
          final link = attrs['link'].toString();
          if (link.startsWith('atlas://') ||
              link.startsWith('[[') && link.endsWith(']]')) {
            text = '[[$text]]';
          } else {
            text = '[$text]($link)';
          }
        }

        buffer.write(text);
      }

      buffer.writeln();
    }

    if (inCodeBlock) {
      buffer.writeln('```');
    }

    return buffer.toString().trimRight();
  }

  String _buildFrontmatter({
    required NodeEntry node,
    required List<String> tags,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('id: "${node.id}"');
    buffer.writeln('title: "${node.title.replaceAll('"', r'\"')}"');
    buffer.writeln('created: "${node.createdAt.toUtc().toIso8601String()}"');
    buffer.writeln('updated: "${node.updatedAt.toUtc().toIso8601String()}"');
    buffer.writeln('type: "${node.type}"');
    if (tags.isNotEmpty) {
      buffer.writeln('tags:');
      for (final tag in tags) {
        buffer.writeln('  - "${tag.replaceAll('"', r'\"')}"');
      }
    } else {
      buffer.writeln('tags: []');
    }
    buffer.writeln('---');
    return buffer.toString();
  }

  String _sanitizeFilename(String title) {
    var sanitized = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (sanitized.isEmpty) {
      sanitized = 'Untitled';
    }
    return sanitized;
  }

  String _extractImageHash(String pathOrHash) {
    if (pathOrHash.contains('/')) {
      final name = pathOrHash.split('/').last;
      return name.split('.').first;
    }
    return pathOrHash.split('.').first;
  }

  String _detectImageExtension(Uint8List bytes) {
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'png';
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF) {
      return 'jpg';
    }
    return 'png';
  }
}

class _DeltaSpan {
  final String text;
  final String? imageHash;
  final Map<String, dynamic>? attributes;

  _DeltaSpan({required this.text, this.imageHash, this.attributes});
}

class _DeltaLine {
  final List<_DeltaSpan> spans = [];
  Map<String, dynamic>? lineAttributes;
}
