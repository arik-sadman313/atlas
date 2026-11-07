import 'dart:io';

import 'package:atlas/core/storage/cas_storage_service.dart';
import 'package:atlas/features/documents/data/services/document_content_service.dart';
import 'package:atlas/features/documents/domain/models/document_embed_models.dart';
import 'package:atlas/features/handwriting/domain/models/atlas_ink_document.dart';
import 'package:atlas/features/handwriting/domain/models/ink_layer.dart';
import 'package:atlas/features/handwriting/domain/models/ink_point.dart';
import 'package:atlas/features/handwriting/domain/models/ink_stroke.dart';
import 'package:atlas/features/handwriting/domain/models/ink_tool.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Inline Ink Block Persistence & Round-Trip CAS Tests', () {
    late Directory tempDir;
    late CasStorageService blobStorage;
    late DocumentContentService contentService;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('atlas_ink_block_test_');
      blobStorage = CasStorageService(rootDirectory: tempDir);
      contentService = DocumentContentService(blobStorage: blobStorage);
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('InkBlockEmbed serializes and deserializes inkHash, height, and inkDocId', () {
      final embed = InkBlockEmbed.fromAttributes(
        inkHash:
            'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        height: 260.0,
        width: 760.0,
      );

      expect(embed.type, 'ink_block');
      expect(embed.height, 260.0);
      expect(embed.width, 760.0);
      expect(
        embed.inkHash,
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
      expect(embed.inkDocId, embed.inkHash);

      // Deserialization from map
      final fromMap = InkBlockEmbed.fromData({
        'inkHash': 'abc123hash',
        'height': 360.0,
      });
      expect(fromMap.inkHash, 'abc123hash');
      expect(fromMap.height, 360.0);

      // copyWith height adjustment
      final resized = embed.copyWith(height: 480.0);
      expect(resized.height, 480.0);
      expect(resized.inkHash, embed.inkHash);
    });

    test('saveInkBlockDrawing saves AtlasInkDocument to CAS and loadInkBlockDrawing restores losslessly', () async {
      final stroke1 = InkStroke(
        id: 'stroke_embed_1',
        tool: InkToolType.ballpointPen,
        color: 0xFF6366F1,
        baseWidth: 3.0,
        points: const [
          InkPoint(x: 10, y: 15, pressure: 0.6),
          InkPoint(x: 35, y: 40, pressure: 0.7),
          InkPoint(x: 80, y: 110, pressure: 0.8),
        ],
      );

      final stroke2 = InkStroke(
        id: 'stroke_embed_2',
        tool: InkToolType.highlighter,
        color: 0xFF10B981,
        baseWidth: 16.0,
        opacity: 0.4,
        points: const [InkPoint(x: 100, y: 50), InkPoint(x: 200, y: 50)],
      );

      final inkDoc = AtlasInkDocument(
        documentId: 'sketch_test_doc',
        pageNumber: 1,
        width: 760.0,
        height: 260.0,
        layers: [
          InkLayer(
            id: 'layer_main',
            name: 'Main Layer',
            strokes: [stroke1, stroke2],
          ),
        ],
      );

      // 1. Save to CAS
      final contentHash = await contentService.saveInkBlockDrawing(inkDoc);
      expect(contentHash.length, 64); // SHA-256 hex string

      // Verify blob exists in CAS storage
      final blobBytes = await blobStorage.readBlob(contentHash);
      expect(blobBytes.isNotEmpty, isTrue);

      // 2. Load from CAS
      final restoredDoc = await contentService.loadInkBlockDrawing(
        contentHash,
        documentId: 'sketch_test_doc',
        width: 760.0,
        height: 260.0,
      );

      expect(restoredDoc.width, 760.0);
      expect(restoredDoc.height, 260.0);
      expect(restoredDoc.totalStrokeCount, 2);

      final loadedLayer = restoredDoc.layers.first;
      expect(loadedLayer.strokes.length, 2);

      final loadedStroke1 = loadedLayer.strokes[0];
      expect(loadedStroke1.id, 'stroke_embed_1');
      expect(loadedStroke1.tool, InkToolType.ballpointPen);
      expect(loadedStroke1.color, 0xFF6366F1);
      expect(loadedStroke1.baseWidth, 3.0);
      expect(loadedStroke1.points.length, 3);
      expect(loadedStroke1.points[0].x, 10);
      expect(loadedStroke1.points[0].y, 15);
      expect(loadedStroke1.points[2].x, 80);
      expect(loadedStroke1.points[2].y, 110);

      final loadedStroke2 = loadedLayer.strokes[1];
      expect(loadedStroke2.id, 'stroke_embed_2');
      expect(loadedStroke2.tool, InkToolType.highlighter);
      expect(loadedStroke2.color, 0xFF10B981);
    });

    test('loadInkBlockDrawing with empty or non-existent hash returns empty document safely', () async {
      final docFromEmpty = await contentService.loadInkBlockDrawing(
        '',
        documentId: 'fallback_doc',
      );
      expect(docFromEmpty.totalStrokeCount, 0);

      final docFromMissing = await contentService.loadInkBlockDrawing(
        'non_existent_sha256_hash_value',
        documentId: 'fallback_doc_2',
      );
      expect(docFromMissing.totalStrokeCount, 0);
    });
  });
}
