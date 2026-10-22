

import 'dart:async';

import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/firebase_core_platform_interface.dart';
import 'package:firebase_core_platform_interface/test.dart';
import 'package:firebase_database_platform_interface/src/pigeon/messages.pigeon.dart'
    as pigeon;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:closers/remote_storage/remote_storage.dart' as rs;
import 'package:closers/repository/models/models.dart' as models;

// --- Firebase core mocks ----------------------------------------------------

class MockFirebaseCoreHostApi implements TestFirebaseCoreHostApi {
  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async {
    return CoreInitializeResponse(
      name: appName,
      options: CoreFirebaseOptions(
        apiKey: '123',
        projectId: '123',
        appId: '123',
        messagingSenderId: '123',
      ),
      pluginConstants: {},
    );
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async {
    return [
      CoreInitializeResponse(
        name: defaultFirebaseAppName,
        options: CoreFirebaseOptions(
          apiKey: '123',
          projectId: '123',
          appId: '123',
          messagingSenderId: '123',
        ),
        pluginConstants: {},
      ),
    ];
  }

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async {
    return CoreFirebaseOptions(
      apiKey: '123',
      projectId: '123',
      appId: '123',
      messagingSenderId: '123',
    );
  }
}

class MockFirebaseAppHostApi implements TestFirebaseAppHostApi {
  @override
  Future<void> delete(String appName) async {}

  @override
  Future<void> setAutomaticDataCollectionEnabled(
      String appName, bool enabled) async {}

  @override
  Future<void> setAutomaticResourceManagementEnabled(
      String appName, bool enabled) async {}
}

// --- Auth mocks -------------------------------------------------------------

class TestFirebaseAuthPlatform extends FirebaseAuthPlatform {
  TestFirebaseAuthPlatform() : super();

  final List<String> createdUsers = [];
  final List<String> signedInUsers = [];
  final List<bool> tokenRequests = [];
  final List<String?> displayNames = [];
  String? currentUserUid = 'user-1';

  @override
  FirebaseAuthPlatform delegateFor(
          {FirebaseApp? app, Persistence? persistenceType}) =>
      this;

  @override
  FirebaseAuthPlatform setInitialValues(
      {InternalUserDetails? currentUser, String? languageCode}) {
    return this;
  }

  @override
  UserPlatform? get currentUser => currentUserUid == null
      ? null
      : TestUserPlatform(this, currentUserUid!);

  @override
  Future<UserCredentialPlatform> createUserWithEmailAndPassword(
      String email, String password) async {
    createdUsers.add(email);
    return _TestUserCredential(auth: this);
  }

  @override
  Future<UserCredentialPlatform> signInWithEmailAndPassword(
      String email, String password) async {
    signedInUsers.add(email);
    return _TestUserCredential(auth: this);
  }

  @override
  Future<String?> getIdToken(bool forceRefresh) async {
    tokenRequests.add(forceRefresh);
    return 'token';
  }

  @override
  Future<void> updateDisplayName(String? displayName) async {
    displayNames.add(displayName);
  }
}

class _TestUserCredential extends UserCredentialPlatform {
  _TestUserCredential({required FirebaseAuthPlatform auth}) : super(auth: auth);
}


class TestUserPlatform extends UserPlatform {
  TestUserPlatform(FirebaseAuthPlatform auth, String uid)
      : super(
          auth,
          _NoopMultiFactor(auth),
          InternalUserDetails(
            userInfo: InternalUserInfo(
              uid: uid,
              isAnonymous: false,
              isEmailVerified: true,
            ),
            providerData: [],
          ),
        );

  @override
  @override
  Future<String> getIdToken(bool forceRefresh, {bool? tokenOnly}) async {
    (auth as TestFirebaseAuthPlatform).tokenRequests.add(forceRefresh);
    return 'test-token';
  }

  @override
  Future<void> updateProfile(Map<String, String?> profile) async {
    print('DEBUG updateProfile: $profile, auth type: ${auth.runtimeType}');
    if (profile['displayName'] != null) {
      final m = auth as TestFirebaseAuthPlatform;
      m.displayNames.add(profile['displayName']!);
    }
  }
}

class _NoopMultiFactor extends MultiFactorPlatform {
  _NoopMultiFactor(FirebaseAuthPlatform auth) : super(auth);
}

// --- Database pigeon mock ---------------------------------------------------

class MockDatabaseApi {
  final List<Map<String, dynamic>> log = [];
  Map<String, Object?> getModelValue = {};
  Map<String, Object?> registryTransactions = {};
  Map<String, Object?> registryMetadata = {};
  PlatformException? updateError;

  static const _prefix =
      'dev.flutter.pigeon.firebase_database_platform_interface.FirebaseDatabaseHostApi.';

  void setUp() {
    void register(String method, Future<Object?> Function(List<Object?>) h) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(
        BasicMessageChannel<Object?>('$_prefix$method',
            pigeon.FirebaseDatabaseHostApi.pigeonChannelCodec),
        (Object? message) async =>
            <Object?>[await h(message! as List<Object?>)],
      );
    }

