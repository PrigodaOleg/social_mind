# Навигация: роутинг, экраны, вложенность, параметры, deeplinks, сохранение истории

## Библиотека и точка настройки роутинга

- Роутинг реализован вручную на `Router`/`RouterDelegate`/`RouteInformationParser` из `package:flutter/material.dart`, сторонняя библиотека роутинга (`go_router` и т.п.) не используется — классы объявлены в `lib/ui/navigation.dart:10-179`.
- Корневой виджет подключает роутинг через `MaterialApp.router(routerDelegate: AppRouterDelegate(...), routeInformationParser: AppRouteInformationParser())` — `lib/app.dart:34, 45-65`.
- Веб-URL-стратегия задаётся в точке входа: `usePathUrlStrategy()` из `package:flutter_web_plugins/url_strategy.dart` — `lib/main.dart:7, 12`.

## Основные классы навигации

- `AppRouterDelegate extends RouterDelegate<Uri> with ChangeNotifier, PopNavigatorRouterDelegateMixin<Uri>` — держит таблицу маршрутов `_routes`, текущий путь `_routePath`, стек `navStack` и единственный экземпляр `Repository repository = Repository();` — `lib/ui/navigation.dart:62-90`.
- `AppRouteInformationParser extends RouteInformationParser<Uri>` — преобразует `RouteInformation` в `Uri` без дополнительного разбора (`parseRouteInformation` просто возвращает `routeInformation.uri`) и восстанавливает адресную строку как есть (`restoreRouteInformation` возвращает `RouteInformation(uri: configuration)`) — `lib/ui/navigation.dart:42-58`.
- `AppNavigator extends Navigator` и `AppNavigatorState extends NavigatorState` переопределяют `pushNamed`/`pushReplacementNamed`, перенаправляя их в `AppRouterDelegate`, и добавляют метод `replaceNavigationStack(List<NavStackEntry> navStack)` — `lib/ui/navigation.dart:10-39`.
- `NavStackEntry` (`lib/repository/navigation/navigation_stack.dart:8-31`) — элемент стека с полями `path` и `args` (`Map<String, dynamic>`), с `toJson()`/`fromJson()` для сериализации.

## Список экранов и их `routeName`

- `SplashScreen.routeName = '/splash'` — `lib/ui/pages/splash_screen.dart:9`.
- `LoginPage.routeName = '/login'` — `lib/ui/pages/login.dart:23`.
- `HomePage.routeName = '/home'` — `lib/ui/pages/home.dart:11`.
- `DomainListPage.routeName = '/domains'` — `lib/ui/pages/domain_list.dart:9`.
- `DomainContentPage.routeName = '/domain'` — `lib/ui/pages/domain_content.dart:9`.
- `TaskListPage.routeName = '/tasklist'` — `lib/ui/pages/task_list.dart:13`.
- `ContactListPage.routeName = '/contacts'` — `lib/ui/pages/contact_list.dart:10`.
- `UnknownPage.routeName = '/unknownpage'` — `lib/ui/pages/unknown_page.dart:8`.
- Дополнительные `routeName`, объявленные в классах страниц, но не включённые в таблицу `routes` в `lib/app.dart:56-63`: `CreateUserPage.routeName = '/create_user'` (`lib/ui/pages/login_user_create.dart:7`), `LoginUserExistingPage.routeName = '/login_user_existing'` (`lib/ui/pages/login_user_existing.dart:8`), `SaveUserCredentialsPage.routeName = '/save_credentials'` (`lib/ui/pages/login_user_save_credentials.dart:7`) — эти три страницы открываются не через `Navigator.pushNamed`, а через `showModalBottomSheet` (см. раздел «Вложенность»).

## Таблица маршрутов

