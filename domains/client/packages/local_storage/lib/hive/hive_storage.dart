import 'package:hive_flutter/hive_flutter.dart';
import 'package:repository/models/models.dart';
// import 'package:path_provider/path_provider.dart';

class HiveStorage {
  HiveStorage();

  static const taskBoxName = 'task_box';
  static const operationalBoxName = 'operational_box';
  static const commonBoxName = 'common_box';
  late Box<Task> _taskBox;
  late Box _operationalBox;
  late Box _commonBox;

  Future<void> init() async {
    // final directory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter();
    Hive.registerAdapter(LocationAdapter());
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(DomainAdapter());
    _taskBox = await Hive.openBox(taskBoxName);
    _operationalBox = await Hive.openBox(operationalBoxName);
    _commonBox = await Hive.openBox(commonBoxName);
  }

  String? getOperational(String key) {
    return _operationalBox.get(key);
  }

  Future<void> setOperational(String key, String value) async {
    return await _operationalBox.put(key, value);
  }

  String? getUserId() {
    return _operationalBox.get('userId');
  }

  Future<void> setUserId(String userId) async {
    return await _operationalBox.put('userId', userId);
  }

  Future<User?> getUser() async {
    return await _operationalBox.get('user');
  }

  Future<void> setUser(User user) async {
    return await _operationalBox.put('user', user);
  }

  Future<void> save({required Task item}) async {
    await _taskBox.put(item.id, item);
  }

  Future<Map<String, Task>> getTasks() async {
    // Hive did not save the task order, unfortunately
    return _taskBox.toMap().cast<String, Task>();
  }

  dynamic getItem({required String id}) {
    // Get item by ID
    return _commonBox.get(id);
  }

  Map<String, T> getItems<T>(List ids) {
    // Get item by ID
    Map<String, T> items = {};
    // ignore: avoid_function_literals_in_foreach_calls
    ids.forEach((id) {
      dynamic item = _commonBox.get(id);
      if (item != null) items[id] = item;
    });
    return items;
  }

  Future<void> storeItem(dynamic item) async {
    await _commonBox.put(item.id, item);
  }

  Future<int> storeItems(Map<String, dynamic> items) async {
    await _commonBox.putAll(items);
    return items.length;
  }

  Future<void> deleteItem(String id) async {
    await _commonBox.delete(id);
  }

}
