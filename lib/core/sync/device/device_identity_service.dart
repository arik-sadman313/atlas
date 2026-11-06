import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class DeviceIdentityService {
  static const String _keyDeviceId = 'atlas_device_id';
  static const String _keyDeviceName = 'atlas_device_name';
  static const String _keySyncDirectory = 'atlas_sync_directory_path';

  final SharedPreferences? prefs;
  final Uuid _uuid;

  DeviceIdentityService({this.prefs, Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  Future<SharedPreferences> _getPrefs() async {
    return prefs ?? await SharedPreferences.getInstance();
  }

  /// Gets the persistent UUID v4 for this client instance or generates a new one.
  Future<String> getOrCreateDeviceId() async {
    final prefs = await _getPrefs();
    String? id = prefs.getString(_keyDeviceId);
    if (id == null || id.isEmpty) {
      id = 'atlas-client-${_uuid.v4()}';
      await prefs.setString(_keyDeviceId, id);
    }
    return id;
  }

  /// Gets the user-friendly device name (e.g. 'Linux Workstation', 'Android Companion').
  Future<String> getDeviceName() async {
    final prefs = await _getPrefs();
    String? name = prefs.getString(_keyDeviceName);
    if (name == null || name.isEmpty) {
      name = _defaultDeviceName();
      await prefs.setString(_keyDeviceName, name);
    }
    return name;
  }

  Future<void> setDeviceName(String name) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyDeviceName, name.trim());
  }

  /// Gets the designated local sync directory path (e.g. Syncthing, shared folder).
  Future<String?> getSyncDirectoryPath() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keySyncDirectory);
  }

  Future<void> setSyncDirectoryPath(String? path) async {
    final prefs = await _getPrefs();
    if (path == null || path.isEmpty) {
      await prefs.remove(_keySyncDirectory);
    } else {
      await prefs.setString(_keySyncDirectory, path.trim());
    }
  }

  String _defaultDeviceName() {
    if (Platform.isLinux) return 'Linux Workstation';
    if (Platform.isAndroid) return 'Android Companion';
    if (Platform.isIOS) return 'iPad / iOS Client';
    if (Platform.isMacOS) return 'MacBook';
    if (Platform.isWindows) return 'Windows PC';
    return 'Atlas Client';
  }
}
