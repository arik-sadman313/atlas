import 'package:atlas/core/database/app_database.dart';
import 'package:atlas/core/database/daos/ink_dao.dart';
import 'package:atlas/core/storage/blob_storage_service.dart';
import 'package:drift/drift.dart';

import '../../domain/models/atlas_ink_document.dart';
import '../serializers/ink_binary_serializer.dart';
import '../serializers/ink_json_serializer.dart';

class InkRepository {
  final InkDao inkDao;
  final BlobStorageService blobStorage;

  InkRepository({required this.inkDao, required this.blobStorage});

  Future<AtlasInkDocument> loadPageDrawing(InkPageEntry page) async {
    final hash = page.portableInkHash;
    if (hash == null || hash.isEmpty) {
      return AtlasInkDocument.empty(
        documentId: page.documentId,
        pageNumber: page.pageNumber,
        width: page.width,
        height: page.height,
        backgroundTemplate: page.templateType,
        backgroundColor: page.backgroundColor,
      );
    }

    try {
      final bytes = await blobStorage.readBlob(hash);
      // Check if binary format by inspecting magic bytes
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
      // Fallback to empty document on read failure to prevent crash
      return AtlasInkDocument.empty(
        documentId: page.documentId,
        pageNumber: page.pageNumber,
        width: page.width,
        height: page.height,
        backgroundTemplate: page.templateType,
        backgroundColor: page.backgroundColor,
      );
    }
  }

  Future<InkPageEntry> savePageDrawing({
    required InkPageEntry page,
    required AtlasInkDocument doc,
    Uint8List? rawPencilKitBytes,
    Uint8List? previewPngBytes,
  }) async {
    // 1. Serialize portable ink to binary format
    final inkBytes = InkBinarySerializer.serialize(doc);
    final inkHash = await blobStorage.writeBlob(
      inkBytes,
      fileName: 'page_${page.pageNumber}.atlas_ink',
      mimeType: 'application/vnd.atlas.ink',
    );

    // 2. Optionally store original Apple PencilKit binary
    String? pkHash = page.rawPencilkitHash;
    if (rawPencilKitBytes != null && rawPencilKitBytes.isNotEmpty) {
      pkHash = await blobStorage.writeBlob(
        rawPencilKitBytes,
        fileName: 'page_${page.pageNumber}.pkdrawing',
        mimeType: 'application/octet-stream',
      );
    }

    // 3. Optionally store raster preview PNG
    String? pngHash = page.previewPngHash;
    if (previewPngBytes != null && previewPngBytes.isNotEmpty) {
      pngHash = await blobStorage.writeBlob(
        previewPngBytes,
        fileName: 'preview_${page.pageNumber}.png',
        mimeType: 'image/png',
      );
    }

    // 4. Update SQLite ink_pages table
    final updatedCompanion = page
        .toCompanion(true)
        .copyWith(
          portableInkHash: Value(inkHash),
          rawPencilkitHash: Value(pkHash),
          previewPngHash: Value(pngHash),
          updatedAt: Value(DateTime.now()),
        );

    await inkDao.updatePage(updatedCompanion);

    return (await inkDao.getPage(page.id))!;
  }
}
