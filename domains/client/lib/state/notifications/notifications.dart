import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:closers/repository/repository.dart';
import 'package:equatable/equatable.dart';

import 'event_interpreter.dart';

// # Правила уведомлений (фаза пуши).
//
// Философия: пользователь сам управляет тем, о каких событиях от каких
// пользователей и доменов он хочет получать уведомления.
// Правила хранятся только локально (чувствительные данные в облако не идут).
// Грубая часть правил (источник-домен x приоритет) дополнительно выгружается
// в notification_rules/<userId> в удаленном хранилище - по ней серверная
// часть (Cloud Function / отправитель-скрипт) фильтрует офлайн-пуши.
// Точная фильтрация (типы событий, будущий механизм экспонирования статусов)
// выполняется локально при получении события.

enum NotificationPriority { low, normal, high }
enum NotificationAction { notify, silent, off }

NotificationPriority notificationPriorityFromString(String? value) =>
    NotificationPriority.values.firstWhere((p) => p.name == value, orElse: () => NotificationPriority.normal);

NotificationAction notificationActionFromString(String? value) =>
    NotificationAction.values.firstWhere((a) => a.name == value, orElse: () => NotificationAction.off);

/// Правило уведомлений: предикат по полям события.
class NotificationRule extends Equatable {
  const NotificationRule({
    this.eventTypes = const [],
    this.actorIds = const [],
    this.sourceDomainIds = const [],
    this.minPriority = NotificationPriority.low,
    this.action = NotificationAction.notify,
  });

  /// Типы событий ('task_assigned', 'task_completed', 'invitation', ...).
  /// Пустой список - все типы.
  final List<String> eventTypes;

  /// От кого (userId актора). Пустой список - от всех.
  final List<String> actorIds;

  /// Из каких доменов. Пустой список - из всех.
  final List<String> sourceDomainIds;

  /// Минимальный приоритет события.
  final NotificationPriority minPriority;

  /// Что делать с подошедшими событиями.
  final NotificationAction action;

  /// Проверка события против правила.
  bool matches({required String eventType, required String actorId, required String sourceDomainId, required NotificationPriority priority}) {
    if (eventTypes.isNotEmpty && !eventTypes.contains(eventType)) return false;
    if (actorIds.isNotEmpty && !actorIds.contains(actorId)) return false;
    if (sourceDomainIds.isNotEmpty && !sourceDomainIds.contains(sourceDomainId)) return false;
    if (priority.index < minPriority.index) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
    'eventTypes': eventTypes,
    'actorIds': actorIds,
    'sourceDomainIds': sourceDomainIds,
    'minPriority': minPriority.name,
    'action': action.name,
  };

  factory NotificationRule.fromJson(Map<String, dynamic> json) => NotificationRule(
    eventTypes: List<String>.from(json['eventTypes'] ?? []),
    actorIds: List<String>.from(json['actorIds'] ?? []),
    sourceDomainIds: List<String>.from(json['sourceDomainIds'] ?? []),
    minPriority: notificationPriorityFromString(json['minPriority'] as String?),
    action: notificationActionFromString(json['action'] as String?),
  );

  @override
  List<Object?> get props => [eventTypes, actorIds, sourceDomainIds, minPriority, action];
}

/// Набор правил пользователя + выгрузка грубой части в удаленное хранилище.
class NotificationRules {
  NotificationRules({List<NotificationRule>? rules}) : rules = rules ?? _defaultRules();

  List<NotificationRule> rules;

  /// Дефолтные правила: приглашения и назначения задач - уведомлять.
  static List<NotificationRule> _defaultRules() => [
    const NotificationRule(
      eventTypes: ['invitation', 'task_assigned'],
      action: NotificationAction.notify,
    ),
  ];

  /// Решение по событию: найти первое подошедшее правило.
  NotificationAction resolve({
    required String eventType,
    required String actorId,
    required String sourceDomainId,
    required NotificationPriority priority,
  }) {
    for (final rule in rules) {
      if (rule.matches(eventType: eventType, actorId: actorId, sourceDomainId: sourceDomainId, priority: priority)) {
        return rule.action;
      }
    }
    return NotificationAction.off;
  }

  /// Грубая часть правил для сервера (без actorIds - приватность).
  Map<String, dynamic> coarseRulesForServer() => {
    'coarse_rules': rules.map((r) => {
      'sourceDomainIds': r.sourceDomainIds,
      'minPriority': r.minPriority.name,
    }).toList(),
  };

  /// Выгрузить грубую часть правил в удаленное хранилище.
  Future<void> publishCoarseRules(Repository repo) async {
    final json = coarseRulesForServer();
    for (var storageEntry in repo.connectedStorages.entries) {
      try {
        await storageEntry.value.saveRaw('notification_rules/${repo.myId}', json);
      } catch (e) {
        print('Failed to publish notification rules to ${storageEntry.key}: $e');
      }
    }
  }

  String toJsonString() => jsonEncode({'rules': rules.map((r) => r.toJson()).toList()});

  static NotificationRules fromJsonString(String s) {
    try {
      final json = jsonDecode(s) as Map<String, dynamic>;
      return NotificationRules(rules: (json['rules'] as List).map((r) => NotificationRule.fromJson(Map<String, dynamic>.from(r))).toList());
    } catch (_) {
      return NotificationRules();
    }
  }
}

