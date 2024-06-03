import 'package:local_storage/hive/hive_storage.dart';
import 'package:local_storage/models/task.dart';


class Repository {
  const Repository({required LocalStorage localStorage}) : _localStorage = localStorage;

  final LocalStorage _localStorage;

  Future<void> init() async => await _localStorage.init();

  Future<Map<String, Task>> getTasks() async => await _localStorage.getTasks();

  Future<void> addTask(Task task) async => await _localStorage.save(item: task);
}