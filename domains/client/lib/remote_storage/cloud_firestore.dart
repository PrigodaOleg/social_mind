import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:closers/remote_storage/remote_storage.dart';
import 'package:closers/repository/models/models.dart';

/// Реализация RemoteStorage на Firebase Cloud Firestore.
/// Структура данных:
///   instances/<app>/models/<id>          - сериализованные модели
///   instances/<app>/registries/<id>      - реестры: metadata + transactions/<idx> + lastIdx
/// Консистентная запись транзакций обеспечивается транзакциями Firestore
/// с проверкой lastIdx (аналог коллизии RemoteStorageWriteCollision в RTDB).
class CloudFirestoreStorage extends RemoteStorage {
  CloudFirestoreStorage();

  static const emailSuffix = '@a.aa';
  FirebaseFirestore? _firestore;
  FirebaseAuth? _auth;
  String _modelsPath = 'models';
  String _registriesPath = 'registries';

  FirebaseFirestore get firestore {
    if (_firestore == null) {
      throw StateError('CloudFirestoreStorage is not initialized');
    }
    return _firestore!;
  }

  FirebaseAuth get authInstance {
    if (_auth == null) {
      throw StateError('CloudFirestoreStorage is not initialized');
    }
    return _auth!;
  }

  @override
  Future<bool> init(String instance, {String? anonKey}) async {
    _firestore = FirebaseFirestore.instanceFor(app: Firebase.app(instance));
    _auth = FirebaseAuth.instanceFor(app: Firebase.app(instance));
    return true;
  }

  @override
  Future<bool> createUserAndAuth(String login, String password) async {
    await authInstance.createUserWithEmailAndPassword(email: '$login$emailSuffix', password: password);
    return true;
  }

  @override
  Future<bool> auth(String login, String password) async {
    await authInstance.signInWithEmailAndPassword(email: '$login$emailSuffix', password: password);
    return true;
  }

  @override
  Future<bool> updateUserPassword(String login, String oldPassword, String newPassword) async {
    final credential = EmailAuthProvider.credential(email: '$login$emailSuffix', password: oldPassword);
    final user = authInstance.currentUser;
    if (user == null) return false;
    await user.reauthenticateWithCredential(credential);
    await user.updatePassword(newPassword);
    return true;
  }

  @override
  Future<dynamic> getItem({required String id}) async {
    try {
      final doc = await firestore.collection(_modelsPath).doc(id).get();
      if (doc.exists) {
        final json = doc.data()!;
        if (!json.containsKey('type')) return null;
        return models[json['type']]?.call(json);
      }
    } catch (error) {
      print(error);
    }
    return null;
  }

  @override
  Future<Map<String, Model>> getItems(List ids) async {
    Map<String, Model> items = {};
    // Firestore позволяет батчевое чтение по `wherein` (до 30 id за запрос)
    final idList = ids.cast<String>().toList();
    for (var i = 0; i < idList.length; i += 30) {
      final chunk = idList.sublist(i, i + 30 > idList.length ? idList.length : i + 30);
      final snapshot = await firestore.collection(_modelsPath).where(FieldPath.documentId, whereIn: chunk).get();
      for (final doc in snapshot.docs) {
        final json = doc.data();
        if (!json.containsKey('type')) continue;
        final model = models[json['type']]?.call(json);
        if (model != null) items[doc.id] = model;
      }
    }
    return items;
  }

  Map<String, dynamic> _flattenModel(Model item) {
    final json = item.toJson();
    // Списки в Firestore хранить можно, но для паритета с RTDB и ребейзом
    // переводим их в словари ключ->true (как это делает RTDB при записи).
    // Однако rebase ожидает списки. Компромисс: пишем как есть (Firestore поддерживает
    // массивы), список читается обратно корректно.
    return json;
  }

