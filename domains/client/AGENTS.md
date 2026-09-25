# AGENTS.md

## 1. Проект

Клиентское Flutter-приложение "Closers" (пакет `closers`) — таск-менеджер с доменами,
пользователями и задачами. Хранит данные локально (Isar) и синхронизирует их с удалённым
хранилищем (Firebase Realtime Database) через собственный слой `Repository`.

## 2. Команды

- Установка зависимостей: `flutter pub get` — `.github/workflows/dart.yml:40`
- Тесты: `flutter test` — `.github/workflows/dart.yml:56`
- Сборка APK: `flutter build apk --split-per-abi --dart-define ...` — `.github/workflows/dart.yml:66-72`
- Сборка web: `flutter build web --release --base-href /social_mind/ --dart-define ...` — `.github/workflows/dart.yml:77-82`
- Настройка Firebase/FlutterFire (разово, локально): `firebase_setup.ps1`

Кодогенерация: команда запуска `build_runner` в репозитории не найдена (пакет есть в
`pubspec.yaml:89`, но скрипта вызова нет). Существующий `lib/local_storage/isar/isar_storage.g.dart`
сгенерирован ранее, `build.yaml` отсутствует.

## 3. Тесты

- Расположение: `test/` — `repository_test.dart`, `models_test.dart`, `local_database_test.dart`.
- Логику с зависимостями (`Repository`) тестировать через моки: `class MockX extends LocalStorage`
  / `extends RemoteStorage` с `@override` нужных методов — `test/repository_test.dart:6-60`.
- Чистые функции (например `JsonHelper` в `models.dart`) — простые `test()` без моков,
  см. `test/models_test.dart`.
- Тесты, требующие реальную Isar-БД, инициализируют нативный бинарник в `setUpAll`
  (`test/isar_windows_x64.dll` / `test/libisar_linux_x64.so`) и закрывают БД в `tearDownAll` —
  `test/local_database_test.dart:16-38`.
- Стиль: `flutter_test`, `group('...', () { test('...', () async {...}); });`.
- Новый тест — файл `test/<name>_test.dart`, импорт кода через `package:closers/...`.

## 4. Правила правки кода

- Модели данных → `lib/repository/models/` (новый файл — `part of 'models.dart'`, см. `user.dart`, `task.dart`).
- Работа с хранилищами/синхронизация → `lib/repository/repository/repository.dart`.
- Локальное хранилище → `lib/local_storage/` (интерфейс `local_storage.dart`, реализация `isar/`).
- Удалённое хранилище → `lib/remote_storage/` (интерфейс `remote_storage.dart`, реализация `firebase_realtime_database.dart`).
- Бизнес-логика (BLoC) → `lib/state/<feature>/<feature>.dart`, регистрируется в `lib/state/state.dart`.
- Экраны → `lib/ui/pages/`, общие виджеты → `lib/ui/widgets/`, экспорт — в `lib/ui/ui.dart`.
- Роутинг/маршруты → добавлять страницу в таблицу `routes` в `lib/app.dart`.
- Локализация → строки в `lib/ui/l10n/app_en.arb` и `app_ru.arb`.

## 5. Запреты (не редактировать)

- `lib/**/*.g.dart` (генерируется, напр. `isar_storage.g.dart`)
- `lib/ui/l10n/app_localizations*.dart` (генерируются из `.arb`)
- `lib/firebase_options.dart` (генерируется FlutterFire CLI)
- `pubspec.lock`, `.dart_tool/`, `build/`
- `android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/` (нативные проекты Flutter)
- `.env`, `android/app/google-services.json` (секреты/креды)

## 6. docs/ai/

- `docs/ai/00-overview.md` — факты о структуре, слоях, роутинге, зависимостях, тестах и CI проекта.
- `docs/ai/01-architecture.md` — слои, зависимости между ними, границы ответственности, поток данных от UI до хранения.
- `docs/ai/02-conventions.md` — соглашения Dart/Flutter в проекте: именование файлов и классов, структура виджетов, обработка ошибок, логирование, работа с асинхронностью.
- `docs/ai/03-state.md` — выбранный подход к состоянию, где живёт бизнес-логика, как состояние передаётся между экранами, как тестируется.
- `docs/ai/04-navigation.md` — роутинг, список экранов, вложенность, передача параметров, deeplinks, созранение истории навигации между запусками.
- `docs/ai/05-build.md` — сборка, flavors, переменные окружения, кодогенерация, тесты, CI — с точными командами.
- `docs/ai/07-glossary.md` — доменные термины проекта и их соответствие классам в коде.

## 7. Доменные термины

- `Model` — базовый класс всех сущностей (`id`, `children`/`parents`-связи, `sync`).
- `Domain`, `User`, `Task` — конкретные модели, наследники `Model`.
- `Registry`/`Transaction` — журнал изменений модели для разрешения конфликтов синхронизации.
- `Repository` — фасад, объединяющий локальное и удалённое хранилище, точка входа для UI/BLoC.
- `LocalStorage`/`RemoteStorage` — абстракции хранения (Isar / Firebase Realtime Database).
- `SyncStatus` — состояние синхронизации модели (`synced`/`syncing`/`no`).
- `NavStackEntry` — элемент сохранённого стека навигации (декларативный роутер).
- rebase/merge conflict — процедура слияния локальных и удалённых изменений модели.
