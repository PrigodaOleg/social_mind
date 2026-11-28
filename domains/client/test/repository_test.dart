import 'dart:async' show Completer, unawaited;
import 'dart:io';
import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:closers/repository/repository.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';

class MockLocalStorage extends LocalStorage {
  Map<String, Model> lastModels = {};
  Map<String, Registry> lastRegistries = {};
  Map<String, dynamic> get lastItems => {...lastModels, ...lastRegistries};
  Map<String, Model> oldModels = {};
  int clearHistoryQueueHeadCallCount = 0;


//do we need real testing?
  @override
  Uint8List? getImage(String id) => null;

  @override
  Future<int> storeItems(Map<String, dynamic> items) async {
    for (final item in items.values) {
      if (item is Model) {
        if (lastModels.containsKey(item.id)) {
          oldModels[item.id] = models[item.type]!(lastModels[item.id]!.toJson());
        }
        lastModels[item.id] = item;
      }
      if (item is Registry) {
        if (lastRegistries.containsKey(item.id)) {
          lastRegistries[item.id!]?.transactions.addAll(item.transactions);
        } else {
          lastRegistries[item.id!] = item;
        }
      }
    }
    return items.length;
  }

  @override
  String? getUserId() {
    return 'me';
  }

  @override
  dynamic getItem({required String id}) {
    if (id == 'me') return User(id: 'me', name: 'me');
  }

  @override
  Registry? getRegistry({String? id, String? parentId, int count = 5}) {
    if (id != null) return lastRegistries[id];
    if (parentId != null) return lastRegistries[(lastModels[parentId] as User?)?.registryId];
    return null;
  }

  Map<String, dynamic> getNextItemsFromHistoryQueue() {
    return oldModels..clear();
  }

  @override
  void clearHistoryQueueHead() {
    clearHistoryQueueHeadCallCount++;
  }
}

class MockRemoteStorage extends RemoteStorage {
  Map<String, Model> lastModels = {};
  Map<String, Registry> lastRegistries = {};
  Map<String, dynamic> get lastItems => {...lastModels, ...lastRegistries};
  @override
  Future<int> saveItems(Map<String, dynamic> items, {Map<String, Map<String, Set<String>>> deletions = const {}}) async {
    for (final item in items.values.toList().reversed) {
      if (item is Registry) {
        if ((item.lastTransactionIndex ?? -1) <= (lastRegistries[item.id]?.lastTransactionIndex ?? -1)) {
          throw RemoteStorageWriteCollision('message', -1);
        }
        if (lastRegistries.containsKey(item.id)) {
          lastRegistries[item.id!]?.transactions.addAll(item.transactions);
        } else {
          lastRegistries[item.id!] = item.copyWith();
        }
      }
      if (item is Model) lastModels[item.id] = models[item.type]!(item.toJson()); // ignore: avoid-async-in-sync-methods
    }
    return items.length;
  }

  @override
  Future<Map<String, Registry>> readRegistries({List<String>? ids, List<(String id, int? count)>? idsCounts, int count = 1}) async {
    if (ids != null) return Map.fromEntries(lastRegistries.entries.where((e) => ids.contains(e.key)).map((e) => MapEntry(e.key, e.value.copyWith())));
    if (idsCounts != null) return Map.fromEntries(idsCounts.map((rec) => MapEntry(lastRegistries[rec.$1]!.id!, lastRegistries[rec.$1]!.copyWith())));
    return {};
  }

  @override
  Future<Map<String, Model>> getItems(List ids) async {
    return Map.fromEntries(lastModels.entries.where((e) => ids.contains(e.key)).map((e) => MapEntry(e.key, models[e.value.type]!(e.value.toJson()))));
  }

  void externalChange(Map<String, Model> items) {
    items.forEach((id, item) {
      lastRegistries.values.last.addNewTransaction(
        Transaction.next(
          lastRegistries.values.last.lastTransaction,
          id,
          'changeDetails',
          'changeType',
          [id],
          'path',
        )
      );
      saveItems({id: item});
    });
  }
}

class DenyingRemoteStorage extends MockRemoteStorage {
  bool deny = false;

  @override
  Future<int> saveItems(Map<String, dynamic> items, {Map<String, Map<String, Set<String>>> deletions = const {}}) async {
    if (deny) {
      throw RemoteStorageWriteCollision('access denied', 403);
    }
    return super.saveItems(items);
  }
}

