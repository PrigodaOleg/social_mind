import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/ui/l10n/app_localizations.dart';
import 'package:closers/ui/navigation.dart';
import 'package:closers/ui/pages/home.dart';
import 'package:closers/ui/pages/login.dart';
import 'package:closers/ui/pages/splash_screen.dart';
import 'package:closers/ui/pages/unknown_page.dart';

import '../fake_local_storage.dart';

void main() {
  testWidgets('start -> splash -> /login -> blank user -> /home', (tester) async {
    final storage = FakeLocalStorage();
    final repo = Repository(localStorage: storage);
    // В тестовом окружении нет удаленных бэкендов: не даём репозиторию
    // инстанцировать Firebase/Supabase из настроек пользователя по умолчанию.
    repo.knownRemoteStorages.clear();

    final delegate = AppRouterDelegate(
      initialRoute: (
        path: SplashScreen.routeName,
        constructor: SplashScreen.new,
        args: {
          'nextRoute': LoginPage.routeName,
          'lottieAsset': 'assets/Lottie/Animation - 1719759862682.json',
          'backgroundTask': (Repository repository) async => null,
        }
      ),
      unknownRoute: (
        path: UnknownPage.routeName,
        constructor: UnknownPage.new,
        args: {}
      ),
      routes: {
        LoginPage.routeName: LoginPage.new,
        HomePage.routeName: HomePage.new,
      },
    );
    delegate.repository = repo;

    await tester.pumpWidget(
      MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerDelegate: delegate,
        routeInformationParser: AppRouteInformationParser(),
      ),
    );

    // Splash: анимация 200ms, затем Future.delayed(1000ms) и pushReplacementNamed.
    // pumpAndSettle не используем: lottie может анимироваться бесконечно.
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    // Оказались на LoginPage.
    expect(find.text('Hi there'), findsOneWidget);
    expect(find.text('Blank user'), findsOneWidget);

    // Пользователь нажимает "Blank user" -> модалка SaveUserCredentialsPage.
    await tester.tap(find.text('Blank user'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.arrow_forward), findsOneWidget);

    // Подтверждаем сохранение (pop(true)) -> продолжение onPressed:
    // repository.me = ..., initRemoteStorages, createUserRemoteStorages,
    // pushReplacementNamed('/home').
    await tester.tap(find.byIcon(Icons.arrow_forward));
    await tester.pumpAndSettle();

    // Оказались на HomePage: в списке виден id пользователя.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text(repo.me.id), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Стек навигации после замен не испорчен (регрессия на двойное удаление).
    expect(delegate.navStack.single.path, HomePage.routeName);
  });
}
