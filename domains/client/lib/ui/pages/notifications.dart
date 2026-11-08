// Страница правил уведомлений.
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:closers/state/state.dart';
import 'package:closers/repository/repository.dart';
import '../ui.dart';

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
    final l = AppLocalizations.of(context);
    final b = BlocProvider.of<NotificationsBloc>(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: t.colorScheme.inversePrimary,
        title: Text(l.notificationsPageTitle),
      ),
      body: BlocBuilder<NotificationsBloc, NotificationsState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(l.notificationsRulesTitle, style: t.textTheme.titleLarge),
              Text(l.notificationsRulesHint),
              const SizedBox(height: 8),
              for (var i = 0; i < state.rules.length; i++)
                Card(
                  child: ListTile(
                    title: Text(_ruleTitle(l, state.rules[i])),
                    subtitle: Text(_ruleSubtitle(l, state.rules[i])),
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
                label: Text(l.notificationsAddRule),
              ),
              ElevatedButton.icon(
                onPressed: () => b.add(const NotificationsRulesPublished()),
                icon: const Icon(Icons.cloud_upload),
                label: Text(l.notificationsPublishRules),
              ),
              const Divider(height: 32),
              Text(l.notificationsRecentTitle, style: t.textTheme.titleLarge),
              for (final notification in state.notifications)
                ListTile(
                  leading: const Icon(Icons.notifications),
                  title: Text('${_eventTypeName(l, notification.eventType)}: ${notification.subjectTitle}'),
                  subtitle: Text('${l.notificationsFrom(notification.actorId)} · ${notification.time.toLocal()}'),
                ),
              if (state.notifications.isEmpty) Text(l.notificationsEmpty),
            ],
          );
        },
      ),
    );
  }

  String _ruleTitle(AppLocalizations l, NotificationRule rule) {
    final types = rule.eventTypes.isEmpty
        ? l.notificationsFromAll
        : rule.eventTypes.map((type) => _eventTypeName(l, type)).join(', ');
    final actors = rule.actorIds.isEmpty
        ? l.notificationsActorsFrom
        : l.notificationsActorsCount(rule.actorIds.length);
    return '$types ($actors)';
  }

  String _ruleSubtitle(AppLocalizations l, NotificationRule rule) {
    final domains = rule.sourceDomainIds.isEmpty
        ? l.notificationsAllDomains
        : l.notificationsDomainsCount(rule.sourceDomainIds.length);
    return '$domains, ${rule.minPriority.name} → ${rule.action.name}';
  }

  String _eventTypeName(AppLocalizations l, String type) {
    switch (type) {
      case 'task_assigned': return l.notificationsEventTaskAssigned;
      case 'task_completed': return l.notificationsEventTaskCompleted;
      case 'invitation': return l.notificationsEventInvitation;
      default: return type;
    }
  }
}
