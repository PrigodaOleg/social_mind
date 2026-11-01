import 'package:flutter/material.dart';
import 'package:closers/repository/repository.dart';
import '../ui.dart';

class DomainContentPage extends StatelessWidget {
  const DomainContentPage(this.repository, {super.key, this.id});

  static const routeName = '/domain';
  final Repository repository;
  final String? id;

  Future<void> _createTaskList(BuildContext context, Domain domain) async {
    final l = AppLocalizations.of(context);
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.newTaskList),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l.taskListName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l.create)),
        ],
      ),
    );
    if (created != true || controller.text.trim().isEmpty) return;
    final list = TaskList(title: controller.text.trim());
    await domain.linkTo(list);
    if (context.mounted) {
      Navigator.of(context).pushNamed('${TaskListPage.routeName}/${list.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final n = Navigator.of(context);
    if (id == null) {
      return TextButton(
          onPressed: () => n.pushNamed(DomainListPage.routeName),
          child: const Text('Domains'));
    }

    Domain? domain = repository.getModel<Domain>(id!);
    // Пока я не разобрался, что делать, мы пришли в это окно по прямой ссылке из WEB на домен,
    // а его нет в репозитории
    if (domain == null) {
      return TextButton(
          onPressed: () => n.pushNamed(HomePage.routeName),
          child: const Text('Home'));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(domain.title),
      ),
      body: ListView(
        children: [
          Text(domain.id),
          ListTile(
            title: Text(l.tasksListsTitle),
            leading: const Icon(Icons.playlist_play),
          ),
          for (final MapEntry<String, String> child in domain.children.entries)
            if (child.value == 'TaskList')
              ListTile(
                title: Text(repository.getModel<TaskList>(child.key)?.title ??
                    child.key),
                leading: const Icon(Icons.task_alt),
                onTap: () =>
                    n.pushNamed('${TaskListPage.routeName}/${child.key}'),
              ),
          Row(
            children: [
              IconButton(
                tooltip: l.addTaskList,
                onPressed: () => _createTaskList(context, domain),
                icon: const Icon(Icons.playlist_add),
              )
            ],
          )
        ],
      ),
    );
  }
}
