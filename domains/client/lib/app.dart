import 'package:flutter/material.dart';
import 'package:ui/domain_list_page/domain_list_page.dart';
import 'package:ui/ui.dart';
import 'package:repository/repository.dart';

// Reference: https://stackoverflow.com/questions/57537347/how-to-save-last-opened-screen-in-flutter-app
// class AppRouteObserver extends RouteObserver {
//   AppRouteObserver(this.repository);
//   Repository repository;
//   void saveLastRoute(Route? lastRoute) async {
//     if (!repository.late) {
//       repository.lastRoute = lastRoute?.settings.name;
//     }
//   }

//   @override
//   void didPop(Route route, Route? previousRoute) {
//     saveLastRoute(previousRoute); // note : take route name in stacks below
//     super.didPop(route, previousRoute);
//   }

//   @override
//   void didPush(Route route, Route? previousRoute) {
//     saveLastRoute(route); // note : take new route name that just pushed
//     super.didPush(route, previousRoute);
//   }

//   @override
//   void didRemove(Route route, Route? previousRoute) {
//     saveLastRoute(route);
//     super.didRemove(route, previousRoute);
//   }

//   @override
//   void didReplace({Route? newRoute, Route? oldRoute}) {
//     saveLastRoute(newRoute);
//     super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
//   }
// }

class App extends StatelessWidget {
  const App({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    MaterialApp x = MaterialApp.router(
      // navigatorKey: navigator.key,
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
      routerDelegate: AppRouterDelegate(),
      routeInformationParser: AppRouteInformationParser(),
      // navigatorObservers: <NavigatorObserver>[AppRouteObserver(repository)],
      // // Reference: https://stackoverflow.com/questions/70730934/how-do-i-detect-if-app-was-launched-with-a-route-in-flutter-web
      // onGenerateInitialRoutes: (initialRoute) => [
      //   MaterialPageRoute(
      //     builder: (context) => SplashScreen(
      //       nextRoute: initialRoute,
      //       lottieAsset: "assets/Lottie/Animation - 1719759862682.json",
      //       repository: repository,
      //       backgroundTask: locateUser
      //     ),
      //   )
      // ],
      // initialRoute: '/',
      // routes: {
      //   '/': (context) => IntroductionPage(repository),
      //   '/home': (context) => HomePage(title: AppLocalizations.of(context).homePageName, repository: repository),
      //   '/domains': (context) => DomainListPage(title: AppLocalizations.of(context).domainListPageName, repository: repository),
      // },
      // onGenerateRoute: (settings) {
      //   // Здесь обрабатываем всякие непонятные маршруты
      //   // Например, с параметрами или динамические
      //   // Сперва извлекаем параметры из настроек, потом из маршрута, если они есть
      //   final arguments = <String, dynamic>{};
      //   final uri = Uri.parse(settings.name ?? '');
      //   final id = uri.path.split('/').last;
      //   if (settings.arguments != null) arguments.addAll(settings.arguments as Map<String, dynamic>);
      //   if (uri.hasQuery) arguments.addAll(uri.queryParameters);
      //   if (id.isNotEmpty) arguments['id'] = id;
      //   final routeSettings = RouteSettings(name: settings.name, arguments: arguments);
      //   // final x = uri.removeFragment().path;
        
      //   // Сохраняем последний маршрут, по которому ходил пользователь
      //   // TODO: Кстати, а, может быть, нужно сохранять весь стек маршрутов, чтобы сохранялась вся история переходов? 
      //   // Если он пуст, то тогда идем по маршруту поумолчанию
      //   repository.lastRoute = Uri(path: uri.path, queryParameters: arguments).toString();

      //   // Ищем маршрут без всяческих параметров
      //   final rootRoute = uri.path.substring(0, uri.path.lastIndexOf('/'));
      //   switch (rootRoute) {
      //     case DomainContentPage.routeName:
      //       // Этот маршрут не работает без идентификатора домена среди аргументов
      //       if (arguments.isEmpty) break;
      //       return MaterialPageRoute(builder: (context) => DomainContentPage(repository), settings: routeSettings);
      //     case TaskListPage.routeName:
      //       // Этому маршруту нужен идентификатор родителя среди аргументов
      //       if (arguments.isEmpty) break;
      //       return MaterialPageRoute(builder: (context) => TaskListPage(repository: repository,), settings: routeSettings);
      //     default:
      //       return MaterialPageRoute(
      //         builder: (context) => HomePage(title: AppLocalizations.of(context).homePageName, repository: repository),
      //         settings: const RouteSettings(name: '/home', arguments: null)
      //       );
      //   }
      //   return MaterialPageRoute(
      //     builder: (context) => HomePage(title: AppLocalizations.of(context).homePageName, repository: repository),
      //     settings: const RouteSettings(name: '/home', arguments: null)
      //   );
      // },
    );
    return x;
  }
}

// Класс для парсинга информации о маршруте
class AppRouteInformationParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = routeInformation.uri;

