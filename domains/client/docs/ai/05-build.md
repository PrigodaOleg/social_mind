# Сборка, окружение, кодогенерация, тесты, CI

## Установка зависимостей

- Команда: `flutter pub get`, используется в CI с рабочей директорией `./domains/client` — `.github/workflows/dart.yml:38-40`.
- Пакет — `closers`, SDK-констрейнт `>=3.3.1 <4.0.0` — `pubspec.yaml:1, 21-22`.

## Запуск в режиме разработки

- Локальная задача запуска в VS Code: конфигурация `"Web debug"` в `.vscode/launch.json:7-15` запускает `program: "lib/main.dart"` на устройстве `-d chrome` с `--dart-define-from-file=.env`.
- Файл `.env` в корне `domains/client` содержит пары `КЛЮЧ=значение` для всех платформ (`CLOSERS_PROJECT_ID`, `CLOSERS_PROJECT_NUMBER`, `CLOSERS_DATABASE_URL`, `CLOSERS_WEB_API_KEY`, `CLOSERS_WEB_APP_ID`, `CLOSERS_WEB_MEASUREMENT_ID`, `CLOSERS_ANDROID_API_KEY`, `CLOSERS_ANDROID_APP_ID`, `CLOSERS_IOS_API_KEY`, `CLOSERS_IOS_APP_ID`, `CLOSERS_MACOS_API_KEY`, `CLOSERS_MACOS_APP_ID`, `CLOSERS_WINDOWS_API_KEY`, `CLOSERS_WINDOWS_MEASUREMENT_ID`, `CLOSERS_WINDOWS_APP_ID`) — `.env:1-21`.
- Эти переменные читаются в коде через `String.fromEnvironment('CLOSERS_...')` в статических полях `DefaultFirebaseOptions.web`/`android`/`ios`/`macos`/`windows` — `lib/firebase_options.dart:43-92`.
- `DefaultFirebaseOptions.currentPlatform` выбирает нужный набор по `kIsWeb`/`defaultTargetPlatform`, для `TargetPlatform.linux` бросает `UnsupportedError` — `lib/firebase_options.dart:18-40`.

## Flavors

- Flavor-конфигурации (Android `productFlavors`, iOS/Xcode schemes с суффиксами) в проекте не найдены: в `android/app/build.gradle` секции `productFlavors` нет, единственная конфигурация — `defaultConfig`/`buildTypes.release` с `applicationId "com.example.closers"` — `android/app/build.gradle:46-66`.
- `buildTypes.release` подписывается debug-ключом: `signingConfig signingConfigs.debug` — `android/app/build.gradle:60-65`.

## Сборка APK (CI)

- Точная команда из CI:
  ```
  flutter build apk \
    --split-per-abi \
    --dart-define CLOSERS_PROJECT_ID=${{ secrets.CLOSERS_PROJECT_ID }} \
    --dart-define CLOSERS_PROJECT_NUMBER=${{ secrets.CLOSERS_PROJECT_NUMBER }} \
    --dart-define CLOSERS_ANDROID_API_KEY=${{ secrets.CLOSERS_ANDROID_API_KEY }} \
    --dart-define CLOSERS_ANDROID_APP_ID=${{ secrets.CLOSERS_ANDROID_APP_ID }} \
    --dart-define CLOSERS_DATABASE_URL=${{ secrets.CLOSERS_DATABASE_URL }}
  ```
  выполняется с `working-directory: ./domains/client` — `.github/workflows/dart.yml:62-72`.
- Перед сборкой APK CI генерирует `android/app/google-services.json` из секретов через `echo '{"project_info":...}' >> android/app/google-services.json` — `.github/workflows/dart.yml:58-60`.
- Артефакт публикуется шагом `actions/upload-artifact@v4` с `name: 'Closers'`, `path: './domains/client/build/app/outputs/flutter-apk/'` — `.github/workflows/dart.yml:85-89`.

## Сборка Web (CI)

- Точная команда из CI:
  ```
  flutter build web --release --base-href /social_mind/ \
    --dart-define CLOSERS_PROJECT_ID=${{ secrets.CLOSERS_PROJECT_ID }} \
    --dart-define CLOSERS_PROJECT_NUMBER=${{ secrets.CLOSERS_PROJECT_NUMBER }} \
    --dart-define CLOSERS_ANDROID_API_KEY=${{ secrets.CLOSERS_ANDROID_API_KEY }} \
    --dart-define CLOSERS_ANDROID_APP_ID=${{ secrets.CLOSERS_ANDROID_APP_ID }} \
    --dart-define CLOSERS_DATABASE_URL=${{ secrets.CLOSERS_DATABASE_URL }}
  ```
  выполняется с `working-directory: ./domains/client` — `.github/workflows/dart.yml:75-83`.
- Результат публикуется на GitHub Pages: `actions/upload-pages-artifact@v4` с `path: ./domains/client/build/web/`, затем `actions/deploy-pages@v4` — `.github/workflows/dart.yml:92-100`.
- Для веб-сборки в CI используются только `CLOSERS_ANDROID_API_KEY`/`CLOSERS_ANDROID_APP_ID` (не `CLOSERS_WEB_*`), несмотря на то что `DefaultFirebaseOptions.web` в коде читает отдельные переменные `CLOSERS_WEB_API_KEY`/`CLOSERS_WEB_APP_ID`/`CLOSERS_WEB_MEASUREMENT_ID` — сравните набор `--dart-define` в `.github/workflows/dart.yml:77-82` с полями `FirebaseOptions web` в `lib/firebase_options.dart:43-52`.

