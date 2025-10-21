library remote_storage;

import 'package:firebase_database/firebase_database.dart'; // https://firebase.google.com/docs/database/flutter/start
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repository/models/models.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseStorage {
  FirebaseStorage();

  static const String defaultId = '00000000-0000-0000-0000-000000000000';
  // static const String defaultId = '575a8019-c902-4603-b4e5-cea067c31610';
  late DatabaseReference database;

  final models = <String, Function(Map<String, dynamic>)>{
    'Domain': (json) => Domain.fromJson(json),
    'User': (json) => User.fromJson(json),
    'Task': (json) => Task.fromJson(json),
  };

  Future<void> init() async {
    // Connect and get instance
    database = FirebaseDatabase.instanceFor(app: Firebase.app('closers-cd24f')).ref();
    // database = FirebaseDatabase.instance.ref();

    // Check last authentication is alive


    // final newUserKey = FirebaseDatabase.instance.ref().child('users').push().key;
    // final Map<String, Map> updates = {};
    // updates['/users/$newUserKey'] = user;
    // FirebaseDatabase.instance.ref().update(updates);
  }

  Future<User?> getUser() async {
    // Get user by Firebase authorization
    
    try {
      final snapshot = await database.child('users/$defaultId').get();
      if (snapshot.exists) {
        return User.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
      }
    } catch (error) {
      // ignore: avoid_print
      print(error);
    }
    return null;
  }

  Future<void> setUser(User user) async {
    try {
      await database.child('users/${user.id}').update(user.toJson());
    } catch (error) {
      // ignore: avoid_print
      print(error);
    }
  }
  
  Future<void> save({required Task item}) async {
    try {
      await database.child('tasks/${item.id}').update(item.toJson());
    } catch (error) {
      // ignore: avoid_print
      print(error);
    }
  }

  Future<dynamic> getItem({required String id}) async {
    // Get item by ID
    try {
      final snapshot = await database.child('models/$id').get();
      if (snapshot.exists) {
        var json = Map<String, dynamic>.from(snapshot.value as Map);
        if (!json.containsKey('type')) return;
        return models[json['type']]?.call(json);
      }
    } catch (error) {
      print(error);
    }
    return;
  }

  Future<Map<String, dynamic>> getItems(List ids) async {
    // Get items by list of IDs
    Map<String, dynamic> items = {};
    for (var id in ids) {
      var item = await getItem(id: id);
      if (item != null) {
        items.addAll({id: item});
      }
    }
    return items;
  }
  
  Future<int> saveItems(Map<String, dynamic> items) async {
    // https://firebase.google.com/docs/database/flutter/read-and-write
    // 15.12.2024
    // Тут надо не забыть обрабатывать ошибки связи с базой, ошибки прав доступа или правил работы с объектами.
    // Также считаем, что у нас работает контракт - если эта функция выполнилась, то все элементы сохранены.
    // В подтверждение этого возвращаем количество элементов, которое было сохранено.
    // Конечно, это плохой контракт. Возвращать нужно не количество, а конкретные идентификаторы.
    // А также идентификаторы, которые сохранить не удалось.
    // todo: переделать на возврат идентификаторов (структуру или класс с успешными, неуспешными и ошибками)

    // 14.10.2025
    // Оказалось, что у нас есть 2 проблемы.
    // 1. При записи перетирается весь объект. То есть, если зайти от одного пользователя
    //    с нескольких устройств, то на одном не видно изменений другого. Изменения первого
    //    полностью перетирают весь объект в то состояние которое было на нем. А изменения второго
    //    соответственно то же самое.
    // 2. Репозиторий не предоставляет событий на изменения пользователя. Это скорее проблема
    //    архитектуры, поскольку никто не подписан именно на изменения пользователя.
    //    Плюс не реализован механизм уведомлений от удаленного репозитория. Для этого планируется
    //    использовать пуш-уведомления.

    // 20.10.2025
    // Попробуем писать простые поля и списки по отдельности

    try {
      Map<String, Object?> updates = {};
      for (dynamic item in items.values) {
        for (MapEntry<String, dynamic> field in item.toJson().entries) {
          if (field.value is List) {
            for (String value in field.value) {
              updates['models/${item.id}/${field.key}/$value'] = '';
            }
          }
          else {
            updates['models/${item.id}/${field.key}'] = field.value;
          }
        }
      }
      database.update(updates);
    } catch (error) {
      print(error);
    }
    return items.length;
  }

  Future<int> deleteItems(Map<String, dynamic> items) async {
    // for (dynamic item in items.values) {
    //   database.child('models/${item.id}').remove();
    // }
    Map<String, Object?> updates = {};
    for (dynamic item in items.values) {
      updates['models/${item.id}'] = null;
    }
    database.update(updates);
    return items.length;
  }

  Future<Map<String, Task>> getTasks() async {
    // Hive did not save the task order, unfortunately
    // return _taskBox.toMap().cast<String, Task>();

    try {
      final snapshot = await database.child('tasks').get();
      Map<String, Task> tasks = {};
      if (snapshot.exists) {
        Map<String?, dynamic> castedData = (snapshot.value as Map).cast<String?, dynamic>();
        castedData.forEach((key, value) {
          Map<String, dynamic> castedTask = (value as Map).cast<String, dynamic>();
          tasks.addAll({key!: Task.fromJson(castedTask)});
        });
        return tasks;
      }
    } catch (error) {
      // ignore: avoid_print
      print(error);
    }
    return <String, Task>{};
  }
}

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}
