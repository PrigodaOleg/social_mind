import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:hashlib/hashlib.dart';

import '../models/models.dart';
import '../navigation/navigation_stack.dart';


typedef SyncListener = void Function(String id, dynamic syncedItem);
typedef MergeConflictListener = void Function(Map<String, Model> localChanges, Map<String, Model> remoteChanges);
typedef AccessDeniedListener = void Function(Map<String, dynamic> items);
typedef PeriodicCallback = void Function(int left);
typedef DoneCallback = void Function();


class RebaseCollision implements Exception {
  final String message;
  final int statusCode;

  RebaseCollision(this.message, this.statusCode);

  @override
  String toString() => 'RebaseCollision ($statusCode): $message';
}


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
  Repository({
    LocalStorage? localStorage,
    Map<String, RemoteStorage>? remoteStorages
  }) :
  _localStorage = localStorage ?? IsarStorage(),
  // _localStorage = localStorage ?? HiveStorage()
  _remoteStorages = remoteStorages ?? <String, RemoteStorage>{}
  ;

  bool late = true;

  late Timer _sync;

  // User associated with this application instance
  // late String myId;

  late int defaultSyncSubscriber;

  // Локальное хранилище есть всегда, это основное хранилище
  final LocalStorage _localStorage;

  // Удаленное хранилище позволяет хранить состояние
  // Их может быть много
  // Какие именно доступны - нужно узнать из пользовательских настроек
  final Map<String, RemoteStorage> _remoteStorages;

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
  var mergeConflictListeners = <int, MergeConflictListener>{};  // by subscribers
  // Уведомляется, когда удаленное хранилище отказывает в записи изменений (нет прав доступа)
  var accessDeniedListeners = <int, AccessDeniedListener>{};  // by subscribers
  var syncBackIndex = <int, Set<String>>{}; // for find all IDs by subscriber
  int subscribersCounter = 0;
  var incomingSyncIds = <String, Set<int>>{};  // with set of subscribers

  var syncedThisTime = <String>{};

  final knownRemoteStorages = <String, Function()>{
    'FirebaseRealtimeDatabase': () => FirebaseStorage(),
  };

  Future<void> init() async {
    await _localStorage.init();
    await initRemoteStorages();
    await authRemoteStorages();
    defaultSyncSubscriber = addSyncListener(_defaultSyncListener, _defaultMergeConflictListener, _defaultAccessDeniedListener);
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

  int addSyncListener(
    SyncListener syncListener,
    MergeConflictListener mergeConflictListener,
    [AccessDeniedListener? accessDeniedListener]
  ) {
    syncListeners[subscribersCounter] = syncListener;
    mergeConflictListeners[subscribersCounter] = mergeConflictListener;
    if (accessDeniedListener != null) accessDeniedListeners[subscribersCounter] = accessDeniedListener;
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

  void _defaultMergeConflictListener(Map<String, Model> localItems, Map<String, Model> remoteItems) {
    print('Merge conflict detected for items: $localItems');
    print('Remote items: $remoteItems');
  }

  void _defaultAccessDeniedListener(Map<String, dynamic> items) {
    print('Access denied for items: $items');
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
    int deleted = await _deleteFromAllRemoteStorages(Map.fromEntries(outgoingDeletes.map((item) => MapEntry(item.id, item))));
    // Если все прошло успешно, то вызываем событие, по которому произойдет удаление такого объекта.
    while (outgoingDeletes.isNotEmpty) {
      String id = outgoingDeletes.first.id;
      _localStorage.deleteItem(id);
      outgoingDeletes.removeFirst();
    }

    // Отправляем локальные изменения в удаленное хранилище
    int saved = await syncWithRemoteStorage(Map.fromEntries(outgoingChanges.map((item) => MapEntry(item.id, item))));
    // Вызываем для каждого синхронизированного элемента событие для слушателя
    while (outgoingChanges.isNotEmpty) {
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

  // todo: Тут, конечно, получается полный сюрреализм, поскольку мы читаем одни и те же модели из разных источников, получаются дубли.
  // Нужно читать либо откуда-то из одного места, либо при чтении из разных как-то сравнивать получающиеся данные и при их расхождении
  // производить анализ на предмет того, чьи данные актуальнее, и распространять свежую версию во все хранилища.
  // Тут по хорошему нужно нарисовать схему взаимодействия между всеми хранилищами и сделать правильную логику синхронизации.
  Future<Map<String, dynamic>> _getFromAllRemoteStorages(List ids) async {
    Map<String, dynamic> items = {};
    for (var rStorage in _remoteStorages.entries) {
      items.addAll(await rStorage.value.getItems(ids));
    }
    return items;
  }

  Future<int> _saveToAllRemoteStorages(Map<String, Model> items, Map<String, Registry> registries) async {
    int count = 0;
    // todo: Сейчас сохраняет тупым перебором все remote storage'ы. Нужно сделать более умный способ
    for (var rStorage in _remoteStorages.entries) {
      count += await rStorage.value.saveItems({...items,  ...registries});
    }
    return count; // todo: Тут вообще возвращается не пойми что
  }

  Future<int> _deleteFromAllRemoteStorages(Map<String, dynamic> items) async {
    int count = 0;
    for (var rStorage in _remoteStorages.entries) {
      count += await rStorage.value.deleteItems(items);
    }
    return count;
  }

  // Извлекаем домен для модели.
  Model? _getParent(Model model) {
    if (model is Domain || model is User) return model;
    Map<String, Model> parents = _localStorage.getItems(model.parents.keys.toList());
    while (parents.isNotEmpty) {
      Model? parent = parents.remove(parents.keys.first);
      if (parent is Domain || parent is User) {
        return parent;
      } else if (parent != null) {
        parents.addAll(_localStorage.getItems(parent.parents.keys.toList()));
      }
    }
    return null;
  }

  // Реализация консистентной записи с использованием реестра изменений
  @visibleForTesting
  Future<int> syncWithRemoteStorage(Map<String, Model> localItems) async {

    // Так как мы начинаем собирать новую транзакцию,
    // то прекращаем сбор исторических данных для текущей локальной копии
    final oldItems = _localStorage.getNextItemsFromHistoryQueue();

    // Проходим по моделям и определяем, к каким доменам/пользователям они относятся.
    Map<Model, Map<String, dynamic>> parentItems = _clusterItemsByParent(localItems);

    var localRegistries = _getRegistries(parentItems.keys.toList());

    var remoteRegistries = <String, Registry>{};
    var latestRemoteRegistries = <String, Registry>{};

    var localchanges = localItems;
    var remoteChanges = <String, Model>{};

    var localUpdates = localItems;
    var remoteUpdates = <String, Model>{};

    bool mergeConflict = false;

    // Флаг, который указывает на то, что мы подозреваем, что в УХ появились новые данные.
    // В первый раз надеемся на то, что данные в ЛХ актуальны
    bool isRemoteRegistriesActual = true;

    // Будем пробовать создавать транзакции много раз, пока не отправим их удачно,
    // или пока не обнаружим отсутствие прав на запись (пока индексы транзакций меняются при перечитывании).
    do {
      if (isRemoteRegistriesActual == false) {
        latestRemoteRegistries = await _remoteStorages.values.first.readRegistries(ids: localRegistries.keys.toList());
        if (_isIndexesEqual(remoteRegistries, latestRemoteRegistries)) {
          // Индексы не изменились, значит нет прав на запись
          _rollbackLastTransaction(oldItems, localRegistries);
          _accessDeniedCallback(localchanges);
          return 0; // Ошибка доступа
        }
        remoteRegistries = await _getRemoteRegistries(localRegistries, remoteRegistries, latestRemoteRegistries);
        remoteChanges = await _getRemoteChanges(remoteRegistries);
        isRemoteRegistriesActual = true;
        (localUpdates, remoteUpdates, mergeConflict) = _rebaseTransaction(localchanges, remoteChanges, oldItems.cast<String, Model>());
        if (mergeConflict) {
          _rollbackLastTransaction(oldItems, localRegistries);
          _informListenersMergeConflict(localUpdates, remoteUpdates);
          return 0; // Конфликт слияния
        }
      } else {
        remoteUpdates = localUpdates;
      }
      remoteRegistries = _buildTransactions(remoteRegistries, remoteUpdates);
      try {
        if (remoteUpdates.isNotEmpty) await _saveToAllRemoteStorages(remoteUpdates, remoteRegistries.map((k, v) => MapEntry(k, v.onlyLastTransaction())));
        // Залилось
        localRegistries = remoteRegistries;
        if (localUpdates.isNotEmpty) _localStorage.storeItems({...localUpdates, ...localRegistries});
        _localStorage.clearHistoryQueueHead();
      } on RemoteStorageWriteCollision catch (e) {
        // Не залилось
        isRemoteRegistriesActual = false;
        remoteRegistries.forEach((id, registry) => registry.removeLastTransaction());
        localUpdates = <String, Model>{};
      }

    } while (!_isIndexesEqual(localRegistries, remoteRegistries) || isRemoteRegistriesActual == false);

    return localItems.length;
  }

  Map<Model, Map<String, dynamic>> _clusterItemsByParent(Map<String, dynamic> items) {
    Map<Model, Map<String, dynamic>> paretnItems = {};
    for (var entry in items.entries) {
      final parent = _getParent(entry.value);
      if (parent != null) {
        paretnItems.putIfAbsent(parent, () => <String, dynamic>{})[entry.key] = entry.value;
      } else {
        print('No domain found for ${entry.value.runtimeType} ${entry.key}'); // todo: handle users
      }
    }
    return paretnItems;
  }

  (Map<Model, Map<String, dynamic>>, Map<String, Registry>) _generateTransactions(Map<Model, Map<String, dynamic>> parentItems) {
    // Реестр, скорее всего, итак уже есть, кроме случаев, когда мы создали нового пользователя, или залогинились в первый раз
    // на новом устройстрве.
    // В таком случае, создаем новую транзакцию поверх последней валидной.
    // Если же реестр не существует, то создаем его, и создаем первую транзакцию.
    // Либо пытаемся получить существующий реестр и последнюю транзакцию из удаленного или распределенного репозитория,
    // и поверх неё создать новую транзакцию.
    // Итого 3 случая:
    // 1. Новый пользователь, новый домен - создаем всё с нуля
    // 2. Новый логин старого пользователя - нужно подтянуть существующие реестры из у/р репозитория,
    //    поверх них создать новую транзакцию
    // 3. Все уже есть - пытаемся создать транзакцию поверх локальной головы,
    //    при ошибке записи в у/р репозиторий читаем у/р состояние и ребейзим свои изменения на новую голову.
    //    Локально изменения сохраняем сразу. При ребейзе переписываем локальные данные.
    // В случае ребейза нужно послать собитые на перерисовку в bloc.
    var registries = <String, Registry>{};
    for (var parentEntry in parentItems.entries) {
      final parent = parentEntry.key;
      final children = parentEntry.value;
      var registry =
         // Реестр уже существует, сценарий 3
        _localStorage.getRegistry(parentId: parent.id, count: 1)
        // Реестра еще нет, 
        // Нет, тут, кажется, ситуация посложнее. Наверное, при логине старого пользователя нужно подтянуть все домены и реестры.
        // Назовем такую ситуацию - "получить контекст пользователя" (get_user_context()).
        // И тогда они не будут пустыми. Можно поверх них писать транзакции.
        // Тогда ситуация отсутствия реестра будет только в том случае, если пользователь или домен только что создан.
        // Создаем новый реестр с нулевой транзакцией.
        ?? Registry(parentId: parent.id);
      registry.addNewTransaction(
        Transaction.next(
          registry.lastTransaction, 
          me.id,
          '\$session - \$app - \$device',
          'creation',
          children.keys.toList(),
          'path'
        )
      );
      // Линкуем реестр к контейнеру и сохраняем в локальное хранилище
      if (parent is Domain) parent.registryId = registry.id!;
      if (parent is User) parent.registryId = registry.id!;
      _localStorage.storeItems({registry.id!: registry, parent.id: parent});
      // Добавляем реестр к остальным объектам, которые будут сохранены в у/р хранилище
      parentEntry.value[registry.id!] = registry;
      registries[registry.id!] = registry;
    }
    return (parentItems, registries);
  }

  // Map<String, Model> _getUpdatesByRegistries(
  //   Map<String, Registry> localRegistries,
  //   Map<String, Registry> remoteRegistries
  // ) {
  //   // Тут берем все локальные реестры, смотрим какие у них последние транзакции, потом читаем удаленные реестры,
  //   // смотрим их последние транзакции, сравниваем индексы, дочитываем недостающие, если они есть,
  //   // и считываем все недостающие локально транзакции.
  //   // После этого по спискам изменений в транзакциях читаем все новые состояния элементов, возвращаем их.
  //     // Тут проблемка с тем, сколько последних транзакций надо читать.
  //     // List<String> idsToGetUpdates = remoteRegistries.values.expand((reg) => reg.lastTransaction.changes).toList();
  //   return <String, Model>{};
  // }

  // Пробуем смешать данные, если не получили неразрешимой коллизии, то возвращаем изменения, предназначенные для
  // сохранения в ЛХ и УХ.
  // Если получается коллизия, то кидаем исключение.
  // Основные правила ребейза:
  // 1. Если объект новый, то просто сохраняем его в ЛХ и УХ.
  // 2. Если объект изменен (есть и в ЛХ и в УХ), то сравниваем по полям объекта.
  // 3. Чтобы понять, какие поля мы изменили, сравниваем каждое поле с таким же объектом из oldItems.
  // 4. Если поле не менялось, то берем новое значение из объекта из remoteItems.
  // 5. Если поле изменилось, смотрим, изменилось ли оно в УХ, если нет, то берем новое значение из объекта из localItems,
  //    если да, то мы обнаружили конфликт, накапливаем их и кидаем исключение.
  // 6. Для списков также смотрим старое значение, если мы не трогали список, то берем его из remoteItems.
  // 7. Если мы трогали список, то сравниваем его со списком из remoteItems. Если список изменился, 
  //    сравниваем элементы списка. Если он только расширился, то спокойно мержим список.
  //    todo: если мы изменили элемент, как понять, с каким элементом из remoteItems его нужно сравниваеть?
  // 8. Для словарей проверяем по ключам на предмет расширения, мержим расширения.
  // 9. Если значения по одинаковым ключам изменились, рекурсивно ребейзим то, что внутри значения то вышеописанным правилам.
  (Map<String, Model>, Map<String, Model>, bool) _rebaseTransaction(
    Map<String, Model> localItems,
    Map<String, Model> remoteItems,
    Map<String, Model> oldItems
  ) {
    var localModels = <String, Model>{};
    var remoteModels = <String, Model>{};
    var conflicts = <String>{};
    var insolubleConflicts = <String>[];
    for (final modelId in localItems.keys) {
      if (remoteItems.containsKey(modelId)) {
        conflicts.add(modelId);
      } else{
        remoteModels[modelId] = localItems[modelId]!;
      }
    }
    for (final modelId in remoteItems.keys) {
      if (localItems.containsKey(modelId)) {
        conflicts.add(modelId);
      } else {
        localModels[modelId] = remoteItems[modelId]!;
      }
    }
    for (final modelId in conflicts) {
      final localModel = localItems[modelId]!;
      final remoteModel = remoteItems[modelId]!;  
      final oldModel = oldItems[modelId];
      if (localModel != remoteModel) {
        final rebasedModel = _rebaseModel(localModel, remoteModel, oldModel);
        if (rebasedModel == null) {
          insolubleConflicts.add(modelId);
          continue;
        }
        localModels[modelId] = rebasedModel;
        remoteModels[modelId] = rebasedModel;
      } else {
        localModels[modelId] = localModel;
        remoteModels[modelId] = remoteModel;
      }
    }
    if (insolubleConflicts.isEmpty) {
      return (localModels, remoteModels, false);
    } else {
      return (
        Map.fromEntries(localItems.entries.where((e) => insolubleConflicts.contains(e.key))),
        Map.fromEntries(remoteItems.entries.where((e) => insolubleConflicts.contains(e.key))),
        true
      );
    }
  }

  Model? _rebaseModel(Model localModel, Model remoteModel, Model? oldModel) {
    if (localModel == remoteModel) return localModel;
    final oldMap = oldModel?.toJson() ?? {};
    final localMap = localModel.toJson();
    var remoteMap = remoteModel.toJson();
    final fields = <String>{...localMap.keys, ...remoteMap.keys};
    for (final field in fields) {
      if (oldMap.containsKey(field) && oldMap[field] == localMap[field]) {
        // поле не изменилось
        continue;
      }
      if (remoteMap.containsKey(field)) {
        if (localMap.containsKey(field)) {
          // поле изменилось в обоих местах
          if (remoteMap[field] != localMap[field]) {
            // нужно решить конфликт
            if (remoteMap[field] is Map) {
              remoteMap[field] = _rebaseMap(remoteMap[field], localMap[field]);
            } else if (remoteMap[field] is List) {
              remoteMap[field] = {...remoteMap[field], ...(localMap[field] as List)}.toList();
            } else {
              // в остальных случаях нужно спросить пользователя
              // todo: пока берем удаленную версию, локальные изменения теряем
              return null;
            }
          }
        } 
      } else {
        remoteMap[field] = localMap[field];
      }
    }
    return _remoteStorages.values.first.models[remoteModel.type]!(remoteMap);
  }

  Map<String, dynamic>? _rebaseMap(Map<String, dynamic> remoteMap, Map<String, dynamic> localMap) {
    final keys = <String>{...remoteMap.keys, ...localMap.keys};
    for (final key in keys) {
      if (remoteMap.containsKey(key) && localMap.containsKey(key)) {
        if (remoteMap[key] is Map && localMap[key] is Map) {
          final rebasedMap = _rebaseMap(remoteMap[key], localMap[key]);
          if (rebasedMap == null) return null;
          remoteMap[key] = rebasedMap;
        } else if ( remoteMap[key] is List && localMap[key] is List) {
          remoteMap[key] = {...remoteMap[key], ...(localMap[key] as List)}.toList();
        } else {
          if (remoteMap[key] != localMap[key]) {
            // нужно решить конфликт
            // todo: пока берем удаленную версию, локальные изменения теряем
            return null;
          }
        }
      } else if (localMap.containsKey(key)) {
        remoteMap[key] = localMap[key];
      }
    }
    return remoteMap;
  }

  void _rollbackLastTransaction(Map<String, dynamic> oldItems, Map<String, Registry> registries) {
    // Что такое последняя транзакция?
    // Работа репозитория устроена так, что поступающие изменения сразу сохраняются в локальное хранилище.
    // При этом репозиторий накапливает эти изменения за некоторый период времени, зависящий от действий пользователя,
    // группирует эти изменения в пачки, после чего пытается выгрузить их в удаленный репозиторий в виде транзакции.
    // Эта транзакция может оказаться неудачной, и подлежащей пересборке. В таком случае, нужно будет откатить всю эту пачку.
    // Соответственно, откат транзакции означает - откат пачки изменений, накопленной между синхронизациями.
    // Соответственно, в локальном репозитории история изменений также должна храниться в виде транзакций,
    // разделенных событиями синхронизации.
    // При этом, в репозитории есть также методы, выполняющие синхронизацию мгновенно.
    // Получается, что в локальном репозитории накапливается цепочка/очередь из транзакций.
    // Откатывать мы хотим её голову. Новые транзакции поступают в хвост.
    _localStorage.storeItems(oldItems);
    registries.values.forEach((e) => e.removeLastTransaction());
  }

  Map<String, Registry> _getRegistries(List<Model> items) {
    var registries = <String, Registry>{};
    for (final item in items) {
      final registry =
         // Реестр уже существует, сценарий 3
        _localStorage.getRegistry(parentId: item.id, count: 1)
        // Реестра еще нет, 
        // Нет, тут, кажется, ситуация посложнее. Наверное, при логине старого пользователя нужно подтянуть все домены и реестры.
        // Назовем такую ситуацию - "получить контекст пользователя" (get_user_context()).
        // И тогда они не будут пустыми. Можно поверх них писать транзакции.
        // Тогда ситуация отсутствия реестра будет только в том случае, если пользователь или домен только что создан.
        // Создаем новый реестр с нулевой транзакцией.
        ?? Registry(parentId: item.id);
      // Линкуем реестр к контейнеру и сохраняем в локальное хранилище
      if (item is Domain) item.registryId = registry.id!;
      if (item is User) item.registryId = registry.id!;
      registries[registry.id!] = registry;
    }
    return registries;
  }

  bool _isIndexesEqual(Map<String, Registry> a, Map<String, Registry> b) {
    if (a.length != b.length) return false;
    if (!a.keys.every((key) => b.keys.contains(key))) return false;
    for (final id in a.keys) {
      if (a[id]?.lastTransactionIndex != b[id]?.lastTransactionIndex) return false;
    }
    return true;
  }

  // Уведомляем пользователя, что по неизвестной причине ему недоступна операция модификации объектов
  // Оповещаем только тех слушателей, которые подписаны на конкретные ID из [items]
  void _accessDeniedCallback(Map<String, dynamic> items) {
    var itemsByListener = <int, Map<String, dynamic>>{};
    var involvedListenerIds = <int>{};
    for (final id in items.keys) {
      final listeners = incomingSyncIds[id];
      if (listeners == null) continue;
      involvedListenerIds.addAll(listeners);
      for (final listenerId in listeners) {
        itemsByListener[listenerId] ??= {};
        itemsByListener[listenerId]?[id] = items[id];
      }
    }
    for (final listenerId in involvedListenerIds) {
      accessDeniedListeners[listenerId]?.call(itemsByListener[listenerId] ?? {});
    }
  }

  void _informListenersMergeConflict(
    Map<String, Model> localItems,
    Map<String, Model> remoteItems,
  ) {
    // Нужно отправить всем слушателям все прослушиваемые конфликтующие модели, на которые они подписаны
    var localModelsByListeners = <int, Map<String, Model>>{};
    var remoteModelsByListeners = <int, Map<String, Model>>{};
    var involvedListenerIds = <int>{};
    for (final modelId in incomingSyncIds.keys) {
      final listeners = incomingSyncIds[modelId];
      if (listeners == null) continue;
      involvedListenerIds.addAll(listeners);
      for (final listenerId in listeners) {
        localModelsByListeners[listenerId] ??= {};
        remoteModelsByListeners[listenerId] ??= {};
        localModelsByListeners[listenerId]?[modelId] = localItems[modelId]!;
        remoteModelsByListeners[listenerId]?[modelId] = remoteItems[modelId]!;
      }
    }
    for (final listenerId in involvedListenerIds) {
      mergeConflictListeners[listenerId]?.call(localModelsByListeners[listenerId] ?? {}, remoteModelsByListeners[listenerId] ?? {});
    }
  }

  // Вычисляем и читаем опережающие цепочки транзакций по всем реестрам
  // Базовые индексы берем из [localRegistries], известные индексы вычисляем из объединения
  // [remoteRegistries] и [knownFragment]. Причем, так как мы не знаем, появились ли новые транзакции в УХ,
  // то считываем немного больше, и контролируем, попали ли базовые индексы цепочки с новыми индексами.
  // Если нет, то дочитываем еще. Если да, то склеиваем все цепочки и возвращаем все реестры.
  Future<Map<String, Registry>> _getRemoteRegistries(
    Map<String, Registry> localRegistries,
    Map<String, Registry> remoteRegistries,
    Map<String, Registry> knownFragment
  ) async {
    List<(String, int)> registriesIdsToRead = [];
    for (final localRegistry in localRegistries.values) {
      final lastLocalIndex = localRegistry.lastTransactionIndex ?? -1;
      final lastRemoteIndex = remoteRegistries[localRegistry.id]?.lastTransactionIndex ?? -1;
      final firstRemoteIndex = knownFragment[localRegistry.id]?.transactions.keys.reduce(min) ?? -1;
      final lastFragmentIndex = knownFragment[localRegistry.id]?.lastTransactionIndex ?? -1;
      final firstFragmentIndex = knownFragment[localRegistry.id]?.transactions.keys.reduce(min) ?? -1;
      // Просто проверяем, является ли [knownFragment] бесшовным продолжением [remoteRegistries]
      // Если нет, то отбрасываем его, поскольку все равно перечитывать надо будет всё
      int latestRemoteIndex = lastLocalIndex;
      if (latestRemoteIndex >= firstRemoteIndex - 1) latestRemoteIndex = lastRemoteIndex;
      if (latestRemoteIndex >= firstFragmentIndex - 1) latestRemoteIndex = lastFragmentIndex;
      // Читать будем чуть больше, чтобы транзакции точно склеились
      final count = latestRemoteIndex - lastLocalIndex + 2;
      registriesIdsToRead.add((localRegistry.id!, count));
    }
    return await _remoteStorages.values.first.readRegistries(idsCounts: registriesIdsToRead);
  }

  // Читаем из удаленного репозитория все изменения, перечисленные в [registries]
  Future<Map<String, Model>> _getRemoteChanges(Map<String, Registry> registries) async {
    Set<String> allModels = {};
    for (final registry in registries.values) {
      registry.transactions.values.forEach((transaction) => allModels.addAll(transaction.changes));
    }
    return await _remoteStorages.values.first.getItems(allModels.toList());
  }

  // Создаем новые транзакции для каждого реестра в [registries].
  // Тут есть вопрос - как понять, какие из этих изменений к каким реестрам относятся?
  // Заново производить поиск (пока да)?
  // [registries] - свежайшие реестры, на основе которых мы будем делать новые транзакции.
  // [items] - собственно изменения, которые должны войти в транзакции. Однако, тут есть некооторые сложности.
  // А именно, не факт, что для каждого изменения найдется реестр. Не факт, что [registries] не пусты.
  // Получается, что нам все-таки нужно сравнивать с локальными/старыми реестрами.
  Map<String, Registry> _buildTransactions(Map<String, Registry> registries, Map<String, Model> items) {
    Map<Model, Map<String, dynamic>> parentItems = _clusterItemsByParent(items);
    for (final pItemEntry in parentItems.entries) {
      final pItem = pItemEntry.key;
      final pItemItems = pItemEntry.value;
      var oldRegistry = _localStorage.getRegistry(parentId: pItem.id);
      Registry? recentRegistry;
      if (pItem is User) recentRegistry = registries[pItem.registryId];
      if (pItem is Domain) recentRegistry = registries[pItem.registryId];
      // todo: кажется, забыли про случай, когда нового реестра нет локально (но мы почему-то вносим в него изменения, странно ...)
      final lastOldIndex = oldRegistry?.lastTransactionIndex ?? -1;
      final lastRecentIndex = recentRegistry?.lastTransactionIndex ?? -1;
      Map<int, Transaction> actualTransactionChain = {};
      if (recentRegistry != null) {
        if (lastRecentIndex < lastOldIndex) {
          // добавляем в recentRegistry цепочку старых транзакций из oldRegistry
          oldRegistry = _localStorage.getRegistry(id: pItem.id, count: lastOldIndex - lastRecentIndex);
          actualTransactionChain = oldRegistry?.transactions ?? {};
        }
      } else if (oldRegistry != null) {
        // старый реестр наиболее актуален
        recentRegistry = oldRegistry.copyWith();
      } else {
        // создаем новый реестр
        recentRegistry = Registry(parentId: pItem.id);
        if (pItem is User) pItem.registryId = recentRegistry.id!;
        if (pItem is Domain) pItem.registryId = recentRegistry.id!;
      }
      recentRegistry.transactions.addAll(actualTransactionChain);
      recentRegistry.addNewTransaction(
        Transaction.next(
          recentRegistry.lastTransaction, 
          me.id,
          '\$session - \$app - \$device',
          'creation',
          pItemItems.keys.toList(),
          'path'
        )
      );
      registries[recentRegistry.id!] = recentRegistry;
    }
    return registries;
  }
}