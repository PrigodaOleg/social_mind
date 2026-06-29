import 'package:closers/remote_storage/remote_storage.dart';
import 'package:firebase_database/firebase_database.dart'; // https://firebase.google.com/docs/database/flutter/start
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:closers/repository/models/models.dart';


class FirebaseStorage extends RemoteStorage {
  FirebaseStorage();

  static const emailSuffix = '@a.aa';
  late DatabaseReference database;
  late FirebaseApp app;

  @override
  Future<void> init(String instance) async {
    // Connect and get instance
    app = Firebase.app(instance);
    database = FirebaseDatabase.instanceFor(app: app).ref();
  }

  @override
  Future<void> createUserAndAuth(String login, String password, {String? claim}) async {
    final auth = FirebaseAuth.instanceFor(app: app);
    UserCredential userCredential = await auth.createUserWithEmailAndPassword(email: '$login$emailSuffix', password: password);
    if (claim != null) {
      await auth.currentUser?.updateDisplayName(claim);
      await auth.currentUser?.getIdToken(true);
    }
  }

  @override
  Future<void> auth(String login, String password) async {
    final auth = FirebaseAuth.instanceFor(app: app);
    UserCredential userCredential = await auth.signInWithEmailAndPassword(email: '$login$emailSuffix', password: password);
  }

  @override
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

  @override
  Future<Map<String, dynamic>> getItems(List ids) async {
    // Get items by list of IDs
    Map<String, dynamic> items = {};
    if (ids.isNotEmpty) {
      database.child('models/${ids[0]}').onChildChanged.listen((event) {
        if (event.snapshot.key!.isNotEmpty) {
          print('${event.snapshot.ref.key!} - ${event.snapshot.key} - ${event.snapshot.value}');
          // var json = Map<String, dynamic>.from(event.snapshot.value as Map);
          // if (!json.containsKey('type')) return;
          // var model = models[json['type']]?.call(json);
          // print(json['title'] ?? '-');
        }
      });
    }
    for (var id in ids) {
      var item = await getItem(id: id);
      if (item != null) {
        items.addAll({id: item});
      }
    }
    return items;
  }
  
  @override
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
        if (item is Model) {
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
        if (item is Registry) {
          updates['registries/${item.metadata.id}/metadata'] = item.metadata.toJson();
          int lastTransactionIndex = item.transactions.keys.last;
          updates['registries/${item.metadata.id}/transactions/$lastTransactionIndex'] = item.transactions[lastTransactionIndex]!.toJson();
        }
      }
      database.update(updates);
    } catch (error) {
      print(error);
    }
    return items.length;
  }

  @override
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

  Future<Map<String, dynamic>> readRegistry(String id, {int take = 1}) async {
    final ref = database.child('registries/$id/transactions');
    final takeQuery = ref.limitToLast(take);
    final metaRef = database.child('registries/$id/metadata');
    final List<DataSnapshot> snapshots = await Future.wait([takeQuery.get(), metaRef.get()]);
    for (DataSnapshot snapshot in snapshots) {
      print(snapshot.value);
    }
    Map<String, dynamic> registry = {};
    registry['metadata'] = Map<String, dynamic>.from(snapshots[1].value as Map);
    for (DataSnapshot child in snapshots[0].children) {
      registry['transactions'][child.key] = child.value;
    }
    // registry['transactions'] = snapshots[0].children.map((e) => e.value).toList();
    return registry;
  }
}