// Records the arguments passed to init/auth/createUserAndAuth so tests can assert on them,
// and lets tests force each call to succeed or fail.
class TrackingRemoteStorage extends RemoteStorage {
  String? initInstance;
  bool initResult = true;
  bool throwOnInit = false;

  String? authLogin;
  String? authPassword;
  bool authResult = true;

  String? createLogin;
  String? createPassword;
  bool throwOnCreate = false;

  // Models served by getItem (simulates data stored in the remote storage).
  final Map<String, Model> remoteModels = {};

  @override
  Future<bool> init(String instance, {String? anonKey}) async {
    if (throwOnInit) {
      throw Exception('init failed');
    }
    initInstance = instance;
    return initResult;
  }

  @override
  Future<dynamic> getItem({required String id}) async => remoteModels[id];

  @override
  Future<bool> auth(String login, String password) async {
    authLogin = login;
    authPassword = password;
    return authResult;
  }

  @override
  Future<bool> createUserAndAuth(String login, String password) async {
    if (throwOnCreate) {
      throw Exception('createUserAndAuth failed');
    }
    createLogin = login;
    createPassword = password;
    return true;
  }
}

// A minimal LocalStorage that lets tests directly set the "logged in" local user (or none at all).
class ConfigurableLocalStorage extends LocalStorage {
  User? meUser;
  bool initCalled = false;

//do we need real testing?
  @override
  Uint8List? getImage(String id) => null;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  String? getUserId() => meUser?.id;

  @override
  dynamic getItem({required String id}) {
    if (meUser != null && id == meUser!.id) return meUser;
    return null;
  }
}

// initRemoteStorages/tryLogin build remote storages from a hardcoded 'FirebaseRealtimeDatabase' key
// via knownRemoteStorages, which normally constructs a real FirebaseStorage. This subclass swaps that
// factory for a TrackingRemoteStorage so tests never touch Firebase.
class TestRepository extends Repository {
  TestRepository({
    super.localStorage,
    super.remoteStorages,
    required this.testStorage,
  });

  final RemoteStorage testStorage;

  @override
  late final knownRemoteStorages = <String, Function()>{
    'FirebaseRealtimeDatabase': () => testStorage,
  };
}

