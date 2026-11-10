import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:closers/remote_storage/remote_storage.dart';
import 'package:closers/repository/models/models.dart';

/// Реализация RemoteStorage на Supabase (Postgres).
/// Структура таблиц (создается миграцией):
///   models(id text primary key, data jsonb)                     - сериализованные модели
///   registries(id text primary key, parent_id text, last_idx int) - реестры
///   registry_transactions(registry_id text, idx int, data jsonb, primary key (registry_id, idx))
/// Консистентная запись транзакций обеспечивается условным UPDATE
/// по last_idx (аналог коллизии RemoteStorageWriteCollision в RTDB).
class SupabaseStorage extends RemoteStorage {
  SupabaseStorage();

  SupabaseClient? _client;
  static bool _supabaseInitialized = false;

  SupabaseClient get client {
    if (_client == null) {
      throw StateError('SupabaseStorage is not initialized');
    }
    return _client!;
  }

  @override
  Future<bool> init(String instance, {String? anonKey}) async {
    // instance - URL проекта Supabase, например https://xyz.supabase.co
    // Валидация instance: только https, без credentials в URL, host не пуст.
    // Защита от подключения к враждебному серверу по данным из QR.
    if (instance.isEmpty || instance.length > 256) {
      print('SupabaseStorage: invalid instance: $instance');
      return false;
    }
    final uri = Uri.tryParse(instance);
    if (uri == null ||
        !uri.hasScheme ||
        uri.scheme != 'https' ||
        uri.userInfo.isNotEmpty ||
        uri.host.isEmpty) {
      print('SupabaseStorage: instance must be a valid https URL: $instance');
      return false;
    }
    // Ключ anon берется из явного аргумента или из окружения (--dart-define).
    final key = (anonKey != null && anonKey.isNotEmpty)
        ? anonKey
        : const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
    if (key.isEmpty) {
      print('SupabaseStorage: anon key is not configured (SUPABASE_ANON_KEY or remote_storages.Supabase.anon_key)');
      return false;
    }
    // Supabase.initialize кидает исключение при повторной инициализации
    if (!_supabaseInitialized) {
      await Supabase.initialize(url: instance, anonKey: key);
      _supabaseInitialized = true;
    } else if (_client == null) {
      _client = Supabase.instance.client;
    }
    _client ??= Supabase.instance.client;
    return true;
  }

  @override
  Future<bool> createUserAndAuth(String login, String password) async {
    await client.auth.signUp(email: '$login@a.aa', password: password);
    return true;
  }

  @override
  Future<bool> auth(String login, String password) async {
    await client.auth.signInWithPassword(email: '$login@a.aa', password: password);
    return true;
  }

  @override
  Future<bool> updateUserPassword(String login, String oldPassword, String newPassword) async {
    await client.auth.signInWithPassword(email: '$login@a.aa', password: oldPassword);
    await client.auth.updateUser(UserAttributes(password: newPassword));
    return true;
  }

  Map<String, dynamic>? _modelJson(Map<String, dynamic> row) {
    final data = row['data'];
    if (data is! Map) return null;
    final json = Map<String, dynamic>.from(data);
    if (!json.containsKey('type')) return null;
    return json;
  }

  @override
  Future<dynamic> getItem({required String id}) async {
    try {
      final rows = await client.from('models').select().eq('id', id).limit(1);
      if (rows.isEmpty) return null;
      final json = _modelJson(Map<String, dynamic>.from(rows.first));
      if (json == null) return null;
      return models[json['type']]?.call(json);
    } catch (error) {
      print(error);
    }
    return null;
  }

  @override
  Future<Map<String, Model>> getItems(List ids) async {
    Map<String, Model> items = {};
    if (ids.isEmpty) return items;
    try {
      final rows = await client.from('models').select().inFilter('id', ids.cast<String>());
      for (final row in rows) {
        final json = _modelJson(Map<String, dynamic>.from(row));
        if (json == null) continue;
        final model = models[json['type']]?.call(json);
        if (model != null) items[json['id']] = model;
      }
    } catch (error) {
      print(error);
    }
    return items;
  }

