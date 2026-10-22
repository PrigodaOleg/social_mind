import 'dart:typed_data';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/state/state.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory LocalStorage fake: keeps everything in maps so blocs and
/// repository calls can be exercised without any native database.
class FakeLocalStorage extends LocalStorage {
  final Map<String, dynamic> store = {};
  final Map<String, Uint8List> images = {};
  String? userId;
  bool initCalled = false;

  @override
  Future<void> init() async {
    initCalled = true;
  }

  @override
  String? getUserId() => userId;

  @override
  Future<void> setUserId(String id) async {
    userId = id;
  }

  @override
  Uint8List? getImage(String id) => images[id];

  @override
  Future<void> storeImage(String id, Uint8List imageBytes) async {
    images[id] = imageBytes;
  }

  @override
  dynamic getItem({required String id}) => store[id];

  @override
  Map<String, T> getItems<T>(List<String> ids) {
    final result = <String, T>{};
    for (final id in ids) {
      final item = store[id];
      if (item is T) result[id] = item;
    }
    return result;
  }

  @override
  Future<void> storeItem(dynamic item) async {
    store[item.id] = item;
  }

  @override
  Future<int> storeItems(Map<String, dynamic> items) async {
    store.addAll(items);
    return items.length;
  }

  @override
  Registry? getRegistry({String? id, String? parentId, int count = 5}) {
    if (id != null && store[id] is Registry) return store[id] as Registry;
    return null;
  }
}

