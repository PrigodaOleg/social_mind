import 'package:flutter/material.dart';
import 'package:ui/domain_list_page/domain_list_page.dart';
import 'package:ui/ui.dart';
import 'package:repository/repository.dart';

// Reference: https://stackoverflow.com/questions/57537347/how-to-save-last-opened-screen-in-flutter-app
class AppRouteObserver extends RouteObserver {
  AppRouteObserver(this.repository);
  Repository repository;
  void saveLastRoute(Route? lastRoute) async {
    if (!repository.late) {
      repository.lastRoute = lastRoute?.settings.name;
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    saveLastRoute(previousRoute); // note : take route name in stacks below
    super.didPop(route, previousRoute);
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    saveLastRoute(route); // note : take new route name that just pushed
    super.didPush(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    saveLastRoute(route);
    super.didRemove(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    saveLastRoute(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}

class App extends StatelessWidget {
  const App({super.key});

  Future<String?> locateUser(Repository repository) async {

    // This is the origin point of working with repository
    await repository.init();

    // Trying to get user and set it as actual local user
    // User account can be stored locally or remotely
    // (we can take it if we have an actual authorization from remote storage)
    if (repository.myId != null) {
      // Show last active page to user
      var lastRoute = repository.lastRoute ?? '/home';
      lastRoute = lastRoute == '/' ? '/home' : lastRoute;
      return lastRoute;
    } 
    // Otherwise show login screen to user
    // User have a tree options:
    //  - Login to remote storage (and try to take the actual user account from there)
    //  - Transfer actual user account from active device (QR-code and public remote storage)
    //  - Create new user account
    return null;
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    Repository repository = Repository();
    return MaterialApp(
      onGenerateTitle: (context) => AppLocalizations.of(context).applicationTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          // brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      navigatorObservers: <NavigatorObserver>[AppRouteObserver(repository)],
      // Reference: https://stackoverflow.com/questions/70730934/how-do-i-detect-if-app-was-launched-with-a-route-in-flutter-web
      onGenerateInitialRoutes: (initialRoute) => [
        MaterialPageRoute(
          builder: (context) => SplashScreen(
            nextRoute: initialRoute,
            lottieAsset: "assets/Lottie/Animation - 1719759862682.json",
            repository: repository,
            backgroundTask: locateUser
          ),
        )
      ],
      initialRoute: '/',
      routes: {
        '/': (context) => IntroductionPage(repository),
        '/home': (context) => HomePage(title: AppLocalizations.of(context).homePageName, repository: repository),
        '/domains': (context) => DomainListPage(title: AppLocalizations.of(context).domainListPageName, repository: repository),
        '/tasks': (context) => TaskListPage(title: AppLocalizations.of(context).taskListPageName, repository: repository),
        // DomainContentPage.routeName: (context) => DomainContentPage(repository),
      },
      onGenerateRoute: (settings) {
        // Здесь обрабатываем всякие непонятные маршруты
        // Например, с параметрами или динамические
        // Сперва извлекаем параметры из настроек, потом из маршрута, если они есть
        final arguments = <String, dynamic>{};
        final uri = Uri.parse(settings.name ?? '');
        final id = uri.path.split('/').last;
        if (settings.arguments != null) arguments.addAll(settings.arguments as Map<String, dynamic>);
        if (uri.hasQuery) arguments.addAll(uri.queryParameters);
        if (id.isNotEmpty) arguments['id'] = id;
        final routeSettings = RouteSettings(name: settings.name, arguments: arguments);
        // final x = uri.removeFragment().path;
        
        // Сохраняем последний маршрут, по которому ходил пользователь
        // Кстати, а, может быть, нужно сохранять весь стек маршрутов, чтобы сохранялась вся история переходов? 
        // Если он пуст, то тогда идем по маршруту поумолчанию
        repository.lastRoute = Uri(path: uri.path, queryParameters: arguments).toString();

        // Ищем маршрут без всяческих параметров
        final rootRoute = uri.path.substring(0, uri.path.lastIndexOf('/'));
        switch (rootRoute) {
          case DomainContentPage.routeName:
            // Этот маршрут не работает без аргументов
            if (arguments.isEmpty) break;
            return MaterialPageRoute(builder: (context) => DomainContentPage(repository),settings: routeSettings);
          default:
            return MaterialPageRoute(
              builder: (context) => HomePage(title: AppLocalizations.of(context).homePageName, repository: repository),
              settings: const RouteSettings(name: '/home', arguments: null)
            );
        }
      },
    );
  }
}