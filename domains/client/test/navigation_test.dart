import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/ui/navigation.dart';

import 'fake_local_storage.dart';

// Репозиторий на фейковом хранилище: без Isar/Firebase. [initialized] имитирует
// прошедший init (repository.late == false), как после locateUser на splash.
Repository _testRepository({String? userId, bool initialized = true}) {
  final repo = Repository(localStorage: FakeLocalStorage());
  repo.knownRemoteStorages.clear();
  if (initialized) repo.late = false;
  if (userId != null) repo.myId = userId;
  return repo;
}

Widget _dummyPageBuilder(Repository repository, {dynamic args}) => const SizedBox();

void main() {
  group('AppRouterDelegate', () {
    late AppRouterDelegate delegate;
    var notifications = 0;

    setUp(() {
      notifications = 0;
      delegate = AppRouterDelegate(
        initialRoute: (path: '/splash', constructor: _dummyPageBuilder, args: {}),
        unknownRoute: (path: '/unknown', constructor: _dummyPageBuilder, args: {}),
        routes: {
          '/login': _dummyPageBuilder,
          '/home': _dummyPageBuilder,
          '/tasks': _dummyPageBuilder,
        },
      );
      delegate.addListener(() => notifications++);
    });

    test('initial stack contains only the initial route', () {
      expect(delegate.navStack.length, 1);
      expect(delegate.navStack.first.path, '/splash');
    });

    test('pushNamed appends entry and notifies listeners', () async {
      await delegate.pushNamed('/login');

      expect(delegate.navStack.length, 2);
      expect(delegate.navStack.last.path, '/login');
      expect(notifications, 1);
    });

    test('pushNamed extracts id from nested route', () async {
      // Последний сегмент пути считается id, префикс - маршрутом.
      await delegate.pushNamed('/tasks/task42');

      expect(delegate.navStack.last.path, '/tasks');
      expect(delegate.navStack.last.args['id'], 'task42');
    });

    test('pushReplacementNamed replaces the top entry and notifies listeners', () async {
      await delegate.pushNamed('/login');
      notifications = 0;

      await delegate.pushReplacementNamed('/home');

      // Заменяется только верхняя запись, '/splash' остается под ней.
      expect(delegate.navStack.length, 2);
      expect(delegate.navStack.first.path, '/splash');
      expect(delegate.navStack.last.path, '/home');
      expect(notifications, 1);
    });

    test('replaceNavigationStack replaces the stack and notifies listeners', () async {
      await delegate.pushNamed('/login');
      notifications = 0;

      final newStack = [NavStackEntry('/home', {})];
      delegate.replaceNavigationStack(newStack);

      expect(identical(delegate.navStack, newStack), isTrue);
      expect(delegate.navStack.single.path, '/home');
      expect(notifications, 1);
    });

    test('handlePageRemoved removes the entry by identity', () async {
      await delegate.pushNamed('/login');
      final removedEntry = delegate.navStack.first; // '/splash'
      final page = MaterialPage<Object?>(key: ObjectKey(removedEntry), child: const SizedBox());

      notifications = 0;

      delegate.handlePageRemoved(page);

      expect(delegate.navStack.length, 1);
      expect(delegate.navStack.single.path, '/login');
      expect(notifications, 1);
    });

    test('handlePageRemoved removes only the matching entry from the middle', () async {
      await delegate.pushNamed('/login');
      await delegate.pushNamed('/home');
      final removedEntry = delegate.navStack[1]; // '/login'
      final page = MaterialPage<Object?>(key: ObjectKey(removedEntry), child: const SizedBox());

      delegate.handlePageRemoved(page);

      expect(delegate.navStack.length, 2);
      expect(delegate.navStack.map((e) => e.path), ['/splash', '/home']);
    });

    test('handlePageRemoved is a no-op for an entry already removed from the stack', () async {
      // Регрессионный тест на баг пользователя: делегат уже заменил страницу
      // (pushReplacement), Flutter присылает onDidRemovePage для старой страницы -
      // удаление не должно трогать новую запись стека.
      await delegate.pushReplacementNamed('/login');
      final staleEntry = NavStackEntry('/splash', {});
      final stalePage = MaterialPage<Object?>(key: ObjectKey(staleEntry), child: const SizedBox());
      notifications = 0;

      delegate.handlePageRemoved(stalePage);

      expect(delegate.navStack.length, 1);
      expect(delegate.navStack.single.path, '/login');
    });

    test('handlePageRemoved re-adds the initial route when the last entry is removed', () {
      final entry = delegate.navStack.single;
      final page = MaterialPage<Object?>(key: ObjectKey(entry), child: const SizedBox());

      delegate.handlePageRemoved(page);

      expect(delegate.navStack, isNotEmpty);
      expect(delegate.navStack.single.path, delegate.initialRoute.path);
    });

    test('handlePageRemoved ignores pages with foreign keys', () {
      final page = const MaterialPage<Object?>(key: ValueKey('/splash#0'), child: SizedBox());

      delegate.handlePageRemoved(page);
      expect(delegate.navStack.length, 1);
      expect(delegate.navStack.single.path, '/splash');
      expect(notifications, 1);
    });
    group('web links (setNewRoutePath)', () {
      test('known route with user set builds a fresh stack', () async {
        delegate.repository = _testRepository(userId: 'u1');

        await delegate.setNewRoutePath(Uri.parse('/home'));

        expect(delegate.navStack.single.path, '/home');
        expect(delegate.navStack.single.args, isEmpty);
        expect(delegate.currentConfiguration, Uri.parse('/home'));
        expect(notifications, 1);
      });

      test('known nested route keeps the full path and extracts id', () async {
        delegate.repository = _testRepository(userId: 'u1');

        await delegate.setNewRoutePath(Uri.parse('/tasks/task42'));

        expect(delegate.navStack.single.path, '/tasks/task42');
        expect(delegate.navStack.single.args['id'], 'task42');
        expect(delegate.currentConfiguration, Uri.parse('/tasks/task42'));
      });

      test('unknown route lands on the unknown page', () async {
        delegate.repository = _testRepository(userId: 'u1');

        await delegate.setNewRoutePath(Uri.parse('/nope'));

        expect(delegate.navStack.single.path, '/unknown');
        expect(delegate.navStack.single.args, isEmpty);
        expect(notifications, 1);
      });

      test('no user: login first, deferred target applied after login', () async {
        delegate.repository = _testRepository();

        await delegate.setNewRoutePath(Uri.parse('/home'));

        // Стек заменен на логин, цель ссылки отложена.
        expect(delegate.navStack.single.path, '/login');
        expect(delegate.currentConfiguration, Uri.parse('/home'));

        // "Логин": пользователь появился, экран логина делает pushReplacementNamed.
        delegate.repository.myId = 'u1';
        await delegate.pushReplacementNamed('/login');

        expect(delegate.navStack.single.path, '/home');
        expect(delegate.currentConfiguration, Uri.parse('/home'));
      });

      test('root and splash paths keep the stack untouched', () async {
        delegate.repository = _testRepository(userId: 'u1');
        await delegate.pushNamed('/home');
        notifications = 0;

        await delegate.setNewRoutePath(Uri.parse('/'));
        expect(delegate.navStack.map((e) => e.path), ['/splash', '/home']);
        await delegate.setNewRoutePath(Uri.parse('/splash'));
        expect(delegate.navStack.map((e) => e.path), ['/splash', '/home']);
        expect(notifications, 0);
      });

      test('cold start defers the link; restore puts it on top of the stack', () async {
        // Репозиторий без init: repository.late == true (холодный старт).
        final repo = _testRepository(initialized: false);
        delegate.repository = repo;

        await delegate.setNewRoutePath(Uri.parse('/home'));

        expect(delegate.navStack.single.path, '/splash');
        expect(delegate.currentConfiguration, Uri.parse('/home'));

        repo.myId = 'u1';
        repo.late = false;
        delegate.replaceNavigationStack([NavStackEntry('/login', {})]);

        expect(delegate.navStack.map((e) => e.path), ['/login', '/home']);
        expect(delegate.currentConfiguration, Uri.parse('/home'));
      });

      test('route information parser round-trips the uri', () async {
        final parser = AppRouteInformationParser();
        final uri = Uri.parse('/home?x=1');

        final parsed = await parser.parseRouteInformation(RouteInformation(uri: uri));
        expect(parsed, uri);

        final restored = parser.restoreRouteInformation(uri);
        expect(restored!.uri, uri);
      });
    });
  });
}
