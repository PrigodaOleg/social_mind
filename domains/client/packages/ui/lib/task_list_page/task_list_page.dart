import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/state.dart';
import 'package:state/task_list/task_list.dart';
import 'package:ui/widgets/task_list_tile.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';



class TaskListPage extends StatelessWidget {

  static const routeName = '/tasklist';

  const TaskListPage(
    this.repository,
    {
      super.key,
      this.id
    }
  );
  final Repository repository;
  final String? id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListBloc(repository: repository, parentId: id ?? repository.myId ?? ''),
      child: const TaskListView(),
    );
  }
}

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context);
    final b = BlocProvider.of<TaskListBloc>(context);
    // final repo = context.read(Repository);
    return BlocProvider<TaskListBloc>(
      create: (context) => context.read<TaskListBloc>()
      ..add(const TaskListStateInitRequested()),
      child: BlocBuilder<TaskListBloc, TaskListState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: t.colorScheme.inversePrimary,
              title: Text(l.taskListPageName),
            ),
            body: ListView(
              children: [
                for (final (index, task) in state.tasks.values.indexed)
                  TaskListTile(
                    title: task.title,
                    value: task.isCompleted,
                    backgroundColor: index.isEven ? 
                      t.colorScheme.surface : 
                      Color.lerp(
                        t.colorScheme.surface,
                        t.colorScheme.primary,
                        0.07),
                    onValueChanged: (bool? isComplited) {
                      b.add(
                        TaskCompletionRequested(
                          task: task,
                          isComplited: isComplited ?? false
                        )
                      );
                    },
                    onTitleSubmitted: (submittedText) {
                      b.add(
                        TaskSubmitionRequested(
                          task: task,
                          submittedText: submittedText
                        )
                      );
                    },
                    onTitleChanged: (changedText) {
                      context.read<TaskListBloc>().add(
                        TaskChangingRequested(
                          task: task,
                          changedText: changedText
                        )
                      );
                    },
                  )
              ]
            ),
            // floatingActionButton: FloatingActionButton(
            //   onPressed: () {
            //     b.add(
            //       const TaskAddRequested()
            //     );
            //   },
            //   tooltip: l.addTaskHint,
            //   child: const Icon(Icons.add_task),
            // ), // This trailing comma makes auto-formatting nicer for build methods.
          );
      })
    );
  }
}