void main() {
  group('Repository init', () {
    test('init initializes local storage', () async {
      final localStorage = ConfigurableLocalStorage();
      final r = TestRepository(localStorage: localStorage, testStorage: TrackingRemoteStorage());
      await r.init();
      expect(localStorage.initCalled, true);
      expect(r.late, false);
    });

    test('init skips remote storage init/auth when no local user is set', () async {
      final localStorage = ConfigurableLocalStorage();
      final tracking = TrackingRemoteStorage();
      final r = TestRepository(localStorage: localStorage, testStorage: tracking);
      await r.init();
      expect(tracking.initInstance, null);
      expect(tracking.authLogin, null);
      expect(r.syncListeners.containsKey(r.defaultSyncSubscriber), true);
    });

    test('init initializes and authenticates remote storages when local user exists', () async {
      final localStorage = ConfigurableLocalStorage();
      final tracking = TrackingRemoteStorage();
      final user = User(id: 'me', name: 'me');
      user.secrets = {'remote_storages': {'FirebaseRealtimeDatabase': {'hashed_password': 'storedpw'}}};
      localStorage.meUser = user;
      final r = TestRepository(localStorage: localStorage, testStorage: tracking);
      await r.init();
      expect(tracking.initInstance, 'closers-cd24f'); // default instance from User.settings
      expect(tracking.authLogin, 'me');
      expect(tracking.authPassword, 'storedpw');
    });
  });

  group('Repository initRemoteStorages', () {
    test('initializes configured remote storage with instance from settings', () async {
      final localStorage = ConfigurableLocalStorage()..meUser = User(id: 'me', name: 'me');
      final tracking = TrackingRemoteStorage();
      final r = TestRepository(localStorage: localStorage, testStorage: tracking);
      await r.initRemoteStorages();
      expect(tracking.initInstance, 'closers-cd24f');
    });

    test('does not call init when instance setting is missing', () async {
      final user = User(id: 'me', name: 'me');
      user.settings = {'remote_storages': {'FirebaseRealtimeDatabase': <String, dynamic>{}}};
      final localStorage = ConfigurableLocalStorage()..meUser = user;
      final tracking = TrackingRemoteStorage();
      final r = TestRepository(localStorage: localStorage, testStorage: tracking);
      await r.initRemoteStorages();
      expect(tracking.initInstance, null);
    });
  });

  group('Repository authRemoteStorages', () {
    test('authenticates using stored hashed password', () async {
      final user = User(id: 'me', name: 'me');
      user.secrets = {'remote_storages': {'MockStorage': {'hashed_password': 'pw1'}}};
      final localStorage = ConfigurableLocalStorage()..meUser = user;
      final tracking = TrackingRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'MockStorage': tracking});
      await r.authRemoteStorages();
      expect(tracking.authLogin, 'me');
      expect(tracking.authPassword, 'pw1');
    });

    test('skips auth when no password is stored', () async {
      final user = User(id: 'me', name: 'me');
      user.secrets = {'remote_storages': {'MockStorage': <String, dynamic>{}}};
      final localStorage = ConfigurableLocalStorage()..meUser = user;
      final tracking = TrackingRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'MockStorage': tracking});
      await r.authRemoteStorages();
      expect(tracking.authLogin, null);
    });
  });

  group('Repository createUserRemoteStorages', () {
    test('throws when local user is not initialized', () async {
      final localStorage = ConfigurableLocalStorage(); // no meUser -> myId is null
      final r = Repository(localStorage: localStorage, remoteStorages: {});
      expect(() => r.createUserRemoteStorages('secret'), throwsException);
    });

    test('derives and stores a new password when none exists', () async {
      final user = User(id: 'me', name: 'me');
      user.settings = {'remote_storages': {'MockStorage': {'instance': 'inst1'}}};
      user.secrets = {'remote_storages': {'MockStorage': <String, dynamic>{}}};
      final localStorage = ConfigurableLocalStorage()..meUser = user;
      final tracking = TrackingRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'MockStorage': tracking});

      final success = await r.createUserRemoteStorages('mysecret');

      expect(success, true);
      expect(tracking.createLogin, 'me');
      expect(tracking.createPassword, isNotNull);
      expect(user.secrets.getDeep('remote_storages.MockStorage.hashed_password'), tracking.createPassword);
    });

    test('throws when secret is not provided and no password exists', () async {
      final user = User(id: 'me', name: 'me');
      user.secrets = {'remote_storages': {'MockStorage': <String, dynamic>{}}};
      final localStorage = ConfigurableLocalStorage()..meUser = user;
      final r = Repository(localStorage: localStorage, remoteStorages: {'MockStorage': TrackingRemoteStorage()});
      expect(r.createUserRemoteStorages(null), throwsException);
    });

    test('reuses existing password and reports failure when createUserAndAuth throws', () async {
      final user = User(id: 'me', name: 'me');
      user.secrets = {'remote_storages': {'MockStorage': {'hashed_password': 'existingpw'}}};
      final localStorage = ConfigurableLocalStorage()..meUser = user;
      final tracking = TrackingRemoteStorage()..throwOnCreate = true;
      final r = Repository(localStorage: localStorage, remoteStorages: {'MockStorage': tracking});

      final success = await r.createUserRemoteStorages(null);

      expect(success, false);
    });
  });

  group('Repository tryLogin', () {
    test('succeeds and authenticates the configured storage', () async {
      final localStorage = ConfigurableLocalStorage();
      final tracking = TrackingRemoteStorage();
      final r = TestRepository(localStorage: localStorage, testStorage: tracking);

      final success = await r.tryLogin('user123', 'mysecret');

      expect(success, true);
      expect(tracking.initInstance, 'closers-cd24f');
      expect(tracking.authLogin, 'user123');
      expect(tracking.authPassword, isNotNull);
      expect(tracking.authPassword, isNotEmpty);
    });

    test('returns false when remote storage init fails', () async {
      final localStorage = ConfigurableLocalStorage();
      final tracking = TrackingRemoteStorage()..initResult = false;
      final r = TestRepository(localStorage: localStorage, testStorage: tracking);

      final success = await r.tryLogin('user123', 'mysecret');

      expect(success, false);
      expect(tracking.authLogin, 'user123'); // auth is still attempted after a failed init
    });

    test('returns false when remote storage auth fails', () async {
      final localStorage = ConfigurableLocalStorage();
      final tracking = TrackingRemoteStorage()..authResult = false;
      final r = TestRepository(localStorage: localStorage, testStorage: tracking);

      final success = await r.tryLogin('user123', 'mysecret');

      expect(success, false);
      expect(tracking.initInstance, 'closers-cd24f');
    });

    test('returns false instead of throwing when storage init throws', () async {
      // Реальный случай (свежее устройство): Firebase.app(instance) кидал
      // no-app, исключение не ловилось и модальное окно логина не закрывалось.
      final localStorage = ConfigurableLocalStorage();
      final tracking = TrackingRemoteStorage()..throwOnInit = true;
      final r = TestRepository(localStorage: localStorage, testStorage: tracking);

      final success = await r.tryLogin('user123', 'mysecret');

      expect(success, false);
    });

    test('existing-user login initializes storages and returns the user', () async {
      // Свежее устройство: локального пользователя нет, remoteStorages пусты;
      // данные пользователя есть в удаленном хранилище.
      final localStorage = ConfigurableLocalStorage();
      final tracking = TrackingRemoteStorage();
      final storedUser = User(id: 'user123', name: 'remote user');
      tracking.remoteModels['user123'] = storedUser;
      final r = TestRepository(localStorage: localStorage, testStorage: tracking);
      expect(r.connectedStorages, isEmpty);

      final success = await r.tryLogin('user123', 'mysecret');

      expect(success, true);
      expect(r.connectedStorages, isNotEmpty); // tryLogin подключил хранилище
      final restored = await r.getModelNow<User>('user123');
      expect(restored, isNotNull);
      expect(restored!.name, 'remote user');
    });
  });

  group('Repository asyncSetMe after login', () {
    test('initializes and authenticates storages with the derived password', () async {
      final localStorage = ConfigurableLocalStorage();
      final tracking = TrackingRemoteStorage();
      final r = TestRepository(localStorage: localStorage, testStorage: tracking);
      expect(await r.tryLogin('user123', 'mysecret'), isTrue);

      final user = User(id: 'user123', name: 'u');
      await r.asyncSetMe(user);

      expect(r.myId, 'user123');
      expect(tracking.initInstance, 'closers-cd24f');
      // Пароль, выведенный tryLogin из секрета, доезжает до authRemoteStorages
      expect(tracking.authLogin, 'user123');
      expect(tracking.authPassword, isNotNull);
      // и сохраняется в secrets пользователя (в памяти сессии)
      expect(user.secrets.getDeep('remote_storages.FirebaseRealtimeDatabase.hashed_password'), isNotNull);
    });
  });

  group('Repository me store/read race', () {
    test('me getter works immediately after set me', () async {
      final localStorage = ConfigurableLocalStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {});
      final user = User(id: 'race-user', name: 'race');

      r.me = user;

      // storeItem еще не обязан завершиться, а me уже должен работать
      expect(r.me.id, 'race-user');
      expect(r.me.name, 'race');
    });

    test('logout (myId = null) clears the cached me', () async {
      final localStorage = ConfigurableLocalStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {});
      r.me = User(id: 'race-user', name: 'race');
      expect(r.me.id, 'race-user');

      r.myId = null;

      expect(() => r.me, throwsStateError);
    });
  });

  group('Repository', () {
    test('syncWithRemoteStorage simple', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      final user = User(name: 'test_user');
      await r.syncWithRemoteStorage({user.id: user});
      expect(localStorage.lastItems.length, 2);
      expect(localStorage.lastRegistries[user.registryId]?.lastTransaction?.changes.contains(user.id), true);
      expect(remoteStorage.lastItems.length, 2);
      expect(remoteStorage.lastRegistries[user.registryId]?.lastTransaction?.changes.contains(user.id), true);
      // Успешная транзакция должна вычистить обработанный хвост истории
      expect(localStorage.clearHistoryQueueHeadCallCount, 1);
    });

    test('syncWithRemoteStorage re-simple', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      final user = User(name: 'test_user');
      await r.syncWithRemoteStorage({user.id: user});
      expect(localStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 0);
      expect(remoteStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 0);
      await r.syncWithRemoteStorage({user.id: user});
      expect(localStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 1);
      expect(remoteStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 1);
    });

    test('syncWithRemoteStorage collision', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      final user = User(name: 'test_user');
      await r.syncWithRemoteStorage({user.id: user});
      remoteStorage.externalChange({user.id: user});
      expect(localStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 0);
      expect(remoteStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 1);
      await r.syncWithRemoteStorage({user.id: user});
      expect(localStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 2);
      expect(remoteStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 2);
    });

    test('syncWithRemoteStorage no changes', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      await r.syncWithRemoteStorage({});
      expect(localStorage.lastRegistries.length, 0);
      expect(remoteStorage.lastRegistries.length, 0);
    });

    test('syncWithRemoteStorage rebase', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      var user = User(name: 'test_user', domainsIds: ['domain1']);
      await r.syncWithRemoteStorage({user.id: user});
      user = user.copyWith(name: 'test_user_2', domainsIds: [...user.domainsIds, 'domain2']);
      remoteStorage.externalChange({user.id: user});
      user = user.copyWith(domainsIds: ['domain3']);
      await r.syncWithRemoteStorage({user.id: user});
      expect((remoteStorage.lastModels[user.id] as User?)?.name, 'test_user_2');
      expect((remoteStorage.lastModels[user.id] as User?)?.domainsIds.contains('domain1'), true);
      expect((remoteStorage.lastModels[user.id] as User?)?.domainsIds.contains('domain2'), true);
      expect((remoteStorage.lastModels[user.id] as User?)?.domainsIds.contains('domain3'), true);
    });

    test('syncWithRemoteStorage rebase with conflict', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      User? localConflictUser;
      User? remoteConflictUser;
      final listenerId = r.addSyncListener(
        (id, syncedItem) => print(syncedItem),
        (localChanges, remoteChanges) {
          if (localChanges.isNotEmpty && remoteChanges.isNotEmpty) {
            localConflictUser = localChanges.values.first as User?;
            remoteConflictUser = remoteChanges.values.first as User?;
          }
        }
      );
      final user1 = User(name: 'test_user');
      r.subscribeToSync(user1.id, listenerId);
      await r.syncWithRemoteStorage({user1.id: user1});
      final user2 = user1.copyWith(name: 'test_user_2');
      remoteStorage.externalChange({user2.id: user2});
      final user3 = user1.copyWith(name: 'test_user_3');
      await r.syncWithRemoteStorage({user3.id: user3});
      expect((localStorage.lastModels[user1.id] as User?)?.name, 'test_user'); // the local changes have been cancelled
      expect((remoteStorage.lastModels[user1.id] as User?)?.name, 'test_user_2');
      expect(localConflictUser?.name, 'test_user_3');
      expect(remoteConflictUser?.name, 'test_user_2');
      // Конфликт слияния тоже должен вычищать обработанный хвост истории, а не копить его
      expect(localStorage.clearHistoryQueueHeadCallCount, 2); // первый успешный sync + конфликтующий sync
    });

    test('syncWithRemoteStorage access denied', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = DenyingRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});

      Map<String, dynamic>? deniedItemsForSubscriber;
      final subscriberId = r.addSyncListener(
        (id, syncedItem) => print(syncedItem),
        (localChanges, remoteChanges) {},
        (items) {
          deniedItemsForSubscriber = items;
        }
      );
      // Слушатель, не подписанный на изменяемую модель, не должен получать колбэк
      Map<String, dynamic>? deniedItemsForUnrelatedSubscriber;
      r.addSyncListener(
        (id, syncedItem) => print(syncedItem),
        (localChanges, remoteChanges) {},
        (items) {
          deniedItemsForUnrelatedSubscriber = items;
        }
      );

      var user = User(name: 'test_user');
      r.subscribeToSync(user.id, subscriberId);
      await r.syncWithRemoteStorage({user.id: user});
      expect(deniedItemsForSubscriber, null);
      expect(deniedItemsForUnrelatedSubscriber, null);
      expect(localStorage.clearHistoryQueueHeadCallCount, 1); // первый успешный sync

      remoteStorage.deny = true;
      user = user.copyWith(name: 'test_user_2');
      final result = await r.syncWithRemoteStorage({user.id: user});

      expect(result, 0);
      expect(deniedItemsForSubscriber, isNotNull);
      expect(deniedItemsForSubscriber?.containsKey(user.id), true);
      expect((deniedItemsForSubscriber?[user.id] as User?)?.name, 'test_user_2');
      // Не подписанный слушатель не должен быть оповещен
      expect(deniedItemsForUnrelatedSubscriber, null);
      // Локальные изменения должны быть откачены, так как запись была отклонена
      expect((localStorage.lastModels[user.id] as User?)?.name, 'test_user');
      // Отказ в доступе тоже должен вычищать обработанный хвост истории, а не копить его
      expect(localStorage.clearHistoryQueueHeadCallCount, 2);
    });

  });
