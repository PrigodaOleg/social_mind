import 'package:flutter/material.dart';
import 'package:closers/repository/repository.dart';


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
    required this.initialRoute,
    this.loginRoutePath = '/login'
  }) : 
    _navigatorKey = GlobalKey<AppNavigatorState>(),
    _routePath = Uri.parse(initialRoute.path),
    navStack = [NavStackEntry(initialRoute.path, initialRoute.args)],
    _routes = {initialRoute.path: initialRoute.constructor}..addAll(routes)
  ;

  // Маршрут логина (строкой, чтобы navigation.dart не зависел от страниц):
  // на него уходит стек, когда веб-ссылка пришла без локального пользователя.
  final String loginRoutePath;

  // Отложенная цель веб-ссылки: холодный старт или отсутствие пользователя.
  NavStackEntry? _pendingLink;

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

  // Событие удаления страницы может прийти как от системного pop, так и при
  // перестроении стеков самим делегатом (pushReplacement). Во втором случае
  // запись уже удалена из navStack - повторное удаление по identity не найдет
  // совпадения и будет no-op, что защищает от двойного удаления новой страницы.
  void handlePageRemoved(Page<Object?> page) {
    final entry = page.key is ObjectKey ? (page.key as ObjectKey).value : null;
    if (entry is NavStackEntry) {
      final idx = navStack.indexWhere((e) => identical(e, entry));
      if (idx >= 0) navStack.removeAt(idx);
    }
    // Стек не должен быть пустым: Navigator не принимает пустой список страниц.
    if (navStack.isEmpty) {
      navStack.add(NavStackEntry(initialRoute.path, initialRoute.args));
    }
    _routePath = Uri.parse(navStack.last.path);
    repository.lastNavStack = navStack;
    notifyListeners();
  }

  @override
  Widget build(BuildContext context) {
    return AppNavigator(
      key: navigatorKey,
      pages: [
        for (var i = 0; i < navStack.length; i++)
          MaterialPage(
            key: ObjectKey(navStack[i]),
            child: Function.apply(
              _routes[navStack[i].path] ?? unknownRoute.constructor,
              [repository],
              _routes[navStack[i].path] != null ?
                navStack[i].args.map((key, value) => MapEntry(Symbol(key), value)) :
                unknownRoute.args.map((key, value) => MapEntry(Symbol(key), value))
            )
          )
      ],
      onDidRemovePage: handlePageRemoved,
    );
  }

  // Преобразуем веб-ссылку в запись стека: известный маршрут - как есть,
  // вложенный ('/task_list/<id>') - маршрут с id последнего сегмента,
  // все остальное - UnknownPage.
  NavStackEntry _entryFromUri(Uri uri) {
    final path = uri.path;
    if (_routes.containsKey(path)) {
      return NavStackEntry(path, {...uri.queryParameters});
    }
    final rootRoute = path.substring(0, path.lastIndexOf('/'));
    if (rootRoute.isNotEmpty && _routes.containsKey(rootRoute)) {
      return NavStackEntry(rootRoute, {'id': uri.path.split('/').last, ...uri.queryParameters});
    }
    return NavStackEntry(unknownRoute.path, {});
  }

  @override
  Future<void> setNewRoutePath(Uri path) async {
    // Защита стартового сплеша: '/' и '/splash' не перестраивают стек.
    if (path.path == '/' || path.path == initialRoute.path || path.path.isEmpty) {
      _routePath = path;
      return;
    }
    final entry = _entryFromUri(path);
    // Холодный старт: репозиторий еще не инициализирован (splash выполняет
    // locateUser) - запоминаем цель, стек не трогаем.
    if (repository.late) {
      _pendingLink = entry;
      _routePath = path;
      return;
    }
    if (repository.myId == null) {
      // Нет пользователя: сначала логин, цель ссылки применится после входа.
      _pendingLink = entry;
      navStack
        ..clear()
        ..add(NavStackEntry(loginRoutePath, {}));
    } else {
      // Переход по ссылке строит свежий стек от целевой страницы.
      navStack
        ..clear()
        ..add(entry);
    }
    _routePath = path;
    notifyListeners();
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
    // Вход выполнен (pushReplacementNamed(loginRoute) вызывается после set me):
    // применяем отложенную цель веб-ссылки, если она была.
    if (routeName == loginRoutePath && _pendingLink != null && repository.myId != null) {
      final target = _pendingLink!;
      _pendingLink = null;
      navStack.removeLast();
      return pushNamed(target.path, arguments: target.args);
    }
    navStack.removeLast();
    return pushNamed(routeName, arguments: arguments);
  }

  replaceNavigationStack(List<NavStackEntry> newNavStack) {
    // Подменяем всю историю переходов кроме текущей страницы
    navStack = newNavStack;
    // Держим маршрут-конфигурацию согласованной с восстановленным стеком,
    // иначе после восстановления URL/глубокие ссылки остаются на '/splash'.
    if (navStack.isNotEmpty) {
      _routePath = Uri.parse(navStack.last.path);
    }
    // Ссылка, пришедшая на холодном старте, ложится поверх восстановленного стека.
    if (_pendingLink != null && repository.myId != null) {
      navStack.add(_pendingLink!);
      _pendingLink = null;
      _routePath = Uri.parse(navStack.last.path);
    }
    notifyListeners();
  }
}
