import 'package:flutter/material.dart';
//import 'package:flutter_bloc/flutter_bloc.dart';
//import 'package:state/state.dart';
//import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';
import 'package:ui/task_list_page/task_list_page.dart';


class DomainContentPage extends StatelessWidget {
  const DomainContentPage(this.repository, {super.key, this.id});

  static const routeName = '/domain';
  final Repository repository;
  final String? id;

  @override
  Widget build(BuildContext context) {
    if (id == null) return TextButton(onPressed: () => Navigator.of(context).pushNamed('/domains'), child: const Text('Domains'));

    Domain? domain = repository.getModel<Domain>(id!);
    // Пока я не разобрался, что делать, мы пришли в это окно по прямой ссылке из WEB на домен, а его нет в репозитории
    if (domain == null) return TextButton(onPressed: () => Navigator.of(context).pushNamed('/home'), child: const Text('Home'));

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
              Navigator.of(context).pushNamed('${TaskListPage.routeName}/${domain.id}');
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
                onPressed: () {
                  // Тут почему-то не обновляется список на UI, надо переделать на BLOC
                  domain.linkTo(Task(originatorId: repository.me.id));
                },
                icon: const Icon(Icons.add_task)
              )
            ],
          )
        ],
      ),
    );
  }
}