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

  // Номер дефолтного sync-слушателя. Дефолтные слушатели живут в слое
  // реестров и регистрируются в конструкторе [RegistryManager].
  int get defaultSyncSubscriber => registryManager.defaultSyncSubscriber;

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

  Future<void> init() async {
    await _localStorage.init();
    if (myId != null) {
      await initRemoteStorages();
      await authRemoteStorages();
    }
    _sync = Timer(_runRegistrySync);
    _sync.start();
    instance = this;
    late = false;
  }

  // Транспортная часть синхронизации: debounce-таймер запускает один цикл
  // реестрового конвейера (runSync в слое реестров).
  Future<void> _runRegistrySync() => registryManager.runSync();

  // # Слой реестров: ВСЯ реестровая логика инкапсулирована в [RegistryManager] -
  // и входящий конвейер (подписки, маршрутизация чтения, диффинг входящих
  // транзакций, дочитывание изменившихся моделей, sync-слушатели), и исходящий
  // (очереди изменений/удалений, построение транзакций, ребейз, коллизии
  // записи). Бизнес-слой получает только абстрактные события
  // [ModelsChangedEvent] - без registryId, Transaction и changeType.
  // Repository остается транспортной оберткой и публичным API.
  late final RegistryManager registryManager = RegistryManager(
    localStorage: _localStorage,
    remoteStorages: _remoteStorages,
    getMyId: () => myId,
  );

  // # Бизнес-события "изменились модели" (для подписчиков; интерпретация в бизнес-слое).
  int addModelsChangedListener(void Function(ModelsChangedEvent event) listener) =>
      registryManager.addModelsChangedListener(listener);

  void removeModelsChangedListener(int id) => registryManager.removeModelsChangedListener(id);

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

  // Консистентная запись изменений через реестры (исходящий конвейер слоя
  // реестров). Синхронизирует локальные изменения с удаленными хранилищами:
  // построение транзакций, ребейз, коллизии записи - в RegistryManager.
  @visibleForTesting
  Future<int> syncWithRemoteStorage(Map<String, Model> localItems) =>
      registryManager.syncWithRemoteStorage(localItems);

  // Очереди исходящих изменений/удалений живут в слое реестров; наружу -
  // только чтение (запись через saveModel(s)/deleteModel).
  Queue<dynamic> get outgoingChanges => registryManager.outgoingChanges;
  Queue<dynamic> get outgoingDeletes => registryManager.outgoingDeletes;

  // Подписки на sync-события живут в слое реестров; наружу - только чтение
  // карты слушателей и публичное API ниже.
  Map<int, SyncListener> get syncListeners => registryManager.syncListeners;

  int addSyncListener(
    SyncListener syncListener,
    MergeConflictListener mergeConflictListener,
    [AccessDeniedListener? accessDeniedListener]
  ) => registryManager.addSyncListener(syncListener, mergeConflictListener, accessDeniedListener);

  void removeSyncListener(int subscriberId) => registryManager.removeSyncListener(subscriberId);

  void subscribeToSync(String modelId, int? subscriberId) =>
      registryManager.subscribeToSync(modelId, subscriberId);

  void subscribeToSyncAll(List<String> modelIds, int? subscriberId) =>
      registryManager.subscribeToSyncAll(modelIds, subscriberId);

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

  // Отправить модель на синхронизацию после сохранения (исходящий конвейер).
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
    registryManager.queueOutgoingSave(model);
    if (immediate) {
      await registryManager.runSync();
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
    registryManager.markSyncedAll(models);
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
    registryManager.queueOutgoingSaveAll(models);
    if (immediate) {
      await registryManager.runSync();
    } else {
      postponeSync();
    }
  }

  void deleteModel(
    Model model,
    [int? subscriberId] // Item ID - sync callback pair
  ) {
    registryManager.queueOutgoingDelete(model);
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
}
