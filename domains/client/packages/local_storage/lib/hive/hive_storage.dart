import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_storage/models/task.dart';

class LocalStorage {
  LocalStorage();

  static const privateBoxName = 'private_box';
  late Box<Task> box;

  Future<void> init() async {
    Hive.init('');
    Hive.registerAdapter(TaskAdapter());
    box = await Hive.openBox(privateBoxName);
  }

  Future<void> save({required Task item}) async {
    box.put(item.id, item);
  }

  Future<Map<String, Task>> getTasks() async {
    // Hive did not save the task order, unfortunately
    return box.toMap().cast<String, Task>();
  }

}