## Кодогенерация

- Зависимость на генератор объявлена, но команда его запуска (`dart run build_runner build`) не встречается ни в одном файле репозитория: `build_runner: ^2.4.9` — `pubspec.yaml:89` (dev-зависимость), файл `build.yaml` (конфигурация `build_runner`) отсутствует.
- Единственный присутствующий сгенерированный файл — `lib/local_storage/isar/isar_storage.g.dart`, подключён как `part 'isar_storage.g.dart';` в `lib/local_storage/isar/isar_storage.dart:12`.
- Пакет-генератор для Isar (`isar_generator`) закомментирован в зависимостях: `# isar_generator: ^3.1.0` — `pubspec.yaml:85`; активная dev-зависимость `isar_plus_flutter_libs: ^1.2.6` подключает только нативные бинарники, не кодогенерацию — `pubspec.yaml:86`.
- Генератор для Hive также закомментирован: `# hive_generator: ^2.0.1` — `pubspec.yaml:84`, при этом аннотации `@HiveType`/`@HiveField` присутствуют в моделях (`lib/repository/models/models.dart:16-24, 68-93`, `lib/repository/models/user.dart:4, 26, 29`), но соответствующий `.g.dart` для Hive не сгенерирован.
- Заготовки `part`-директив для будущей кодогенерации закомментированы: `// part 'models.g.dart';` — `lib/repository/models/models.dart:14`; `// part 'navigation_stack.g.dart';` — `lib/repository/navigation/navigation_stack.dart:4`.
- Локализация генерируется встроенным механизмом Flutter: `flutter.generate: true` — `pubspec.yaml:132`, плюс включён плагин `flutter_intl.enabled: true` — `pubspec.yaml:133-134`; исходники — `lib/ui/l10n/app_en.arb`, `lib/ui/l10n/app_ru.arb`, сгенерированные файлы — `lib/ui/l10n/app_localizations.dart`, `lib/ui/l10n/app_localizations_en.dart`, `lib/ui/l10n/app_localizations_ru.dart`.
- `firebase_options.dart` генерируется отдельно через FlutterFire CLI, не через `build_runner`: команда `flutterfire configure --project=$project_id` — `firebase_setup.ps1:9`; сам файл помечен `// File generated by FlutterFire CLI.` — `lib/firebase_options.dart:1`.

## Тесты

- Команда: `flutter test`, используется в CI с `working-directory: ./domains/client` — `.github/workflows/dart.yml:54-56`.
- Файлы тестов: `test/repository_test.dart`, `test/models_test.dart`, `test/local_database_test.dart`.
- `test/local_database_test.dart` требует нативный бинарник Isar рядом с тестами: `test/isar_windows_x64.dll` (Windows), `test/libisar_linux_x64.so` (Linux), инициализируется через `Isar.initialize(...)` в `setUpAll` — `test/local_database_test.dart:29-31`.
- Отдельной команды покрытия (`flutter test --coverage`) в CI и `pubspec.yaml` не найдено, при этом в репозитории присутствует файл `coverage/lcov.info` — команда его генерации не найдена.

## Анализ кода

- Конфигурация анализатора: `analysis_options.yaml:10` — `include: package:flutter_lints/flutter.yaml`; правило `unnecessary_library_name: false` переопределено — `analysis_options.yaml:26`.
- Шаг `flutter analyze` в CI присутствует, но закомментирован: `#- name: Analyze project source` / `#  run: flutter analyze` — `.github/workflows/dart.yml:46-49`.
- Шаг `dart format --output=none --set-exit-if-changed .` в CI также закомментирован — `.github/workflows/dart.yml:42-44`.

## CI: полный пайплайн

- Файл: `.github/workflows/dart.yml` (в корне репозитория `social_mind`, не в `domains/client`), имя воркфлоу — `Closers Flutter` — `.github/workflows/dart.yml:6`.
- Триггеры: `push`/`pull_request` в ветку `main` с фильтром `paths: [ "domains/client/**" ]`, а также `workflow_dispatch` — `.github/workflows/dart.yml:8-15`.
- Джоба `build` выполняется на `ubuntu-latest` с правами `contents: write`, `pages: write`, `id-token: write` — `.github/workflows/dart.yml:18-23`.
- Шаги по порядку: `actions/checkout@v4` (`:26`) → `actions/setup-java@v2` с `distribution: "temurin"`, `java-version: '17'` (`:28-32`) → `subosito/flutter-action@v2` (`:35-36`) → `flutter pub get` (`:38-40`) → `flutter test` (`:54-56`) → генерация `google-services.json` (`:58-60`) → `flutter build apk --split-per-abi ...` (`:62-72`) → `flutter build web --release --base-href /social_mind/ ...` (`:75-83`) → `actions/upload-artifact@v4` (`:85-89`) → `actions/upload-pages-artifact@v4` (`:92-95`) → `actions/deploy-pages@v4` (`:97-99`).

## Разовая настройка Firebase/FlutterFire (локально)

- Скрипт `firebase_setup.ps1` выполняет по порядку: `npm install -g firebase-tools`, `npm i -g firebase`, `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass`, `$env:NODE_TLS_REJECT_UNAUTHORIZED=0`, добавление `Pub\Cache\bin` в `$env:Path`, `dart pub global activate firebase`, `firebase login --reauth`, `dart pub global activate flutterfire_cli`, `flutterfire configure --project=$project_id`, `flutter pub add firebase_core` — `firebase_setup.ps1:1-10`.
