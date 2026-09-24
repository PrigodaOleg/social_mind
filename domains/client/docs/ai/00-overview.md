# Обзор проекта (факты, без изменений в коде)

## 1. Дерево `lib/` (до 3-го уровня вложенности)

Путь корня: `domains/client/lib/`

```
lib/
├── main.dart
├── app.dart
├── firebase_options.dart
├── local_storage/
│   ├── local_storage.dart
│   ├── _pubspec.yaml
│   ├── hive/
│   │   └── hive_storage.dart
│   └── isar/
│       ├── isar_storage.dart
│       └── isar_storage.g.dart
├── remote_storage/
│   ├── remote_storage.dart
│   ├── _pubspec.yaml
│   ├── firebase_realtime_database.dart
│   └── firebase_realtime_database_rules.json
├── repository/
│   ├── repository.dart
│   ├── _pubspec.yaml
│   ├── repository/
│   │   └── repository.dart
│   ├── models/
│   │   ├── models.dart
│   │   ├── user.dart
│   │   ├── domain.dart
│   │   ├── task.dart
│   │   └── registry.dart
│   └── navigation/
│       └── navigation_stack.dart
├── state/
│   ├── state.dart
│   ├── _pubspec.yaml
│   ├── task_list/
│   │   └── task_list.dart
│   ├── domain_list/
│   │   └── domain_list.dart
│   └── contact_list/
│       └── contact_list.dart
└── ui/
    ├── ui.dart
    ├── navigation.dart
    ├── _pubspec.yaml
    ├── pages/
    │   ├── home.dart
    │   ├── login.dart
    │   ├── login_user_create.dart
    │   ├── login_user_existing.dart
    │   ├── login_user_save_credentials.dart
    │   ├── splash_screen.dart
    │   ├── domain_list.dart
    │   ├── domain_content.dart
    │   ├── task_list.dart
    │   ├── contact_list.dart
    │   ├── user_profile.dart
    │   └── unknown_page.dart
    ├── widgets/
    │   └── task_list_tile.dart
    └── l10n/
        ├── app_localizations.dart
        ├── app_localizations_en.dart
        ├── app_localizations_ru.dart
        ├── app_en.arb
        └── app_ru.arb
```
Источник перечисления файлов: результат glob по `lib/**` (`domains/client/lib`).

## 2. Точка входа и обёртки до `runApp`

Файл: `lib/main.dart`.

Последовательность в `main()`:
1. `WidgetsFlutterBinding.ensureInitialized()` — `lib/main.dart:11`
2. `usePathUrlStrategy()` (пакет `flutter_web_plugins`) — `lib/main.dart:12`
3. `Firebase.initializeApp(name: options.projectId, options: DefaultFirebaseOptions.currentPlatform)` — `lib/main.dart:13-17`
4. `runApp(const App())` — `lib/main.dart:20`

Всё оборачивается в `try/catch` с `print(error)` в `catch` — `lib/main.dart:10-23`.

Строки про `FirebaseCrashlytics` закомментированы — `lib/main.dart:18-19` (не используется).

Виджет `App` (`lib/app.dart`) — корневой `StatelessWidget`, строит `MaterialApp.router` с `routerDelegate: AppRouterDelegate(...)` и `routeInformationParser: AppRouteInformationParser()` — `lib/app.dart:33-66`.

## 3. Слои приложения

