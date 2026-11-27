// Shared body of the two-device acquaintance e2e. DO NOT run this file
// directly — it has no main(); the entrypoints are
// acquaintance_e2e_initiator_test.dart (shows the QR, AYya T1) and
// acquaintance_e2e_scanner_test.dart (scans it with the camera, A15).
//
// The role is a function argument baked into each entrypoint source, NOT a
// --dart-define: two parallel `flutter test` processes share one kernel build
// cache, and a role passed as a dart-define gets baked into the compiled
// kernel — the second process' kernel wins and BOTH devices end up running
// the same role (observed: both opened the camera). Distinct entrypoint files
// compile distinct kernels, so the roles cannot collide.
//
// Both roles drive the REAL app UI (InvitationPage + QrScannerPage with the
// real camera); all data-sync assertions are Repository-level
// (auth_e2e_test.dart style) against the Firebase emulators (adb reverse
// 127.0.0.1). The runner (tool/run_acquaintance_e2e.sh, Makefile:
// test-acquaintance-e2e) starts both `flutter test` processes and passes the
// shared run id via --dart-define=E2E_RUN_ID.
import 'dart:io' show Platform;
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/firebase_realtime_database.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/state/invitation/invitation.dart';
import 'package:closers/ui/l10n/app_localizations.dart';
import 'package:closers/ui/pages/invitation.dart';

const project = 'closers-test';
const authPort = 9099;
const dbPort = 9000;

const runIdDefine = String.fromEnvironment('E2E_RUN_ID');
const emulatorHostDefine = String.fromEnvironment('E2E_EMULATOR_HOST');

final String emulatorHost = emulatorHostDefine.isNotEmpty
    ? emulatorHostDefine
    : (Platform.isAndroid ? '10.0.2.2' : 'localhost');

/// Poll [predicate] until true or [timeout] elapses.
Future<bool> waitUntil(Future<bool> Function() predicate,
    {Duration timeout = const Duration(seconds: 60),
    Duration step = const Duration(milliseconds: 500)}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (await predicate()) return true;
    await Future<void>.delayed(step);
  }
  return false;
}

/// Minimal in-memory LocalStorage (same trick as auth_e2e_test.dart):
/// only what Repository actually touches in this scenario.
class MemoryLocalStorage extends LocalStorage {
  final modelsMap = <String, Model>{};
  final registriesMap = <String, Registry>{};
  final historyQueue = <String, Model>{};
  String? _userId;

  @override
  Uint8List? getImage(String id) => null;

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
  Future<void> storeItem(dynamic item) async {
    await storeItems({if (item is Model) item.id: item});
  }

  @override
  Future<int> storeItems(Map<String, dynamic> items) async {
    for (final item in items.values) {
      if (item is Model) {
        // База для 3-way ребейза на коллизии: состояние ДО изменения (так же
        // снимает head-пакет IsarStorage). Для новой модели база - само
        // создание. putIfAbsent: база окна синхронизации - первое состояние,
        // повторные записи в окне ее не затирают (иначе базой ребейза станет
        // само новое состояние, ребейз сочтет поля неизмененными локально и
        // приоритет отдаст remote - локальные правки терялись: rename домена
        // не доезжал до второй стороны).
        historyQueue.putIfAbsent(item.id, () => modelsMap[item.id] ?? item);
        modelsMap[item.id] = item;
      }
      if (item is Registry) registriesMap[item.id!] = item;
    }
    return items.length;
  }

  @override
  Future<void> deleteItem(String id) async {
    modelsMap.remove(id);
  }

  @override
  Registry? getRegistry({String? id, String? parentId, int count = 5}) {
    if (id != null) return registriesMap[id];
    if (parentId != null) {
      // The parent's registry id is stored on Domain/User.registryId.
      final parent = modelsMap[parentId];
      final regId = parent is Domain
          ? parent.registryId
          : parent is User
              ? parent.registryId
              : null;
      return regId == null ? null : registriesMap[regId];
    }
    return null;
  }

