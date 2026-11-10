# Настройка Firebase Cloud Messaging

Инструкция по доведению пуш-уведомлений до рабочего состояния: что уже сделано
в коде и что нужно сделать в кабинетах разработчика (Firebase Console,
Apple Developer). Код отправки и приема описан в
`lib/notifications/push_notification_service.dart`.

## Что уже есть в проекте

- `lib/firebase_options.dart` сгенерирован FlutterFire CLI (`firebase_setup.ps1`), все значения читаются из `CLOSERS_*` через `--dart-define`; `messagingSenderId` = `CLOSERS_PROJECT_NUMBER` (`lib/firebase_options.dart:46, 57, 67, 77, 87`). Базовая конфигурация FCM, таким образом, в проекте есть.
- `Firebase.initializeApp` в `main()` с `try/catch` (приложение работает и без Firebase) — `lib/main.dart:21-40`.
- `PushNotificationService`: FCM на android/ios/macos; linux/windows — только локальные уведомления (`lib/notifications/push_notification_service.dart:9-17`).
- Регистрация токена выполняется после логина, когда репозиторий знает `myId`: `App.locateUser` → `PushNotificationService.initOnLogin` — `lib/app.dart:14-19`.
- Токены устройств пишутся в RTDB по пути `push_tokens/<userId>/<deviceId>` (deviceId = хэш токена; поля `token`, `platform`) в личное хранилище пользователя — `lib/notifications/push_notification_service.dart:84-108`.
- Android-плагин `com.google.gms.google-services` подключен — `android/app/build.gradle:3-5`.
- Зависимости: `firebase_messaging: ^16.7.1` (`pubspec.yaml:55`), `firebase_core: ^4.9.0` (`pubspec.yaml:53`).

## Что НУЖНО сделать в кабинетах (кратко)

| Платформа | Кабинет | Действия |
|---|---|---|
| Android | Firebase Console | Ничего для базовых пушей; убедиться, что `android/app/google-services.json` на месте (см. Android ниже) |
| iOS | Apple Developer + Firebase Console | APNs Auth Key (.p8), capabilities в Xcode — см. iOS ниже |
| macOS | Apple Developer + Firebase Console | То же, что для iOS (тот же APNs key) |
| Web | Firebase Console | Ничего сейчас: FCM на web в коде не активируется; VAPID — только при включении web-пушей |
| Linux/Windows | — | Ничего: FCM не поддерживается, локальные уведомления уже работают |

## Firebase Console

1. console.firebase.google.com → выбрать проект: тот, что в `CLOSERS_PROJECT_ID` (судя по дефолтному RTDB-instance — `closers-cd24f`, `lib/repository/models/user.dart:53`).
2. Project Settings → Cloud Messaging — здесь управляются APNs-ключи и Web Push-сертификаты.

## Android

В кабинете для базовых пушей дополнительно ничего не требуется.

- `android/app/google-services.json` в репозитории отсутствует — это секрет: в `.gitignore` (`git check-ignore` → корневой `.gitignore`), CI генерирует его из секретов перед сборкой — `.github/workflows/dart.yml:58-60`. Для локальной сборки Android: Firebase Console → Project Settings → General → Your apps → Android-приложение (`com.example.closers`) → Download google-services.json → положить в `android/app/`. Без этого файла Gradle-плагин `google-services` падает при сборке.
- Bundle ID `com.example.closers` должен совпадать с зарегистрированным в Firebase Android-приложении (`android/app/build.gradle:50`).

## iOS (и аналогично macOS)

Требуется аккаунт Apple Developer Program ($99/год): free-provisioning не включает APNs, пуш на реальном устройстве без платного аккаунта работать не будет.

