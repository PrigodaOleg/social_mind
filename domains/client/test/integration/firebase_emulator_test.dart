
// Integration tests for RemoteStorage (FirebaseStorage) and Repository against
// the Firebase Local Emulator Suite (Auth + Realtime Database).
//
// These tests require running emulators:
//   firebase emulators:start --only auth,database --project closers-test
// (see firebase.json in the project root)
//
// They run on the web platform only (firebase plugins need a real platform):
//   flutter test --platform chrome test_integration
//
// The Realtime Database rules under test are the production ones:
//   lib/remote_storage/firebase_realtime_database_rules.json

@TestOn('browser')
library firebase_emulator_test;

import 'dart:async';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart' as fb_db;
import 'package:firebase_auth_web/firebase_auth_web.dart' as fb_auth_web;
import 'package:firebase_core_web/firebase_core_web.dart' as fb_core_web;
import 'package:firebase_database_web/firebase_database_web.dart' as fb_db_web;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:closers/repository/models/models.dart';
import 'package:closers/repository/repository/repository.dart';

const project = 'closers-test';
const authPort = 9099;
const dbPort = 9000;

// Minimal in-memory LocalStorage sufficient for Repository.syncWithRemoteStorage.
class MemoryLocalStorage extends LocalStorage {
  final modelsMap = <String, Model>{};
  final registriesMap = <String, Registry>{};
  final historyQueue = <String, Model>{};
  int clearHistoryQueueHeadCallCount = 0;
  String? _userId;

  @override
  Uint8List? getImage(String id) => null;

  @override
  Future<int> storeItems(Map<String, dynamic> items) async {
    for (final item in items.values) {
      if (item is Model) {
        modelsMap[item.id] = item;
      }
      if (item is Registry) {
        final existing = registriesMap[item.id!];
        if (existing != null) {
          existing.transactions.addAll(item.transactions);
        } else {
          registriesMap[item.id!] = item;
        }
      }
    }
    return items.length;
  }

  @override
  String? getUserId() => _userId;

  @override
  Future<void> setUserId(String userId) async {
    _userId = userId;
  }

  @override
  dynamic getItem({required String id}) => modelsMap[id];

  @override
  Map<String, T> getItems<T>(List<String> ids) {
    final items = <String, T>{};
    for (final id in ids) {
      final item = modelsMap[id];
      if (item is T) items[id] = item as T;
    }
    return items;
  }

  @override
  Registry? getRegistry({String? id, String? parentId, int count = 5}) {
    if (id != null) return registriesMap[id];
    if (parentId != null) {
      return registriesMap[(modelsMap[parentId] as User?)?.registryId];
    }
    return null;
  }

  @override
  Map<String, dynamic> getNextItemsFromHistoryQueue() {
    final items = Map<String, dynamic>.from(historyQueue);
    historyQueue.clear();
    return items;
  }

  @override
  void clearHistoryQueueHead() {
    clearHistoryQueueHeadCallCount++;
  }
}

// Repository that builds a real FirebaseStorage for the well-known key.
class TestRepository extends Repository {
  TestRepository({super.localStorage, super.remoteStorages});

  @override
  late final knownRemoteStorages = <String, Function()>{
    'FirebaseRealtimeDatabase': () => FirebaseStorage(),
  };
}

