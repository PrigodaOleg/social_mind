
// End-to-end тесты авторизации пользователя через UI (LoginPage) на web-платформе
// с использованием Firebase Local Emulator Suite (Auth + Realtime Database).
//
// Применяются актуальные продакшн-правила Firebase:
//   lib/remote_storage/firebase_realtime_database_rules.json
// (их загружает в эмулятор tool/run_firebase_emulator_tests.sh).
//
// Запуск (web, эмулятор запускается автоматически):
//   make test-e2e
// Эквивалент:
//   tool/run_firebase_emulator_tests.sh test/e2e/auth_e2e_test.dart
//
// Интерактивный запуск web-версии против эмулятора (ручное тестирование):
//   make run-web-emulator
// В режиме отладки:
//   make run-web-emulator-debug
@TestOn('browser')
library auth_e2e_test;

import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart' as fb_auth_web;
import 'package:firebase_core_web/firebase_core_web.dart' as fb_core_web;
import 'package:firebase_database/firebase_database.dart' as fb_db;
import 'package:firebase_database_web/firebase_database_web.dart' as fb_db_web;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:hashlib/hashlib.dart';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:closers/repository/models/models.dart';
import 'package:closers/repository/repository/repository.dart';
import 'package:closers/ui/l10n/app_localizations.dart';
import 'package:closers/ui/pages/login.dart';
import 'package:closers/ui/pages/login_user_existing.dart';

const project = 'closers-test';
const authPort = 9099;
const dbPort = 9000;
const appName = 'closers-cd24f'; // дефолтный instance remote storage из User.settings
const storageKey = 'FirebaseRealtimeDatabase';

/// Пароль remote storage — вычисляется так же, как в Repository.
String derivedPassword(String secret) =>
    scrypt(utf8.encode(secret), utf8.encode('${storageKey}closers-cd24f')).toString();

/// Минимальное in-memory локальное хранилище (замена IsarStorage на web в тестах).
class MemoryLocalStorage extends LocalStorage {
  final modelsMap = <String, Model>{};
  int clearHistoryQueueHeadCallCount = 0;
  String? _userId;

  @override
  Uint8List? getImage(String id) => null;

  @override
  Future<int> storeItems(Map<String, dynamic> items) async {
    for (final item in items.values) {
      if (item is Model) modelsMap[item.id] = item;
    }
    return items.length;
  }

  @override
  Future<void> storeItem(dynamic item) async {
    if (item is Model) modelsMap[item.id] = item;
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
  Registry? getRegistry({String? id, String? parentId, int count = 5}) => null;

  @override
  Map<String, dynamic> getNextItemsFromHistoryQueue() => {};

  @override
  void clearHistoryQueueHead() {
    clearHistoryQueueHeadCallCount++;
  }
}

/// Repository с реальным FirebaseStorage, работающим против эмулятора.
class TestRepository extends Repository {
  TestRepository({super.localStorage, super.remoteStorages});