1. Ключ APNs: developer.apple.com → Certificates, Identifiers & Profiles → Keys → Create Key → отметить Apple Push Notifications service (APNs) → скачать `.p8` (один раз; сохранить Key ID).
2. Загрузить ключ в Firebase: Firebase Console → Project Settings → Cloud Messaging → Apple app → APNs Authentication Key → загрузить `.p8`, указать Key ID и Team ID.
3. Bundle ID: `com.example.closers` (`iosBundleId` — `lib/firebase_options.dart:70`) должен быть привязан к iOS-приложению в Project Settings → General → Your apps (если нет — Add app с этим Bundle ID).
4. Xcode: открыть `ios/Runner.xcworkspace` → target Runner → Signing & Capabilities → «+ Capability» → Push Notifications; затем «+ Capability» → Background Modes → отметить Remote notifications. Сейчас capabilities не включены: файлов `*.entitlements` в `ios/Runner` нет, `UIBackgroundModes` в `ios/Runner/Info.plist` нет.
5. `GoogleService-Info.plist` не нужен: конфигурация берется из `lib/firebase_options.dart` (FlutterFire), файл в `ios/` отсутствует и не требуется.

Для macOS — те же шаги 1-3 (тот же APNs-ключ) и capabilities в target macos/Runner.

## Web

В текущем коде FCM на web не инициализируется: `initOnLogin` ограничен платформами android/ios/macos — `lib/notifications/push_notification_service.dart:59`. Настройка в кабинете не нужна.

При включении web-ветки понадобится: VAPID key (Firebase Console → Project Settings → Cloud Messaging → Web Push certificates → Generate key pair) и передача его в `getToken(vapidKey: ...)`. Текущий вызов `getToken()` без `vapidKey` (`lib/notifications/push_notification_service.dart:79`) на web вернет пустой токен/ошибку — при включении web-пушей это место надо править.

## Linux / Windows

FCM не поддерживается — приложение показывает только локальные уведомления при запущенном приложении (события приходят по подписке на реестры, `showEvent`). Это уже реализовано, отдельная настройка не нужна — `lib/notifications/push_notification_service.dart:12-14, 124-127`.

## Отправка пушей

Отправитель сейчас не реализован (CLI-скрипт для тестов / Cloud Functions — следующая фаза). Токен устройства для отправки берется из RTDB: `push_tokens/<userId>/<deviceId>` (читать в Firebase Console → Realtime Database; туда его пишет приложение — `lib/notifications/push_notification_service.dart:84-108`).

Ручная отправка через FCM HTTP v1 API:

1. Firebase Console → Project Settings → Service accounts → Generate new private key (JSON-файл сервисного аккаунта).
2. Получить OAuth-токен (нужен google-cloud-sdk):
   ```
   gcloud auth application-default login
   access_token=$(gcloud auth application-default print-access-token)
   ```
3. Отправить сообщение:
   ```
   curl -X POST "https://fcm.googleapis.com/v1/projects/<project-id>/messages:send" \
     -H "Authorization: Bearer $access_token" \
     -H "Content-Type: application/json" \
     -d '{"message": {"token": "<FCM-токен из RTDB>", "notification": {"title": "Closers", "body": "Тестовый пуш"}}}'
   ```

`<project-id>` — `CLOSERS_PROJECT_ID` (см. Firebase Console выше).

## Тестирование на iPhone по USB

1. Подключить iPhone 8 по USB, убедиться в списке: `flutter devices`.
2. Собрать и запустить: `flutter run -d <ios-device-id> --dart-define-from-file=.env` (переменные `CLOSERS_*` — см. `docs/ai/05-build.md`); в Xcode настроить команду подписи (Signing Team).
3. На устройстве разрешить уведомления (запрос через `requestPermission` — `lib/notifications/push_notification_service.dart:68`).
4. После логина токен появится в RTDB: `push_tokens/<myUserId>/<deviceId>`.
5. Отправить тестовый пуш curl'ом (см. раздел выше). В форграунде уведомление показывается через локальные уведомления: `FirebaseMessaging.onMessage` → `_showLocalNotification` — `lib/notifications/push_notification_service.dart:71-76`.
