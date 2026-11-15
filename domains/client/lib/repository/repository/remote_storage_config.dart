import 'dart:convert';

import 'package:closers/repository/models/models.dart';

/// Pre-login remote storage profile (Option A).
///
/// Stored locally on the device (via [LocalStorage.getOperational] /
/// [LocalStorage.setOperational]) before the user is known. The login page
/// lets the user pick and configure remote storages here; the saved profile
/// is then merged into `User.settings['remote_storages']` of every user
/// created or logged in on this device (see [Repository.applyRemoteStorageConfig]).
///
/// Format is exactly what `Repository.initRemoteStorages()` /
/// `authRemoteStorages()` already read from user settings:
/// ```
/// {
///   "FirebaseRealtimeDatabase": {"instance": "closers-cd24f", "anon_key": "..."},
///   "Supabase": {"instance": "https://xyz.supabase.co", "anon_key": "..."}
/// }
/// ```
class RemoteStorageConfig {
  /// storageKey -> {'instance': ..., 'anon_key': ...}
  final Map<String, Map<String, dynamic>> storages;

  RemoteStorageConfig([Map<String, Map<String, dynamic>>? storages])
      : storages = storages ?? {};

  static const String operationalKey = 'remoteStorageConfig';

  bool get isEmpty => storages.isEmpty;

  bool contains(String storageKey) => storages.containsKey(storageKey);

  String? instanceOf(String storageKey) =>
      storages[storageKey]?['instance'] as String?;

  String? anonKeyOf(String storageKey) =>
      storages[storageKey]?['anon_key'] as String?;

  void set(String storageKey, {String? instance, String? anonKey}) {
    final config = <String, dynamic>{
      if (instance != null) 'instance': instance,
      if (anonKey != null && anonKey.isNotEmpty) 'anon_key': anonKey,
    };
    if (config.isEmpty) {
      storages.remove(storageKey);
    } else {
      storages[storageKey] = config;
    }
  }

  void remove(String storageKey) => storages.remove(storageKey);

  /// Merge this profile into a user's `settings['remote_storages']`.
  /// Profile entries override user defaults for the same storageKey;
  /// user defaults for keys absent from the profile are kept.
  void applyToUserSettings(Map<String, dynamic> userSettings) {
    final remote = Map<String, dynamic>.from(
      userSettings.getDeep('remote_storages', defaultValue: {}),
    );
    storages.forEach((key, config) {
      remote[key] = Map<String, dynamic>.from(config);
    });
    userSettings.setDeep('remote_storages', remote);
  }

  Map<String, dynamic> toJson() => storages;

  String encode() => jsonEncode(toJson());

  factory RemoteStorageConfig.decode(String? json) {
    if (json == null || json.isEmpty) return RemoteStorageConfig();
    try {
      final decoded = jsonDecode(json);
      if (decoded is! Map<String, dynamic>) return RemoteStorageConfig();
      return RemoteStorageConfig(decoded.map(
        (key, value) => MapEntry(
          key,
          value is Map<String, dynamic> ? value : <String, dynamic>{},
        ),
      ));
    } on FormatException {
      return RemoteStorageConfig();
    }
  }
}
