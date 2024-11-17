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
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(DomainAdapter());
    _taskBox = await Hive.openBox(taskBoxName);
    _operationalBox = await Hive.openBox(operationalBoxName);
    _commonBox = await Hive.openBox(commonBoxName);
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

  Future<dynamic> getItem({required String id}) async {
    // Get item by ID
    return await _commonBox.get(id);
  }

  Future<Map<String, T>> getItems<T>(List ids) async {
    // Get item by ID
    Map<String, T> items = {};
    ids.forEach((id) async {
      dynamic item = await _commonBox.get(id);
      if (item != null) items[id] = item;
    });
    return items;
  }

  Future<void> storeItem(dynamic item) async {
    await _commonBox.put(item.id, item);
  }

  Future<int> saveItems(Map<String, dynamic> items) async {
    await _commonBox.putAll(items);
    return items.length;
  }

  Future<void> deleteItem(String id) async {
    await _commonBox.delete(id);
  }

}