  @override
  Future<int> saveItems(Map<String, dynamic> items) async {
    try {
      for (var entry in items.entries) {
        if (entry.value is Model) {
          final model = entry.value as Model;
          await client.from('models').upsert({'id': model.id, 'data': model.toJson()});
        }
        if (entry.value is Registry) {
          final registry = entry.value as Registry;
          await _saveRegistryTransactionally(registry);
        }
      }
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        // RLS - отказано в доступе политикой безопасности строк
        throw RemoteStorageWriteCollision(e.message, 0);
      }
      print('Supabase Error: ${e.code} — ${e.message}');
    } catch (e) {
      if (e.toString().contains('row-level security') || e.toString().contains('permission')) {
        throw RemoteStorageWriteCollision(e.toString(), 0);
      }
      print('Unknown Supabase Error: $e');
    }
    return items.length;
  }

  /// Консистентная запись транзакции реестра. Порядок записи:
  /// 1) идемпотентный upsert строки транзакции, 2) условный UPDATE головы.
  /// Если процесс упадет между ними, голова останется старой - повторная
  /// попытка перезапишет ту же транзакцию и сдвинет голову.
  /// Если удаленная голова ушла вперед (last_idx >= нашему), кидаем коллизию -
  /// клиент сделает rebase.
  Future<void> _saveRegistryTransactionally(Registry registry) async {
    final lastTransactionIndex = registry.transactions.keys.last;
    // 0. Гарантируем существование строки головы (FK registry_transactions
    //    требует ее раньше транзакций). Upsert без last_idx не трогает
    //    удаленную голову при конфликте.
    await client.from('registries').upsert({
      'id': registry.id,
      'parent_id': registry.parentId,
    });
    // 1. Транзакция - идемпотентный upsert
    await client.from('registry_transactions').upsert({
      'registry_id': registry.id,
      'idx': lastTransactionIndex,
      'data': registry.transactions[lastTransactionIndex]!.toJson(),
    });
    // 2. Условный апдейт головы (UPDATE, а не upsert): PostgREST игнорирует
    //    фильтры в query string у POST/upsert, поэтому коллизия детектируется
    //    только через UPDATE c условием .lt - при устаревшей голове он
    //    возвращает 0 строк.
    final updated = await client
        .from('registries')
        .update({'last_idx': lastTransactionIndex})
        .eq('id', registry.id!)
        .lt('last_idx', lastTransactionIndex)
        .select();
    if ((updated as List).isEmpty) {
      // Голова не изменилась - значит удаленный last_idx >= нашего, коллизия
      throw RemoteStorageWriteCollision('registry head moved forward', 0);
    }
  }

  @override
  Future<int> deleteItems(Map<String, dynamic> items) async {
    try {
      await client.from('models').delete().inFilter('id', items.keys.toList());
    } on PostgrestException catch (e) {
      if (e.code == '42501') {
        throw RemoteStorageWriteCollision(e.message, 0);
      }
      print('Supabase Error: ${e.code} — ${e.message}');
    }
    return items.length;
  }

  @override
  Future<Registry?> readRegistry(String id, {int count = 1}) async {
    try {
      final registryRows = await client.from('registries').select().eq('id', id).limit(1);
      if ((registryRows as List).isEmpty) return null;
      final registryRow = Map<String, dynamic>.from(registryRows.first);
      final transactionRows = await client
          .from('registry_transactions')
          .select()
          .eq('registry_id', id)
          .gte('idx', ((registryRow['last_idx'] as int?) ?? -1) - count + 1)
          .order('idx');
      final transactions = <String, dynamic>{};
      for (final row in transactionRows) {
        final r = Map<String, dynamic>.from(row);
        transactions[r['idx'].toString()] = r['data'];
      }
      return Registry.fromJson({
        'metadata': {'id': id, 'parentId': registryRow['parent_id'] ?? ''},
        'transactions': transactions,
      });
    } catch (error) {
      print(error);
    }
    return null;
  }

  @override
  Future<Map<String, Registry>> readRegistries({
    List<String>? ids,
    List<(String id, int? count)>? idsCounts,
    int count = 1,
  }) async {
    final registries = <String, Registry>{};
    final requests = idsCounts ?? [for (final id in (ids ?? [])) (id, count)];
    for (final (id, c) in requests) {
      final registry = await readRegistry(id, count: c ?? count);
      if (registry != null) registries[id] = registry;
    }
    return registries;
  }

  @override
  Stream<RegistryChangeEvent> watchRegistries(List<String> ids) {
    final controller = StreamController<RegistryChangeEvent>();
    final channels = <RealtimeChannel>[];
    for (final id in ids) {
      final channel = client.channel('registries_$id');
      channel.onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'registries',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'id', value: id),
        callback: (payload) {
          final newRecord = payload.newRecord;
          int? lastIndex;
          if (newRecord['last_idx'] is int) lastIndex = newRecord['last_idx'] as int;
          controller.add(RegistryChangeEvent(id, lastIndex));
        },
      ).subscribe();
      channels.add(channel);
    }
    controller.onCancel = () {
      for (final channel in channels) {
        client.removeChannel(channel);
      }
    };
    return controller.stream;
  }

  @override
  Future<bool> saveRaw(String path, Map<String, dynamic> json) async {
    try {
      await client.from('raw_storage').upsert({'path': path, 'data': json});
      return true;
    } catch (e) {
      print('saveRaw error: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> readRaw(String path) async {
    try {
      final rows = await client.from('raw_storage').select().eq('path', path).limit(1);
      if ((rows as List).isNotEmpty) {
        final row = Map<String, dynamic>.from(rows.first);
        return Map<String, dynamic>.from(row['data']);
      }
    } catch (e) {
      print('readRaw error: $e');
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> readRawPrefix(String pathPrefix) async {
    final result = <Map<String, dynamic>>[];
    try {
      final rows = await client.from('raw_storage').select().gte('path', pathPrefix).lt('path', '$pathPrefix\u0000');
      for (final row in rows) {
        final r = Map<String, dynamic>.from(row);
        if (r['data'] is Map) result.add(Map<String, dynamic>.from(r['data']));
      }
    } catch (e) {
      print('readRawPrefix error: $e');
    }
    return result;
  }
}
