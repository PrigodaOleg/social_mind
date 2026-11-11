import 'dart:typed_data';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/repository/repository.dart';

// Упрощенная версия мока локального хранилища (из collaboration_test.dart):
// хранит модели/оперативные настройки в памяти, без Isar.
class FakeLocalStorage extends LocalStorage {
  final Map<String, Model> storedModels = {};
  final Map<String, dynamic> opItems = {};
  final Map<String, String> operational = {};
  final Map<String, Uint8List> images = {};
  String? userId;

  @override
  Future<void> init() async {}

  @override
  String? getUserId() => userId;

  @override
  Future<void> setUserId(String id) async {
    // Честно асинхронная запись (как в реальном хранилище): завершится
    // в следующем микротаске, а не мгновенно.
    await Future<void>.delayed(Duration.zero);
    userId = id;
  }

  @override
  String? getOperational(String key) => operational[key];

  @override
  Future<void> setOperational(String key, String value) async {
    await Future<void>.delayed(Duration.zero);
    operational[key] = value;
  }

  @override
  Uint8List? getImage(String id) => images[id];

  @override
  Future<void> storeImage(String id, Uint8List imageBytes) async {
    images[id] = imageBytes;
  }

  @override
  dynamic getOpItem(String id) => opItems[id];

  @override
  Future<void> storeOpItem(String id, dynamic item) async {
    opItems[id] = item;
  }

  @override
  dynamic getItem({required String id}) => storedModels[id];

  @override
  Future<void> storeItem(dynamic item) async {
    if (item is Model) storedModels[item.id] = item;
  }

  @override
  Future<int> storeItems(Map<String, dynamic> items) async {
    for (final item in items.values) {
      if (item is Model) storedModels[item.id] = item;
    }
    return items.length;
  }

  @override
  Future<void> deleteItem(String id) async {
    storedModels.remove(id);
  }

  @override
  Registry? getRegistry({String? id, String? parentId, int count = 5}) => null;

  @override
  Map<String, dynamic> getNextItemsFromHistoryQueue() => <String, dynamic>{};

  @override
  void clearHistoryQueueHead() {}
}
