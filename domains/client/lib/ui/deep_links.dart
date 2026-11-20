// Обработка входящих deeplink-ссылок (app_links): холодный старт (initial
// link) и теплый старт (uriLinkStream). Ссылки приглашений приводятся к
// канонической форме маршрута /invitations?d=... до передачи делегату,
// остальные ссылки проходят как есть (существующее поведение Router).
import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/services.dart' show MissingPluginException;

import 'package:closers/repository/repository/invitations.dart';
import 'pages/invitation.dart';

/// Преобразовать входящую ссылку приглашения в каноническую форму маршрута.
///
/// Принимаются:
/// - кастомная схема приложения: `closers://join?d=<payload>` ->
///   `/invitations?d=<payload>`;
/// - https-ссылка, последний сегмент пути которой 'join' или 'join.html'
///   (лендинг web/join.html и будущие App Links вида https://closee.app/join)
///   -> `/invitations?d=<payload>`.
///
/// Все прочие ссылки возвращаются как null (проходят в Router без изменений).
/// Ссылки приглашений без параметра `d` тоже дают null: маршрут /invitations
/// без данных не имеет смысла как цель deeplink.
Uri? mapInvitationLinkToRouterUri(Uri uri) {
  final scheme = uri.scheme.toLowerCase();
  final String? d;
  if (scheme == acquaintanceAppScheme) {
    if (uri.host.toLowerCase() != acquaintanceAppSchemeHost) return null;
    d = uri.queryParameters['d'];
  } else if (scheme == 'https') {
    final segments = uri.path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final last = segments.last.toLowerCase();
    if (last != 'join' && last != 'join.html') return null;
    d = uri.queryParameters['d'];
  } else {
    return null;
  }
  if (d == null || d.isEmpty) return null;
  return Uri(path: InvitationPage.routeName, queryParameters: {'d': d});
}

/// Подписка на входящие ссылки: initial link (холодный старт) + поток
/// ссылок (теплый старт). На платформах без поддержки app_links (Windows,
/// тесты) подписка молча отключается - приложение работает без deeplink.
class DeepLinkHandler {
  DeepLinkHandler({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  StreamSubscription<Uri>? _subscription;
  bool _enabled = true;
  late Uri? Function(Uri uri) _mapLink;
  late void Function(Uri uri) _onLink;

  /// Начать обработку ссылок. [onLink] вызывается с входящим Uri (уже
  /// преобразованным [mapInvitationLinkToRouterUri], либо исходным).
  void start(Uri? Function(Uri uri) mapLink, void Function(Uri uri) onLink) {
    _mapLink = mapLink;
    _onLink = onLink;
    try {
      _appLinks.getInitialLink().then<void>(
        (uri) {
          if (uri != null) _handle(uri);
        },
        onError: (Object error) => _disable(),
      );
    } catch (_) {
      _disable();
      return;
    }
    try {
      _subscription = _appLinks.uriLinkStream.listen(
        _handle,
        onError: (Object error) {
          if (error is MissingPluginException) _disable();
        },
      );
    } catch (_) {
      _disable();
    }
  }

  void _handle(Uri uri) {
    if (!_enabled) return;
    try {
      _onLink(_mapLink(uri) ?? uri);
    } catch (_) {
      // Некорректная ссылка не должна ронять приложение.
    }
  }

  void _disable() {
    _enabled = false;
    unawaited(_subscription?.cancel());
    _subscription = null;
  }

  void dispose() {
    _disable();
  }
}