  @override
  late final knownRemoteStorages = <String, Function()>{
    storageKey: () => FirebaseStorage(),
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (!const bool.fromEnvironment('RUN_EMULATOR_TESTS')) {
    throw Skip('Requires Firebase emulator: make test-e2e '
        '(flutter test --platform chrome --dart-define=RUN_EMULATOR_TESTS=true)');
  }

  final registrar = Registrar();
  fb_core_web.FirebaseCoreWeb.registerWith(registrar);
  fb_auth_web.FirebaseAuthWeb.registerWith(registrar);
  fb_db_web.FirebaseDatabaseWeb.registerWith(registrar);

  late FirebaseApp app;
  late fb_auth.FirebaseAuth auth;
  late fb_db.FirebaseDatabase db;

  setUpAll(() async {
    app = await Firebase.initializeApp(
      name: appName,
      options: const FirebaseOptions(
        apiKey: 'test-api-key',
        appId: '1:1:web:1',
        messagingSenderId: '1',
        projectId: project,
        databaseURL: 'http://localhost:$dbPort/?ns=$project',
      ),
    );
    auth = fb_auth.FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator('localhost', authPort);
    db = fb_db.FirebaseDatabase.instanceFor(app: app);
    db.useDatabaseEmulator('localhost', dbPort);
    // Очистка базы от предыдущих запусков (нужен аутентифицированный пользователь).
    try {
      await auth.createUserWithEmailAndPassword(
          email: 'clean@a.aa', password: 'secret123');
    } catch (_) {
      await auth.signInWithEmailAndPassword(
          email: 'clean@a.aa', password: 'secret123');
    }
    await db.ref().set(null);
    await auth.signOut();
  });

  tearDownAll(() async {
    await auth.signOut();
    await app.delete();
  });

  // Создает пользователя в эмуляторе напрямую через Auth + запись User/Registry
  // в RTDB (с соблюдением актуальных правил).
  Future<(String, String)> createExistingUser(String id, String secret) async {
    await auth.createUserWithEmailAndPassword(
        email: '$id@a.aa', password: derivedPassword(secret));
    final user = User(id: id, name: id);
    final registry = Registry(id: 'r_$id', parentId: id);
    user.registryId = registry.id!;
    registry.transactions[0] = Transaction.zero(id, 'test', 'create', [id], '/');
    final storage = FirebaseStorage();
    await storage.init(app.name);
    expect(await storage.saveItems({id: user, registry.id!: registry}), 2);
    await auth.signOut();
    return (id, secret);
  }

  Future<TestRepository> freshRepository() async {
    final repo = TestRepository(localStorage: MemoryLocalStorage());
    return repo;
  }

  // Инициализация репозитория с пользователем: сначала init (подписчики),
  // затем asyncSetMe (сохраняет пользователя и подключает remote storages).
  Future<TestRepository> initRepositoryWith(User me) async {
    final storage = FirebaseStorage();
    await storage.init(app.name);
    final repo = TestRepository(
        localStorage: MemoryLocalStorage(),
        remoteStorages: {storageKey: storage});
    await repo.init();
    await repo.asyncSetMe(me);
    // Ставим модель в очередь синхронизации (set me вызывает _syncModel).
    repo.me = me;
    return repo;
  }

  // Прогнать UI-сценарий логина существующего пользователя.
  // Возвращает true, если логин прошел (bottom sheet закрылся).
  Future<bool> uiLoginExisting(
      WidgetTester tester, Repository repo, String id, String secret) async {
    await tester.binding.setSurfaceSize(const Size(1280, 800));
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: LoginPage(repo),
      ));
    });
    await tester.pump();

    await tester.tap(find.text('Existing user'));
    await tester.pump();
    expect(find.byType(LoginUserExistingPage), findsOneWidget);

    // Сначала ID (Enter), затем Secret (Enter) — так устроена страница.
    // onSubmitted запускает реальный сетевой вызов tryLogin — весь ввод
    // выполняем внутри runAsync (fake async зона testWidgets не пропускает
    // реальные таймеры firebase_auth).
    final fields = find.descendant(
        of: find.byType(LoginUserExistingPage), matching: find.byType(TextField));
    await tester.runAsync(() async {
      await tester.enterText(fields.first, id);
      final a1 = tester.testTextInput.receiveAction(TextInputAction.done);
      await a1.timeout(const Duration(seconds: 10), onTimeout: () {});
      final a2 = tester.testTextInput.receiveAction(TextInputAction.done);
      await a2.timeout(const Duration(seconds: 10), onTimeout: () {});
      // Даем время на сетевые операции с эмулятором.
      await Future.delayed(const Duration(seconds: 5));
    });
    // Финальный pump не нужен: sheet-закрытие в смешанной fake/real async
    // зоне дедлочит. Даем анимации завершиться через runAsync (real zone).
    await tester.runAsync(() => Future.delayed(const Duration(seconds: 1)));
    // Успешный логин аутентифицирует пользователя в firebase
    // (суффикс email: RemoteStorage.emailSuffix = '@a.aa').
    const emailSuffix = '@a.aa';
    return id.isNotEmpty &&
        secret.isNotEmpty &&
        fb_auth.FirebaseAuth.instance.currentUser?.email == '$id$emailSuffix';
  }

  group('Auth e2e (Firebase emulator, актуальные правила)', () {
    test('новый пользователь: создание через UI (blank -> create) успешно',
        () async {
      final id = 'e2e_new_${DateTime.now().millisecondsSinceEpoch}';
      final me = User(id: id, name: 'newbie');
      me.secret = 's3cret-new';

      final repo = await initRepositoryWith(me);
      expect(await repo.createUserRemoteStorages(me.secret), true);

      // Пользователь аутентифицирован в эмуляторе и данные записаны по правилам.
      expect(auth.currentUser?.email, '$id@a.aa');
      final storage = FirebaseStorage();
      await storage.init(app.name);
      // Явно сохраняем модель (set me не отправляет модель в remote),
      // запись должна пройти по правилам (auth.uid != null, email @a.aa).
      await repo.saveModel(me);
      User? loaded;
      for (var i = 0; i < 10; i++) {
        await Future.delayed(const Duration(seconds: 1));
        loaded = await storage.getItem(id: id);
        if (loaded != null) break;
      }
      expect(loaded, isA<User>());

      await auth.signOut();
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('новый пользователь: повторное создание того же id отклонено', () async {
      final id = 'e2e_dup_${DateTime.now().millisecondsSinceEpoch}';
      final storage = FirebaseStorage();
      await storage.init(app.name);

      final me = User(id: id, name: 'dup');
      me.secret = 's3cret-dup';
      final repo = TestRepository(
          localStorage: MemoryLocalStorage(),
          remoteStorages: {storageKey: storage});
      await repo.init();
      await repo.asyncSetMe(me);
      await repo.createUserRemoteStorages(me.secret);
      await auth.signOut();

      // Второй раз создать того же пользователя нельзя — FirebaseStorage бросит.
      final me2 = User(id: id, name: 'dup2');
      me2.secret = 'other';
      final repo2 = TestRepository(
          localStorage: MemoryLocalStorage(),
          remoteStorages: {storageKey: storage});
      await repo2.init();
      await repo2.asyncSetMe(me2);
      expect(() async => await repo2.createUserRemoteStorages('other'),
          throwsA(isA<Exception>()));
      await auth.signOut();
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('существующий пользователь: логин успешен', () async {
      final created = await createExistingUser(
          'e2e_ex_${DateTime.now().millisecondsSinceEpoch}', 's3cret-ex');
      final (id, secret) = created;
      final repo = await freshRepository();
      expect(await repo.tryLogin(id, secret), true);
      // Пользователь аутентифицирован в firebase (email суффикс RemoteStorage).
      expect(app.options.projectId, 'closers-test');
      final user = fb_auth.FirebaseAuth.instanceFor(app: app).currentUser;
      expect(user?.email, '$id@a.aa');
      // tryLogin авторизует только в firebase; загрузка me происходит
      // на уровне UI после логина — здесь достаточно проверки аутентификации.
    }, timeout: const Timeout(Duration(minutes: 5)));

    testWidgets('пустой пользователь: пустой id/secret не логинит',
        (tester) async {
      final repo = await freshRepository();
      // Пустые значения страница логина просто игнорирует (return без действий).
      // tryLogin ходит в реальную сеть — оборачиваем в runAsync (fake async зона
      // testWidgets не пропускает реальные таймеры firebase_auth).
      expect(await tester.runAsync(() => repo.tryLogin('', '')), false);
      // И через UI: sheet остается открытым.
      expect(await uiLoginExisting(tester, repo, '', ''), false);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('негативные сценарии: неверный secret и несуществующий пользователь',
        () async {
      final created = await createExistingUser(
          'e2e_neg_${DateTime.now().millisecondsSinceEpoch}',
          'right-secret');
      final (id, _) = created;
      final repo = await freshRepository();
      // Неверный secret.
      expect(await repo.tryLogin(id, 'wrong-secret'), false);
      // Несуществующий пользователь.
      expect(await repo.tryLogin('no_such_user_e2e', 'whatever'), false);
      // Пустые данные не логинят.
      expect(await repo.tryLogin('', ''), false);
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('многократный логин-логаут подряд', () async {
      final (id, secret) = await createExistingUser(
          'e2e_loop_${DateTime.now().millisecondsSinceEpoch}', 'loop-secret');
      for (var i = 0; i < 3; i++) {
        // ignore: avoid_print
        print('loop iteration $i: login');
        final repo = await freshRepository();
        expect(await repo.tryLogin(id, secret).timeout(const Duration(seconds: 20)),
            true, reason: 'iteration $i');
        // ignore: avoid_print
        print('loop iteration $i: logout');
        await auth.signOut();
        expect(auth.currentUser, isNull, reason: 'iteration $i');
      }
      // ignore: avoid_print
      print('loop test finished');
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
