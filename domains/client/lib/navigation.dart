import 'package:ui/domain_list_page/domain_list_page.dart';
import 'package:flutter/material.dart';

import 'package:repository/repository.dart';
import 'package:ui/ui.dart';


// Класс для парсинга информации о маршруте
class AppRouteInformationParser extends RouteInformationParser<Uri> {
  @override
  Future<Uri> parseRouteInformation(RouteInformation routeInformation) async {
    final uri = routeInformation.uri;

    // Определение маршрута на основе URL
    // Здесь мы как будто бы и должны навернуть логику с анализом маршрута,
    // который приезжает из адресной строки браузера

    return uri;
  }
  @override
  RouteInformation? restoreRouteInformation(Uri configuration) {
    // Отображаем в адресной строке честный маршрут
    return RouteInformation(uri: configuration);
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
    return appRouterDelegate.pushNamed(routeName, arguments: arguments);
  }

  @override
  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(String routeName, {TO? result, Object? arguments}) {
    final appRouterDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
    return appRouterDelegate.pushReplacementNamed(routeName, arguments: arguments);
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
        _routePath = Uri.parse(navStack.last.path);
        notifyListeners();
      },
    );
  }

  @override
  Future<void> setNewRoutePath(Uri path) async {
    _routePath = path;
  }

  Future<T?> pushNamed<T extends Object?>(
    String routeName, {
    Object? arguments,
  }) async {
    // Сюда перенаправляется PushNamed из навигатора (или его состояния),
    // чтобы тут можно было занавигироваться в декларативном режиме,
    // но по именованому линку

    final uri = Uri.parse(routeName);
    
    final symbolArguments = (arguments ?? <Symbol, dynamic>{}) as Map<Symbol, dynamic>;

    // Достаем идентификатор из маршрута
    final id = uri.path.split('/').last;
    final rootRoute = uri.path.substring(0, uri.path.lastIndexOf('/'));
    if (rootRoute.isNotEmpty) {
      symbolArguments[#id] = id;
      routeName = rootRoute;
    }

    // Достаем параметры
    if (uri.hasQuery) symbolArguments.addAll(uri.queryParameters as Map<Symbol, dynamic>);

    // Правим стек навигатора
    navStack.add(NavStackEntry(routeName, symbolArguments));

    _routePath = uri;
    notifyListeners();
  }

  Future<T?> pushReplacementNamed<T extends Object?, TO extends Object?>(String routeName, {TO? result, Object? arguments}) async {
    navStack.removeLast();
    return pushNamed(routeName, arguments: arguments);
  }
}
