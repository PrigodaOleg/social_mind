import 'package:hive_flutter/hive_flutter.dart';
import 'package:repository/models/task.dart';
import 'package:repository/models/user.dart';
// import 'package:path_provider/path_provider.dart';

class HiveStorage {
  HiveStorage();

  static const taskBoxName = 'task_box';
  static const operationalBoxName = 'operational_box';
  late Box<Task> _taskBox;
  late Box _operationalBox;

  Future<void> init() async {
    // final directory = await getApplicationDocumentsDirectory();
    await Hive.initFlutter();
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(UserAdapter());
    _taskBox = await Hive.openBox(taskBoxName);
    _operationalBox = await Hive.openBox(operationalBoxName);
  }

  Future<User?> getUser() async {
    return _operationalBox.get('user');
  }

  Future<void> setUser(User user) async {
    return _operationalBox.put('user', user);
  }

  Future<void> save({required Task item}) async {
    _taskBox.put(item.id, item);
  }

  Future<Map<String, Task>> getTasks() async {
    // Hive did not save the task order, unfortunately
    return _taskBox.toMap().cast<String, Task>();
  }

}
