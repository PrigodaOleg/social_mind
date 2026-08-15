library remote_storage;

export 'firebase_realtime_database.dart';

import 'package:closers/repository/models/models.dart';


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
  };

  Future<void> init(String instance) async {}

  Future<void> createUserAndAuth(String login, String password) async {}

  Future<void> auth(String login, String password) async {}

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
}