Future<FirebaseApp> _initApp(String name) async {
  return Firebase.initializeApp(
    name: name,
    options: const FirebaseOptions(
      apiKey: 'test-api-key',
      appId: '1:1:web:1',
      messagingSenderId: '1',
      projectId: project,
      databaseURL: 'http://localhost:$dbPort/?ns=$project',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // These tests need the Firebase Local Emulator Suite and only work on the
  // web platform. Skip on the default VM platform (plain `flutter test`).
  if (!const bool.fromEnvironment('RUN_EMULATOR_TESTS')) {
    throw Skip('Requires Firebase emulator: '
        'flutter test --platform chrome --dart-define=RUN_EMULATOR_TESTS=true');
  }

  final registrar = Registrar();
  fb_core_web.FirebaseCoreWeb.registerWith(registrar);
  fb_auth_web.FirebaseAuthWeb.registerWith(registrar);
  fb_db_web.FirebaseDatabaseWeb.registerWith(registrar);

  late FirebaseApp app;
  late fb_db.FirebaseDatabase db;
  late FirebaseStorage storage;

  setUpAll(() async {
    app = await _initApp('integration-test');
    fb_auth.FirebaseAuth.instanceFor(app: app)
        .useAuthEmulator('localhost', authPort);
    db = fb_db.FirebaseDatabase.instanceFor(app: app);
    db.useDatabaseEmulator('localhost', dbPort);
    storage = FirebaseStorage();
    await storage.init(app.name);
    // Clean the database from previous runs (requires an authenticated user).
    final auth = fb_auth.FirebaseAuth.instanceFor(app: app);
    try {
      await auth.createUserWithEmailAndPassword(
          email: 'clean@a.aa', password: 'secret123');
    } catch (_) {
      await auth.signInWithEmailAndPassword(
          email: 'clean@a.aa', password: 'secret123');
    }
    await db.ref().set(null);
  });

  tearDownAll(() async {
    await app.delete();
  });

  group('FirebaseStorage against emulator', () {
    final login = 'user${DateTime.now().millisecondsSinceEpoch}';

    test('createUserAndAuth + auth', () async {
      expect(await storage.createUserAndAuth(login, 'secret123'), true);
      // Already signed in after creation; sign out and sign in again.
      await fb_auth.FirebaseAuth.instanceFor(app: app).signOut();
      expect(await storage.auth(login, 'secret123'), true);
      expect(fb_auth.FirebaseAuth.instanceFor(app: app).currentUser?.email, '$login@a.aa');
    });

    test('saveItems, getItem, getItems roundtrip for User + Registry', () async {
      final user = User(id: 'u1', name: 'alice');
      final registry = Registry(id: 'r1', parentId: user.id);
      user.registryId = registry.id!;
      registry.transactions[0] = Transaction.zero(
        user.id,
        'test',
        'create',
        [user.id],
        '/',
      );

      final saved = await storage.saveItems({'u1': user, 'r1': registry});
      expect(saved, 2);

      final loaded = await storage.getItem(id: 'u1');
      expect(loaded, isA<User>());
      final loadedUser = loaded as User;
      expect(loadedUser.id, 'u1');
      expect(loadedUser.name, 'alice');
      expect(loadedUser.registryId, registry.id);

      final items = await storage.getItems(['u1', 'missing']);
      expect(items.keys, ['u1']);
      expect(items['u1'], isA<User>());
    });

    test('readRegistry returns metadata and transactions', () async {
      final registry = await storage.readRegistry('r1');
      expect(registry, isNotNull);
      expect(registry!.metadata.id, 'r1');
      expect(registry.metadata.parentId, 'u1');
      expect(registry.transactions.keys, contains(0));
      expect(registry.transactions[0]!.changes, contains('u1'));
    });

    test('saveItems appends transactions sequentially (lastIdx)', () async {
      final registry = Registry(id: 'r1', parentId: 'u1');
      registry.transactions[1] = Transaction.zero(
        'u1',
        'test',
        'update',
        ['u1'],
        '/',
      );
      expect(await storage.saveItems({'r1': registry}), 1);

      final snapshot = await db.ref('registries/r1/lastIdx').get();
      expect(snapshot.value, 1);
    });

    test('rules reject transaction with wrong index', () async {
      // lastIdx is 1, so index 5 must be rejected by the rules.
      expect(
        () => db.ref('registries/r1/transactions/5/id').set('bad'),
        throwsA(anyOf(
          isA<Exception>(),
          isA<Exception>(),
        )),
      );
    });

    test('deleteItems removes models', () async {
      final user = User(id: 'u2', name: 'bob');
      // Rules require a model to be referenced by its registry transaction.
      final registry = Registry(id: 'r2', parentId: user.id);
      user.registryId = registry.id!;
      registry.transactions[0] = Transaction.zero(
        user.id,
        'test',
        'create',
        [user.id],
        '/',
      );
      expect(await storage.saveItems({'u2': user, 'r2': registry}), 2);
      expect(await storage.getItem(id: 'u2'), isNotNull);
      expect(await storage.deleteItems({'u2': user}), 1);
      expect(await storage.getItem(id: 'u2'), isNull);
    });
  });

  group('Repository + FirebaseStorage integration', () {
    test('syncWithRemoteStorage persists user and registry to emulator',
        () async {
      final localStorage = MemoryLocalStorage();
      final me = User(id: 'me', name: 'me');
      await localStorage.storeItems({me.id: me});
      final fs = FirebaseStorage();
      await fs.init(app.name);
      final repository = TestRepository(
        localStorage: localStorage,
        remoteStorages: {'FirebaseRealtimeDatabase': fs},
      );
      repository.myId = 'me';

      final user = User(name: 'sync_user');
      final saved = await repository.syncWithRemoteStorage({user.id: user});
      expect(saved, 1);

      // Local side got the registry with the first transaction.
      final localRegistry = localStorage.registriesMap[user.registryId]!;
      expect(localRegistry.lastTransactionIndex, 0);
      expect(localStorage.clearHistoryQueueHeadCallCount, 1);

      // Remote side: model and registry are readable through FirebaseStorage.
      final remote = fs;
      final loadedUser = await remote.getItem(id: user.id);
      expect(loadedUser, isA<User>());
      expect((loadedUser as User).name, 'sync_user');
      expect((loadedUser as User).registryId, user.registryId);

      final remoteRegistry = await remote.readRegistry(user.registryId);
      expect(remoteRegistry, isNotNull);
      expect(remoteRegistry!.lastTransactionIndex, 0);
      expect(remoteRegistry.transactions[0]!.changes, contains(user.id));
    });

    test('second sync appends the next transaction', () async {
      final localStorage = MemoryLocalStorage();
      final me = User(id: 'me', name: 'me');
      await localStorage.storeItems({me.id: me});
      final fs = FirebaseStorage();
      await fs.init(app.name);
      final repository = TestRepository(
        localStorage: localStorage,
        remoteStorages: {'FirebaseRealtimeDatabase': fs},
      );
      repository.myId = 'me';

      var user = User(name: 'sync_user2');
      await repository.syncWithRemoteStorage({user.id: user});
      user = user.copyWith(name: 'sync_user2_renamed');
      await repository.syncWithRemoteStorage({user.id: user});

      final remote = fs;
      final remoteRegistry = await remote.readRegistry(user.registryId);
      expect(remoteRegistry!.lastTransactionIndex, 1);

      final loadedUser = await remote.getItem(id: user.id) as User;
      expect(loadedUser.name, 'sync_user2_renamed');
    });
  });
}
