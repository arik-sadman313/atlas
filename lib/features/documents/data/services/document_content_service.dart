import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_quill/flutter_quill.dart';

import '../../../../core/storage/blob_storage_service.dart';

class DocumentContentService {
  final BlobStorageService blobStorage;

  DocumentContentService({required this.blobStorage});

  /// Loads a [Document] from CAS storage by [contentHash].
  /// If [contentHash] is null or the blob cannot be found/parsed, returns a blank document.
  Future<Document> loadDocument(String? contentHash, {String? defaultTitle}) async {
    if (contentHash != null && contentHash.isNotEmpty) {
      try {
        final bytes = await blobStorage.readBlob(contentHash);
        if (bytes.isNotEmpty) {
          final jsonStr = utf8.decode(bytes);
          final decoded = jsonDecode(jsonStr);
          if (decoded is List) {
            return Document.fromJson(decoded);
          } else if (decoded is Map<String, dynamic> && decoded.containsKey('ops')) {
            return Document.fromJson(decoded['ops'] as List);
          }
        }
      } catch (_) {
        // Fall back to blank document on corruption
      }
    }

    return createDefaultDocument(title: defaultTitle);
  }

  /// Creates a standard default document.
  Document createDefaultDocument({String? title}) {
    final doc = Document();
    if (title != null && title.trim().isNotEmpty) {
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

  /// Extracts all plain text from [document] for search indexing and link extraction.
  static String extractPlainText(Document document) {
    return document.toPlainText();
  }
}
