library remote_storage;

// export 'hive/hive_storage.dart';

import 'package:firebase_database/firebase_database.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:repository/models/user.dart';

class FirebaseStorage {
  FirebaseStorage();

  late DatabaseReference database;

  Future<void> init() async {
    // FirebaseDatabase database = FirebaseDatabase.instance;
    // DatabaseReference ref = database.ref('users/$');
    // FirebaseFirestore db = FirebaseFirestore.instance;
    // db.collection('users').add(data)
    // final user = {
    //   'username': 'Олег'
    // };
    database = FirebaseDatabase.instance.ref();


    // final newUserKey = FirebaseDatabase.instance.ref().child('users').push().key;
    // final Map<String, Map> updates = {};
    // updates['/users/$newUserKey'] = user;
    // FirebaseDatabase.instance.ref().update(updates);
  }

  Future<User?> getUser() async {
    final snapshot = await database.child('users/575a8019-c902-4603-b4e5-cea067c31610').get();
    if (snapshot.exists) {
      return User.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    } else {
      return null;
    }
  }

  Future<void> setUser(User user) async {
    await database.child('users/${user.id}').update(user.toJson());
  }
}

/// A Calculator.
class Calculator {
  /// Returns [value] plus 1.
  int addOne(int value) => value + 1;
}