Future<Repository> makeRepo({User? me}) async {
  final storage = FakeLocalStorage();
  final repo = Repository(localStorage: storage, remoteStorages: {});
  await repo.init();
  if (me != null) {
    repo.me = me;
    await Future.delayed(Duration.zero);
  }
  return repo;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Task model', () {
    test('constructor sets defaults and generates id', () {
      final task = Task(originatorId: 'u1');
      expect(task.id, isNotEmpty);
      expect(task.title, '');
      expect(task.description, '');
      expect(task.isCompleted, isFalse);
      expect(task.executorId, '');
      expect(task.type, 'Task');
      expect(task.location, Location.local);
      expect(task.children, isEmpty);
      expect(task.parents, isEmpty);
    });

    test('constructor accepts explicit id, title and executor', () {
      final task = Task(
          id: 't1',
          title: 'Do it',
          description: 'desc',
          originatorId: 'u1',
          executorId: 'u2');
      expect(task.id, 't1');
      expect(task.title, 'Do it');
      expect(task.description, 'desc');
      expect(task.executorId, 'u2');
    });

    test('constructor with empty id throws', () {
      expect(() => Task(id: '', originatorId: 'u1'),
          throwsA(isA<AssertionError>()));
    });

    test('toJson/fromJson roundtrip', () {
      final task = Task(
          id: 't1',
          title: 'Do it',
          description: 'desc',
          originatorId: 'u1',
          executorId: 'u2');
      task.children['d1'] = 'Domain';
      task.parents['u1'] = 'User';
      final json = task.toJson();
      final restored = Task.fromJson(json);
      expect(restored.id, 't1');
      expect(restored.title, 'Do it');
      expect(restored.description, 'desc');
      expect(restored.isCompleted, isFalse);
      expect(restored.originatorId, 'u1');
      expect(restored.executorId, 'u2');
      expect(restored.children, {'d1': 'Domain'});
      expect(restored.parents, {'u1': 'User'});
    });

    test('fromJson tolerates missing fields', () {
      final restored = Task.fromJson({'id': 't2'});
      expect(restored.title, '');
      expect(restored.isCompleted, isFalse);
      expect(restored.originatorId, '');
      expect(restored.executorId, '');
      expect(restored.children, isEmpty);
      expect(restored.parents, isEmpty);
    });

    test('copyWith replaces only given fields', () {
      final task = Task(id: 't1', title: 'a', originatorId: 'u1');
      final changed = task.copyWith(title: 'b', isCompleted: true);
      expect(changed.title, 'b');
      expect(changed.isCompleted, isTrue);
      expect(changed.id, 't1');
      expect(changed.originatorId, 'u1');
      // original untouched
      expect(task.title, 'a');
      expect(task.isCompleted, isFalse);
    });

    test('copyWith keeps id when omitted', () {
      final task = Task(originatorId: 'u1');
      expect(task.copyWith().id, task.id);
    });

    test('equality is by value via equatable props', () {
      final a = Task(id: 'x', title: 't', originatorId: 'u');
      final b = Task(id: 'x', title: 't', originatorId: 'u');
      expect(a, equals(b));
      final c = Task(id: 'x', title: 'other', originatorId: 'u');
      expect(a, isNot(equals(c)));
    });

    test('link/unlink mutate children and parents', () {
      final task = Task(originatorId: 'u');
      final child = Task(originatorId: 'u');
      task.link(to: child, from: child);
      expect(task.children, {child.id: 'Task'});
      expect(task.parents, {child.id: 'Task'});
      task.unlink(to: child, from: child);
      expect(task.children, isEmpty);
      expect(task.parents, isEmpty);
    });

    test('ids<T> filters children by type', () {
      final task = Task(originatorId: 'u');
      final sub = Task(originatorId: 'u');
      final domain = Domain(originatorId: 'u');
      task.link(to: sub);
      task.link(to: domain);
      expect(task.ids<Task>(), [sub.id]);
      expect(task.ids<Domain>(), [domain.id]);
    });

    test('locationFromString maps known and unknown values', () {
      expect(locationFromString('Location.remote'), Location.remote);
      expect(locationFromString('Location.both'), Location.both);
      expect(locationFromString('Location.local'), Location.local);
      expect(locationFromString(null), Location.local);
      expect(locationFromString('garbage'), Location.local);
    });
  });

  group('TaskListBloc', () {
    late Repository repo;
    late User me;
    late Domain domain;

    setUp(() async {
      me = User(id: 'me', name: 'me');
      repo = await makeRepo(me: me);
      domain = Domain(originatorId: me.id, title: 'root');
      await repo.saveModel(domain);
    });

    test('init loads parent tasks and adds a placeholder', () async {
      final t1 = Task(id: 't1', title: 'one', originatorId: me.id);
      await repo.saveModel(t1);
      await domain.linkTo(t1);

      final bloc = TaskListBloc(repository: repo, parentId: domain.id);
      bloc.add(TaskListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<TaskListState>()));

      final tasks = bloc.state.tasks;
      expect(tasks.keys, contains('t1'));
      // placeholder task is not completed and has empty title
      final placeholders = tasks.values
          .where((t) => t.id != 't1' && t.title == '')
          .toList();
      expect(placeholders.length, 1);
      await bloc.close();
    });

    test('init without existing tasks still emits placeholder', () async {
      final bloc = TaskListBloc(repository: repo, parentId: domain.id);
      bloc.add(TaskListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<TaskListState>()));
      expect(bloc.state.tasks.length, 1);
      await bloc.close();
    });

    test('TaskAddRequested adds a new empty task', () async {
      final bloc = TaskListBloc(repository: repo, parentId: domain.id);
      bloc.add(TaskListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<TaskListState>()));
      final countBefore = bloc.state.tasks.length;

      bloc.add(TaskAddRequested());
      await expectLater(bloc.stream, emits(isA<TaskListState>()));
      expect(bloc.state.tasks.length, countBefore + 1);
      await bloc.close();
    });

    test('TaskCompletionRequested saves completed task', () async {
      final t1 = Task(id: 't1', title: 'one', originatorId: me.id);
      await repo.saveModel(t1);
      await domain.linkTo(t1);

      final bloc = TaskListBloc(repository: repo, parentId: domain.id);
      bloc.add(TaskListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<TaskListState>()));

      bloc.add(TaskCompletionRequested(task: t1, isComplited: true));
      await expectLater(bloc.stream, emits(isA<TaskListState>()));
      expect(bloc.state.tasks['t1']!.isCompleted, isTrue);
      // persisted to local storage
      final stored = repo.getModel<Task>('t1');
      expect(stored!.isCompleted, isTrue);
      await bloc.close();
    });

    test('TaskCompletionRequested ignores empty-title task', () async {
      final empty = Task(id: 'empty', title: '', originatorId: me.id);
      await repo.saveModel(empty);
      await domain.linkTo(empty);

      final bloc = TaskListBloc(repository: repo, parentId: domain.id);
      bloc.add(TaskListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<TaskListState>()));

      bloc.add(TaskCompletionRequested(task: empty, isComplited: true));
      // no state change; storage not updated
      await Future.delayed(Duration.zero);
      expect(bloc.state.tasks['empty']!.isCompleted, isFalse);
      await bloc.close();
    });

    test('TaskSubmitionRequested sets title, links and adds placeholder',
        () async {
      final bloc = TaskListBloc(repository: repo, parentId: domain.id);
      bloc.add(TaskListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<TaskListState>()));
      final placeholder = bloc.state.tasks.values.first;

      bloc.add(TaskSubmitionRequested(
          task: placeholder, submittedText: 'new title'));
      await expectLater(bloc.stream, emits(isA<TaskListState>()));

      final submitted =
          bloc.state.tasks.values.where((t) => t.title == 'new title');
      expect(submitted.length, 1);
      expect(submitted.first.parents[domain.id], 'Domain');
      // new placeholder appended
      final emptyTasks = bloc.state.tasks.values.where((t) => t.title == '');
      expect(emptyTasks.length, 1);
      await bloc.close();
    });

    test('TaskChangingRequested updates title in state only', () async {
      final t1 = Task(id: 't1', title: 'one', originatorId: me.id);
      await repo.saveModel(t1);

      final bloc = TaskListBloc(repository: repo, parentId: domain.id);
      bloc.add(TaskListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<TaskListState>()));

      bloc.add(
          TaskChangingRequested(task: t1, changedText: 'renamed in place'));
      await expectLater(bloc.stream, emits(isA<TaskListState>()));
      expect(bloc.state.tasks['t1']!.title, 'renamed in place');
      // not persisted
      expect(repo.getModel<Task>('t1')!.title, 'one');
      await bloc.close();
    });
  });

  group('DomainListBloc', () {
    late Repository repo;
    late User me;

    setUp(() async {
      me = User(id: 'me', name: 'me');
      repo = await makeRepo(me: me);
    });

    test('init emits domains of me', () async {
      final d1 = Domain(id: 'd1', title: 'personal', originatorId: me.id);
      await repo.saveModel(d1);
      await me.linkTo(d1);

      final bloc = DomainListBloc(repository: repo);
      bloc.add(DomainListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<DomainListState>()));
      expect(bloc.state.domains, isNotEmpty);
      await bloc.close();
    });

    test('DomainCreationRequested creates and links a domain', () async {
      final bloc = DomainListBloc(repository: repo);
      bloc.add(DomainListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));

      bloc.add(DomainCreationRequested('shopping'));
      await expectLater(bloc.stream, emits(isA<dynamic>()));
      expect(bloc.state.domains.values.map((d) => d.title),
          contains('shopping'));
      // domain is persisted and linked to me
      final created = bloc.state.domains.values
          .firstWhere((d) => d.title == 'shopping');
      expect(me.domainsIds, contains(created.id));
      final stored = repo.getModel<Domain>(created.id);
      expect(stored!.title, 'shopping');
      await bloc.close();
    });

    test('DomainDeletionRequested ignores untitled domains', () async {
      final untitled = Domain(id: 'd0', title: '', originatorId: me.id);
      await repo.saveModel(untitled);
      await me.linkTo(untitled);

      final bloc = DomainListBloc(repository: repo);
      bloc.add(DomainListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));

      bloc.add(DomainDeletionRequested(domain: untitled));
      await Future.delayed(Duration.zero);
      // still there
      expect(me.domainsIds, contains('d0'));
      await bloc.close();
    });

    test('DomainDeletionRequested removes titled domain', () async {
      final d1 = Domain(id: 'd1', title: 'doomed', originatorId: me.id);
      await repo.saveModel(d1);
      await me.linkTo(d1);

      final bloc = DomainListBloc(repository: repo);
      bloc.add(DomainListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));
      expect(bloc.state.domains.keys, contains('d1'));

      bloc.add(DomainDeletionRequested(domain: d1));
      await Future.delayed(Duration.zero);
      expect(me.domainsIds, isNot(contains('d1')));
      expect(bloc.state.domains.keys, isNot(contains('d1')));
      await bloc.close();
    });

    test('DomainSyncRequested merges incoming domains', () async {
      final bloc = DomainListBloc(repository: repo);
      bloc.add(DomainListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));

      final external = Domain(id: 'dext', title: 'external', originatorId: me.id);
      bloc.add(DomainSyncRequested(domains: {external.id: external}));
      await expectLater(bloc.stream, emits(isA<dynamic>()));
      expect(bloc.state.domains['dext']!.title, 'external');
      await bloc.close();
    });

    test('DomainChangingRequested updates the domain in state', () async {
      final d1 = Domain(id: 'd1', title: 'personal', originatorId: me.id);
      await repo.saveModel(d1);
      await me.linkTo(d1);

      final bloc = DomainListBloc(repository: repo);
      bloc.add(DomainListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));

      bloc.add(DomainChangingRequested(domain: d1));
      await expectLater(bloc.stream, emits(isA<dynamic>()));
      // title becomes listenerId string value (>= '0')
      expect(bloc.state.domains['d1']!.title, isNotEmpty);
      await bloc.close();
    });
  });

  group('ContactListBloc', () {
    late Repository repo;
    late User me;

    setUp(() async {
      me = User(id: 'me', name: 'me');
      repo = await makeRepo(me: me);
    });

    test('init emits contacts from shared domains', () async {
      final domain = Domain(
          id: 'd1',
          title: 'shared',
          originatorId: me.id,
          participantsIds: ['me', 'alice']);
      await repo.saveModel(domain);
      await me.linkTo(domain);
      final alice = User(id: 'alice', name: 'Alice');
      await repo.saveModel(alice);

      final bloc = ContactListBloc(repository: repo);
      bloc.add(ContactListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));

      expect(bloc.state.contacts.keys, contains('alice'));
      expect(bloc.state.contacts['alice']!.name, 'Alice');
      await bloc.close();
    });

    test('close removes sync listener without errors', () async {
      final bloc = ContactListBloc(repository: repo);
      bloc.add(ContactListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));
      final listenersBefore = repo.syncListeners.length;
      await bloc.close();
      expect(repo.syncListeners.length, listenersBefore - 1);
    });

    test('domain with no participants yields no contacts', () async {
      final domain = Domain(id: 'd1', title: 'solo', originatorId: me.id);
      await repo.saveModel(domain);
      await me.linkTo(domain);

      final bloc = ContactListBloc(repository: repo);
      bloc.add(ContactListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));
      expect(bloc.state.contacts, isEmpty);
      await bloc.close();
    });

    test('no-op events (invitation, handshake, projection, syncs) are handled without errors', () async {
      final bloc = ContactListBloc(repository: repo);
      bloc.add(ContactListStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));

      bloc.add(ContactInvitationRequested('bob', 'hi', 'email'));
      bloc.add(ContactHandshakeRequested('bob-id'));
      bloc.add(ContactCreateUserProjectionRequested('projection'));
      bloc.add(ContactUserSyncRequested(contacts: {}));
      bloc.add(ContactDomainSyncRequested(domains: {}));
      // All handlers run as no-ops: pump the event queue and verify no crash.
      await Future.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.contacts, isA<Map<String, User>>());
      await bloc.close();
    });
  });

  group('ProfilePageBloc', () {
    late Repository repo;
    late User me;

    setUp(() async {
      me = User(id: 'me', name: 'me');
      repo = await makeRepo(me: me);
    });

    test('init loads records excluding avatarUrl and reads avatar', () async {
      me = User(id: 'me', name: 'me', avatarUrl: 'me-avatar');
      await repo.saveModel(me);
      repo.me = me;
      final bytes = Uint8List.fromList([1, 2, 3]);
      repo.saveImage('me-avatar', bytes);

      final bloc = ProfilePageBloc(repository: repo, userId: me.id);
      bloc.add(ProfilePageStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));

      final props = bloc.state.userProfileRecords;
      expect(props.map((r) => r['propId']), isNot(contains('avatarUrl')));
      expect(props.map((r) => r['propId']),
          containsAll(['id', 'name', 'firstName', 'lastName', 'description']));
      expect(bloc.state.avatarBytes, bytes);
      expect(bloc.state.avatarDBName, 'me-avatar');
      await bloc.close();
    });

    test('init with unknown user does nothing', () async {
      final bloc = ProfilePageBloc(repository: repo, userId: 'nobody');
      bloc.add(ProfilePageStateInitRequested());
      await Future.delayed(Duration.zero);
      expect(bloc.state.userProfileRecords, isEmpty);
      expect(bloc.state.avatarBytes, isNull);
      await bloc.close();
    });

    test('ProfileRecordChangingRequested updates record value', () async {
      final bloc = ProfilePageBloc(repository: repo, userId: me.id);
      bloc.add(ProfilePageStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));

      final nameIndex =
          bloc.state.userProfileRecords.indexWhere((r) => r['propId'] == 'name');
      bloc.add(ProfileRecordChangingRequested(
          recordIndex: nameIndex, changedText: 'NewName'));
      await expectLater(bloc.stream, emits(isA<dynamic>()));
      expect(bloc.state.userProfileRecords[nameIndex]['value'], 'NewName');
      await bloc.close();
    });

    test('ProfileRecordSubmitRequested persists changed value', () async {
      final bloc = ProfilePageBloc(repository: repo, userId: me.id);
      bloc.add(ProfilePageStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));

      final nameIndex =
          bloc.state.userProfileRecords.indexWhere((r) => r['propId'] == 'name');
      bloc.add(ProfileRecordSubmitRequested(
          recordIndex: nameIndex, changedText: 'SavedName'));
      await Future.delayed(Duration.zero);

      final stored = repo.getModel<User>(me.id)!;
      expect(stored.name, 'SavedName');
      await bloc.close();
    });

    test('ProfileAvatarUpdateRequested saves image bytes', () async {
      final bloc = ProfilePageBloc(repository: repo, userId: me.id);
      bloc.add(ProfilePageStateInitRequested());
      await expectLater(bloc.stream, emits(isA<dynamic>()));

      final bytes = Uint8List.fromList([9, 8, 7]);
      bloc.add(ProfileAvatarUpdateRequested(
          avatarDBName: 'me-avatar', avatarBytes: bytes));
      await Future.delayed(Duration.zero);

      expect(bloc.state.avatarBytes, bytes);
      expect(repo.getImage('me-avatar'), bytes);
      await bloc.close();
    });
  });
}
