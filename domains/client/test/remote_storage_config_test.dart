import 'dart:convert';

import 'package:closers/repository/repository/remote_storage_config.dart';
import 'package:closers/repository/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteStorageConfig', () {
    test('starts empty', () {
      final config = RemoteStorageConfig();
      expect(config.isEmpty, isTrue);
      expect(config.storages, isEmpty);
    });

    test('set() adds storage with instance and anon key', () {
      final config = RemoteStorageConfig();
      config.set('FirebaseRealtimeDatabase',
          instance: 'closers-cd24f', anonKey: 'key123');
      expect(config.contains('FirebaseRealtimeDatabase'), isTrue);
      expect(config.instanceOf('FirebaseRealtimeDatabase'), 'closers-cd24f');
      expect(config.anonKeyOf('FirebaseRealtimeDatabase'), 'key123');
    });

    test('set() with empty instance removes storage', () {
      final config = RemoteStorageConfig();
      config.set('Supabase', instance: 'https://x.supabase.co');
      config.set('Supabase');
      expect(config.contains('Supabase'), isFalse);
 expect(config.isEmpty, isTrue);
    });

    test('set() skips empty anon key', () {
      final config = RemoteStorageConfig();
      config.set('Supabase', instance: 'inst', anonKey: '');
      expect(config.storages['Supabase'], {'instance': 'inst'});
    });

    test('remove() deletes storage', () {
      final config = RemoteStorageConfig();
      config.set('CloudFirestore', instance: 'proj');
      config.remove('CloudFirestore');
      expect(config.contains('CloudFirestore'), isFalse);
    });

    test('encode/decode roundtrip', () {
      final config = RemoteStorageConfig();
      config.set('FirebaseRealtimeDatabase',
          instance: 'closers-cd24f', anonKey: 'key');
      config.set('Supabase', instance: 'https://x.supabase.co');
      final restored = RemoteStorageConfig.decode(config.encode());
      expect(restored.instanceOf('FirebaseRealtimeDatabase'), 'closers-cd24f');
      expect(restored.anonKeyOf('FirebaseRealtimeDatabase'), 'key');
      expect(restored.instanceOf('Supabase'), 'https://x.supabase.co');
    });

    test('decode handles null, empty and malformed json', () {
      expect(RemoteStorageConfig.decode(null).isEmpty, isTrue);
      expect(RemoteStorageConfig.decode('').isEmpty, isTrue);
      expect(RemoteStorageConfig.decode('not json').isEmpty, isTrue);
      expect(RemoteStorageConfig.decode(jsonEncode([1, 2])).isEmpty, isTrue);
    });

    test('decode tolerates non-map values', () {
      final restored =
          RemoteStorageConfig.decode(jsonEncode({'Supabase': 'garbage'}));
      expect(restored.contains('Supabase'), isTrue);
      expect(restored.instanceOf('Supabase'), isNull);
    });

    test('applyToUserSettings overrides same key and keeps others', () {
      final config = RemoteStorageConfig();
      config.set('FirebaseRealtimeDatabase', instance: 'my-instance');

      final userSettings = <String, dynamic>{
        'remote_storages': {
          'FirebaseRealtimeDatabase': {'instance': 'closers-cd24f'},
          'Supabase': {'instance': 'https://x.supabase.co'},
        }
      };

      config.applyToUserSettings(userSettings);

      final remote =
          userSettings.getDeep('remote_storages') as Map<String, dynamic>;
      // Profile overrides the user default
      expect(
        (remote['FirebaseRealtimeDatabase'] as Map)['instance'],
        'my-instance',
      );
      // User default for a key absent from the profile is kept
      expect(
        (remote['Supabase'] as Map)['instance'],
        'https://x.supabase.co',
      );
    });

    test('applyToUserSettings works on empty user settings', () {
      final config = RemoteStorageConfig();
      config.set('Supabase', instance: 'inst', anonKey: 'k');
      final userSettings = <String, dynamic>{};
      config.applyToUserSettings(userSettings);
      final remote =
          userSettings.getDeep('remote_storages') as Map<String, dynamic>;
      expect((remote['Supabase'] as Map)['instance'], 'inst');
      expect((remote['Supabase'] as Map)['anon_key'], 'k');
    });
  });
}