- Таблица `routes` строится в `App.build` и передаётся в конструктор `AppRouterDelegate`: ключи — `LoginPage.routeName`, `HomePage.routeName`, `DomainListPage.routeName`, `DomainContentPage.routeName`, `TaskListPage.routeName`, `ContactListPage.routeName`, значения — конструкторы страниц (`LoginPage.new` и т.п.) — `lib/app.dart:45-64`.
- `AppRouterDelegate` добавляет в `_routes` ещё и `initialRoute.path` при создании: `_routes = {initialRoute.path: initialRoute.constructor}..addAll(routes)` — `lib/ui/navigation.dart:74`.
- Начальный маршрут задаётся отдельно как `initialRoute` — запись `(path: SplashScreen.routeName, constructor: SplashScreen.new, args: {...})` — `lib/app.dart:46-54`.
- Маршрут для не найденных путей задаётся как `unknownRoute` — `(args: {}, constructor: UnknownPage.new, path: UnknownPage.routeName)` — `lib/app.dart:55`.
- В `AppRouterDelegate.build` для каждого элемента `navStack` строится `MaterialPage`, конструктор страницы выбирается из `_routes[route.path] ?? unknownRoute.constructor`, при отсутствии маршрута используются аргументы `unknownRoute.args` — `lib/ui/navigation.dart:97-120`.

## Вложенность экранов

- Основной навигационный стек (`navStack`) — плоский список `NavStackEntry`, без вложенных `Navigator` для разделов приложения; единственный `AppNavigator` строится в `AppRouterDelegate.build` — `lib/ui/navigation.dart:99-119`.
- Вложенность реализуется через модальные листы поверх текущего экрана, а не через отдельный маршрут в `navStack`: `LoginPage` открывает `SaveUserCredentialsPage`, `LoginUserExistingPage`, `CreateUserPage` через `showModalBottomSheet(context: context, builder: (BuildContext context) => ...)` — `lib/ui/pages/login.dart:41-47, 61-67, 79-92`.
- Результат из вложенного модального экрана возвращается через `Navigator.pop(value)` и обрабатывается вызывающей стороной синхронно после `await showModalBottomSheet(...)`: `bool? isPerformed = await showModalBottomSheet(...); if (isPerformed == true) {...}` — `lib/ui/pages/login.dart:42-56`; `n.pop(true)`/`n.pop(false)` в `SaveUserCredentialsPage` — `lib/ui/pages/login_user_save_credentials.dart:21, 37, 42`; `n.pop(user)` в `CreateUserPageState` — `lib/ui/pages/login_user_create.dart:46, 67, 86`; `n.pop(tryingUser)` в `LoginUserExistingPage` — `lib/ui/pages/login_user_existing.dart:36`.
- Внутри страниц с BLoC используется двойная обёртка `BlocProvider` — внешняя создаёт BLoC на уровне `<Feature>Page`, внутренняя в `<Feature>View` добавляет стартовое событие и оборачивает `BlocBuilder`: `TaskListPage`/`TaskListView` — `lib/ui/pages/task_list.dart:27-46`.

## Передача параметров между экранами

- Каждая страница получает `Repository repository` как первый позиционный параметр конструктора, остальные параметры (`id`, `title`) — именованные опциональные: `TaskListPage(this.repository, {super.key, this.id})` — `lib/ui/pages/task_list.dart:15-21`; `DomainContentPage(this.repository, {super.key, this.id})` — `lib/ui/pages/domain_content.dart:7`.
- При построении `MaterialPage` в `AppRouterDelegate.build` аргументы страницы передаются через `Function.apply(constructor, [repository], route.args.map((key, value) => MapEntry(Symbol(key), value)))`, то есть ключи `Map<String, dynamic> args` конвертируются в именованные параметры конструктора по `Symbol` — `lib/ui/navigation.dart:104-110`.
- Переход с параметрами инициируется через `Navigator.of(context).pushNamed('${TaskListPage.routeName}/${domain.id}')` — путь с ID домена в конце — `lib/ui/pages/domain_content.dart:43`.
- `AppRouterDelegate.pushNamed` разбирает такой путь: берёт последний сегмент как `id`, обрезает `routeName` до родительского пути, если он не пуст, кладёт `id` в `symbolArguments['id']`, и добавляет `query`-параметры через `uri.queryParameters` — `lib/ui/navigation.dart:127-151`.
- Итоговая запись `NavStackEntry(routeName, symbolArguments)` добавляется в `navStack`, а сам `navStack` сохраняется в репозиторий при каждом переходе: `repository.lastNavStack = navStack;` — `lib/ui/navigation.dart:151-155`.
- `HomePage` инициирует переходы без параметров: `n.pushNamed(TaskListPage.routeName)`, `n.pushNamed(DomainListPage.routeName)`, `n.pushNamed(ContactListPage.routeName)`, `n.pushNamed(LoginPage.routeName)` — `lib/ui/pages/home.dart:52-66`.

