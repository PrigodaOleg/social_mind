import 'package:closers/repository/repository.dart';
import 'package:closers/state/state.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_local_storage.dart';

// Host-level test of the 'rename task list' flow: TaskListBloc._onTitleChanged
// must update the bloc state AND persist the renamed list in the repository
// (local-first: the write lands in the local storage immediately).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TaskListBloc rename', () {
    test('TaskListTitleChanged renames the list and persists it', () async {
      final repo =
          Repository(localStorage: FakeLocalStorage(), remoteStorages: {});
      // linkTo() saves through Repository.instance.
      Repository.instance = repo;
      repo.knownRemoteStorages.clear();
      await repo.init();

      final user = User(name: 'tester');
      repo.me = user;
      // set me stores the user model asynchronously (fire-and-forget).
      await Future<void>.delayed(Duration.zero);
      expect(repo.myId, isNotNull);

      final list = TaskList(title: 'Initial');
      await repo.me.linkTo(list);

      final bloc = TaskListBloc(repository: repo, parentId: list.id);
      bloc.add(const TaskListStateInitRequested());
      // Wait (bounded) until the bloc has loaded the list.
      await bloc.stream
          .firstWhere((state) => state.list != null)
          .timeout(const Duration(seconds: 10));

      // Rename via the same event the AppBar settings dialog dispatches.
      bloc.add(const TaskListTitleChanged('Renamed'));
      await bloc.stream.first.timeout(const Duration(seconds: 10));

      expect(bloc.state.list!.title, 'Renamed');

      // The rename must be persisted in the local storage (source of truth).
      final stored = repo.getModel<TaskList>(list.id);
      expect(stored, isNotNull);
      expect(stored!.title, 'Renamed');

      await bloc.close();
    });
  });
}
