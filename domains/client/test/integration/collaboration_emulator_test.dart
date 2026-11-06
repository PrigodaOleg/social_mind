// Integration test for the two-user collaboration scenario against the
// Firebase Local Emulator Suite (Auth + Realtime Database).
//
// Requires running emulators:
//   firebase emulators:start --only auth,database --project closers-test
// and runs on the web platform only (firebase plugins need a real platform):
//   flutter test --platform chrome test/integration/collaboration_emulator_test.dart \
//     --dart-define=RUN_EMULATOR_TESTS=true
//
// Conventions follow test/integration/firebase_emulator_test.dart.

@TestOn('browser')
library collaboration_emulator_test;

import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_auth_web/firebase_auth_web.dart' as fb_auth_web;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_web/firebase_core_web.dart' as fb_core_web;
import 'package:firebase_database/firebase_database.dart' as fb_db;
import 'package:firebase_database_web/firebase_database_web.dart' as fb_db_web;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:closers/repository/repository.dart';

const project = 'closers-test';
const authPort = 9099;
const dbPort = 9000;

// Minimal in-memory LocalStorage sufficient for Repository.syncWithRemoteStorage.
// Same as in firebase_emulator_test.dart.
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
      final parent = modelsMap[parentId];
      final registryId = switch (parent) {
        User() => parent.registryId,
        Domain() => parent.registryId,
        _ => null,
      };
      return registryId == null ? null : registriesMap[registryId];
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
  late fb_auth.FirebaseAuth auth;

  setUpAll(() async {
    app = await _initApp('collaboration-test');
    auth = fb_auth.FirebaseAuth.instanceFor(app: app);
    auth.useAuthEmulator('localhost', authPort);
    db = fb_db.FirebaseDatabase.instanceFor(app: app);
    db.useDatabaseEmulator('localhost', dbPort);
    // Clean the database from previous runs (requires an authenticated user).
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

  // Creates a repository for a "device" of the given user, registered in the
  // emulator with a stable secret. Uses createUserAndAuth with secrets.
  Future<(TestRepository, User)> createUserAndRepo(String userId) async {
    final localStorage = MemoryLocalStorage();
    final fs = FirebaseStorage();
    await fs.init(app.name);
    final repository = TestRepository(
      localStorage: localStorage,
      remoteStorages: {'FirebaseRealtimeDatabase': fs},
    );
    // user.storageKey must point to the connected storage so the repository
    // routes user- and domain-scoped models to it.
    final user = User(id: userId, name: userId, storageKey: 'FirebaseRealtimeDatabase');
    await localStorage.storeItems({user.id: user});
    repository.myId = user.id;
    // Register the user in the remote storage with a derived password.
    // Register the user in the remote storage with a derived password.
    await fs.createUserAndAuth(user.id, 'secret-$userId');
    // Point the user's default remote storage at the already-initialized
    // Firebase app of this test, then start the sync timer. Without init()
    // the repository stays in the pre-init state and debounced (non-immediate)
    // saves never reach remote.
    user.settings['remote_storages'] = {
      'FirebaseRealtimeDatabase': {'instance': app.name}
    };
    user.secrets['remote_storages']['FirebaseRealtimeDatabase']['hashed_password'] = 'secret-$userId';
    await repository.init();
    return (repository, user);
  }

  group('two-user collaboration against emulator', () {
    test('task created by A assigned to B becomes visible and completable by B',
        () async {
      final (repoA, userA) = await createUserAndRepo(
          'ua${DateTime.now().millisecondsSinceEpoch}');
      final (repoB, userB) = await createUserAndRepo(
          'ub${DateTime.now().millisecondsSinceEpoch}');

      // A creates a domain with participants [A, B].
      final domain = Domain(
        originatorId: userA.id,
        title: 'collab',
        storageKey: 'FirebaseRealtimeDatabase',
      );
      domain.participantsIds.addAll([userA.id, userB.id]);
      await repoA.saveModels([domain, userA], null, true);

      // A saves a Task assigned to B inside the domain.
      final task = Task(
        title: 'shared task',
        originatorId: userA.id,
        executorId: userB.id,
      );
      task.link(from: domain);
      domain.link(to: task);
      await repoA.saveModels([task, domain], null, true);

      // B syncs and sees the task (deterministic pull, not realtime streams).
      final seen = await repoB.getModelNow<Task>(task.id);
      expect(seen, isNotNull, reason: 'B must see the task created by A');
      expect(seen!.executorId, userB.id);
      expect(seen.isCompleted, isFalse);

      // B pulls the task's parent domain (and its registry) into local
      // storage: without them the repository cannot route the task to the
      // domain's remote storage and would fork a new registry instead of
      // appending to A's chain.
      final remoteB0 = repoB.connectedStorages['FirebaseRealtimeDatabase']!;
      final parentDomainId = seen.parents.keys.first;
      final parentDomain = await repoB.getModelNow<Domain>(parentDomainId);
      expect(parentDomain, isNotNull, reason: 'B must see the parent domain');
      final domainRegistry =
          await remoteB0.readRegistry(parentDomain!.registryId);
      expect(domainRegistry, isNotNull,
          reason: 'B must see the domain registry');
      await repoB.localStorage.storeItems({
        domainRegistry!.id!: domainRegistry,
        parentDomain.id: parentDomain,
      });

      // B updates the task: isCompleted = true.
      final updated = seen.copyWith(isCompleted: true);
      updated.link(from: parentDomain);
      parentDomain.link(to: updated);
      await repoB.saveModels([updated, parentDomain], null, true);

      // A reads and sees completion. A has its own (stale, local-first) copy,
      // so verify the completion through the remote storage, polling until
      // B's debounced sync lands.
      final remoteA = repoA.connectedStorages['FirebaseRealtimeDatabase']!;
      Model? readBack;
      for (var i = 0; i < 100 && readBack is! Task; i++) {
        final item = await remoteA.getItem(id: task.id);
        if (item is Task && item.isCompleted) readBack = item;
        if (readBack is! Task) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      expect(readBack, isNotNull, reason: 'A must see the task completed by B');
      expect((readBack as Task).isCompleted, isTrue);
    });

    test('InvitationService acquaintance round trip between two repositories',
        () async {
      final (repoA, userA) = await createUserAndRepo(
          'ia${DateTime.now().millisecondsSinceEpoch}');
      final (repoB, userB) = await createUserAndRepo(
          'ib${DateTime.now().millisecondsSinceEpoch}');

      final serviceA = InvitationService(repoA);
      final serviceB = InvitationService(repoB);

      // B scans A's QR and sends an acquaintance invitation to A.
      final invitation = await serviceB.sendAcquaintanceInvitation(
        initiatorId: userA.id,
        initiatorName: userA.name,
        storageKey: 'FirebaseRealtimeDatabase',
        storageInstance: project,
      );
      expect(invitation.inviteeId, userA.id);

      // A accepts incoming invitations: a mutual domain must be created.
      final domains = await serviceA.acceptAcquaintanceInvitations();
      expect(domains, isNotEmpty,
          reason: 'A must accept the invitation sent by B');
      final domain = domains.first;
      expect(domain.participantsIds, containsAll([userA.id, userB.id]));

      // B sees the shared domain too. The domain lands in the remote storage
      // asynchronously (debounced sync), so poll for it.
      final remoteB = repoB.connectedStorages['FirebaseRealtimeDatabase']!;
      Domain? seen;
      for (var i = 0; i < 100 && seen == null; i++) {
        final item = await remoteB.getItem(id: domain.id);
        if (item is Domain) seen = item;
        if (seen == null) {
          await Future.delayed(const Duration(milliseconds: 200));
        }
      }
      expect(seen, isNotNull, reason: 'B must see the shared domain');
      expect(seen!.participantsIds, containsAll([userA.id, userB.id]));
    });
  });
}