## Deeplinks

- Отдельного парсинга deeplink-схем (например `closers://...`) не реализовано: `AppRouteInformationParser.parseRouteInformation` возвращает входной `Uri` без изменений — `lib/ui/navigation.dart:43-52`.
- Deeplink из веб-адресной строки распознаётся стандартным механизмом `MaterialApp.router` + `usePathUrlStrategy()`: путь `Uri` берётся из адресной строки браузера, `restoreRouteInformation` отображает текущий `_routePath` обратно в адресную строку без изменений — `lib/ui/navigation.dart:53-57`, `lib/main.dart:12`.
- Комментарий в коде фиксирует, что анализ входящего URL из браузера — предполагаемое, но нереализованное место: `// Здесь мы как будто бы и должны навернуть логику с анализом маршрута, который приезжает из адресной строки браузера` — `lib/ui/navigation.dart:47-49`.
- При переходе по прямой ссылке на несуществующий в локальном хранилище домен `DomainContentPage.build` обрабатывает случай `domain == null`, показывая кнопку перехода на `HomePage.routeName`, с комментарием `// Пока я не разобрался, что делать, мы пришли в это окно по прямой ссылке из WEB на домен, а его нет в репозитории` — `lib/ui/pages/domain_content.dart:23-31`.
- Сборка web publish-пути задаётся флагом `--base-href /social_mind/` в CI: `flutter build web --release --base-href /social_mind/ ...` — `.github/workflows/dart.yml:77-82`.

## Сохранение истории навигации между запусками

- `AppRouterDelegate.pushNamed` и `AppRouterDelegate.build.onDidRemovePage` при каждом изменении стека записывают его в репозиторий: `repository.lastNavStack = navStack;` — `lib/ui/navigation.dart:113-118, 151-155`.
- `Repository.lastNavStack` — геттер/сеттер поверх `_localStorage`: `get lastNavStack => _localStorage.getOpItem('lastNavStack')?.cast<NavStackEntry>();`, `set lastNavStack(...) { if (late) return; if (lastNavStack == null) return; if (lastNavStack.isNotEmpty) { _localStorage.storeOpItem('lastNavStack', lastNavStack); } }` — `lib/repository/repository/repository.dart:508-518`.
- На уровне `IsarStorage` операционные элементы (включая `lastNavStack`) хранятся в коллекции `OperationalBox` как JSON-строка через `storeOpItem`/`getOpItem`: список `NavStackEntry` кодируется `jsonEncode(item)` и пишется в `OperationalBox.data` (`lib/local_storage/isar/isar_storage.dart:169-182`), при чтении `getOpItem` разбирает JSON-массив и десериализует каждый элемент через `NavStackEntry.fromJson` (`lib/local_storage/isar/isar_storage.dart:154-167`).
- Восстановление стека при следующем запуске идёт через `SplashScreen`: `App.locateUser(repository)` вызывает `repository.init()` и возвращает `repository.lastNavStack` — `lib/app.dart:12-21`; `SplashScreen.routeFunction` получает этот результат как `backgroundTask`, и если стек не пуст, вызывает `(Navigator.of(context) as AppNavigatorState).replaceNavigationStack(lastNavStack)` — `lib/ui/pages/splash_screen.dart:27-34`.
- `AppNavigatorState.replaceNavigationStack` делегирует в `AppRouterDelegate.replaceNavigationStack(newNavStack)`, которая напрямую подменяет поле `navStack = newNavStack;` (без пересохранения в репозиторий на этом шаге) — `lib/ui/navigation.dart:35-38, 175-178`.
