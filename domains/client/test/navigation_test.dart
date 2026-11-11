import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/ui/navigation.dart';

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
  });
}