    register('goOnline', (_) async => null);
    register('goOffline', (_) async => null);
    register('setPersistenceEnabled', (_) async => null);
    register('setPersistenceCacheSizeBytes', (_) async => null);
    register('setLoggingEnabled', (_) async => null);
    register('useDatabaseEmulator', (_) async => null);
    register('ref', (args) async {
      final a = args[0]! as pigeon.DatabasePigeonFirebaseApp;
      return pigeon.DatabaseReferencePlatform(path: a.databaseURL ?? '');
    });
    register('refFromURL', (args) async =>
        pigeon.DatabaseReferencePlatform(path: ''));
    register('purgeOutstandingWrites', (_) async => null);

    register('databaseReferenceSet', (_) async => null);
    register('databaseReferenceSetWithPriority', (_) async => null);
    register('databaseReferenceSetPriority', (_) async => null);
    register('databaseReferenceRunTransaction', (_) async => null);
    register('databaseReferenceGetTransactionResult', (_) async => null);
    register('databaseReferenceUpdate', (args) async {
      final request = args[1]! as pigeon.UpdateRequest;
      log.add({'method': 'update', 'value': request.value});
      if (updateError != null) throw updateError!;
      return null;
    });

    register('onDisconnectSet', (_) async => null);
    register('onDisconnectSetWithPriority', (_) async => null);
    register('onDisconnectUpdate', (_) async => null);
    register('onDisconnectCancel', (_) async => null);

