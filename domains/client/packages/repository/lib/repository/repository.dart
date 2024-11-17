import 'dart:collection';

import 'package:local_storage/hive/hive_storage.dart';
import '../models/models.dart';

import 'package:remote_storage/remote_storage.dart';


typedef SyncListener = void Function(String id, dynamic syncedItem);


class Closee {}


// Operates (soon) with 3 types of storages (databases):
//    - Local storage - stores data on this device (exlude web).
//    - Remote storage - stores data remotely in back-end database (now it is 3d party).
//    - Peer to peer storage - stores data locally on this device, but periodically updates it from closers devices.
//          Uses remote beacons to get link to closers devices.
//          All data transmitted directly between user devices in encrypted form.
//          Merge conflicts solves according user chousen merge politic.
class Repository {
  Repository();

  late final HiveStorage _localStorage;
  late final FirebaseStorage _remoteStorage;
  var outgoingChanges = Queue<dynamic>();

  // Listeners to incoming changes
  var syncListeners = <int, SyncListener>{};  // by sybscribers
  var syncBackIndex = <int, Set<String>>{}; // for find all IDs by subscriber
  int subscribersCounter = 0;
  var incomingSyncIds = <String, Set<int>>{};  // with set of subscribers

  var syncedThisTime = <String>{};

  Future<void> init() async {
    _localStorage = HiveStorage();
    _remoteStorage = FirebaseStorage();
    await _localStorage.init();
    await _remoteStorage.init();
    loop();
  }

  int addSyncListener(SyncListener syncListener) {
    syncListeners[subscribersCounter] = syncListener;
    return subscribersCounter++;
  }

  void removeSyncListener(int subscriberId) {
    syncListeners.remove(subscriberId);
    if (!syncBackIndex.containsKey(subscriberId)) return;
    syncBackIndex[subscriberId]?.forEach((syncId) {
      if (incomingSyncIds.containsKey(syncId)) {
        incomingSyncIds[syncId]?.remove(subscriberId);
        if (incomingSyncIds[syncId]!.isEmpty) incomingSyncIds.remove(syncId);
      }
    });
    syncBackIndex.remove(subscriberId);
  }

  // todo: Change to timer timer stream
  void loop() async {
    // Transmit outgoing changes
    int saved = await _remoteStorage.saveItems(Map.fromEntries(outgoingChanges.map((item) => MapEntry(item.id, item))));

    // Make sure everything went well
    // Тут на самом деле самого факта сохранения достаточно.
    // Дальнейшая работа уже идет про другое. Если есть удаленные изменения
    // в прослушиваемых моделях, то мы эти изменения отправляем слушателям
    // Однако, о самих изменениях мы узнаем по событиям из удаленного репозитория
    while (saved-- > 0) {
      String id = outgoingChanges.first.id;
      _findAndCallListeners(id);
      outgoingChanges.removeFirst();
    }

    // Process incoming sync first time
    var idsToSync = incomingSyncIds.keys.toSet().difference(syncedThisTime).toList();
    // var syncedModels = await _remoteStorage.getItems(idsToSync);
    // Find and call listeners for group of synced models
    for (final id in idsToSync) {
      _findAndCallListeners(id);
    }
    syncedThisTime.addAll(idsToSync);

    Future.delayed(const Duration(seconds: 5), loop);
  }

  void _findAndCallListeners(String id) async {
    incomingSyncIds[id]?.forEach((subscriberId) async {
      Model? model = await _remoteStorage.getItem(id: id);
      model?.sync = SyncStatus.synced;
      syncedThisTime.add(id);
      if (model != null) syncListeners[subscriberId]?.call(id, model);
    });
  }

  void _subscribeToSync(String modelId, int? subscriberId) {
    if (subscriberId != null) {
      if (!incomingSyncIds.containsKey(modelId)) incomingSyncIds[modelId] = {};
      incomingSyncIds[modelId]?.add(subscriberId);
      if (!syncBackIndex.containsKey(subscriberId)) syncBackIndex[subscriberId] = {};
      syncBackIndex[subscriberId]?.add(modelId);
    }
  }

  void _subscribeToSyncs(List<String> modelIds, int? subscriberId) {
    modelIds.forEach((id) {
      _subscribeToSync(id, subscriberId);
    });
  }

