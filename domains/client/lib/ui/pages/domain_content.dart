import 'package:flutter/material.dart';
import 'package:closers/repository/repository.dart';
import '../ui.dart';

class DomainContentPage extends StatelessWidget {
  const DomainContentPage(this.repository, {super.key, this.id});

  static const routeName = '/domain';
  final Repository repository;
  final String? id;

  Future<void> _createTaskList(BuildContext context, Domain domain) async {
    final controller = TextEditingController();
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New task list'),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Create')),
        ],
      ),
    );
    if (created != true || controller.text.trim().isEmpty) return;
    final list = TaskList(title: controller.text.trim());
    await domain.linkTo(list);
    if (context.mounted)
      Navigator.of(context).pushNamed('${TaskListPage.routeName}/${list.id}');
  }

  @override
  Widget build(BuildContext context) {
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
            title: const Text('Tasks lists'),
            onTap: () {
              Navigator.of(context)
                  .pushNamed('${TaskListPage.routeName}/${domain.id}');
            },
            leading: const Icon(Icons.task_alt),
          ),
          for (final MapEntry<String, String> task in domain.children.entries)
            ListTile(
              title: Text(task.key),
              leading: const Icon(Icons.task),
            ),
          Row(
            children: [
              IconButton(
                tooltip: 'Add task list',
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
