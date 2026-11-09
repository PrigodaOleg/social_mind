import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:hashlib/hashlib.dart';

import '../models/models.dart';
import '../navigation/navigation_stack.dart';
import 'registry.dart';


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
  
  _remoteStorages = remoteStorages ?? <String, RemoteStorage>{}
  ;

  bool late = true;

  late Timer _sync;

  // Отложить синхронизацию (безопасно до вызова init - например, в тестах)
  void postponeSync() {
    if (late) return;
    _sync.postpone();
  }

  // Номер дефолтного sync-слушателя. Дефолтные слушатели регистрируются при
  // первом обращении (см. [addSyncListener]) и складывают приехавшие модели
  // в локальное хранилище; конфликты и отказы в доступе логируются.
  late final int defaultSyncSubscriber = addSyncListener(
    _defaultSyncListener,
    _defaultMergeConflictListener,
    _defaultAccessDeniedListener,
  );

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

  final knownRemoteStorages = <String, Function()>{
    'FirebaseRealtimeDatabase': () => FirebaseStorage(),
    'CloudFirestore': () => CloudFirestoreStorage(),
    'Supabase': () => SupabaseStorage(),
  };

  // # Исходящая очередь: свои изменения, ожидающие отправки в удаленные хранилища.
  // Заполняется через saveModel(s)/deleteModel.
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

  Future<void> init() async {
    await _localStorage.init();
    if (myId != null) {
      await initRemoteStorages();
      await authRemoteStorages();
    }
    _sync = Timer(_delayedSync);
    _sync.start();
    instance = this;
    late = false;
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

  // Мьютекс синхронизации: исключает параллельный запуск _delayedSync из
  // debounce-таймера и из immediate-вызовов saveModel/saveModels.
  bool _syncInProgress = false;
  Future<void> _syncMutex() async {
    while (_syncInProgress) {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    _syncInProgress = true;
  }

  Future<void> _delayedSync() async {
    await _syncMutex();
    try {
      await _doDelayedSync();
    } finally {
      _syncInProgress = false;
    }
  }

  Future<void> _doDelayedSync() async {
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

    // Отправляем локальные изменения в удаленное хранилище (реестровый
    // конвейер: транзакции, ребейз, коллизии записи - в RegistryManager).
    // Автор транзакций передается параметром: слой реестров myId не знает.
    int saved = await registryManager.syncWithRemoteStorage(
      Map.fromEntries(outgoingChanges.map((item) => MapEntry(item.id, item))),
      originatorId: _syncOriginatorId,
    );
    // Вызываем для каждого синхронизированного элемента событие для слушателя
    while (outgoingChanges.isNotEmpty) {
      String id = outgoingChanges.first.id;
      _findAndCallListeners(id);
      outgoingChanges.removeFirst();
    }

    // Актуализируем элементы, на синхронизацию которых поступил запрос от слушателей
    var idsToSync = incomingSyncIds.keys.toSet().difference(syncedThisTime).toList();
    var syncedModels = await _getFromAllRemoteStorages(idsToSync);
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
      final remoteItems = await _getFromAllRemoteStorages([id]);
      Model? model = remoteItems[id]; // тут плохо сделано, на каждый элемент вызывается чтение с сервера. Запросы на чтение нужно накапливать за определенный промежуток времени, а потом батчевать.
      model?.sync = SyncStatus.synced;
      syncedThisTime.add(id); // todo: тут ошибка - если в удаленном репозитории такой модели нет, то ее надо либо туда загрузить, либо удалить тут, тихо промолчать нельзя
      // print(model);
      if (model != null) syncListeners[subscriberId]?.call(id, model);
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

  // Идентификатор автора транзакций для реестрового слоя: слой реестров не
  // знает локального пользователя и получает originatorId параметром.
  String? get _syncOriginatorId {
    if (myId == null) return null;
    return me.id;
  }

  // # Слой реестров: работа с реестрами (подписки на изменения реестров,
  // маршрутизация чтения реестров, диффинг входящих транзакций, построение
  // транзакций, ребейз, коллизии записи) инкапсулирована в [RegistryManager].
  // Транспорт (debounce-таймер, очереди исходящих изменений, маршрутизация
  // моделей по хранилищам, sync-слушатели) остается здесь и внедряется в слой
  // реестров колбэками; бизнес-слой получает только абстрактные события
  // [ModelsChangedEvent] - без registryId, Transaction и changeType.
  late final RegistryManager registryManager = RegistryManager(
    localStorage: _localStorage,
    remoteStorages: _remoteStorages,
    fetchModels: _fetchModelsForRegistry,
    clusterByParent: _clusterItemsByParent,
    saveToRemote: _saveToAllRemoteStorages,
    onIncomingModelsStored: _onIncomingModelsStored,
    onModelsChanged: _onModelsChanged,
    onAccessDenied: _accessDeniedCallback,
    onMergeConflict: _informListenersMergeConflict,
  );

  // Дочитываем изменившиеся модели по ID с маршрутизацией по хранилищам
  // (транспорт для входящего конвейера слоя реестров).
  Future<Map<String, Model>> _fetchModelsForRegistry(List<String> ids) async {
    final items = await _getFromAllRemoteStorages(ids);
    return items.cast<String, Model>();
  }

  // После сохранения приехавших моделей: помечаем их синхронизированными в этой
  // сессии и уведомляем sync-слушателей, подписанных на конкретные ID.
  void _onIncomingModelsStored(List<String> modelIds, Map<String, Model> models) {
    for (final id in modelIds) {
      incomingSyncIds[id]?.forEach((subscriberId) {
        final model = models[id];
        if (model != null) {
          model.sync = SyncStatus.synced;
          syncListeners[subscriberId]?.call(id, model);
        }
      });
    }
    syncedThisTime.addAll(modelIds);
  }

  // # Бизнес-события "изменились модели" (для подписчиков; интерпретация в бизнес-слое).
  final modelsChangedListeners = <int, ModelsChangedListener>{};
  int _modelsChangedListenersCounter = 0;

  int addModelsChangedListener(ModelsChangedListener listener) {
    modelsChangedListeners[_modelsChangedListenersCounter] = listener;
    return _modelsChangedListenersCounter++;
  }

  void removeModelsChangedListener(int id) {
    modelsChangedListeners.remove(id);
  }

  // Диспетчер бизнес-событий из слоя реестров. Собственные изменения (эхо
  // своей транзакции) событий не порождают: автор события сравнивается с
  // локальным пользователем.
  void _onModelsChanged(ModelsChangedEvent event) {
    if (event.actorId == myId) return;
    for (final listener in modelsChangedListeners.values.toList()) {
      listener(event);
    }
  }

  // # Реалтайм: подписки на изменения реестров - делегируются слою реестров.
  Future<void> watchRegistries(Set<String> registryIds) => registryManager.watchRegistries(registryIds);

  Future<void> stopWatchingRegistries() => registryManager.stopWatchingRegistries();

  /// Обработка события изменения реестра (входящий конвейер слоя реестров).
  Future<void> onRemoteRegistryChange(String registryId) => registryManager.onRemoteRegistryChange(registryId);

  /// Обновление реестров всех доменов пользователя + личного реестра (мультиустройство).
  /// Вызывается после логина и при появлении новых доменов.
  Future<void> updateRegistryWatches() async {
    if (myId == null || _remoteStorages.isEmpty) return;
    final userRegistries = <String, String>{};
    try {
      final meUser = me;
      if (meUser.registryId.isNotEmpty) {
        userRegistries[meUser.registryId] = meUser.storageKey;
      }
      for (final domainId in meUser.domainsIds) {
        final domain = _localStorage.getItem(id: domainId);
        if (domain is Domain && domain.registryId.isNotEmpty) {
          userRegistries[domain.registryId] = domain.storageKey;
        }
      }
    } catch (_) {
      // me еще не инициализирован
      return;
    }
    await registryManager.updateWatches(userRegistries);
  }

  // Консистентная запись изменений через реестры. Построение транзакций,
  // ребейз и коллизии записи - в RegistryManager; транспорт (маршрутизация
  // записи/чтения моделей) остается здесь и внедряется туда колбэками.
  // Автор транзакций передается параметром.
  @visibleForTesting
  Future<int> syncWithRemoteStorage(Map<String, Model> localItems) =>
      registryManager.syncWithRemoteStorage(localItems, originatorId: _syncOriginatorId);

  // Подключенные удаленные хранилища (только для чтения извне; запись через
  // addConnectedStorage - при подключении хранилища на лету).
  Map<String, RemoteStorage> get connectedStorages => _remoteStorages;

  // Доступ к локальному хранилищу для настройки-сервисов (правила уведомлений
  // и другие локальные настройки). Общий контракт Repository остается прежним.
  LocalStorage get localStorage => _localStorage;

  // Регистрация уже подключенного хранилища (например, при принятии приглашения
  // в домен, когда хранилище подключается на лету).
  void addConnectedStorage(String storageKey, RemoteStorage storage) {
    _remoteStorages[storageKey] = storage;
  }

  Future<void> initRemoteStorages() async {
    for (var storage in me.settings.getDeep('remote_storages', defaultValue: {}).entries) {
      _remoteStorages[storage.key] = knownRemoteStorages[storage.key]?.call();
    }
    for (var storage in _remoteStorages.entries) {
      var instanceFieldName = 'remote_storages.${storage.key}.instance';
      String? instance = me.settings.getDeep(instanceFieldName);
      if (instance != null) {
        final anonKey = me.settings.getDeep('remote_storages.${storage.key}.anon_key');
        await storage.value.init(instance, anonKey: anonKey);  // todo: wrap in try-catch and show error message to user
      } else {
        print('No parameter $instanceFieldName is specified for ${storage.key}');
      }
    }
  }

  Future<void> authRemoteStorages() async {
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

  Future<bool> tryLogin(String userId, String secret) async {
    bool success = true;
    final dummyUser = User(name: ''); // todo: некрасиво, настройки по-умолчанию должны где-то храниться и быть доступны для ввода до попытки логина
    for (var storage in dummyUser.settings.getDeep('remote_storages', defaultValue: {}).entries) {
      _remoteStorages[storage.key] = knownRemoteStorages[storage.key]?.call();
    }
    for (var storage in _remoteStorages.entries) {
      var instanceFieldName = 'remote_storages.${storage.key}.instance';
      String? instance = dummyUser.settings.getDeep(instanceFieldName);
      if (instance != null) {
        if (!await storage.value.init(instance)) success = false;  // todo: wrap in try-catch and show error message to user
        String password = scrypt(utf8.encode(secret), utf8.encode('${storage.key}$instance')).toString();
        if (!await storage.value.auth(userId, password)) success = false;  // todo: wrap in try-catch and show error message to user
      } else {
        success = false;
        print('No parameter $instanceFieldName is specified for ${storage.key}');
      }
    }
    return success;
  }

  // Отправить модель на синхронизацию после сохранения (транспорт).
  void _syncModel(Model model) {
    subscribeToSync(model.id, defaultSyncSubscriber);
    postponeSync();
  }

  Future<void> saveModel(
    Model model,
    [int? subscriberId, // Item ID - sync callback pair
    bool immediate = false] // немедленная отправка (без дебаунса) - для важных изменений
  ) async  {
    await _localStorage.storeItem(model);
    subscribeToSync(model.id, subscriberId);
    outgoingChanges.addLast(model);
    if (immediate) {
      await _delayedSync();
    } else {
      postponeSync();
    }
  }

  T? getModel<T>(
    String modelId,
    [int? subscriberId] // Item ID - sync callback pair
  ) {
    T? model = _localStorage.getItem(id: modelId);
    subscribeToSync(modelId, subscriberId);
    postponeSync();
    return model;
  }

  Future<T?> getModelNow<T>(String modelId) async {
    T? model = _localStorage.getItem(id: modelId);
    model = model ?? await _remoteStorages.values.first.getItem(id: modelId);
    return model;
  }

  Map<String, T> getModels<T>(
    List<String> ids,
    [int? subscriberId]
  ) {
    Map<String, T> models = _localStorage.getItems(ids);
    subscribeToSyncAll(ids, subscriberId);
    _markSyncedAll(models);
    postponeSync();
    return models;
  }

  Future<void> saveModels(
    List<Model> models,
    [int? subscriberId, // Item ID - sync callback pair
    bool immediate = false]
  ) async {
    var modelsMap = { for (var model in models) model.id : model };
    await _localStorage.storeItems(modelsMap);
    subscribeToSyncAll(modelsMap.keys.toList(), subscriberId);
    outgoingChanges.addAll(models);
    if (immediate) {
      await _delayedSync();
    } else {
      postponeSync();
    }
  }

  void deleteModel(
    Model model,
    [int? subscriberId] // Item ID - sync callback pair
  ) {
    outgoingDeletes.addLast(model);
    postponeSync();
  }

 Future<void> saveImage(String name, Uint8List imageBytes) async {
    await _localStorage.storeImage(name, imageBytes);
  }

Uint8List? getImage(String name) {
  return _localStorage.getImage(name);
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

  Future<Model> asyncSetMe(Model me) async {
    await _localStorage.storeItem(me);
    myId = me.id;
    await initRemoteStorages();
    await authRemoteStorages();
    return me;
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

  // # Транспорт: маршрутизация моделей по подключенным удаленным хранилищам.

  // Читаем модели из тех удаленных хранилищ, к которым они относятся
  // (маршрутизация по storageKey родителя модели).
  Future<Map<String, dynamic>> _getFromAllRemoteStorages(List ids) async {
    Map<String, dynamic> items = {};
    // Группируем ID по хранилищам и читаем батчами
    final idsByStorage = <RemoteStorage, List<String>>{};
    for (final id in ids) {
      final localItem = _localStorage.getItem(id: id as String);
      // Модель с известным storageKey читаем из его хранилища, иначе (обратная
      // совместимость) - из первого подключенного.
      final storage = (localItem != null ? _storageForModel(localItem) : null) ?? _remoteStorages.values.firstOrNull;
      if (storage == null) continue;
      idsByStorage.putIfAbsent(storage, () => []).add(id);
    }
    for (var entry in idsByStorage.entries) {
      items.addAll(await entry.key.getItems(entry.value));
    }
    return items;
  }

  // Сохраняем модели в их удаленные хранилища. Каждая пачка кластеризуется
  // по родителю, и каждая пачка пишется ровно в одно хранилище - то, которое
  // указано в поле storageKey родителя.
  Future<int> _saveToAllRemoteStorages(Map<String, Model> items, Map<String, Registry> registries) async {
    int count = 0;
    Map<Model, Map<String, dynamic>> parentItems = _clusterItemsByParent(items);
    for (var parentEntry in parentItems.entries) {
      final parent = parentEntry.key;
      var storage = _storageForModel(parent);
      // Обратная совместимость: модели без storageKey (старые данные и тесты)
      // пишутся в первое подключенное хранилище.
      storage ??= _remoteStorages.values.firstOrNull;
      if (storage == null) {
        print('No remote storage configured for ${parent.runtimeType} ${parent.id}'); // todo: показывать ошибку пользователю
        continue;
      }
      count += await storage.saveItems({...parentEntry.value, ...registries});
    }
    // Реестры, чей родитель не среди items (например, личный реестр пользователя),
    // пишем в хранилище пользователя.
    final orphanRegistries = <String, Registry>{};
    for (var registryEntry in registries.entries) {
      if (items.containsKey(registryEntry.value.parentId)) continue;
      final parentModel = _localStorage.getItem(id: registryEntry.value.parentId ?? '');
      if (parentModel != null && items.containsKey(parentModel.id)) continue;
      orphanRegistries[registryEntry.key] = registryEntry.value;
    }
    if (orphanRegistries.isNotEmpty) {
      final storage = (_storageByKey(me.storageKey) ?? _remoteStorages.values.firstOrNull);
      if (storage != null) {
        count += await storage.saveItems(orphanRegistries);
      }
    }
    return count;
  }

  // Удаляем модели из их удаленных хранилищ.
  Future<int> _deleteFromAllRemoteStorages(Map<String, dynamic> items) async {
    int count = 0;
    Map<Model, Map<String, dynamic>> parentItems = _clusterItemsByParent(items.cast<String, Model>());
    for (var parentEntry in parentItems.entries) {
      final storage = _storageForModel(parentEntry.key) ?? _remoteStorages.values.firstOrNull;
      if (storage == null) continue;
      count += await storage.deleteItems(parentEntry.value);
    }
    return count;
  }

  // Получаем удаленное хранилище по ключу (storageKey родителя модели или
  // реестра). Если ключ пуст или хранилище не подключено, возвращаем null.
  RemoteStorage? _storageByKey(String? storageKey) {
    if (storageKey == null || storageKey.isEmpty) return null;
    final storage = _remoteStorages[storageKey];
    return storage;
  }

  // Определяем удаленное хранилище для модели по ее родителю (домену или пользователю).
  // Модель существует ровно в одном удаленном хранилище - том, которое указано в
  // поле storageKey родителя.
  RemoteStorage? _storageForModel(Model model) {
    if (model is Domain) return _storageByKey(model.storageKey);
    if (model is User) return _storageByKey(model.storageKey);
    final parent = _getParent(model);
    if (parent == null) return null;
    return _storageForModel(parent);
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

  // Кластеризуем модели по родителю (домену/пользователю): модельная иерархия
  // нужна и транспорту (маршрутизация записи/удаления), и слою реестров
  // (ассоциация изменений с реестрами - внедряется туда колбэком).
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
}
