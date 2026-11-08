import 'package:closers/repository/repository.dart';

// # Интерпретатор транспортных событий репозитория (бизнес-слой).
//
// Репозиторий - это транспорт моделей: он уведомляет об абстрактных
// [RepositoryTransactionEvent] (чужая транзакция изменила модели) и ничего
// не знает о задачах, исполнителях и прочих деталях доменных моделей.
// Здесь, в бизнес-слое, решаем какие конкретные типы уведомлений порождает
// каждое транспортное событие.

/// Конкретное бизнес-событие, готовое к фильтрации правилами уведомлений.
class InterpretedNotificationEvent {
  const InterpretedNotificationEvent({
    required this.eventType,
    required this.subject,
    required this.actorId,
  });

  /// Тип события ('task_assigned', 'task_completed', ...). Код-константа,
  /// не UI-текст - локализация выполняется на UI-слое.
  final String eventType;

  /// Модель, о которой уведомляем.
  final Model subject;

  /// Кто внес изменение (автор транзакции).
  final String actorId;
}

/// Интерпретировать абстрактное транспортное событие в бизнес-события.
/// Актор изменения всегда берется из транзакции
/// ([RepositoryTransactionEvent.originatorId]), а не из поля
/// модели-ориджинатора: модель может создать один пользователь, а изменять -
/// любой участник домена. Собственные изменения (эхо своей транзакции)
/// уведомлений не порождают.
List<InterpretedNotificationEvent> interpretRepositoryEvent(
  RepositoryTransactionEvent event, {
  required String myId,
}) {
  // Чужие действия над моделями (actorId - автор транзакции)
  if (event.originatorId == myId || myId.isEmpty) return [];
  final result = <InterpretedNotificationEvent>[];
  for (final model in event.changedModels.values) {
    if (model is Task) {
      if (model.executorId == myId && model.executorId.isNotEmpty) {
        result.add(InterpretedNotificationEvent(
          eventType: 'task_assigned',
          subject: model,
          actorId: event.originatorId,
        ));
      } else if (model.isCompleted) {
        result.add(InterpretedNotificationEvent(
          eventType: 'task_completed',
          subject: model,
          actorId: event.originatorId,
        ));
      }
    }
  }
  return result;
}