  @override
  Future<int> saveItems(Map<String, dynamic> items) async {
    try {
      // Транзакции реестров пишем консистентно через runTransaction с проверкой lastIdx
      final models_ = <String, dynamic>{};
      final registries_ = <String, Registry>{};
      for (var entry in items.entries) {
        if (entry.value is Model) models_[entry.key] = entry.value;
        if (entry.value is Registry) registries_[entry.key] = entry.value;
      }

      // Модели пишем батчем
      if (models_.isNotEmpty) {
        final batch = firestore.batch();
        for (var entry in models_.entries) {
          batch.set(firestore.collection(_modelsPath).doc(entry.key), _flattenModel(entry.value as Model));
        }
        await batch.commit();
      }

      // Реестры - каждый через транзакцию с проверкой lastIdx
      for (var entry in registries_.entries) {
        final registry = entry.value;
        await _saveRegistryTransactionally(registry);
      }
    } on RemoteStorageWriteCollision {
      // Коллизия реестра должна дойти до вызывающего (rebase в Repository)
      rethrow;
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw RemoteStorageWriteCollision(e.code, 0);
      }
      print("Firestore Error: ${e.code} — ${e.message}");
    } catch (e) {
      print('Unknown Firestore Error: $e');
    }
    return items.length;
  }

  Future<void> _saveRegistryTransactionally(Registry registry) async {
    final ref = firestore.collection(_registriesPath).doc(registry.id);
    final lastTransactionIndex = registry.transactions.keys.last;
    await firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      int? remoteLastIdx;
      if (snapshot.exists) {
        final data = snapshot.data()!;
        remoteLastIdx = data['lastIdx'] as int?;
      }
      // Если удаленная голова ушла вперед - коллизия, клиент сделает rebase
      if (remoteLastIdx != null && remoteLastIdx >= lastTransactionIndex) {
        throw RemoteStorageWriteCollision('registry head moved forward', 0);
      }
      transaction.set(ref, {
        'metadata': registry.metadata.toJson(),
        'lastIdx': lastTransactionIndex,
      }, SetOptions(merge: true));
      // Индекс храним zero-padded (Firestore сортирует document ID лексикографически)
      transaction.set(
        ref.collection('transactions').doc(_paddedIndex(lastTransactionIndex)),
        {...registry.transactions[lastTransactionIndex]!.toJson(), 'idx': lastTransactionIndex},
      );
    });
  }

  /// Zero-padded индекс транзакции для лексикографически сортируемых document ID.
  static String _paddedIndex(int index) => index.toString().padLeft(15, '0');

  @override
  Future<int> deleteItems(Map<String, dynamic> items) async {
    try {
      final batch = firestore.batch();
      for (var entry in items.entries) {
        batch.delete(firestore.collection(_modelsPath).doc(entry.key));
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        throw RemoteStorageWriteCollision(e.code, 0);
      }
      print("Firestore Error: ${e.code} — ${e.message}");
    }
    return items.length;
  }

  @override
  Future<Registry?> readRegistry(String id, {int count = 1}) async {
    try {
      final ref = firestore.collection(_registriesPath).doc(id);
      final metaSnap = await ref.get();
      if (!metaSnap.exists) return null;
      final transactionsSnap = await ref
          .collection('transactions')
          .orderBy('idx', descending: true)
          .limit(count)
          .get();
      final metadata = Map<String, dynamic>.from(metaSnap.data()!['metadata'] as Map);
      final transactions = <String, dynamic>{};
      for (final doc in transactionsSnap.docs) {
        transactions[doc.id] = doc.data();
      }
      return Registry.fromJson({
        'metadata': metadata,
        'transactions': transactions,
      });
    } catch (error) {
      print(error);
    }
    return null;
  }

  @override
  Future<Map<String, Registry>> readRegistries({
    List<String>? ids,
    List<(String id, int? count)>? idsCounts,
    int count = 1,
  }) async {
    final registries = <String, Registry>{};
    final requests = idsCounts ?? [for (final id in (ids ?? [])) (id, count)];
    for (final (id, c) in requests) {
      final registry = await readRegistry(id, count: c ?? count);
      if (registry != null) registries[id] = registry;
    }
    return registries;
  }

  @override
  Stream<RegistryChangeEvent> watchRegistries(List<String> ids) {
    final controller = StreamController<RegistryChangeEvent>();
    final subscriptions = <StreamSubscription>[];
    for (final id in ids) {
      final sub = firestore.collection(_registriesPath).doc(id).snapshots().listen((snapshot) {
        if (!snapshot.exists) return;
        final data = snapshot.data()!;
        controller.add(RegistryChangeEvent(id, data['lastIdx'] as int?));
      });
      subscriptions.add(sub);
    }
    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
    };
    return controller.stream;
  }

  @override
  Future<bool> saveRaw(String path, Map<String, dynamic> json) async {
    try {
      final segments = path.split('/');
      final docPath = segments.where((s) => s.isNotEmpty).toList();
      // Firestore требует чётное число сегментов (collection/document/...):
      // чередуем collection 'invitations_data' с document id
      if (docPath.length.isOdd) docPath.add('data');
      final ref = firestore.collection(docPath[0]);
      for (var i = 1; i < docPath.length - 1; i += 2) {
        // промежуточные сегменты кодируем в id документа
      }
      final compositeId = docPath.sublist(1).join('__');
      await ref.doc(compositeId).set(json);
      return true;
    } catch (e) {
      print('saveRaw error: $e');
      return false;
    }
  }

  @override
  Future<Map<String, dynamic>?> readRaw(String path) async {
    try {
      final docPath = path.split('/').where((s) => s.isNotEmpty).toList();
      if (docPath.length.isOdd) docPath.add('data');
      final compositeId = docPath.sublist(1).join('__');
      final doc = await firestore.collection(docPath[0]).doc(compositeId).get();
      if (doc.exists) return doc.data();
    } catch (e) {
      print('readRaw error: $e');
    }
    return null;
  }

  @override
  Future<List<Map<String, dynamic>>> readRawPrefix(String pathPrefix) async {
    // Для Firestore префиксный поиск ограничен: читаем коллекцию верхнего уровня,
    // фильтруем по составному id на клиенте
    final result = <Map<String, dynamic>>[];
    try {
      final segments = pathPrefix.split('/').where((s) => s.isNotEmpty).toList();
      final collectionName = segments.first;
      final prefix = segments.length > 1 ? segments.sublist(1).join('__') : '';
      final snapshot = await firestore.collection(collectionName).get();
      for (final doc in snapshot.docs) {
        if (prefix.isEmpty || doc.id.startsWith(prefix)) {
          result.add(doc.data());
        }
      }
    } catch (e) {
      print('readRawPrefix error: $e');
    }
    return result;
  }
}