group('Timer postpone restarts countdown', () {
  test('postpone restarts the countdown from zero', () async {
    var doneCalls = 0;
    final t = Timer(() => doneCalls++);
    final sw = Stopwatch()..start();
    t.start(2, 1);
    // Активное действие пользователя через ~0.5s: postpone перезапускает
    // отсчет, done должен приехать ~2s ПОСЛЕ postpone, а не после start.
    await Future.delayed(const Duration(milliseconds: 500));
    final elapsedAtPostpone = sw.elapsedMilliseconds;
    t.postpone();
    // Ждем до 4.5s от старта с запасом: если бы postpone НЕ перезапускал,
    // done пришел бы ~2s от старта (раньше 3s); при перезапуске - ~2.5s
    // от старта (+ допуски на планировщик).
    while (doneCalls == 0 && sw.elapsedMilliseconds < 4500) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    final total = sw.elapsedMilliseconds;
    final sincePostpone = total - elapsedAtPostpone;
    expect(doneCalls, 1);
    // done сработал ~2s ПОСЛЕ postpone (а не через оставшиеся ~1.5s от
    // исходного отсчета): отсчет был перезапущен postpone.
    expect(sincePostpone, greaterThan(1800));
    // Но не слишком поздно: отсчет идет ~2s после postpone с допуском.
    expect(sincePostpone, lessThan(3500));
    expect(t.lastActualtime, 2);
  });
});

