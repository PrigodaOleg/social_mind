import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:closers/state/state.dart';
import 'package:closers/repository/repository.dart';
import '../ui.dart';

class TaskListsPage extends StatelessWidget {
  static const routeName = '/tasklists';
  const TaskListsPage(
    this.repository,
    {
      super.key,
      this.title,
    }
  );
  final String? title;
  final Repository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListsBloc(repository: repository)..add(const TaskListsStateInitRequested()),
      child: const TaskListsView(),
    );
  }
}

class TaskListsView extends StatelessWidget {
  const TaskListsView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final n = Navigator.of(context);
    final t = Theme.of(context);
    return BlocProvider<TaskListsBloc>.value(
      value: context.read<TaskListsBloc>(),
      child: BlocBuilder<TaskListsBloc, TaskListsState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: t.colorScheme.inversePrimary,
              title: Text(l.taskListsPageName),
            ),
            body: ListView(
              children: [
                for (final (index, list) in state.lists.values.indexed)
                  ListTile(
                    title: Text(list.title),
                    onTap: () => n.pushNamed('${TaskListPage.routeName}/${list.id}'),
                  ),
                IconButton(
                  onPressed: () {
                    context.read<TaskListsBloc>().add(
                      TaskListCreationRequested(l.taskListDefaultName)
                    );
                  },
                  icon: const Icon(Icons.add)
                ),
              ]
            ),
          );
        }
      )
    );
  }
}
