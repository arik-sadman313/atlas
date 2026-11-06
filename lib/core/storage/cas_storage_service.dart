import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import '../errors/failures.dart';
import 'blob_storage_service.dart';

class CasStorageService implements BlobStorageService {
  final Directory rootDirectory;

  CasStorageService({required this.rootDirectory}) {
    if (!rootDirectory.existsSync()) {
      rootDirectory.createSync(recursive: true);
    }
  }

  String _computeHash(Uint8List data) {
    return sha256.convert(data).toString().toLowerCase();
  }

  File _resolveBlobFile(String hash) {
    if (hash.length < 2) {
      throw StorageException('Invalid hash format: $hash');
    }
    final prefix = hash.substring(0, 2);
    final partitionDir = Directory(p.join(rootDirectory.path, prefix));
    return File(p.join(partitionDir.path, hash));
  }

  @override
  Future<String> writeBlob(
    Uint8List data, {
    String? fileName,
    String? mimeType,
  }) async {
    try {
      final hash = _computeHash(data);
      final file = _resolveBlobFile(hash);

      if (await file.exists()) {
        // Blob already stored (deduplicated)
        return hash;
      }

      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }

      // Atomic write: write to temp file then rename
      final tempFile = File(
        '${file.path}.tmp_${DateTime.now().microsecondsSinceEpoch}',
      );
      await tempFile.writeAsBytes(data, flush: true);
      await tempFile.rename(file.path);

      return hash;
    } catch (e) {
      if (e is AtlasException) rethrow;
      throw StorageException('Failed to write blob to CAS storage', e);
    }
  }

  @override
  Future<Uint8List> readBlob(String hash) async {
    try {
      final file = _resolveBlobFile(hash);
      if (!await file.exists()) {
        throw BlobNotFoundException(hash);
      }
      return await file.readAsBytes();
    } catch (e) {
      if (e is AtlasException) rethrow;
      throw StorageException('Failed to read blob $hash from CAS storage', e);
    }
  }

  @override
  Future<bool> hasBlob(String hash) async {
    try {
      final file = _resolveBlobFile(hash);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> deleteBlob(String hash) async {
    try {
      final file = _resolveBlobFile(hash);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      throw StorageException('Failed to delete blob $hash from CAS storage', e);
    }
  }

  @override
  Future<String> getBlobPath(String hash) async {
    final file = _resolveBlobFile(hash);
    return file.path;
  }

  @override
  Future<int> getBlobSize(String hash) async {
    final file = _resolveBlobFile(hash);
    if (!await file.exists()) {
      throw BlobNotFoundException(hash);
    }
    return await file.length();
  }
}
