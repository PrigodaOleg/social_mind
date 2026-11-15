import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/ui/navigation.dart';

import 'fake_local_storage.dart';

// Синтетические страницы: рендерят путь маршрута текстом, чтобы сценарий
// навигации проверялся по видимому дереву без l10n/lottie.
Widget Function(Repository, {dynamic args}) _textPage(String path) {
  Widget page(Repository repository, {dynamic args}) => Text(path);
  return page;
}

void main() {
  testWidgets(
    'restore, back/forward, web links (known/unknown/no-user) on the real delegate',
    (tester) async {
      final repo = Repository(localStorage: FakeLocalStorage());
      repo.knownRemoteStorages.clear();
      repo.late = false;
      repo.myId = 'u1';

      final delegate = AppRouterDelegate(
        loginRoutePath: '/login',
        initialRoute: (path: '/start', constructor: _textPage('/start'), args: {}),
        unknownRoute: (path: '/unknown', constructor: _textPage('/unknown'), args: {}),
        routes: {
          '/a': _textPage('/a'),
          '/b': _textPage('/b'),
          '/c': _textPage('/c'),
          '/login': _textPage('/login'),
          '/home': _textPage('/home'),
        },
      );
      delegate.repository = repo;

      await tester.pumpWidget(
        MaterialApp.router(
          routerDelegate: delegate,
          routeInformationParser: AppRouteInformationParser(),
        ),
      );
      await tester.pumpAndSettle();

      // a. Стартовый экран.
      expect(find.text('/start'), findsOneWidget);

      // b. Восстановление стека (как после locateUser на splash).
      delegate.replaceNavigationStack([
        NavStackEntry('/a', {}),
        NavStackEntry('/b', {}),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('/b'), findsOneWidget);
      expect(find.text('/start'), findsNothing);
      expect(delegate.navStack.map((e) => e.path), ['/a', '/b']);

      // c. Назад: системный pop удаляет верхнюю страницу.
      final navigatorState = tester.state<AppNavigatorState>(find.byType(AppNavigator));
      await navigatorState.maybePop();
      await tester.pumpAndSettle();
      expect(find.text('/a'), findsOneWidget);
      expect(delegate.navStack.length, 1);

      // d. Вперед.
      await delegate.pushNamed('/c');
      await tester.pumpAndSettle();
      expect(find.text('/c'), findsOneWidget);

      // e. Веб-ссылка на известный маршрут: свежий стек от целевой страницы.
      await delegate.setNewRoutePath(Uri.parse('/b'));
      await tester.pumpAndSettle();
      expect(find.text('/b'), findsOneWidget);
      expect(find.text('/c'), findsNothing);
      expect(delegate.navStack.single.path, '/b');

      // f. Неизвестная ссылка: UnknownPage.
      await delegate.setNewRoutePath(Uri.parse('/nope'));
      await tester.pumpAndSettle();
      expect(find.text('/unknown'), findsOneWidget);
      expect(delegate.navStack.single.path, '/unknown');

      // g. Ссылка без пользователя: сначала логин, цель применяется после входа.
      final freshRepo = Repository(localStorage: FakeLocalStorage());
      freshRepo.knownRemoteStorages.clear();
      freshRepo.late = false;
      delegate.repository = freshRepo;

      await delegate.setNewRoutePath(Uri.parse('/c'));
      await tester.pumpAndSettle();
      expect(find.text('/login'), findsOneWidget);
      expect(find.text('/unknown'), findsNothing);
      expect(delegate.navStack.single.path, '/login');

      // "Логин": пользователь сохранен, экран логина делает pushReplacementNamed.
      await freshRepo.asyncSetMe(User(name: 'x'));
      await delegate.pushReplacementNamed('/login');
      await tester.pumpAndSettle();
      expect(find.text('/c'), findsOneWidget);
      expect(delegate.navStack.single.path, '/c');
      expect(tester.takeException(), isNull);
    },
  );
}
