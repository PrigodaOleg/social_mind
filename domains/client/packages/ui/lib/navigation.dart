import 'package:flutter/material.dart';
import 'package:repository/repository.dart';


// Изменяем штатный навигатор, чтобы переопределить вызовы pushNamed для совмещения
// декларативного и динамического подхода к управлению стеком навигации.
// Все эти приседания приходится делать ради того, чтобы можно было инициализировать
// стек навигатора сохраненным ранее стеком в репозитории.
// Этот стек может быть сохранен в рамках другой сессии использования на других устройствах.
class AppNavigator extends Navigator {
  const AppNavigator({
    super.key,
    super.pages,
    super.onDidRemovePage
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

  void replaceNavigationStack(List<NavStackEntry> navStack) {
    final appRouterDelegate = Router.of(context).routerDelegate as AppRouterDelegate;
    appRouterDelegate.replaceNavigationStack(navStack);
  }
}

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


// Класс для определения маршрутов
class AppRouterDelegate extends RouterDelegate<Uri>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri> {
  final GlobalKey<AppNavigatorState> _navigatorKey;

AppRouterDelegate({
    required routes,
    required this.unknownRoute,
    required this.initialRoute
  }) : 
    _navigatorKey = GlobalKey<AppNavigatorState>(),
    _routePath = Uri.parse(initialRoute.path),
    navStack = [NavStackEntry(initialRoute.path, initialRoute.args)],
    _routes = {initialRoute.path: initialRoute.constructor}..addAll(routes)
  ;

  @override
  GlobalKey<AppNavigatorState> get navigatorKey => _navigatorKey;

  Uri _routePath;

  @override
  Uri get currentConfiguration => _routePath;

  Repository repository = Repository();

  // Таблица соответствия имени маршрута конструктору его страницы и его аргументам
  final Map<String, Function> _routes;
  ({String path, Function constructor, Map<String, dynamic> args}) unknownRoute;
  ({String path, Function constructor, Map<String, dynamic> args}) initialRoute;

  // Map по-умолчанию работает как стек. Храним в ней историю переходов на новые страницы + аргументы.
  // Эту историю нужно писать в репозиторий.
  // Начинаем всегда со сплешскрина, а он должен вернуть 
  List<NavStackEntry> navStack;

  @override
  Widget build(BuildContext context) {
    return AppNavigator(
      key: navigatorKey,
      pages: [
        for (var route in navStack)
          MaterialPage(
            child: Function.apply(
              _routes[route.path] ?? unknownRoute.constructor,
              [repository],
              _routes[route.path] != null ?
                route.args.map((key, value) => MapEntry(Symbol(key), value)) :
                unknownRoute.args.map((key, value) => MapEntry(Symbol(key), value))
            )
          )
      ],
      onDidRemovePage: (Page<Object?> page) {
        navStack.removeLast();
        _routePath = Uri.parse(navStack.last.path);
        repository.lastNavStack = navStack;
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
    // но по именованному линку

    final uri = Uri.parse(routeName);
    
    final symbolArguments = (arguments ?? Map<String, dynamic>()) as Map<String, dynamic>;

    // Достаем идентификатор из маршрута
    final id = uri.path.split('/').last;
    final rootRoute = uri.path.substring(0, uri.path.lastIndexOf('/'));
    if (rootRoute.isNotEmpty) {
      symbolArguments['id'] = id;
      routeName = rootRoute;
    }

    // Достаем параметры
    if (uri.hasQuery) symbolArguments.addAll(uri.queryParameters);

    // Правим стек навигатора
    navStack.add(NavStackEntry(routeName, symbolArguments));

    // Сохраняем историю переходов каждый раз при новом переходе
    // Кажется, что это расточительно, но как можно это сделать оптимальнее пока не понятно
    repository.lastNavStack = navStack;

    _routePath = uri;
    notifyListeners();

    return null;
  }

  Future<T?> pushReplacementNamed<
    T extends Object?,
    TO extends Object?
  >(String routeName, {TO? result, Object? arguments}) async {
    if (routeName.isEmpty) {
      notifyListeners();
      return null;
    }
    navStack.removeLast();
    return pushNamed(routeName, arguments: arguments);
  }

  replaceNavigationStack(List<NavStackEntry> newNavStack) {
    // Подменяем всю историю переходов кроме текущей страницы
    navStack = newNavStack;
  }
}
