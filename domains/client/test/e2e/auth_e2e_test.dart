
// End-to-end auth tests against the Firebase Local Emulator Suite
// (Auth + Realtime Database) with the PRODUCTION security rules applied
// (lib/remote_storage/firebase_realtime_database_rules.json, sanitized by
// tool/prepare_firebase_rules.py — see tool/run_auth_e2e_tests.sh).
//
// The tests exercise the same flows the UI login page drives
// (lib/ui/pages/login.dart):
//   - new user creation + login
//   - existing user login
//   - blank user login
//   - repeated login/logout cycles
//   - negative scenarios (wrong secret, empty secret, unknown user)
//
// They run on the web platform only:
//   tool/run_auth_e2e_tests.sh
//   (== firebase emulators + flutter test --platform chrome)
//
// Future: the same file must run on android emulator / ios simulator /
// physical devices over USB once platform test harnesses are added — the test
// body is platform-agnostic (it talks to the emulator over TCP).
@TestOn('browser')
library auth_e2e_test;

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart' as fb_auth_web;
import 'package:firebase_core_web/firebase_core_web.dart' as fb_core_web;
import 'package:firebase_database_web/firebase_database_web.dart' as fb_db_web;

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:closers/repository/models/models.dart';
import 'package:closers/repository/repository/repository.dart';

const project = 'closers-test';
const authPort = 9099;
const dbPort = 9000;

// The default instance name used by User.settings
// ('remote_storages.FirebaseRealtimeDatabase.instance') — Repository.tryLogin
// calls Firebase.app(instance), so the app MUST be registered under this name.
const defaultInstance = 'closers-cd24f';

/// Minimal in-memory LocalStorage (same trick as
/// test/integration/firebase_emulator_test.dart) sufficient for Repository.
class MemoryLocalStorage extends LocalStorage {
  final modelsMap = <String, Model>{};
  final registriesMap = <String, Registry>{};
  final historyQueue = <String, Model>{};
  String? _userId;

  @override
  Uint8List? getImage(String id) => null;

