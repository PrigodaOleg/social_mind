import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:closers/repository/repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLocalStorage extends LocalStorage {
  Map<String, Model> lastModels = {};
  Map<String, Registry> lastRegistries = {};
  Map<String, dynamic> get lastItems => {...lastModels, ...lastRegistries};
  Map<String, Model> oldModels = {};
  int clearHistoryQueueHeadCallCount = 0;

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
  Future<int> saveItems(Map<String, dynamic> items) async {
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
  Future<int> saveItems(Map<String, dynamic> items) async {
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

  String? authLogin;
  String? authPassword;
  bool authResult = true;

  String? createLogin;
  String? createPassword;
  bool throwOnCreate = false;

  @override
  Future<bool> init(String instance) async {
    initInstance = instance;
    return initResult;
  }

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
}