  void _markSynced<T>(T model) {
    Model m = model as Model;
    if (syncedThisTime.contains(m.id)) {
      m.sync = SyncStatus.synced;
    }
  }

  void _markSynceds<T>(Map<String, T> models) {
    models.forEach((id, model) {
      _markSynced(model);
    });
  }

  Future<void> saveModel(
    Model model,
    [int? subscriberId] // Item ID - sync callback pair
  ) async {
    await _localStorage.storeItem(model);
    _subscribeToSync(model.id, subscriberId);
    outgoingChanges.addLast(model);
  }

  Future<Model> getModel(
    String modelId,
    [int? subscriberId] // Item ID - sync callback pair
  ) async {
    Model model = await _localStorage.getItem(id: modelId);
    _subscribeToSync(modelId, subscriberId);
    return model;
  }

  Future<Map<String, T>> getModels<T>(
    List<String> ids,
    [int? subscriberId]
  ) async {
    Map<String, T> models = await _localStorage.getItems(ids);
    _subscribeToSyncs(ids, subscriberId);
    _markSynceds(models);
    return models;
  }

  // # Settings

  // ## Operational settings - always local
  // Contains such data as credentials, active auth tokens...
  // создать нового пользователя, получить его токен или креды, сохранить токен, креды или авторизацию
  Future<void> setLocalUser(User user) async {
    await _localStorage.setUser(user);
  }
  Future<User?> getLocalUser({
    // Item ID - sync callback pair
    Map<String, SyncListener>? syncListeners,
  }) async {
    return await _localStorage.getUser();
  }
  Future<void> removeLocalUser() async {throw UnimplementedError('repository removeLocalUser');}
  Future<void> flushLocalStorage() async {throw UnimplementedError('repository flushLocalStorage');}
  Future<void> setRemoteAuth(auth) async {}
  Future<void> setRemoteUser(User user) async {_remoteStorage.setUser(user);}
  Future<User?> getRemoteUser() async {return await _remoteStorage.getUser();}
  Future<void> removeRemoteUser(User user) async {throw UnimplementedError('repository removeRemoteUser');}


  // ## User settings
  // Contains such data as theme, default type of repo to store user data (local or remote).
  // Can be stored as locally as remotely
  Future<void> saveUserSettings() async {}

  // ## User data - local/remote

  // Close people (known users)
  Future<Map<String, Closee>> getClosers() async {throw UnimplementedError('repository getClosers');}
  Future<void> addClosee(Closee closee) async {throw UnimplementedError('repository addClosePerson');}
  Future<void> removeClosee(Closee closee) async {throw UnimplementedError('repository removeClosePerson');}

  // ### Tasks
  // добавить новую задачу, обновить имеющуюся задачу, удалить задачу
  // переместить задачу в другое хранилище 
  Future<Map<String, Task>> getTasks() async {
    return await _remoteStorage.getTasks();
    // await _localStorage.getTasks();
  }
  Future<void> addTask(Task task) async {
    await _localStorage.save(item: task);
    await _remoteStorage.save(item: task);
  }
  Future<void> removeTask(Task task) async {throw UnimplementedError('repository removeTask');}

  // ### Domains
  // войти в домен, выйти из домена, создать домен, пригласить в домен, удалить из домена, удалить домен...
  // перенести домен в другое хранилище
  Future<Map<String, Domain>> getDomains(User user) async {
    Map<String, Domain> domains = (await _localStorage.getItems(user.domainsIds)).cast<String, Domain>();
    // _user.domainsIds.forEach((domainId) async {
    //   domains[domainId] = await _localStorage.getItem(id: domainId);
    // });
    return domains;
  }
  Future<void> addDomain(Domain domain) async {
    // user.domainsIds.add(domain.id);
    await _localStorage.storeItem(domain);
  }
  Future<void> deleteDomain(Domain domain) async {
    // user.domainsIds.remove(domain.id);
    await _localStorage.deleteItem(domain.id);
  }
  Future<void> inviteToDomain(Closee closee) async {throw UnimplementedError('repository inviteToDomain');}
  Future<void> excludeFromDomain(Closee closee) async {throw UnimplementedError('repository excludeFromDomain');}

  // ### Projects
  // ### Periods
  // ### Events
  // ...
}