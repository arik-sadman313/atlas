import 'dart:convert';
import 'dart:typed_data';

import 'package:atlas/core/errors/failures.dart';

import '../../domain/models/atlas_ink_document.dart';

class InkJsonSerializer {
  static String serialize(AtlasInkDocument document) {
    try {
      return jsonEncode(document.toJson());
    } catch (e) {
      throw StorageException('Failed to serialize AtlasInkDocument to JSON', e);
    }
  }

  static Uint8List serializeToBytes(AtlasInkDocument document) {
    final jsonStr = serialize(document);
    return Uint8List.fromList(utf8.encode(jsonStr));
  }

  static AtlasInkDocument deserialize(String jsonString) {
    try {
      final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
      final version = decoded['version'] as num? ?? 1;

      if (version > AtlasInkDocument.currentSchemaVersion) {
        // Handle future version gracefully if needed, or throw version error
      }

      return AtlasInkDocument.fromJson(decoded);
    } catch (e) {
      throw StorageException(
        'Failed to deserialize JSON to AtlasInkDocument',
        e,
      );
    }
  }

  static AtlasInkDocument deserializeFromBytes(Uint8List bytes) {
    final jsonStr = utf8.decode(bytes);
    return deserialize(jsonStr);
  }
}
