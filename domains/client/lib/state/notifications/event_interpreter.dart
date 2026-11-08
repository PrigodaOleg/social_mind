import 'package:closers/repository/repository.dart';

// # Интерпретатор бизнес-событий "изменились модели" (бизнес-слой).
//
// Слой реестров (RegistryManager) уведомляет об абстрактных
// [ModelsChangedEvent] (чужие изменения моделей) и ничего не знает о задачах,
// исполнителях и прочих деталях доменных моделей. Здесь, в бизнес-слое,
// решаем какие конкретные типы уведомлений порождает каждое событие.

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

  /// Кто внес изменение.
  final String actorId;
}

/// Интерпретировать абстрактное бизнес-событие "изменились модели".
/// Актор изменения всегда берется из [ModelsChangedEvent.actorId], а не из
/// поля модели-ориджинатора: модель может создать один пользователь, а
/// изменять - любой участник домена. Собственные изменения уведомлений не
/// порождают (страховка: слой реестров их уже отфильтровал).
List<InterpretedNotificationEvent> interpretModelsChangedEvent(
  ModelsChangedEvent event, {
  required String myId,
}) {
  // Чужие действия над моделями
  if (event.actorId == myId || myId.isEmpty) return [];
  final result = <InterpretedNotificationEvent>[];
  for (final model in event.changedModels.values) {
    if (model is Task) {
      if (model.executorId == myId && model.executorId.isNotEmpty) {
        result.add(InterpretedNotificationEvent(
          eventType: 'task_assigned',
          subject: model,
          actorId: event.actorId,
        ));
      } else if (model.isCompleted) {
        result.add(InterpretedNotificationEvent(
          eventType: 'task_completed',
          subject: model,
          actorId: event.actorId,
        ));
      }
    }
  }
  return result;
}
