import 'dart:convert';

class VaultManifest {
  final String formatVersion;
  final String appVersion;
  final String createdAt;
  final String deviceId;
  final String deviceName;
  final int totalNodes;
  final String databaseChecksum;
  final Map<String, String> blobs; // relativePath -> sha256

  const VaultManifest({
    this.formatVersion = '1.0',
    this.appVersion = '0.1.0',
    required this.createdAt,
    required this.deviceId,
    required this.deviceName,
    required this.totalNodes,
    required this.databaseChecksum,
    required this.blobs,
  });

  Map<String, dynamic> toJson() => {
    'formatVersion': formatVersion,
    'appVersion': appVersion,
    'createdAt': createdAt,
    'deviceId': deviceId,
    'deviceName': deviceName,
    'totalNodes': totalNodes,
    'databaseChecksum': databaseChecksum,
    'blobs': blobs,
  };

  factory VaultManifest.fromJson(Map<String, dynamic> json) {
    final rawBlobs = json['blobs'] as Map<String, dynamic>? ?? {};
    final blobs = rawBlobs.map((k, v) => MapEntry(k, v.toString()));

    return VaultManifest(
      formatVersion: json['formatVersion']?.toString() ?? '1.0',
      appVersion: json['appVersion']?.toString() ?? '0.1.0',
      createdAt: json['createdAt']?.toString() ?? '',
      deviceId: json['deviceId']?.toString() ?? '',
      deviceName: json['deviceName']?.toString() ?? '',
      totalNodes: (json['totalNodes'] as num?)?.toInt() ?? 0,
      databaseChecksum: json['databaseChecksum']?.toString() ?? '',
      blobs: blobs,
    );
  }

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}