group('Timer sync error resilience', () {
  test('a sync error does not kill the timer: repeated sync cycles survive', () async {
    final localStorage = MockLocalStorage();
    final remote = ThrowingSaveRemoteStorage();
    final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remote});
    final user = User(id: 'me', name: 'me');
    // Постановка в очередь без немедленной синхронизации - как в local-first потоке.
    await r.saveModel(user, null, false);
    expect(r.outgoingChanges, isNotEmpty);
    // Ошибка сохранения в удаленном хранилище не должна вылетать наружу
    // (иначе подписка таймера умирает по cancelOnError и sync больше не
    // запускается до конца сессии).
    await r.runSyncForTest();
    // Таймер "жив": следующий цикл запускается и завершается (мьютекс
    // освобожден, исключение не накопилось).
    await r.runSyncForTest();
    // Незасинхронизированные изменения остаются в очереди для следующего цикла.
    expect(r.outgoingChanges, isNotEmpty);
  });
});

group('Repository full sync scenario', () {
  // Полный сценарий локальной работы с синхронизацией на реальном IsarStorage:
  // A) базовая синхронизация домена; B) правки во время синхронизации встают
  // в очередь и доезжают только следующим циклом (правки НЕ теряются);
  // D) отказ в доступе -> accessDenied-колбэк, откат локальных правок,
  // восстановление после снятия флага; C) неразрешимая коллизия слияния ->
  // mergeConflict-колбэк. Порядок D перед C: после merge-конфликта локальная
  // база откатывается к remote-версии, и последующая правка без пул-обновления
  // (реестровые подписки в тесте неактивны) ушла бы в конфликт вместо deny.
  late IsarStorage storage;

  Future<IsarStorage> freshStorage() async {
    try {
      storage.isar.close(deleteFromDisk: true);
    } catch (_) {}
    final fresh = IsarStorage();
    await fresh.init();
    storage = fresh; // tearDownAll закрывает актуальный инстанс
    return fresh;
  }

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.';
        }
        return null;
      },
    );
    // https://github.com/ahmtydn/isar_plus/releases?q=1.2.6&expanded=true
    if (Platform.isWindows) await Isar.initialize('test/isar_windows_x64.dll');
    if (Platform.isLinux) await Isar.initialize('test/libisar_linux_x64.so');
    if (Platform.isMacOS) await Isar.initialize('test/libisar_macos.dylib');
    storage = IsarStorage();
    await storage.init();
  });

  tearDownAll(() async {
    // close() синхронный (возвращает bool), см. isar_plus 1.2.6.
    storage.isar.close(deleteFromDisk: true);
  });

  Future<void> waitFor(bool Function() condition, {String because = 'condition'}) async {
    final sw = Stopwatch()..start();
    while (!condition() && sw.elapsedMilliseconds < 10000) {
      await Future.delayed(const Duration(milliseconds: 10));
    }
    expect(condition(), isTrue, reason: 'Timed out waiting: $because');
  }

  test('edits made during a sync stay queued and sync after it completes; conflict and access denied callbacks fire', () async {
    final localStorage = await freshStorage();
    final remote = GatedRemoteStorage();
    final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remote});
    // Без init() таймера нет (late == true): saveModel(immediate: true)
    // синхронизирует напрямую, immediate: false - только очередь,
    // а runSyncForTest() запускает цикл вручную.
    r.me = User(id: 'me', name: 'me');

    // set me подписывает 'me' на дефолтного слушателя; снимаем эту подписку,
    // чтобы колбэки получал только адресный слушатель task1.
    r.removeSyncListener(r.defaultSyncSubscriber);

    final localConflicts = <Map<String, Model>>[];
    final remoteConflicts = <Map<String, Model>>[];
    final accessDenied = <Map<String, dynamic>>[];
    final listenerId = r.addSyncListener(
      (id, syncedItem) {},
      (localChanges, remoteChanges) {
        localConflicts.add(localChanges);
        remoteConflicts.add(remoteChanges);
      },
      (items) {
        accessDenied.add(items);
      },
    );

    // Фаза A: базовая синхронизация домена и задачи.
    final domain = Domain(id: 'domain1', title: 'Domain 1', originatorId: 'me');
    final task = Task(id: 'task1', title: 'Task 1', originatorId: 'me');
    // Родитель задачи - домен: у задачи children=[domain1], у домена
    // parents=[task1] - _getParent идет по parents вверх до домена.
    task.link(from: domain);
    domain.link(to: task);
    // task3 создается заранее и удаляется во время синхронизации (фаза B).
    final task3 = Task(id: 'task3', title: 'Task 3', originatorId: 'me');
    task3.link(from: domain);
    domain.link(to: task3);
    r.me.domainsIds.add('domain1');
    // Немедленная отправка не должна блокировать UI (local-first).
    // Базовые модели едут без подписки на колбэки (subscriberId null);
    // task1 подписана на адресного слушателя - только его колбэки и ловим.
    await r.saveModels([r.me, domain, task3], null, true);
    await r.saveModel(task, listenerId, true);
    expect((remote.lastModels['task1'] as Task?)?.title, 'Task 1');
    expect((remote.lastModels['task3'] as Task?)?.title, 'Task 3');
    expect(r.outgoingChanges, isEmpty);
    expect(r.outgoingDeletes, isEmpty);

    // Фаза B: правка задачи начинает синхронизироваться и застревает на
    // шлюзе - очередь непуста, второй правки в remote еще нет.
    remote.closeGate();
    final syncDone = Completer<void>();
    // Правка в очередь, sync стартует и застревает: не ждем его (saveModel
    // с immediate дожидался бы синхронизации - в тесте без init() это
    // дедлок на шлюзе).
    await r.saveModel(
      (remote.lastModels['task1'] as Task).copyWith(title: 'Task 1 v2'),
      listenerId,
    );
    unawaited(r.runSyncForTest().whenComplete(syncDone.complete));
    await waitFor(
      () => remote.saveItemsCalls.any(
        (batch) => (batch['task1'] as Task?)?.title == 'Task 1 v2',
      ),
      because: 'first edit sync reached the gate',
    );
    // Правка в полете: она еще в очереди (очистка после отправки).
    expect(r.outgoingChanges, hasLength(1));
    expect(syncDone.isCompleted, false); // sync еще в полете

    // Следующие правки во время синхронизации: новая модель и удаление.
    final task2 = Task(id: 'task2', title: 'Task 2', originatorId: 'me');
    task2.link(from: domain);
    domain.link(to: task2);
    await r.saveModel(task2, listenerId);
    expect(r.outgoingChanges, isNotEmpty); // правки ждут окончания sync
    expect(remote.lastModels['task2'], isNull); // и еще не уехали в remote
    r.deleteModel(task3);
    expect(r.outgoingDeletes, isNotEmpty);
    // Открываем шлюз: застрявшая пачка дотекает, правки из очереди остаются.
    remote.openGate();
    await syncDone.future; // sync с застрявшей правкой завершается
    // Застрявший цикл увозит только свой снапшот (правку task1): правки,
    // добавленные во время синхронизации, остаются в очереди.
    expect(r.outgoingChanges, hasLength(1)); // только task2
    expect(remote.lastModels['task2'], isNull); // task2 еще не уехал
    expect(remote.deleteItemsCalls, isEmpty); // удаление task3 еще не уехало
    expect(remote.lastModels['task3'], isNotNull); // task3 еще не удален

    // Следующий цикл: правки из очереди и удаления доезжают до remote.
    await r.runSyncForTest();
    expect(r.outgoingChanges, isEmpty);
    expect(r.outgoingDeletes, isEmpty);
    expect((remote.lastModels['task2'] as Task?)?.title, 'Task 2');
    expect(remote.deleteItemsCalls, hasLength(1));
    expect(remote.deleteItemsCalls.last.containsKey('task3'), isTrue);
    expect(remote.lastModels['task3'], isNull); // удалена в remote

    // Фаза D: пользователь исключен из домена - транспорт отвечает 403.
    remote.deny = true;
    await r.saveModel(
      (remote.lastModels['task1'] as Task).copyWith(title: 'Task 1 v3'),
      listenerId,
      true,
    );
    expect(accessDenied, hasLength(1));
    expect(accessDenied.last['task1'], isA<Task>());
    // Локальные изменения откачены к последней закоммиченной базе.
    final rolledBack = await r.getModelNow<Task>('task1');
    expect(rolledBack?.title, 'Task 1 v2');

    // Восстановление: флаг снят - та же правка проходит без конфликта.
    remote.deny = false;
    await r.saveModel(
      (await r.getModelNow<Task>('task1'))!.copyWith(title: 'Task 1 v3'),
      listenerId,
      true,
    );
    expect(accessDenied, hasLength(1));
    expect((remote.lastModels['task1'] as Task?)?.title, 'Task 1 v3');

    // Фаза C: вторая сторона меняет тот же скаляр (title) - неразрешимая
    // коллизия слияния -> mergeConflict-колбэк.
    // Чужая транзакция в реестре домена: индекс 5 в remote занят внешним
    // изменением, локальная транзакция 5 столкнется с ней.
    remote.lastRegistries[domain.registryId]!.addNewTransaction(
      Transaction.next(
        remote.lastRegistries[domain.registryId]!.lastTransaction,
        'task1',
        'changeDetails',
        'changeType',
        ['task1'],
        'path',
      ),
    );
    remote.lastModels['task1'] = (remote.lastModels['task1'] as Task).copyWith(title: 'Remote edit');
    await r.saveModel(
      (remote.lastModels['task1'] as Task).copyWith(title: 'Local edit'),
      listenerId,
      true,
    );
    expect(localConflicts, hasLength(1));
    expect((localConflicts.last['task1'] as Task?)?.title, 'Local edit');
    expect((remoteConflicts.last['task1'] as Task?)?.title, 'Remote edit');
    // Локальная правка откачена к последней закоммиченной базе; у второй
    // стороны осталась ее версия.
    expect((await r.getModelNow<Task>('task1'))?.title, 'Task 1 v3');
    expect((remote.lastModels['task1'] as Task?)?.title, 'Remote edit');
  });
});

}

