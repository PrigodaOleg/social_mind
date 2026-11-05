import 'package:flutter/material.dart';
import 'app.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'package:flutter_web_plugins/url_strategy.dart';

import 'notifications/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    usePathUrlStrategy();
  } catch (error) {
    // PathUrlStrategy требует <base href> в index.html. Без него (например,
    // при локальной раздаче файлов без сборки с --base-href) работаем
    // с hash-стратегией вместо белого экрана.
    print(error);
  }
  try {
    final options = DefaultFirebaseOptions.currentPlatform;
    // БЕЗ name: Firebase.initializeApp создаёт дефолтный инстанс "[DEFAULT]",
    // который и ожидается всеми плагинами. name: options.projectId ломает
    // инициализацию на web (FirebaseError: bad-app-name), когда projectId
    // пуст (сборка без --dart-define), и создаёт не-дефолтный инстанс,
    // который не видят пакеты, запрашивающие дефолтное приложение.
    await Firebase.initializeApp(options: options);
    // Локальная инициализация уведомлений (права, плагин). Регистрация FCM
    // токена выполняется после логина (когда репозиторий знает myId) -
    // см. PushNotificationService.initOnLogin.
    await PushNotificationService.instance.initLocalNotifications();
    // FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    // FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
  } catch (error) {
    // Не прерываем запуск: приложение способно работать без удалённого
    // хранилища, иначе при ошибке инициализации Firebase пользователь
    // видит пустую страницу без какого-либо UI.
    print(error);
  }
  runApp(const App());
}