| Слой | Расположение | Путь |
|---|---|---|
| UI (виджеты, страницы, навигация) | `lib/ui/` | `lib/ui/ui.dart`, `lib/ui/pages/*.dart`, `lib/ui/navigation.dart`, `lib/ui/widgets/task_list_tile.dart` |
| Бизнес-логика (state management, BLoC) | `lib/state/` | `lib/state/state.dart`, `lib/state/task_list/task_list.dart`, `lib/state/domain_list/domain_list.dart`, `lib/state/contact_list/contact_list.dart` |
| Доступ к данным — локальное хранилище | `lib/local_storage/` | `lib/local_storage/local_storage.dart` (абстрактный класс `LocalStorage`), реализации: `lib/local_storage/isar/isar_storage.dart` (активная, подключена через `export` в `local_storage.dart:4`), `lib/local_storage/hive/hive_storage.dart` (есть в коде, но `export` закомментирован — `lib/local_storage/local_storage.dart:3`) |
| Доступ к данным — удалённое хранилище | `lib/remote_storage/` | `lib/remote_storage/remote_storage.dart` (абстрактный класс `RemoteStorage`), реализация `lib/remote_storage/firebase_realtime_database.dart` (класс `FirebaseStorage`) |
| Координация хранилищ / синхронизация | `lib/repository/repository/repository.dart` | класс `Repository` — использует `LocalStorage` и `RemoteStorage` (`lib/repository/repository/repository.dart:6-7, 89-98`) |
| Модели данных | `lib/repository/models/` | `lib/repository/models/models.dart` (базовый `sealed class Model`), `user.dart`, `domain.dart`, `task.dart`, `registry.dart` — подключены как `part of 'models.dart'` (`lib/repository/models/models.dart:10-13`, `lib/repository/models/user.dart:1`) |
| Навигационная модель | `lib/repository/navigation/navigation_stack.dart` | класс `NavStackEntry extends Equatable` с полями `path`, `args` (`Map<String, dynamic>`), методами `toJson()`/`fromJson()` (`lib/repository/navigation/navigation_stack.dart:8-31`); используется в `lib/ui/navigation.dart` |

## 4. State management

Библиотека: `bloc` (`^9.2.1`) + `flutter_bloc` (`^9.1.1`) — заявлены в `pubspec.yaml:59, 65`.

BLoC-классы объявлены в `lib/state/`:
- `TaskListBloc` — `lib/state/task_list/task_list.dart:6`
- `DomainListBloc` — `lib/state/domain_list/domain_list.dart:6`
- `ContactListBloc` — `lib/state/contact_list/contact_list.dart:6`

Инициализация (создание инстансов) происходит через `BlocProvider` прямо на страницах:
- `DomainListPage.build` создаёт `DomainListBloc` — `lib/ui/pages/domain_list.dart:22-23`
- `TaskListPage.build` создаёт `TaskListBloc` через `BlocProvider(create: (context) => TaskListBloc(repository: repository, parentId: id ?? repository.myId ?? ''))` — `lib/ui/pages/task_list.dart:27-28`
- `ContactListPage.build` создаёт `ContactListBloc` через `BlocProvider(create: (context) => ContactListBloc(repository: repository))` — `lib/ui/pages/contact_list.dart:23-24`

Единого глобального `MultiBlocProvider`/`RepositoryProvider` над `MaterialApp` не найдено — не найдено.

## 5. Роутинг

Собственная реализация роутинга (не сторонняя библиотека роутинга типа `go_router`) на основе `Router`/`RouterDelegate` из `package:flutter/material.dart`.

Классы: `AppRouterDelegate`, `AppRouteInformationParser`, `AppNavigator`, `AppNavigatorState` — все объявлены в `lib/ui/navigation.dart:10-179`.

Таблица маршрутов (`routes`) передаётся в конструктор `AppRouterDelegate` внутри `App.build` — `lib/app.dart:45-64`:
```
LoginPage.routeName, HomePage.routeName, DomainListPage.routeName,
DomainContentPage.routeName, TaskListPage.routeName, ContactListPage.routeName
```
Начальный маршрут (`initialRoute`) — `SplashScreen.routeName` с параметрами `nextRoute: LoginPage.routeName`, `lottieAsset`, `backgroundTask: locateUser` — `lib/app.dart:46-54`.
Маршрут для неизвестных путей (`unknownRoute`) — `UnknownPage.routeName` — `lib/app.dart:55`.