class ThrowingSaveRemoteStorage extends TrackingRemoteStorage {
  @override
  Future<int> saveItems(Map<String, dynamic> items, {Map<String, Map<String, Set<String>>> deletions = const {}}) async {
    throw Exception('saveItems failed');
  }
}

/// Транспорт для сценария полной синхронизации: обычный MockRemoteStorage,
/// но пока шлюз [gate] закрыт (closeGate), каждый saveItems висит на нем -
/// тест держит синхронизацию mid-flight; флаг [deny] эмулирует отказ
/// в доступе (пользователь исключен из домена). Все вызовы saveItems
/// записываются.
class GatedRemoteStorage extends DenyingRemoteStorage {
  /// Изначально открыт: базовая синхронизация проходит свободно.
  Completer<void> gate = Completer<void>()..complete();

  void closeGate() {
    gate = Completer<void>();
  }

  void openGate() {
    if (!gate.isCompleted) gate.complete();
  }

  final List<Map<String, dynamic>> saveItemsCalls = [];

  @override
  Future<int> saveItems(Map<String, dynamic> items, {Map<String, Map<String, Set<String>>> deletions = const {}}) async {
    saveItemsCalls.add(Map<String, dynamic>.from(items));
    await gate.future;
    return super.saveItems(items, deletions: deletions);
  }

  final List<Map<String, dynamic>> deleteItemsCalls = [];

  @override
  Future<int> deleteItems(Map<String, dynamic> items) async {
    deleteItemsCalls.add(Map<String, dynamic>.from(items));
    for (final id in items.keys) {
      lastModels.remove(id);
    }
    return items.length;
  }
}
