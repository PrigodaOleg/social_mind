import 'dart:async';

import 'package:flutter/material.dart';
import 'ui/ui.dart';
import 'ui/navigation.dart';
import 'repository/repository.dart';
import 'notifications/push_notification_service.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppRouterDelegate _routerDelegate = _createRouterDelegate();
  DeepLinkHandler? _deepLinks;

  @override
  void initState() {
    super.initState();
    // Deeplink-ссылки: холодный старт (initial link) и теплый старт (поток).
    // На платформах без поддержки app_links обработчик молча отключается.
    try {
      _deepLinks = DeepLinkHandler()..start(mapInvitationLinkToRouterUri, _onLink);
    } catch (_) {
      _deepLinks = null;
    }
  }

  void _onLink(Uri uri) {
    _routerDelegate.setNewRoutePath(uri);
  }

  @override
  void dispose() {
    _deepLinks?.dispose();
    super.dispose();
  }

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
    // Нет локального пользователя - на дефолтный маршрут логина; сохраненный
    // стек (в т.ч. с других устройств) восстановится после входа.
    if (repository.myId == null) {
      return null;
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

  AppRouterDelegate _createRouterDelegate() {
    return AppRouterDelegate(
      loginRoutePath: LoginPage.routeName,
      initialRoute: (
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
        TaskListsPage.routeName: TaskListsPage.new,
        ContactListPage.routeName: ContactListPage.new,
        UserProfilePage.routeName: UserProfilePage.new,
        InvitationPage.routeName: InvitationPage.new,
        NotificationsPage.routeName: NotificationsPage.new
      });
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
      routerDelegate: _routerDelegate,
      routeInformationParser: AppRouteInformationParser(),
    );
  }
}
