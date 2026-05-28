import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:hashlib/hashlib.dart';

import 'package:closers/local_storage/hive/hive_storage.dart';
import '../models/models.dart';
import '../navigation/navigation_stack.dart';

import 'package:closers/remote_storage/remote_storage.dart';


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
      (x) => time - x - 1
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


// Operates (soon) with 3 types of storages (databases):
//    - Local storage - stores data on this device (exclude web).
//    - Remote storage - stores data remotely in back-end database (now it is 3d party).
//    - Peer to peer storage - stores data locally on this device, but periodically updates it from closers devices.
//          Uses remote beacons to get link to closers devices.
//          All data transmitted directly between user devices in encrypted form.
//          Merge conflicts solves according user chosen merge politic.
class Repository {
  static late Repository instance;
  Repository();

  bool late = true;

  late Timer _sync;

  // User associated with this application instance
  // late String myId;

  late int defaultSyncSubscriber;

  // Локальное хранилище есть всегда, это основное хранилище
  late final HiveStorage _localStorage;

  // Удаленное хранилище позволяет хранить состояние 
  // Их может быть много
  // Какие именно доступны - нужно узнать из пользовательских настроек
  final Map<String, RemoteStorage> _remoteStorages = {};

  // Холодное хранилище предназначено для бесконечно долгого хранения данных
  // Их может быть много
  //Map<String, RemoteStorage> _coldStorages = {}

  // Распределенное хранилище предназначено для хранения данных на устройствах других пользователей,
  // хранения данных других пользователей на этом устройстве,
  // а также прямого обмеда данными между устройствами пользователей.
  // По сути, представляет собой вычислительную сеть.
  //late final MeshStorage _mashStorage;

  var outgoingChanges = Queue<dynamic>();
  var outgoingDeletes = Queue<dynamic>();

  // Listeners to incoming changes
  var syncListeners = <int, SyncListener>{};  // by subscribers
  var syncBackIndex = <int, Set<String>>{}; // for find all IDs by subscriber
  int subscribersCounter = 0;
  var incomingSyncIds = <String, Set<int>>{};  // with set of subscribers

  var syncedThisTime = <String>{};

  final knownRemoteStorages = <String, Function()>{
    'FirebaseRealtimeDatabase': () => FirebaseStorage(),
  };

  Future<void> init() async {
    _localStorage = HiveStorage();
    await _localStorage.init();
    await initRemoteStorages();
    await authRemoteStorages();
    defaultSyncSubscriber = addSyncListener(_defaultSyncListener);
    _sync = Timer(_delayedSync);
    _sync.start();
    instance = this;
    late = false;
  }

  Future<void> initRemoteStorages() async {
    if (myId == null) return;
    for (var storage in me.settings.getDeep('remote_storages', defaultValue: {}).entries) {
      _remoteStorages[storage.key] = knownRemoteStorages[storage.key]?.call();
    }
    for (var storage in _remoteStorages.entries) {
      var instanceFieldName = 'remote_storages.${storage.key}.instance';
      String? instance = me.settings.getDeep(instanceFieldName);
      if (instance != null) {
        await storage.value.init(instance);  // todo: wrap in try-catch and show error message to user
      } else {
        print('No parameter $instanceFieldName is specified for ${storage.key}');
      }
    }
  }

  Future<void> authRemoteStorages() async {
    if (myId == null) return;
    for (var storage in _remoteStorages.entries) {
      var passwordFieldName = 'remote_storages.${storage.key}.hashed_password';
      String? password = me.secrets.getDeep(passwordFieldName);
      if (password != null) {
        await storage.value.auth(me.id, password);  // todo: wrap in try-catch and show error message to user
      } else {
        print('No parameter $passwordFieldName is specified for ${storage.key}');
      }
    }
  }