  @override
  Future<int> storeItems(Map<String, dynamic> items) async {
    for (final item in items.values) {
      if (item is Model) {
        modelsMap[item.id] = item;
        historyQueue[item.id] = item;
      }
      if (item is Registry) registriesMap[item.id!] = item;
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
  void clearHistoryQueueHead() {}

  @override
  Future<void> storeItem(dynamic item) async {
    if (item is Model) {
      modelsMap[item.id] = item;
      historyQueue[item.id] = item;
    }
    if (item is Registry) registriesMap[item.id!] = item;
  }

  @override
  Future<void> deleteItem(String id) async {
    modelsMap.remove(id);
  }
}

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

  if (!const bool.fromEnvironment('RUN_EMULATOR_TESTS')) {
    throw Skip('Requires Firebase emulator: '
        'flutter test --platform chrome --dart-define=RUN_EMULATOR_TESTS=true');
  }

  final registrar = Registrar();
  fb_core_web.FirebaseCoreWeb.registerWith(registrar);
  fb_auth_web.FirebaseAuthWeb.registerWith(registrar);
  fb_db_web.FirebaseDatabaseWeb.registerWith(registrar);

  late FirebaseApp app;
  late fb_auth.FirebaseAuth auth;
  // Independent probe used to poll the emulator from the tests.
  late FirebaseStorage fsProbe;

  setUpAll(() async {
    // Registered under the default instance name so that
    // Repository.tryLogin / initRemoteStorages resolve it.
    app = await _initApp(defaultInstance);
    auth = fb_auth.FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator('localhost', authPort);
    fsProbe = FirebaseStorage();
    await fsProbe.init(defaultInstance);
  });

  tearDownAll(() async {
    await auth.signOut();
    await app.delete();
  });

  // Signs out on the Firebase side and forgets the local user —
  // the "logout" half of the login/logout cycle.
  Future<void> logout(TestRepository repository) async {
    await fb_auth.FirebaseAuth.instanceFor(app: app).signOut();
    repository.myId = null;
  }

  // The "New user"/"Blank user" UI flows (lib/ui/pages/login.dart):
  // repository.me = user -> initRemoteStorages() -> createUserRemoteStorages().
  // The model itself reaches the remote storage asynchronously (the delayed
  // sync timer), so we wait for it to appear before logging out.
  Future<void> createUserFlow(TestRepository repository, User user) async {
    // Initialize late fields (sync listeners, timer) like the real app does
    // in App.locateUser.
    await repository.init();

    repository.me = user;
    await repository.initRemoteStorages();
    expect(
      await repository.createUserRemoteStorages(user.secret),
      isTrue,
    );
    expect(repository.myId, user.id);
    expect(auth.currentUser?.email, '${user.id}@a.aa');

    // Give the background delayed sync a short grace period, then force a
    // sync round explicitly (syncWithRemoteStorage is @visibleForTesting).
    for (var i = 0; i < 10; i++) {
      final remote = await fsProbe.getItem(id: user.id);
      if (remote != null) return;
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    final synced = await repository.syncWithRemoteStorage({user.id: user});
    expect(synced, greaterThan(0),
        reason: 'user ${user.id} must be pushed to the emulator');
  }

  group('auth e2e (new / existing / blank user)', () {
    test('new user: create, login, logout, login again', () async {
      final repository = TestRepository(localStorage: MemoryLocalStorage());
      final user = User(name: 'newbie_e2e');
      user.secret = 'top-secret-${DateTime.now().millisecondsSinceEpoch}';

      await createUserFlow(repository, user);

      // Logout and back in with the secret — the "Existing user" flow.
      await logout(repository);
      expect(auth.currentUser, isNull);
      expect(await repository.tryLogin(user.id, user.secret!), isTrue);
      expect(auth.currentUser?.email, '${user.id}@a.aa');
      final restored = await repository.getModelNow<User>(user.id);
      expect(restored, isNotNull);
      expect(restored!.name, 'newbie_e2e');
    });

    test('existing user: login with correct secret', () async {
      final repository = TestRepository(localStorage: MemoryLocalStorage());
      final user = User(name: 'existing_e2e');
      user.secret = 'existing-secret';

      await createUserFlow(repository, user);
      await logout(repository);

      // Fresh repository — simulates a new app run / new device.
      final repository2 = TestRepository(localStorage: MemoryLocalStorage());
      expect(await repository2.tryLogin(user.id, user.secret!), isTrue);
      final restored = await repository2.getModelNow<User>(user.id);
      expect(restored, isNotNull);
      expect(restored!.name, 'existing_e2e');
    });

    test('blank user: creates account with empty name', () async {
      final repository = TestRepository(localStorage: MemoryLocalStorage());
      // The "Blank user" flow on LoginPage.
      final blankUser = User(name: '');
      blankUser.secret = 'blank-secret';
      await createUserFlow(repository, blankUser);

      // The account is a full one: after logout it can be logged back into.
      await logout(repository);
      expect(
        await repository.tryLogin(blankUser.id, blankUser.secret!),
        isTrue,
      );
    });

    test('repeated login/logout cycles (5x)', () async {
      final repository = TestRepository(localStorage: MemoryLocalStorage());
      final user = User(name: 'cycle_e2e');
      user.secret = 'cycle-secret';

      await createUserFlow(repository, user);

      for (var i = 1; i <= 5; i++) {
        await logout(repository);
        expect(auth.currentUser, isNull, reason: 'cycle $i: after logout');
        expect(
          await repository.tryLogin(user.id, user.secret!),
          isTrue,
          reason: 'cycle $i: login must succeed',
        );
        expect(auth.currentUser?.email, '${user.id}@a.aa',
            reason: 'cycle $i: after login');
      }
    });

    test('negative: wrong secret is rejected', () async {
      final repository = TestRepository(localStorage: MemoryLocalStorage());
      final user = User(name: 'negative_e2e');
      user.secret = 'right-secret';

      await createUserFlow(repository, user);
      await logout(repository);

      await expectLater(
        repository.tryLogin(user.id, 'wrong-secret'),
        throwsA(isA<Exception>()),
      );
      expect(auth.currentUser, isNull);
    });

    test('negative: empty secret is rejected', () async {
      final repository = TestRepository(localStorage: MemoryLocalStorage());
      final user = User(name: 'empty_secret_e2e');
      user.secret = 'non-empty';

      await createUserFlow(repository, user);
      await logout(repository);

      await expectLater(
        repository.tryLogin(user.id, ''),
        throwsA(isA<Exception>()),
      );
      expect(auth.currentUser, isNull);
    });

    test('negative: unknown user id is rejected', () async {
      final repository = TestRepository(localStorage: MemoryLocalStorage());
      await repository.init();

      await expectLater(
        repository.tryLogin(
            'no-such-user-${DateTime.now().millisecondsSinceEpoch}',
            'whatever'),
        throwsA(isA<Exception>()),
      );
      expect(auth.currentUser, isNull);
    });

    test('negative: correct secret for wrong user is rejected', () async {
      final repository = TestRepository(localStorage: MemoryLocalStorage());
      final user = User(name: 'pair_e2e');
      user.secret = 'pair-secret';

      await createUserFlow(repository, user);
      await logout(repository);

      await expectLater(
        repository.tryLogin(
            'other-user-${DateTime.now().millisecondsSinceEpoch}',
            user.secret!),
        throwsA(isA<Exception>()),
      );
      expect(auth.currentUser, isNull);
    });
  });
}