`routeName` каждой страницы объявлен как статическое поле внутри самого класса страницы, например `SplashScreen.routeName = '/splash'` — `lib/ui/pages/splash_screen.dart:9`, `DomainListPage.routeName = '/domains'` — `lib/ui/pages/domain_list.dart:9`.

## 6. `pubspec.yaml` — ключевые зависимости

Путь: `pubspec.yaml` (`domains/client/pubspec.yaml`). Версия проекта: `1.0.0+1`, SDK: `>=3.3.1 <4.0.0` (`pubspec.yaml:19-22`). Имя пакета — `closers` (`pubspec.yaml:1`), что подтверждается импортами `package:closers/...` во всех файлах.

| Пакет | Версия (constraint) | Резолвнутая версия (pubspec.lock) | Назначение (по комментарию в pubspec.yaml) |
|---|---|---|---|
| `cupertino_icons` | `^1.0.6` | `1.0.9` (`pubspec.lock:196-203`) | иконки iOS-стиля |
| `firebase_core` | `^4.9.0` | `4.9.0` (`pubspec.lock:284-291`) | Firebase база |
| `hive_flutter` | `^1.1.0` | `1.1.0` (`pubspec.lock:440-447`) | local_storage |
| `isar_plus` | `^1.2.6` | `1.2.6` (`pubspec.lock:504-511`) | local_storage |
| `path_provider` | `^2.1.6` | `2.1.6` (`pubspec.lock:680-687`) | local_storage |
| `firebase_database` | `^12.4.1` | `12.4.1` (`pubspec.lock:308-315`) | remote_storage |
| `firebase_auth` | `^6.5.1` | `6.5.1` (`pubspec.lock:260-267`) | remote_storage |
| `equatable` | `^2.0.5` | `2.0.8` (`pubspec.lock:220-227`) | repository |
| `uuid` | `^4.4.0` | `4.5.3` (`pubspec.lock:981-988`) | repository |
| `hashlib` | `^2.3.4` | `2.3.4` (`pubspec.lock:416-423`) | repository |
| `bloc` | `^9.2.1` | `9.2.1` (`pubspec.lock:60-67`) | state |
| `flutter_localizations` (sdk: flutter) | — | `0.0.0` (sdk-пакет, `pubspec.lock:377-381`) | ui (локализация) |
| `intl` | `^0.20.2` | `0.20.2` (`pubspec.lock:488-495`) | ui |
| `flutter_bloc` | `^9.1.1` | `9.1.1` (`pubspec.lock:345-352`) | ui |
| `lottie` | `^3.1.2` | `3.3.3` (`pubspec.lock:592-599`) | ui |
| `animated_splash_screen` | `^1.3.0` | `1.3.0` (`pubspec.lock:28-35`) | ui |
| `page_transition` | `^2.1.0` | `2.2.2` (`pubspec.lock:656-663`) | ui |
| `share_plus` | `^13.1.0` | `13.1.0` (`pubspec.lock:800-807`) | ui |
| `url_launcher` | `^6.3.2` | `6.3.2` (`pubspec.lock:917-924`) | ui |
| `flutter_web_plugins` (sdk: flutter) | — | `0.0.0` (sdk-пакет, `pubspec.lock:387-391`) | url-strategy (`main.dart`) |
| `flutter_test` (sdk: flutter, dev) | — | `0.0.0` (sdk-пакет, `pubspec.lock:382-386`) | тесты |
| `flutter_lints` | `^6.0.0` (dev) | `6.0.0` (`pubspec.lock:369-376`) | линтер |
| `isar_plus_flutter_libs` | `^1.2.6` (dev) | `1.2.6` (`pubspec.lock:512-519`) | нативные бинарники isar |
| `build_runner` | `^2.4.9` (dev) | `2.15.0` (`pubspec.lock:100-107`) | кодогенерация |
| `flutter_gen` | `^5.1.1` (dev) | `5.9.0` (`pubspec.lock:353-360`) | генерация assets/l10n (по комментарию) |