/// Bloc уведомлений: слушает события репозитория, применяет правила,
/// отдает поток уведомлений для показа (локальные уведомления/снекбары).
class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  NotificationsBloc({required Repository repository})
      : _repo = repository,
        super(const NotificationsState()) {
    on<NotificationsInitRequested>(_onInit);
    on<NotificationEventArrived>(_onEventArrived);
    on<NotificationRuleAdded>(_onRuleAdded);
    on<NotificationRuleRemoved>(_onRuleRemoved);
    on<NotificationRuleChanged>(_onRuleChanged);
    on<NotificationsRulesPublished>(_onRulesPublished);
  }

  final Repository _repo;
  NotificationRules notificationRules = NotificationRules();
  int? _listenerId;

  @override
  Future<void> close() {
    if (_listenerId != null) _repo.removeModelsChangedListener(_listenerId!);
    return super.close();
  }

  Future<void> _onInit(
    NotificationsInitRequested event,
    Emitter<NotificationsState> emit,
  ) async {
    // Загружаем правила из локального хранилища (настройки пользователя)
    final stored = _repo.localStorage.getOperational('notification_rules');
    if (stored != null) {
      notificationRules = NotificationRules.fromJsonString(stored);
    }
    _listenerId ??= _repo.addModelsChangedListener((event) {
      // Бизнес-интерпретация события "изменились модели" - в event_interpreter.dart
      for (final notification in interpretModelsChangedEvent(event, myId: _repo.myId ?? '')) {
        add(NotificationEventArrived(
          eventType: notification.eventType,
          subject: notification.subject,
          actorId: notification.actorId,
        ));
      }
    });
    emit(state.copyWith(rules: () => List.from(notificationRules.rules)));
  }

  Future<void> _onEventArrived(
    NotificationEventArrived event,
    Emitter<NotificationsState> emit,
  ) async {
    final action = notificationRules.resolve(
      eventType: event.eventType,
      actorId: event.actorId,
      sourceDomainId: event.subject.parents.keys.firstOrNull ?? '',
      priority: NotificationPriority.normal,
    );
    if (action == NotificationAction.off) return;
    final notification = AppNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      eventType: event.eventType,
      subjectId: event.subject.id,
      subjectTitle: event.subject.title,
      actorId: event.actorId,
      silent: action == NotificationAction.silent,
      time: DateTime.now(),
    );
    emit(state.copyWith(notifications: () => [notification, ...state.notifications]));
  }

  Future<void> _onRuleAdded(
    NotificationRuleAdded event,
    Emitter<NotificationsState> emit,
  ) async {
    notificationRules.rules.add(event.rule);
    await _persistRules(emit);
  }

  Future<void> _onRuleRemoved(
    NotificationRuleRemoved event,
    Emitter<NotificationsState> emit,
  ) async {
    if (event.index >= 0 && event.index < notificationRules.rules.length) {
      notificationRules.rules.removeAt(event.index);
    }
    await _persistRules(emit);
  }

  Future<void> _onRuleChanged(
    NotificationRuleChanged event,
    Emitter<NotificationsState> emit,
  ) async {
    if (event.index >= 0 && event.index < notificationRules.rules.length) {
      notificationRules.rules[event.index] = event.rule;
    }
    await _persistRules(emit);
  }

  Future<void> _onRulesPublished(
    NotificationsRulesPublished event,
    Emitter<NotificationsState> emit,
  ) async {
    await notificationRules.publishCoarseRules(_repo);
  }

  Future<void> _persistRules(Emitter<NotificationsState> emit) async {
    _repo.localStorage.setOperational('notification_rules', notificationRules.toJsonString());
    emit(state.copyWith(rules: () => List.from(notificationRules.rules)));
  }
}

/// Конкретное уведомление для показа пользователю.
class AppNotification extends Equatable {
  const AppNotification({
    required this.id,
    required this.eventType,
    required this.subjectId,
    required this.subjectTitle,
    required this.actorId,
    required this.time,
    this.silent = false,
  });

  final String id;
  final String eventType;
  final String subjectId;
  final String subjectTitle;
  final String actorId;
  final DateTime time;
  final bool silent;

  @override
  List<Object?> get props => [id, eventType, subjectId, subjectTitle, actorId, time, silent];
}

class NotificationsState extends Equatable {
  const NotificationsState({
    this.notifications = const [],
    this.rules = const [],
  });

  final List<AppNotification> notifications;
  final List<NotificationRule> rules;

  NotificationsState copyWith({
    List<AppNotification> Function()? notifications,
    List<NotificationRule> Function()? rules,
  }) {
    return NotificationsState(
      notifications: notifications != null ? notifications() : this.notifications,
      rules: rules != null ? rules() : this.rules,
    );
  }

  @override
  List<Object?> get props => [notifications, rules];
}

sealed class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

final class NotificationsInitRequested extends NotificationsEvent {
  const NotificationsInitRequested();
}

final class NotificationEventArrived extends NotificationsEvent {
  const NotificationEventArrived({required this.eventType, required this.subject, required this.actorId});
  final String eventType;
  final Model subject;
  final String actorId;

  @override
  List<Object?> get props => [eventType, subject, actorId];
}

final class NotificationRuleAdded extends NotificationsEvent {
  const NotificationRuleAdded(this.rule);
  final NotificationRule rule;

  @override
  List<Object?> get props => [rule];
}

final class NotificationRuleRemoved extends NotificationsEvent {
  const NotificationRuleRemoved(this.index);
  final int index;

  @override
  List<Object?> get props => [index];
}

final class NotificationRuleChanged extends NotificationsEvent {
  const NotificationRuleChanged({required this.index, required this.rule});
  final int index;
  final NotificationRule rule;

  @override
  List<Object?> get props => [index, rule];
}

final class NotificationsRulesPublished extends NotificationsEvent {
  const NotificationsRulesPublished();
}
