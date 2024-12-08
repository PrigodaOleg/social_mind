import 'dart:async';
import 'dart:collection';

import 'package:local_storage/hive/hive_storage.dart';
import '../models/models.dart';

import 'package:remote_storage/remote_storage.dart';


typedef SyncListener = void Function(String id, dynamic syncedItem);
typedef PeriodicCallback = void Function(int left);
typedef DoneCallback = void Function();


class Timer {
  Timer([this.done, this.periodic]);
  DoneCallback? done;
  PeriodicCallback? periodic;
  static const int defaultTime = 5;
  static const int defaultPeriod = 1;
  int lastActualPeriod = defaultPeriod;
  int lastActualtime = defaultTime;
  Stream<int>? _timer;
  StreamSubscription<int>? _timerSubscription;

  _start(int time, int? period) {
    _timerSubscription?.cancel();
    _timer = Stream.periodic(
      Duration(seconds: lastActualPeriod),
      (x) => time! - x - 1
    ).take(time);
    _timerSubscription = _timer?.listen(
      periodic,
      onDone: done,
      cancelOnError: true
    );
  }

  start([int? time, int? period]) {
    time = time ?? defaultTime;
    period = period ?? defaultPeriod;
    _start(time, period);
    lastActualPeriod = period;
    lastActualtime = time;
  }

  now() {
    _start(0, 0);
  }

  postpone([int? time]) {
    time = time ?? lastActualtime;
    _start(time, lastActualPeriod);
    lastActualtime = time;
  }

  cancel() {
    _timerSubscription?.cancel();
    _timer = null;
  }
}


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

  late Timer _sync;

  // User associated with this application instance
  late String myId;
  late int defaultSyncSubscriber;

  late final HiveStorage _localStorage;
  late final FirebaseStorage _remoteStorage;
  var outgoingChanges = Queue<dynamic>();

  // Listeners to incoming changes
  var syncListeners = <int, SyncListener>{};  // by subscribers
  var syncBackIndex = <int, Set<String>>{}; // for find all IDs by subscriber
  int subscribersCounter = 0;
  var incomingSyncIds = <String, Set<int>>{};  // with set of subscribers

  var syncedThisTime = <String>{};

  Future<void> init() async {
    _localStorage = HiveStorage();
    _remoteStorage = FirebaseStorage();
    await _localStorage.init();
    await _remoteStorage.init();
    defaultSyncSubscriber = addSyncListener(_defaultSyncListener);
    _sync = Timer(delayedSync);
    _sync.start();
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

  void _defaultSyncListener(String id, dynamic syncedItem) {
    _localStorage.storeItem(syncedItem);
  }

  void delayedSync() async {
    // Свежий взгляд 08.12.2024.
    // Этот метод совершает синхронизацию локальных и удаленных объектов. Конкретно должны обрабатываться следующие сценарии:
    // 1. Локально создан новый объект и его нужно просто загрузить в удаленное хранилище
    // 2. Локальный объект не существует, но известен его ID, по которому нужно запросить его из удаленного хранилища
    // 3. Локальный объект существует и изменен, и эти изменения нужно доставить в удаленное хранилище
    // 4. Приложение только что запустилось, все объекты считаются несинхронизированными и подлежат ленивой синхронизации по запросу
    // 5. Если объект уже был синхронизирован в этой сессии и не был изменен локально, то больше мы его синхронизировать не будем
    // 6. Об удаленных изменениях мы узнаем через другой механизм (чат),
    //    получаем оттуда ID объектов, которые нужно будет синхронизировать
    // Итого, последовательность действий должна быть следующей:
    // 1. Сперва разгребаем очередь из элементов, накопивщихся с момента последней синхронизации,
    //    которые необходимо безусловно отправить в удаленное хранилище
    // 2. Для каждого отправленного элемента вызываем событие для слушателя, так он понимает, что синхронизация произошла
    // 3. После этого обрабатываем элементы, актуальность которых не известна и был запрос на синхронизацию от слушателя

    // Отправляем локальные изменения в удаленное хранилище
    int saved = await _remoteStorage.saveItems(Map.fromEntries(outgoingChanges.map((item) => MapEntry(item.id, item))));
    // Вызываем для каждого синхронизированного элемента событие для слушателя
    while (saved-- > 0) {
      String id = outgoingChanges.first.id;
      _findAndCallListeners(id);
      outgoingChanges.removeFirst();
    }

    // Актуализируем элементы, на синхронизацию которых поступил запрос от слушателей
    var idsToSync = incomingSyncIds.keys.toSet().difference(syncedThisTime).toList();
    var syncedModels = await _remoteStorage.getItems(idsToSync);
    // Вызываем для каждого синхронизированного элемента событие для слушателя
    for (final id in idsToSync) {
      _findAndCallListeners(id);
    }
    // Больше не будем синхронизировать эти объекты, если только они не будут изменены локально
    // или не поступят события об их изменении в удаленном хранилище
    syncedThisTime.addAll(idsToSync);
  }

  void _findAndCallListeners(String id) async {
    incomingSyncIds[id]?.forEach((subscriberId) async {
      Model? model = await _remoteStorage.getItem(id: id); // тут плохо сделано, на каждый элемент вызывается чтение с сервера. Запросы на чтение нужно накапливать за определенный промежуток времени, а потом батчевать.
      model?.sync = SyncStatus.synced;
      syncedThisTime.add(id);
      // print(model);
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

  void _subscribeToSyncAll(List<String> modelIds, int? subscriberId) {
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

  void _markSyncedAll<T>(Map<String, T> models) {
    models.forEach((id, model) {
      _markSynced(model);
    });
  }

  void _syncModel(Model model) {
    _subscribeToSync(model.id, defaultSyncSubscriber);
    _sync.postpone();
  }

  Future<void> saveModel(
    Model model,
    [int? subscriberId] // Item ID - sync callback pair
  ) async {
    await _localStorage.storeItem(model);
    _subscribeToSync(model.id, subscriberId);
    outgoingChanges.addLast(model);
    _sync.postpone();
  }

  Future<Model> getModel(
    String modelId,
    [int? subscriberId] // Item ID - sync callback pair
  ) async {
    Model model = await _localStorage.getItem(id: modelId);
    _subscribeToSync(modelId, subscriberId);
    _sync.postpone();
    return model;
  }

  Future<Map<String, T>> getModels<T>(
    List<String> ids,
    [int? subscriberId]
  ) async {
    Map<String, T> models = await _localStorage.getItems(ids);
    _subscribeToSyncAll(ids, subscriberId);
    _markSyncedAll(models);
    _sync.postpone();
    return models;
  }

  Future<void> saveModels(
    List<Model> models,
    [int? subscriberId] // Item ID - sync callback pair
  ) async {
    var modelsMap = { for (var model in models) model.id : model };
    await _localStorage.storeItems(modelsMap);
    _subscribeToSyncAll(modelsMap.keys.toList(), subscriberId);
    outgoingChanges.addAll(models);
    _sync.postpone();
  }

  // # Settings

  // Get user associated with this instance of application
  // User must be set already
  Future<User> me() async {
    User? me = await _localStorage.getItem(id: myId);
    if (me == null) {
      throw StateError('No such user in local storage $myId');
    }
    return me.mutable(); // ну это костыль, конечно, но что делать, если хайв возвращает строго немутабельный объект
  }
  // Call once at startup
  setMyself(User me) async {
    myId = me.id;
    await _localStorage.storeItem(me);
    _syncModel(me);
  }

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