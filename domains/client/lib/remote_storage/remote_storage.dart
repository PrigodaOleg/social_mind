library remote_storage;

import 'dart:async';

import 'package:closers/repository/models/models.dart';

export 'firebase_realtime_database.dart';
export 'cloud_firestore.dart';
export 'supabase.dart';

/// Событие изменения реестра в удаленном хранилище.
/// [registryId] - идентификатор реестра, [lastIndex] - индекс последней транзакции в удаленном реестре.
/// По этому событию клиент решает, дочитывать ли новые транзакции и изменившиеся модели.
class RegistryChangeEvent {
  RegistryChangeEvent(this.registryId, this.lastIndex);
  final String registryId;
  final int? lastIndex;
}

class RemoteStorageWriteCollision implements Exception {
  final String message;
  final int statusCode;

  RemoteStorageWriteCollision(this.message, this.statusCode);

  @override
  String toString() => 'RemoteStorageWriteCollision ($statusCode): $message';
}

abstract class RemoteStorage {  // todo: abstract?
  RemoteStorage();

  final models = <String, Function(Map<String, dynamic>)>{
    'Domain': (json) => Domain.fromJson(json),
    'User': (json) => User.fromJson(json),
    'Task': (json) => Task.fromJson(json),
    'TaskList': (json) => TaskList.fromJson(json),
    'ContactList': (json) => ContactList.fromJson(json),
    'Invitation': (json) => Invitation.fromJson(json),
  };

  Future<bool> init(String instance, {String? anonKey}) async {return false;}

  Future<bool> createUserAndAuth(String login, String password) async {return false;}

  Future<bool> auth(String login, String password) async {return false;}

  /// Обновление пароля пользователя (например, при смене секрета на устройстве).
  Future<bool> updateUserPassword(String login, String oldPassword, String newPassword) async {return false;}

  Future<dynamic> getItem({required String id}) async {}

  Future<Map<String, Model>> getItems(List ids) async {
    // Get items by list of IDs
    Map<String, Model> items = {};
    return items;
  }
  
  Future<int> saveItems(Map<String, dynamic> items) async {
    return 0;
  }

  Future<int> deleteItems(Map<String, dynamic> items) async {
    return 0;
  }

  Future<Registry?> readRegistry(String id, {int count = 1}) async {}

  Future<Map<String, Registry>> readRegistries({
    List<String>? ids,
    List<(String id, int? count)>? idsCounts,
    int count = 1
  }) async {
    return {};
  }

  /// Подписка на изменения реестров.
  /// При каждом изменении реестра эмитится [RegistryChangeEvent] с идентификатором
  /// реестра и индексом последней транзакции в удаленном реестре (если известен).
  /// Клиент по этим событиям определяет, какие модели изменились, и дочитывает их
  /// через [getItems] - подписки на отдельные модели не требуются.
  Stream<RegistryChangeEvent> watchRegistries(List<String> ids) async* {}

  /// Записать произвольный JSON по пути (используется для приглашений).
  Future<bool> saveRaw(String path, Map<String, dynamic> json) async {return false;}

  /// Прочитать произвольный JSON по пути.
  Future<Map<String, dynamic>?> readRaw(String path) async {return null;}

  /// Прочитать все JSON-объекты по префиксу пути.
  Future<List<Map<String, dynamic>>> readRawPrefix(String pathPrefix) async {return [];}
}