Версии в столбце "резолвнутая" сверены построчно по `pubspec.lock` (каждая ячейка указывает точный диапазон строк блока пакета).

Закомментированные (не активные) зависимости в `pubspec.yaml`: `cloud_firestore` (`pubspec.yaml:49`), `hive_generator`, `isar_generator` (`pubspec.yaml:84-85`).

Assets: `assets/Lottie/` — `pubspec.yaml:99`.
`flutter.generate: true` и `flutter_intl.enabled: true` — `pubspec.yaml:132-134`.

## 7. Flavors и переменные окружения

Flavors (Android/iOS flavor-конфигурации) — не найдено.

Переменные окружения задаются через `--dart-define` / `String.fromEnvironment`:
- Определение и чтение переменных: `lib/firebase_options.dart:44-51` и далее (класс `DefaultFirebaseOptions`), например `CLOSERS_WEB_API_KEY`, `CLOSERS_PROJECT_ID`, `CLOSERS_DATABASE_URL` и т.д.
- Локальный файл значений для разработки: `.env` (`domains/client/.env:1-21`) — содержит те же ключи (`CLOSERS_PROJECT_ID`, `CLOSERS_WEB_API_KEY`, `CLOSERS_ANDROID_API_KEY`, `CLOSERS_IOS_API_KEY`, `CLOSERS_MACOS_API_KEY`, `CLOSERS_WINDOWS_API_KEY` и др.).
- Механизм подстановки `.env` при локальном запуске: конфигурация VS Code `"Web debug"` в `.vscode/launch.json:8-15` запускает `program: "lib/main.dart"` с аргументами `["-d", "chrome", "--dart-define-from-file=.env"]`, то есть Flutter сам читает пары `КЛЮЧ=значение` из `.env` и подставляет их в `String.fromEnvironment(...)`.
- В CI (`.github/workflows/dart.yml:66-82`) переменные передаются через `--dart-define` из `secrets.CLOSERS_*` (GitHub Actions secrets), а не из `.env` — `.env` используется только для локальной разработки через `.vscode/launch.json`.
- Скрипт `firebase_setup.ps1` (`domains/client/firebase_setup.ps1`) — установка Firebase CLI и `flutterfire configure`, не относится к flavors/env напрямую.

## 8. Кодогенерация

Инструмент: `build_runner` (`pubspec.yaml:89`, dev-зависимость).

Сгенерированный файл, реально присутствующий в `lib/`:
- `lib/local_storage/isar/isar_storage.g.dart`, подключён как `part 'isar_storage.g.dart'` в `lib/local_storage/isar/isar_storage.dart:12`. Генератор для Isar (`isar_generator`) в `pubspec.yaml` закомментирован (`pubspec.yaml:85`), поэтому точный генератор, которым файл создавался — не проверено (в комментарии указано на `isar_plus`, но соответствующего `*_generator`-пакета в активных зависимостях нет).

Заготовки под кодогенерацию, которые закомментированы и не активны:
- `part 'models.g.dart';` — закомментировано в `lib/repository/models/models.dart:14`
- `part 'navigation_stack.g.dart';` — закомментировано в `lib/repository/navigation/navigation_stack.dart:4`

Аннотации `@HiveType`/`@HiveField` присутствуют в моделях (`lib/repository/models/models.dart:16-24, 68-93`, `lib/repository/models/user.dart:4, 26, 29`), что указывает на предполагавшуюся кодогенерацию через `hive_generator`, но пакет `hive_generator` закомментирован в `pubspec.yaml:84` и соответствующий `.g.dart`-файл для Hive не найден.

