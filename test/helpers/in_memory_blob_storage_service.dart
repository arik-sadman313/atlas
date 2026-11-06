import 'dart:typed_data';

import 'package:atlas/core/errors/failures.dart';
import 'package:atlas/core/storage/blob_storage_service.dart';
import 'package:crypto/crypto.dart';

/// In-memory implementation of [BlobStorageService] for fast, deterministic unit & widget tests.
class InMemoryBlobStorageService implements BlobStorageService {
  final Map<String, Uint8List> _blobs = {};

  @override
  Future<String> writeBlob(
    Uint8List data, {
    String? fileName,
    String? mimeType,
  }) async {
    final hash = sha256.convert(data).toString().toLowerCase();
    _blobs[hash] = Uint8List.fromList(data);
    return hash;
  }

  @override
  Future<Uint8List> readBlob(String hash) async {
    final data = _blobs[hash];
    if (data == null) {
      throw StorageException('Blob not found: $hash');
    }
    return Uint8List.fromList(data);
  }

  @override
  Future<bool> hasBlob(String hash) async {
    return _blobs.containsKey(hash);
  }

  @override
  Future<bool> deleteBlob(String hash) async {
    return _blobs.remove(hash) != null;
  }

  @override
  Future<String> getBlobPath(String hash) async {
    return '/virtual/$hash';
  }

  @override
  Future<int> getBlobSize(String hash) async {
    final data = _blobs[hash];
    if (data == null) {
      throw StorageException('Blob not found: $hash');
    }
    return data.length;
  }
}
