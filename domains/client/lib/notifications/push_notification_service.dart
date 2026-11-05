import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'package:closers/repository/repository.dart';

/// Сервис пуш-уведомлений.
///
/// Платформенная поддержка:
///   - android/ios/web/macos: firebase_messaging (FCM).
///   - linux/windows: FCM не поддерживается - только локальные уведомления
///     при запущенном приложении (события приходят по подписке на реестры).
///
/// Токены устройств хранятся в RTDB: push_tokens/<userId>/<deviceId>.
/// Пуши - только UX-уведомления, не транспорт данных.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _messagingInitialized = false;

  /// Инициализация локальных уведомлений (вызывается один раз из main()).
  Future<void> initLocalNotifications() async {
    if (_initialized) return;
    _initialized = true;

    // Локальные уведомления - на всех платформах (форграунд и desktop)
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const macosSettings = DarwinInitializationSettings();
    const linuxSettings = LinuxInitializationSettings(defaultActionName: 'Открыть');
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      macOS: macosSettings,
      linux: linuxSettings,
    );
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    // Разрешение на уведомления на Android 13+ (POST_NOTIFICATIONS)
    if (!kIsWeb && Platform.isAndroid) {
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  /// Инициализация FCM после логина (когда репозиторий знает myId).
  /// Вызывается из App.locateUser после repository.init.
  Future<void> initOnLogin(Repository repository) async {
    await initLocalNotifications();
    if (_messagingInitialized) return;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      _messagingInitialized = true;
      await _initFirebaseMessaging(repository);
    }
  }

  Future<void> _initFirebaseMessaging(Repository repository) async {
    final messaging = FirebaseMessaging.instance;
    // Запрашиваем разрешения (на iOS/macOS - обязательно)
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Форграунд-показ (по умолчанию FCM не показывает уведомления в форграунде)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(
        title: message.notification?.title ?? 'Closers',
        body: message.notification?.body ?? message.data['body'] ?? '',
      );
    });

    // Сохраняем токен устройства
    final token = await messaging.getToken();
    await _saveToken(repository, token);
    messaging.onTokenRefresh.listen((token) => _saveToken(repository, token));
  }

  Future<void> _saveToken(Repository repository, String? token) async {
    if (token == null || repository.myId == null) return;
    try {
      final deviceId = token.hashCode.toString(); // упрощенный deviceId по токену
      // Токены пишем только в хранилища, администрируемые самим пользователем
      // (его личное хранилище по storageKey). В доменные/чужие хранилища токены
      // не попадают: их читают другие участники - риск спуфинга уведомлений.
      final myStorageKey = repository.me.storageKey;
      final targetStorages = myStorageKey.isNotEmpty
          ? {if (repository.connectedStorages[myStorageKey] != null) myStorageKey: repository.connectedStorages[myStorageKey]!}
          : repository.connectedStorages;
      for (var storageEntry in targetStorages.entries) {
        try {
          await storageEntry.value.saveRaw('push_tokens/${repository.myId}/$deviceId', {
            'token': token,
            'platform': defaultTargetPlatform.name,
          });
        } catch (e) {
          print('Failed to save push token to ${storageEntry.key}: $e');
        }
      }
    } catch (e) {
      print('Failed to save push token: $e');
    }
  }

  Future<void> _showLocalNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails('closers_events', 'События Closers',
        importance: Importance.defaultImportance, priority: Priority.defaultPriority);
    const iosDetails = DarwinNotificationDetails();
    const macosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails, macOS: macosDetails);
    await _localNotifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  /// Показ локального уведомления (для событий, обнаруженных по подписке на реестры).
  Future<void> showEvent({required String title, required String body}) async {
    await _showLocalNotification(title: title, body: body);
  }
}