    register('queryObserve', (args) async {
      final request = args[1]! as pigeon.QueryRequest;
      log.add({'method': 'queryObserve', 'path': request.path});
      return 'handle-1';
    });
    register('queryKeepSynced', (_) async => null);
    register('queryGet', (args) async {
      final request = args[1]! as pigeon.QueryRequest;
      final path = request.path ?? '';
      log.add({'method': 'queryGet', 'path': path});
      if (path.startsWith('registries/') && path.endsWith('/transactions')) {
        return {
          'snapshot': {
            'key': 'transactions',
            'value': registryTransactions,
            'priority': null,
            'childKeys': registryTransactions.keys.toList(),
          }
        };
      }
      if (path == 'registries/reg-1/metadata') {
        return {
          'snapshot': {
            'key': 'metadata',
            'value': registryMetadata,
            'priority': null,
            'childKeys': registryMetadata.keys.toList(),
          }
        };
      }
      final value = getModelValue[path];
      if (value == null) return <String, Object?>{};
      return {
        'snapshot': {
          'key': path.split('/').last,
          'value': value,
          'priority': null,
          'childKeys': value is Map ? value.keys.toList() : <String>[],
        }
      };
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FirebaseApp app;
  late MockDatabaseApi mockDb;
  late TestFirebaseAuthPlatform mockAuth;
  late rs.FirebaseStorage storage;

  setUpAll(() {
    TestFirebaseCoreHostApi.setUp(MockFirebaseCoreHostApi());
    TestFirebaseAppHostApi.setUp(MockFirebaseAppHostApi());
    mockDb = MockDatabaseApi();
    mockDb.setUp();
  });

  setUp(() async {
    FirebaseAuthPlatform.instance = mockAuth = TestFirebaseAuthPlatform();
    mockDb.log.clear();
    mockDb.getModelValue = {};
    mockDb.registryTransactions = {};
    mockDb.registryMetadata = {};
    mockDb.updateError = null;
    app = await Firebase.initializeApp(
      name: 'testApp',
      options: const FirebaseOptions(
        appId: '1:1234567890:android:42424242424242',
        apiKey: '123',
        projectId: '123',
        messagingSenderId: '1234567890',
      ),
    );
    storage = rs.FirebaseStorage();
    await storage.init('testApp');
  });

  tearDown(() async {
    await app.delete();
  });

  group('FirebaseStorage init', () {
    test('init sets up database', () async {
      expect(storage.app, app);
    });
  });

  group('FirebaseStorage createUserAndAuth / auth', () {
    test('createUserAndAuth calls createUserWithEmailAndPassword', () async {
      final result = await storage.createUserAndAuth('vasya', 'pwd');
      expect(result, isTrue);
      expect(mockAuth.createdUsers, ['vasya@a.aa']);
    });

    test('createUserAndAuth with claim updates display name and token',
        () async {
      final result =
          await storage.createUserAndAuth('vasya', 'pwd', claim: 'claim-1');
      expect(result, isTrue);
      expect(mockAuth.createdUsers, ['vasya@a.aa']);
      expect(mockAuth.displayNames, ['claim-1']);
      expect(mockAuth.tokenRequests, isNotEmpty);
    });

    test('auth calls signInWithEmailAndPassword', () async {
      final result = await storage.auth('petya', 'pwd');
      expect(result, isTrue);
      expect(mockAuth.signedInUsers, ['petya@a.aa']);
    });
  });

  group('FirebaseStorage getItem', () {
    test('returns deserialized model by type', () async {
      mockDb.getModelValue['models/task-1'] = {
        'type': 'Task',
        'id': 'task-1',
        'title': 'do it',
        'originatorId': 'user-1',
        'executorId': 'user-2',
      };
      final item = await storage.getItem(id: 'task-1');
      expect(item, isA<models.Task>());
      expect((item as models.Task).id, 'task-1');
    });

    test('returns null when snapshot has no type key', () async {
      mockDb.getModelValue['models/x-1'] = {'id': 'x-1'};
      final item = await storage.getItem(id: 'x-1');
      expect(item, isNull);
    });

    test('returns null for unknown model type', () async {
      mockDb.getModelValue['models/x-2'] = {'type': 'Unknown', 'id': 'x-2'};
      final item = await storage.getItem(id: 'x-2');
      expect(item, isNull);
    });

    test('returns null when nothing exists', () async {
      final item = await storage.getItem(id: 'nope');
      expect(item, isNull);
    });
  });

  group('FirebaseStorage getItems', () {
    test('collects existing items and skips missing', () async {
      mockDb.getModelValue['models/t-1'] = {
        'type': 'Task',
        'id': 't-1',
        'title': 'one',
        'originatorId': 'u-1',
        'executorId': 'u-2',
      };
      final items = await storage.getItems(['t-1', 't-2']);
      expect(items.keys, ['t-1']);
      expect(items['t-1'], isA<models.Task>());
    });

    test('empty ids list does not observe', () async {
      final items = await storage.getItems(<String>[]);
      expect(items, isEmpty);
      expect(mockDb.log.where((e) => e['method'] == 'queryObserve'), isEmpty);
    });
  });

  models.Task task(String id) =>
      models.Task(id: id, title: 'x', originatorId: 'u');

  group('FirebaseStorage saveItems', () {
    test('saves model fields and list fields flattened', () async {
      final count = await storage.saveItems({'t-9': task('t-9')});
      expect(count, 1);
      final update = mockDb.log.firstWhere((e) => e['method'] == 'update');
      final updates = update['value'] as Map<String, Object?>;
      expect(updates['models/t-9/id'], 't-9');
      expect(updates['models/t-9/title'], 'x');
    });

    test('saves registry metadata and last transaction', () async {
      final registry = models.Registry(id: 'r-1', parentId: 'p-1');
      registry.addNewTransaction(models.Transaction(
        'tr-1',
        'prev-hash',
        'prev-id',
        DateTime.now(),
        'user-1',
        'details',
        'create',
        <String>['t-1'],
        'path',
      ));
      final count = await storage.saveItems({'r-1': registry});
      expect(count, 1);
      final update = mockDb.log.firstWhere((e) => e['method'] == 'update');
      final updates = update['value'] as Map<String, Object?>;
      expect(updates['registries/r-1/lastIdx'], 0);
      expect(updates['registries/r-1/metadata'], registry.metadata.toJson());
    });

    test('rethrows write collision on permission-denied', () async {
      mockDb.updateError = PlatformException(
        code: 'firebase_database',
        message: 'denied',
        details: {'code': 'permission-denied', 'message': 'denied'},
      );
      expect(
        () => storage.saveItems({'t-err': task('t-err')}),
        throwsA(isA<rs.RemoteStorageWriteCollision>()),
      );
    });

    test('swallows other FirebaseException codes', () async {
      mockDb.updateError = PlatformException(
        code: 'firebase_database',
        message: 'unavailable',
        details: {'code': 'unavailable', 'message': 'down'},
      );
      final count = await storage.saveItems({'t-err2': task('t-err2')});
      expect(count, 1);
    });

    test('swallows arbitrary errors', () async {
      mockDb.updateError = PlatformException(code: 'weird', message: '?');
      final count = await storage.saveItems({'t-err3': task('t-err3')});
      expect(count, 1);
    });
  });

  group('FirebaseStorage deleteItems', () {
    test('nulls out model paths', () async {
      final count = await storage.deleteItems({'t-del': task('t-del')});
      expect(count, 1);
      final update = mockDb.log.firstWhere((e) => e['method'] == 'update');
      expect((update['value'] as Map)['models/t-del'], isNull);
    });
  });

  group('FirebaseStorage readRegistry', () {
    test('reads metadata and last transactions', () async {
      mockDb.registryMetadata = {'id': 'reg-1', 'parentId': 'p-1'};
      mockDb.registryTransactions = {
        '0': {
          'id': 'tr-0',
          'prevHash': '',
          'prevId': '',
          'timeStamp': DateTime.now().toIso8601String(),
          'originatorId': 'u-1',
          'changeDetails': 'details',
          'changeType': 'create',
          'changes': <String>['t-1'],
          'path': 'path',
        }
      };
      final registry = await storage.readRegistry('reg-1');
      expect(registry, isNotNull);
      expect(registry!.metadata.id, 'reg-1');
      expect(registry.transactions[0], isA<models.Transaction>());
    });
  });
}

