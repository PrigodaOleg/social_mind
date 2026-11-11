import 'dart:async';

import 'package:flutter/material.dart';
import 'ui/ui.dart';
import 'ui/navigation.dart';
import 'repository/repository.dart';
import 'notifications/push_notification_service.dart';

class App extends StatelessWidget {
  const App({super.key});

  Future<List<NavStackEntry>?> locateUser(Repository repository) async {
    // This is the origin point of working with repository
    // Провал инициализации хранилищ (сеть недоступна, хранилище не отвечает,
    // конфигурация битая) не должен замораживать переход splash -> home:
    // приложение способно работать офлайн, а ошибки синхронизации проявятся
    // при действиях пользователя.
    try {
      await repository.init();
    } catch (error) {
      print('Repository init failed: $error');
    }
    // FCM: регистрация токена после того, как репозиторий знает пользователя.
    // Пуши не критичны для старта: requestPermission/getToken могут ждать сети
    // или ответа пользователя на диалог, поэтому не блокируем ими переход на
    // экран приложения - инициализация едет в фоне, ошибки глотаются.
    unawaited(
      PushNotificationService.instance.initOnLogin(repository).catchError(
        (Object error) {
          print('Push notifications init failed: $error');
        },
      ),
    );

    // Trying to get user and set it as actual local user
    // User account can be stored locally or remotely
    // (we can take it if we have an actual authorization from remote storage)
    return repository.lastNavStack;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context).applicationTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          // brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Браузеры могут отдавать локали без языка (und/ничего) или локали,
      // не входящие в supportedLocales с непарсимым для Intl кодом —
      // intl.Intl.canonicalizedLocale бросает RangeError и приложение
      // остаётся на splash-экране. Фолбэк на английский решает это.
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) return supported;
        }
        return const Locale('en');
      },
      routerDelegate: AppRouterDelegate(initialRoute: (
        path: SplashScreen.routeName,
        constructor: SplashScreen.new,
        args: {
          'nextRoute': LoginPage.routeName,
          'lottieAsset': "assets/Lottie/Animation - 1719759862682.json",
          'backgroundTask': locateUser
        }
      ), unknownRoute: (
        args: {},
        constructor: UnknownPage.new,
        path: UnknownPage.routeName
      ), routes: {
        LoginPage.routeName: LoginPage.new,
        HomePage.routeName: HomePage.new,
        DomainListPage.routeName: DomainListPage.new,
        DomainContentPage.routeName: DomainContentPage.new,
        TaskListPage.routeName: TaskListPage.new,
        ContactListPage.routeName: ContactListPage.new,
        UserProfilePage.routeName: UserProfilePage.new,
        InvitationPage.routeName: InvitationPage.new,
        NotificationsPage.routeName: NotificationsPage.new
      }),
      routeInformationParser: AppRouteInformationParser(),
    );
  }
}