Файл `build.yaml` (конфигурация `build_runner`) — не найдено.
Файл `l10n.yaml` (конфигурация локализации) — не найдено, при этом `.arb`-файлы (`lib/ui/l10n/app_en.arb`, `lib/ui/l10n/app_ru.arb`) и сгенерированные `app_localizations*.dart` присутствуют — вероятно генерируются встроенным механизмом Flutter (`flutter.generate: true`, `pubspec.yaml:132`) и/или `flutter_intl` (`pubspec.yaml:133-134`), но точный механизм не проверено.

## 9. Тесты и CI

Тесты лежат в `test/` (`domains/client/test/`):
- `test/repository_test.dart` (502 строки, юнит-тесты `Repository`, содержит мок `MockLocalStorage extends LocalStorage`)
- `test/models_test.dart` (44 строки, тесты `JsonHelper` из `lib/repository/models/models.dart`)
- `test/local_database_test.dart` (312 строк, тесты `IsarStorage`, использует `flutter_test`, мокает `path_provider` через `MethodChannel`, а также требует нативные бинарники `test/isar_windows_x64.dll` и `test/libisar_linux_x64.so`)

Запуск тестов: `flutter test` — прямо не найдено отдельного скрипта в `pubspec.yaml`, но команда `flutter test` используется в CI (`.github/workflows/dart.yml:56`).

CI: GitHub Actions, файл `.github/workflows/dart.yml` (в корне репозитория `social_mind`, не в `domains/client`). Триггеры — `push`/`pull_request` в `main` с фильтром путей `domains/client/**`, а также `workflow_dispatch` (`.github/workflows/dart.yml:8-15`).

Шаги CI (`.github/workflows/dart.yml`):
1. `actions/checkout@v4` — `:26`
2. Установка JDK 17 (`actions/setup-java@v2`) — `:28-32`
3. Установка Flutter (`subosito/flutter-action@v2`) — `:35-36`
4. `flutter pub get` (workdir `./domains/client`) — `:38-40`
5. `flutter test` (workdir `./domains/client`) — `:54-56`
6. Генерация `android/app/google-services.json` из секретов — `:58-60`
7. `flutter build apk --split-per-abi` с `--dart-define` из секретов — `:62-72`
8. `flutter build web --release --base-href /social_mind/` с `--dart-define` из секретов — `:75-83`
9. Загрузка APK-артефакта (`actions/upload-artifact@v4`) — `:85-89`
10. Публикация на GitHub Pages (`actions/upload-pages-artifact@v4`, `actions/deploy-pages@v4`) — `:92-100`

Шаги `dart format` и `flutter analyze` присутствуют в файле, но закомментированы — `.github/workflows/dart.yml:42-49`.

Дополнительно найден файл `coverage/lcov.info` (`domains/client/coverage/lcov.info`) — результат покрытия тестами, команда его генерации не найдено.

---

## Открытые вопросы

1. **Механизм генерации `lib/ui/l10n/app_localizations*.dart`** — нет файла `l10n.yaml`, генератор (встроенный Flutter `gen-l10n` или `flutter_intl` плагин VSCode) не установлен по коду однозначно.
2. **Механизм генерации `isar_storage.g.dart`** — соответствующий генератор (`isar_generator`/аналог для `isar_plus`) закомментирован в `pubspec.yaml`, поэтому неясно, чем и когда файл был сгенерирован; нужно проверить историю git. Резолвнутая версия `build_runner` в `pubspec.lock:100-107` — `2.15.0`, но это не подтверждает, каким пакетом создан именно `isar_storage.g.dart`.
3. **iOS/macOS нативная конфигурация** (`ios/Runner/Info.plist`, Xcode schemes) не проверялась на предмет flavors — доказательство отсутствия flavors проверено только для Android (`android/app/build.gradle:28-67` не содержит `productFlavors`) и CI-скрипта (нет `--flavor`).
4. **Команда генерации `coverage/lcov.info`** не найдена ни в `pubspec.yaml`, ни в CI (`.github/workflows/dart.yml`) — файл присутствует, но неясно, чем и когда он создаётся.
