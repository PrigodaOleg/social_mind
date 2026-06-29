library local_storage;

// export 'hive/hive_storage.dart';
export 'isar/isar_storage.dart';

import 'package:closers/repository/models/models.dart';


abstract class LocalStorage {
  LocalStorage();

  final models = <String, Function(Map<String, dynamic>)>{
    'Domain': (json) => Domain.fromJson(json),
    'User': (json) => User.fromJson(json),
    'Task': (json) => Task.fromJson(json),
  };

  Future<void> init() async {}

  String? getUserId() {
    // return _operationalBox.get('userId');
  }

  Future<void> setUserId(String userId) async {
    // return await _operationalBox.put('userId', userId);
  }

  String? getOperational(String key) {
    // return _operationalBox.get(key);
  }

  Future<void> setOperational(String key, String value) async {
    // return await _operationalBox.put(key, value);
  }

  dynamic getOpItem(String id) {
    // return _operationalBox.get(id);
  }

  Future<void> storeOpItem(String id, dynamic item) async {
    // await _operationalBox.put(id, item);
  }

  dynamic getItem({required String id}) async {}

  Map<String, T> getItems<T>(List<String> ids) {
    // Get items by list of IDs
    Map<String, T> items = {};
    return items;
  }

  Future<void> storeItem(dynamic item) async {
    // await _commonBox.put(item.id, item);
  }

  Future<int> storeItems(Map<String, dynamic> items) async {
    // await _commonBox.putAll(items);
    return items.length;
  }

  Future<void> deleteItem(String id) async {
    // await _commonBox.delete(id);
  }
}
