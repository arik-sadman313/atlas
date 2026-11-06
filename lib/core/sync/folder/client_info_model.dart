import 'dart:convert';

class ClientInfo {
  final String deviceId;
  final String deviceName;
  final DateTime lastActive;
  final int lastSequence;

  const ClientInfo({
    required this.deviceId,
    required this.deviceName,
    required this.lastActive,
    required this.lastSequence,
  });

  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'deviceName': deviceName,
    'lastActive': lastActive.toUtc().toIso8601String(),
    'lastSequence': lastSequence,
  };

  factory ClientInfo.fromJson(Map<String, dynamic> json) => ClientInfo(
    deviceId: json['deviceId']?.toString() ?? '',
    deviceName: json['deviceName']?.toString() ?? '',
    lastActive:
        DateTime.tryParse(json['lastActive']?.toString() ?? '') ??
        DateTime.now().toUtc(),
    lastSequence: (json['lastSequence'] as num?)?.toInt() ?? 0,
  );

  String encode() => const JsonEncoder.withIndent('  ').convert(toJson());
}
