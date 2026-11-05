// Страница правил уведомлений.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:closers/state/state.dart';
import 'package:closers/repository/repository.dart';

class NotificationsPage extends StatelessWidget {
  static const routeName = '/notifications';
  const NotificationsPage(this.repository, {super.key});
  final Repository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsBloc(repository: repository)
        ..add(const NotificationsInitRequested()),
      child: const NotificationsView(),
    );
  }
}

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    final b = BlocProvider.of<NotificationsBloc>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: t.colorScheme.inversePrimary,
        title: const Text('Уведомления'),
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Правила уведомлений', style: t.textTheme.titleLarge),
              const Text('Определите, о каких событиях и от кого вы хотите получать уведомления.'),
              const SizedBox(height: 8),
              for (var i = 0; i < state.rules.length; i++)
                Card(
                  child: ListTile(
                    title: Text(_ruleTitle(state.rules[i])),
                    subtitle: Text(_ruleSubtitle(state.rules[i])),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => b.add(NotificationRuleRemoved(i)),
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () => b.add(const NotificationRuleAdded(
                  NotificationRule(eventTypes: ['task_assigned', 'invitation'], action: NotificationAction.notify),
                )),
                icon: const Icon(Icons.add),
                label: const Text('Добавить правило (задачи и приглашения)'),
              ),
              ElevatedButton.icon(
                onPressed: () => b.add(const NotificationsRulesPublished()),
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Выгрузить правила на сервер (для офлайн-пушей)'),
              ),
              const Divider(height: 32),
              Text('Последние уведомления', style: t.textTheme.titleLarge),
              for (final notification in state.notifications)
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text('${_eventTypeName(notification.eventType)}: ${notification.subjectTitle}'),
                  subtitle: Text('от ${notification.actorId} · ${notification.time.toLocal()}'),
                ),
              if (state.notifications.isEmpty) const Text('Пока нет уведомлений'),
            ],
          );
        },
      ),
    );
  }

  String _ruleTitle(NotificationRule rule) {
    final types = rule.eventTypes.isEmpty ? 'все события' : rule.eventTypes.map(_eventTypeName).join(', ');
    final actors = rule.actorIds.isEmpty ? 'от всех' : 'от ${rule.actorIds.length} польз.';
    return '$types ($actors)';
  }

  String _ruleSubtitle(NotificationRule rule) {
    final domains = rule.sourceDomainIds.isEmpty ? 'все домены' : '${rule.sourceDomainIds.length} доменов';
    return '$domains, приоритет от ${rule.minPriority.name} → ${rule.action.name}';
  }

  String _eventTypeName(String type) {
    switch (type) {
      case 'task_assigned': return 'Назначение задачи';
      case 'task_completed': return 'Задача завершена';
      case 'invitation': return 'Приглашение';
      default: return type;
    }
  }
}
