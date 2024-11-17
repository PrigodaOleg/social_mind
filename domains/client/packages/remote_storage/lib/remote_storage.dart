library remote_storage;

// export 'hive/hive_storage.dart';

import 'package:firebase_database/firebase_database.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repository/models/models.dart';

class FirebaseStorage {
  FirebaseStorage();

  // static const String defaultId = '00000000-0000-0000-0000-000000000000';
  static const String defaultId = '575a8019-c902-4603-b4e5-cea067c31610';
  late DatabaseReference database;

  final models = <String, Function(Map<String, dynamic>)>{
    'Domain': (json) => Domain.fromJson(json),
  };

  Future<void> init() async {
    // Connect and get instance
    database = FirebaseDatabase.instance.ref();

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
      print(error);
    }
    return null;
  }

  Future<void> setUser(User user) async {
    try {
      await database.child('users/${user.id}').update(user.toJson());
    } catch (error) {
      print(error);
    }
  }
  
  Future<void> save({required Task item}) async {
    try {
      await database.child('tasks/${item.id}').update(item.toJson());
    } catch (error) {
      print(error);
    }
  }

  Future<dynamic> getItem({required String id}) async {
    // Get item by ID
    // try {
      final snapshot = await database.child('models/$id').get();
      if (snapshot.exists) {
        var json = Map<String, dynamic>.from(snapshot.value as Map);
        if (!json.containsKey('type')) return;
        return models[json['type']]?.call(json);
      }
    // } catch (error) {
      // print(error);
    // }
    return;
  }

  Future<Map<String, dynamic>> getItems(List ids) async {
    // Get item by ID
    Map<String, dynamic> items = {};
    return items;
  }
  
  Future<int> saveItems(Map<String, dynamic> items) async {
    // await database.child('tasks/${item.id}').update(item.toJson());
    // try {
      for (Domain item in items.values) {
        await database.child('models/${item.id}').update(item.toJson());
      }
    // } catch (error) {
    //   print(error);
    // }
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