  Future<bool> createUserRemoteStorages(String? secret) async {
    if (myId == null) {
      throw Exception('Cant create user for remote storages while local user not initialized');
    }
    bool success = true;
    for (var storage in _remoteStorages.entries) {
      var passwordFieldName = 'remote_storages.${storage.key}.hashed_password';
      var instanceFieldName = 'remote_storages.${storage.key}.instance';
      String? password = me.secrets.getDeep(passwordFieldName);
      String? instance = me.settings.getDeep(instanceFieldName);
      if (password == null) {
        if (secret == null) throw Exception('User secret for remote storage ${storage.key} is not specified');
        String password = scrypt(utf8.encode(secret), utf8.encode('${storage.key}$instance')).toString();
        await storage.value.createUserAndAuth(me.id, password);
        me.secrets.setDeep(passwordFieldName, password);
      } else {
        try {
          await storage.value.createUserAndAuth(me.id, password);
        } on Exception catch (e) {
          print('User creation for storage ${storage.key} error: $e');
          success = false;
        }
      }
    }
    return success;
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

  void _defaultSyncListener(String id, dynamic syncedItem) async {
    await _localStorage.storeItem(syncedItem);
  }

  void _delayedSync() async {
    // Свежий взгляд 08.12.2024.
    // Этот метод совершает синхронизацию локальных и удаленных объектов. Конкретно должны обрабатываться следующие сценарии:
    // 1. Локально создан новый объект и его нужно просто загрузить в удаленное хранилище.
    // 2. Локальный объект не существует, но известен его ID, по которому нужно запросить его из удаленного хранилища.
    // 3. Локальный объект существует и изменен, и эти изменения нужно доставить в удаленное хранилище.
    // 4. Приложение только что запустилось, все объекты считаются несинхронизированными и подлежат ленивой синхронизации по запросу.
    // 5. Если объект уже был синхронизирован в этой сессии и не был изменен локально, то больше мы его синхронизировать не будем
    // 6. Об удаленных изменениях мы узнаем через другой механизм (чат),
    //    получаем оттуда ID объектов, которые нужно будет синхронизировать.
    // Итого, последовательность действий должна быть следующей:
    // 1. Сперва разгребаем очередь из элементов, накопивщихся с момента последней синхронизации,
    //    которые необходимо безусловно отправить в удаленное хранилище.
    // 2. Для каждого отправленного элемента вызываем событие для слушателя, так он понимает, что синхронизация произошла.
    // 3. После этого обрабатываем элементы, актуальность которых не известна и был запрос на синхронизацию от слушателя.
    //
    // 14.12.2024
    // Забыл про удаление элементов. При удалении должно сперва произойти удаление в удаленном хранилище,
    // а по его итогам локальное удаление. Тут возможны несколько вариантов:
    // 1. В удаленном хранилище был такой объект и он удалился. Значит удаляем локально.
    // 2. В удаленном хранилище не было такого объекта. В таком случае просто удаляем локальный объект.
    // 3. Пришло сообщение об удалении в ремоуте. В таком случае удаляем локальный объект.
    // 4. Нет прав на удаление в ремоуте. Тогда нельзя удалять локальный объект.
    // 5. Права на удаление есть, однако удалить все равно нельзя из-за взаимосвязей с другими пользователями.
    //    Локальный объект удалять нельзя. Мало того, в этом случае нельзя даже изменять связи,
    //    так как в удаленном хранилище они все равно не изменятся.
    // При манипуляциях с удалением никакие события для слушателей вызывать не надо, так как будет нечего туда посылать.
    // Однако при удалении объекта изменятся и объекты, которые с ним связвны, и для них будут вызваны соответствующие события.
    // 
    // Также, на данный момент не учтено, что даже сохранение может произойти из-за ошибка в правах или ошибки внутренних правил
    // по изменениям связей объектов. В таком случае надо отменять все изменения... Так что, здесь нужно пересматривать всю политику.
    // todo: пересмотреть всю политику синхронизации с учетом возможных ошибок правил и доступов, а также учесть тот факт,
    //        что в самих объектах есть поле, которое указывает, где необходимо располагать данный объект.
    // Пока просто добавим удаление без учета ошибок.
    //
    // 10.12.2024
    // При приеме моделей из удаленного хранилища нужно их обязательно мержить/класть в локальное хранилище,
    // поскольку их там либо нет, либо они там старые.
    // Как понять, что они там старые? Пока есть идея завести внутри модели счетчик, и инкрементировать его при каждом изменении модели.
    // Однако, если на другом устройстве другой пользователь тоже будет инкрементить этот счетчик, то показания разойдутся.
    // Может 2 счетчика? Типа каким был счетчик до того, как я начал его менять и какой счетчик сейчас.
    // При мерже находить более раннее значение счетчика и отсчитывать мерж от него.

    // Если нет ни одного удаленного хранилища, то ничего не делаем.
    if (_remoteStorages.isEmpty) {
      return;
    }

    // Следим за каждый удаленным хранилищем, все они должны быть проинициализированы, во всех должны быть аутентифицированы пользователи.
    // todo: сделать проверку на инициализацию и аутентификацию.

    // Отправляем локальные удаления в удаленное хранилище
    int deleted = await _remoteStorages['FirebaseRealtimeDatabase']!.deleteItems(Map.fromEntries(outgoingDeletes.map((item) => MapEntry(item.id, item))));
    // Если все прошло успешно, то вызываем событие, по которому произойдет удаление такого объекта.
    while (deleted--> 0) {
      String id = outgoingDeletes.first.id;
      _localStorage.deleteItem(id);
      outgoingDeletes.removeFirst();
    }

    // Отправляем локальные изменения в удаленное хранилище
    int saved = await _remoteStorages['FirebaseRealtimeDatabase']!.saveItems(Map.fromEntries(outgoingChanges.map((item) => MapEntry(item.id, item))));
    // Вызываем для каждого синхронизированного элемента событие для слушателя
    while (saved-- > 0) {
      String id = outgoingChanges.first.id;
      _findAndCallListeners(id);
      outgoingChanges.removeFirst();
    }

    // Актуализируем элементы, на синхронизацию которых поступил запрос от слушателей
    var idsToSync = incomingSyncIds.keys.toSet().difference(syncedThisTime).toList();
    var syncedModels = await _remoteStorages['FirebaseRealtimeDatabase']!.getItems(idsToSync);
    // Вот тут, внимание(!), сохраняем приехвашие изменения в локальное хранилище, хотя надо делать слияние
    await _localStorage.storeItems(syncedModels);
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
      Model? model = await _remoteStorages['FirebaseRealtimeDatabase']!.getItem(id: id); // тут плохо сделано, на каждый элемент вызывается чтение с сервера. Запросы на чтение нужно накапливать за определенный промежуток времени, а потом батчевать.
      model?.sync = SyncStatus.synced;
      syncedThisTime.add(id); // todo: тут ошибка - если в удаленном репозитории такой модели нет, то ее надо либо туда загрузить, либо удалить тут, тихо промолчать нельзя
      // print(model);
      if (model != null) syncListeners[subscriberId]?.call(id, model);
    });
  }

  void subscribeToSync(String modelId, int? subscriberId) {
    if (subscriberId != null) {
      if (!incomingSyncIds.containsKey(modelId)) incomingSyncIds[modelId] = {};
      incomingSyncIds[modelId]?.add(subscriberId);
      if (!syncBackIndex.containsKey(subscriberId)) syncBackIndex[subscriberId] = {};
      syncBackIndex[subscriberId]?.add(modelId);
    }
  }

  void subscribeToSyncAll(List<String> modelIds, int? subscriberId) {
    // ignore: avoid_function_literals_in_foreach_calls
    modelIds.forEach((id) {
      subscribeToSync(id, subscriberId);
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
    subscribeToSync(model.id, defaultSyncSubscriber);
    _sync.postpone();
  }

  Future<void> saveModel(
    Model model,
    [int? subscriberId] // Item ID - sync callback pair
  ) async  {
    await _localStorage.storeItem(model);
    subscribeToSync(model.id, subscriberId);
    outgoingChanges.addLast(model);
    _sync.postpone();
  }

  T? getModel<T>(
    String modelId,
    [int? subscriberId] // Item ID - sync callback pair
  ) {
    T? model = _localStorage.getItem(id: modelId);
    subscribeToSync(modelId, subscriberId);
    _sync.postpone();
    return model;
  }

  Future<T?> getModelNow<T>(String modelId) async {
    T? model = _localStorage.getItem(id: modelId);
    model = model ?? await _remoteStorages['FirebaseRealtimeDatabase']!.getItem(id: modelId);
    return model;
  }

  Map<String, T> getModels<T>(
    List<String> ids,
    [int? subscriberId]
  ) {
    Map<String, T> models = _localStorage.getItems(ids);
    subscribeToSyncAll(ids, subscriberId);
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
    subscribeToSyncAll(modelsMap.keys.toList(), subscriberId);
    outgoingChanges.addAll(models);
    _sync.postpone();
  }

  void deleteModel(
    Model model,
    [int? subscriberId] // Item ID - sync callback pair
  ) {
    outgoingDeletes.addLast(model);
    _sync.postpone();
  }

  // Get user associated with this instance of application
  // User must be set already
  User get me {
    if (myId == null) {
      throw StateError('Local user is unknown: $myId');
    }
    User? me = _localStorage.getItem(id: myId!);
    if (me == null) {
      throw StateError('No such user in local storage: $myId');
    }
    return me;
  }
  // Call once at startup
  set me(User me) {
    // unfortunately store item is async, so set callback to sync user with remote storage
    _localStorage.storeItem(me).then((value) => _syncModel(me));
    // _syncModel(me);
    myId = me.id; // actually its async, so no call ME immediately after that? wait for second
  }

  // # Settings
  // Contains such data as credentials, active auth tokens...

  // ## Operational settings - always local
  // создать нового пользователя, получить его токен или креды, сохранить токен, креды или авторизацию
  // Gel local uder Id
  String? get myId {
    return _localStorage.getUserId();
  }

  set myId(String? id) {
    // setUserId is async? so just start saving and leave
    if (id != null) {
      _localStorage.setUserId(id);
    }
  }

  String? get lastRoute {
    return _localStorage.getOperational('lastRoute');
  }

  set lastRoute(String? lastRoute) {
    if (late) return;
    if (lastRoute != null) {
      _localStorage.setOperational('lastRoute', lastRoute);  // await
    }
  }

  List<NavStackEntry>? get lastNavStack {
    return _localStorage.getOpItem('lastNavStack')?.cast<NavStackEntry>();
  }

  set lastNavStack(List<NavStackEntry>? lastNavStack) {
    if (late) return;
    if (lastNavStack == null) return;
    if (lastNavStack.isNotEmpty) {
      _localStorage.storeOpItem('lastNavStack', lastNavStack);
    }
  }
  

  // ## User settings
  // Contains such data as theme, default type of repo to store user data (local or remote).
  // Can be stored as locally as remotely
  Future<void> saveUserSettings() async {}

  // ## User data - local/remote

  // // ### Tasks
  // // добавить новую задачу, обновить имеющуюся задачу, удалить задачу
  // // переместить задачу в другое хранилище 
  // Future<Map<String, Task>> getTasks() async {
  //   return await _remoteStorages['FirebaseRealtimeDatabase']!.getTasks();
  //   // await _localStorage.getTasks();
  // }
  // Future<void> addTask(Task task) async {
  //   await _localStorage.save(item: task);
  //   await _remoteStorages['FirebaseRealtimeDatabase']!.save(item: task);
  // }
  // Future<void> removeTask(Task task) async {throw UnimplementedError('repository removeTask');}
}