    // Определение маршрута на основе URL

    return uri;
  }
}

typedef WidgetConstructor = Widget Function(Repository, Map<Symbol, dynamic>);

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

// Изменяем штатный навигатор, чтобы переопределить вызовы pushNamed для совмещения
// декларативного и динамического подхода к управлению стеком навигации.
// Все эти приседания приходится делать ради того, чтобы можно было инициализировать
// стек навигатора сохраненным ранее стеком в репозитории.
// Этот стек можен быть созранен в рамках другой сессии использования на других устройствах.
class AppNavigator extends Navigator {
  const AppNavigator({
    super.key,
    super.pages,
    super.onDidRemovePage,
    super.onGenerateRoute
  }) : super();

  @override
  NavigatorState createState() => AppNavigatorState();
}

class AppNavigatorState extends NavigatorState {

  @override
  Future<T?> pushNamed<T extends Object?>(String routeName, {Object? arguments}) {
    final appRouterDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
    return appRouterDelegate.pushNamed(context, routeName, arguments: arguments);
  }

  @override
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(String routeName, {TO? result, Object? arguments}) {
    final appRouterDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
    return appRouterDelegate.pushNamed(context, routeName, arguments: arguments);
  }
}

class NavStackEntry {
  NavStackEntry(
    this.path,
    this.args
  );
  String path;
  Map<Symbol, dynamic> args;
}

// Класс для определения маршрутов
class AppRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  final GlobalKey<AppNavigatorState> _navigatorKey;

  AppRouterDelegate() : _navigatorKey = GlobalKey<AppNavigatorState>();

  @override
  GlobalKey<AppNavigatorState> get navigatorKey => _navigatorKey;

  Uri _routePath = Uri.parse('/');

  @override
  Uri get currentConfiguration => _routePath;

  Repository repository = Repository();

  Map<String, WidgetConstructor> pageTable = {
    "/": (Repository repo, var args) => Function.apply(IntroductionPage.new, [repo], args),
    "/splash": (Repository repo, var args) => Function.apply(SplashScreen.new, [], {
      #nextRoute: "/",
      #lottieAsset: "assets/Lottie/Animation - 1719759862682.json",
      #repository: repo,
      #backgroundTask: locateUser
    }),
    "/404": (Repository repo, var args) => Function.apply(IntroductionPage.new, [repo], args),
    "/home": (Repository repo, var args) => Function.apply(HomePage.new, [repo], args),
    "/domains": (Repository repo, var args) => Function.apply(DomainListPage.new, [repo], args),
    DomainContentPage.routeName: (Repository repo, var args) => Function.apply(DomainContentPage.new, [repo], args),
    TaskListPage.routeName: (Repository repo, var args) => Function.apply(TaskListPage.new, [repo], args)
  };

  // Map по-умолчанию работает как стек. Храним в ней историю переходов на новые страницы + аргументы.
  // Эту историю нужно писать в репозиторий.
  List<NavStackEntry> navStack = [
    NavStackEntry("/splash", {}),
  ];

  @override
  Widget build(BuildContext context) {
    return AppNavigator(
      key: navigatorKey,
      pages: [
        for (var route in navStack)
          MaterialPage(
            child: (pageTable[route.path] ?? pageTable["/"]!)(repository, route.args),
          ),
      ],
      onDidRemovePage: (Page<Object?> page) {
        navStack.removeLast();
        notifyListeners();
      },
    );
  }

  @override
  Future<void> setNewRoutePath(Uri path) async {
    _routePath = path;
  }

  Future<T?> pushNamed<T extends Object?>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) async {
    // Сюда перенаправляется PushNamed из навигатора (или его состояния),
    // чтобы тут можно было занавигироваться в декларативном режиме,
    // но по именованому линку

    // Тут хотим извлечь из uri аргументы или идентификаторы
    
    // В нужно еще добиться того, чтобы приложение реагировало на адресную строку браузера
    // и, соответственно, чтобы можно было переходить по ссылкам на определенные экраны приложения.
    // А также изменять по определенным правилам (каким?) navStack при различных событиях
    // (типа перехода по внешней ссылке).
    final args = ModalRoute.of(context)!.settings.arguments;
    final _arguments = (arguments ?? <Symbol, dynamic>{}) as Map<Symbol, dynamic>;
    final uri = Uri.parse(routeName);
    final id = uri.path.split('/').last;
    final rootRoute = uri.path.substring(0, uri.path.lastIndexOf('/'));
    if (rootRoute.isNotEmpty) {
      _arguments[#id] = id;
      routeName = rootRoute;
    }
    if (uri.hasQuery) _arguments.addAll(uri.queryParameters as Map<Symbol, dynamic>);
    navStack.add(NavStackEntry(routeName, _arguments));
    notifyListeners();
  }
}
