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

  String? getUserId() {}

  Future<void> setUserId(String userId) async {}

  String? getOperational(String key) {}

  Future<void> setOperational(String key, String value) async {}

  dynamic getOpItem(String id) {}

  Future<void> storeOpItem(String id, dynamic item) async {}

  dynamic getItem({required String id}) async {}

  // Get items by list of IDs
  Map<String, T> getItems<T>(List<String> ids) {
    Map<String, T> items = {};
    return items;
  }

  Future<void> storeItem(dynamic item) async {}

  Future<int> storeItems(Map<String, dynamic> items) async {
    return items.length;
  }

  Future<void> deleteItem(String id) async {}

  Registry? getRegistry({String? id, String? parentId, int count = 5}) {}

  // Gets all items from history queue head with increment of tail index.
  // So new history items will be put in new tail
  Map<String, dynamic> getNextItemsFromHistoryQueue() {
    return <String, dynamic>{};
  }

  // Increments history queue head index and deletes these historical data.
  void clearHistoryQueueHead() {}
}