  @override
  Map<String, dynamic> getNextItemsFromHistoryQueue() {
    // Неразрушающее чтение head-пакета (как в IsarStorage): пакет живет до
    // clearHistoryQueueHead после успешной отправки, повторный getNext до
    // того вернет ту же базу ребейза.
    return Map<String, dynamic>.from(historyQueue);
  }

  @override
  void clearHistoryQueueHead() {
    historyQueue.clear();
  }
}

class TestRepository extends Repository {
  TestRepository({super.localStorage, super.remoteStorages});
}

void runAcquaintanceE2e(String role) {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  // Per-run unique ids (the runner passes the same runId to both processes).
  final String myId = '${role}_$runIdDefine';
  final String peerId =
      '${role == 'initiator' ? 'scanner' : 'initiator'}_$runIdDefine';

  testWidgets(
      'acquaintance e2e [$role]: camera QR handshake, shared domain, two-way task sync',
      (tester) async {
    final app = await Firebase.initializeApp(
      name: 'e2e-acq',
      options: FirebaseOptions(
        apiKey: 'AIzaSyD-9tJkeQsLFVi_9NvNleKzLb42i9SBnPo',
        appId: '1:1:android:1',
        messagingSenderId: '1',
        projectId: project,
        databaseURL: 'http://$emulatorHost:$dbPort/?ns=$project',
      ),
    );
    // Без этого FirebaseAuth на Android уходит в ПРОДАКШН-API, где тестовый
    // apiKey невалиден ("API key not valid"). automaticHostMapping: false —
    // firebase_core на Android молча подменяет "localhost"/"127.0.0.1" на
    // 10.0.2.2 (алиас эмулятора), недостижимый с физического устройства
    // (см. auth_e2e_test.dart setUpAll).
    final auth = fb_auth.FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator(emulatorHost, authPort, automaticHostMapping: false);

    final fs = FirebaseStorage();
    await fs.init(app.name);
    final repo = TestRepository(
      localStorage: MemoryLocalStorage(),
      remoteStorages: {'FirebaseRealtimeDatabase': fs},
    );
    final service = InvitationService(repo);

    // Register the user in the auth emulator and configure the remote
    // storage exactly like the real login does (createUserAndRepo pattern
    // from collaboration_emulator_test.dart).
    final password = 'e2e-secret-$myId';
    try {
      await fs.createUserAndAuth(myId, password);
    } on Exception catch (e) {
      // Страховка от перезапусков/гонок: аккаунт с этим runId уже существует
      // (например, предыдущий прогон упал после регистрации) — входим.
      if (e.toString().contains('email-already-in-use')) {
        await fs.auth(myId, password);
      } else {
        rethrow;
      }
    }
    final me = User(
      id: myId,
      name: role == 'initiator' ? 'Initiator' : 'Scanner',
      storageKey: 'FirebaseRealtimeDatabase',
    );
    me.settings['remote_storages'] = {
      'FirebaseRealtimeDatabase': {'instance': app.name}
    };
    me.secrets['remote_storages']['FirebaseRealtimeDatabase']['hashed_password'] =
        password;
    await repo.localStorage.storeItems({me.id: me});
    repo.myId = me.id;
    await repo.init();

    // Real InvitationPage. NOTE: the page creates its OWN InvitationBloc
    // internally (BlocProvider create: ...) — an externally provided bloc
    // would never see the UI events (observed: the QR was rendered on screen
    // while the external bloc's state stayed null), so after pumping we grab
    // the page's bloc from the element tree and use it for the waits below.
    await tester.pumpWidget(
      MaterialApp(
        // Fix the locale: the physical device may be localized differently
        // (ru-RU on the Samsung Galaxy A15).
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InvitationPage(repo),
      ),
    );
    await tester.pumpAndSettle();
    final bloc =
        tester.element(find.byType(InvitationView)).read<InvitationBloc>();

    // ------------------------------------------------------------ Phase 1 --
    // Physical handshake: the initiator shows the QR on screen; the scanner
    // opens the camera (QrScannerPage) and scans it. Both test processes run
    // in parallel; the phones are on the same desk facing each other.
    Domain? sharedDomain;

    if (role == 'scanner') {
      // The runner grants CAMERA as soon as the app process appears on the
      // device (a fresh install resets runtime permissions, and the system
      // permission dialog would silently block the camera page); give the
      // grant a moment to land before opening the camera.
      await Future<void>.delayed(const Duration(seconds: 3));

      // SCANNER: open the camera page and scan the initiator's QR.
      await tester.tap(find.text('Scan QR'));
      await tester.pumpAndSettle();
      debugPrint(
          'E2E acquaintance [$role]: camera open, point this phone at the initiator QR');

      // QrScannerPage pops with the raw value and InvitationPage dispatches
      // AcquaintanceQrScanned itself; wait for the bloc's lastAction.
      final sent = await waitUntil(() async {
        await tester.pump(const Duration(milliseconds: 500));
        return bloc.state.lastAction?.startsWith('acquaintance_sent') == true;
      }, timeout: const Duration(minutes: 5));
      expect(bloc.state.error, isNull,
          reason: 'scanner failed to send the acquaintance: ${bloc.state.error}');
      expect(sent, isTrue,
          reason: 'camera never scanned the initiator QR (aim at the QR screen)');
      await tester.pumpAndSettle();
    }

    if (role == 'initiator') {
      // INITIATOR: show my QR and wait for the scanner's invitation.
      await tester.tap(find.text('Show my QR'));
      await tester.pump();
      final qrShown = await waitUntil(() async {
        await tester.pump();
        return bloc.state.acquaintanceQrPayload != null;
      });
      expect(qrShown, isTrue, reason: 'QR payload must be rendered on screen');
      debugPrint('E2E acquaintance [$role]: QR is on screen, waiting for the scanner');

      // Poll the product accept path until the scanner's invitation arrives
      // and is processed (idempotent).
      final accepted = <Domain>[];
      final got = await waitUntil(() async {
        accepted
          ..clear()
          ..addAll(await service.acceptAcquaintanceInvitations());
        await tester.pump();
        return accepted.isNotEmpty;
      }, timeout: const Duration(minutes: 5));
      expect(got, isTrue,
          reason: 'initiator never received the acquaintance invitation');
      sharedDomain = accepted.first;
    }

    // ------------------------------------------------------------ Phase 2 --
    // Data sync through the shared domain, asserted on model level.
    // NOTE: sharedDomain is set only on the initiator; the scanner gets the
    // domain later (joined.first) — hence `late`, not `sharedDomain!`.
    late Domain domain;
    Task? initiatorTask;
    String? ownTaskId;

    if (role == 'initiator') {
      domain = sharedDomain!;
      expect(domain.participantsIds.contains(myId), isTrue);
      expect(domain.participantsIds.contains(peerId), isTrue);

      // Task created by the initiator inside the shared domain.
      final task = Task(title: 'e2e task from initiator', originatorId: myId);
      task.link(from: domain);
      domain.link(to: task);
      await repo.saveModels([task, domain], null, true);
      initiatorTask = task;
    } else {
      // The domainJoin invitation lands in MY inbox; accept it through the
      // product path (acceptAcquaintanceInvitations -> domainJoin branch).
      final joined = <Domain>[];
      final joinedOk = await waitUntil(() async {
        joined
          ..clear()
          ..addAll(await service.acceptAcquaintanceInvitations());
        return joined.isNotEmpty;
      }, timeout: const Duration(minutes: 5));
      expect(joinedOk, isTrue,
          reason: 'scanner never received/accepted the domainJoin invitation');
      domain = joined.first;
      expect(domain.participantsIds.contains(myId), isTrue);
      expect(domain.participantsIds.contains(peerId), isTrue);

      // Discover the initiator's task through the domain children (fresh
      // remote read: the local copy may not have the task yet).
      final domainId = domain.id;
      String? taskId;
      final taskAppeared = await waitUntil(() async {
        final remoteDomain = await fs.getItem(id: domainId) as Domain?;
        if (remoteDomain == null) return false;
        taskId = remoteDomain.children.entries
            .where((e) => e.value == 'Task')
            .map((e) => e.key)
            .firstOrNull;
        return taskId != null;
      });
      expect(taskAppeared, isTrue,
          reason: 'scanner never saw the initiator task in the shared domain');
      final task = await repo.getModelNow<Task>(taskId!);
      expect(task, isNotNull, reason: 'task must be readable from remote');
      expect(task!.title, 'e2e task from initiator');

      // Reverse direction: the scanner creates its own task in the domain.
      final ownTask = Task(
        title: 'e2e task from scanner',
        originatorId: myId,
        executorId: peerId,
      );
      ownTask.link(from: domain);
      domain.link(to: ownTask);
      await repo.saveModels([ownTask, domain], null, true);
      ownTaskId = ownTask.id;
    }

    // Status change: scanner completes the initiator's task; initiator sees it.
    if (role == 'scanner') {
      final domainNow = await fs.getItem(id: domain.id) as Domain;
      // There are 2 tasks in the domain by now; pick the INITIATOR's one.
      final initiatorTaskId = domainNow.children.entries
          .where((e) => e.value == 'Task')
          .map((e) => e.key)
          .firstWhere((id) => id != ownTaskId);
      final task = await repo.getModelNow<Task>(initiatorTaskId);
      expect(task, isNotNull, reason: 'initiator task must be readable');
      // NOTE: Task.copyWith drops parents/children, but the registry routing
      // uses the task's parents - copyWith is the product path here
      // (TaskListBloc._onComplete), so we use it too.
      final completed = task!.copyWith(isCompleted: true);
      await repo.saveModels([completed], null, true);
    } else {
      final iTask = initiatorTask!;
      final done = await waitUntil(() async {
        final remote = await fs.getItem(id: iTask.id) as Task?;
        return remote?.isCompleted ?? false;
      }, timeout: const Duration(minutes: 3));
      expect(done, isTrue, reason: 'initiator never saw the completion');
    }

    // Rename: the initiator renames the shared domain; the scanner must see
    // the new title through the remote domain model.
    if (role == 'initiator') {
      final renamed = domain.copyWith(title: 'e2e renamed domain');
      await repo.saveModels([renamed], null, true);
    } else {
      final domainId = domain.id;
      final renamed = await waitUntil(() async {
        final remote = await fs.getItem(id: domainId) as Domain?;
        return remote?.title == 'e2e renamed domain';
      });
      expect(renamed, isTrue, reason: 'scanner never saw the domain rename');
    }

    // Deletion: each side deletes the OTHER side's task; both must see them
    // disappear from the remote storage.
    if (role == 'scanner') {
      // Find the initiator's task in the domain children and delete it.
      final domainNow = await fs.getItem(id: domain.id) as Domain;
      final initiatorTaskId = domainNow.children.entries
          .where((e) => e.value == 'Task')
          .map((e) => e.key)
          .first;
      final task = await repo.getModelNow<Task>(initiatorTaskId);
      expect(task, isNotNull);
      repo.deleteModel(task!);
      final gone = await waitUntil(() async {
        final remote = await fs.getItem(id: initiatorTaskId) as Task?;
        return remote == null;
      });
      expect(gone, isTrue, reason: 'initiator task still visible after delete');
    } else {
      final iTask = initiatorTask!;
      // Find the scanner's task id in the domain children (2 tasks total).
      final domainNow = await fs.getItem(id: domain.id) as Domain;
      final scannerTaskId = domainNow.children.entries
          .where((e) => e.value == 'Task')
          .map((e) => e.key)
          .firstWhere((id) => id != iTask.id);
      final scannerTask = await repo.getModelNow<Task>(scannerTaskId);
      expect(scannerTask, isNotNull,
          reason: 'scanner task must be readable before delete');
      // Each side deletes the OTHER side's task: the initiator deletes the
      // scanner's one (deletion is routed by the task's parents - the local
      // copy fetched via getModelNow carries them).
      repo.deleteModel(scannerTask!);
      final gone = await waitUntil(() async {
        final remote = await fs.getItem(id: scannerTaskId) as Task?;
        return remote == null;
      });
      expect(gone, isTrue, reason: 'scanner task still visible after delete');
    }

    await bloc.close();
    await app.delete();
  });
}
