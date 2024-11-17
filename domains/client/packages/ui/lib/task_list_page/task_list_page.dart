import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:state/state.dart';
import 'package:state/task_list/task_list.dart';
import 'package:ui/widgets/task_list_tile.dart';
import 'package:ui/l10n/app_localizations.dart';
import 'package:repository/repository.dart';



class TaskListPage extends StatelessWidget {
  const TaskListPage({
    super.key,
    required this.title,
    required this.repository});
  final String title;
  final Repository repository;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => TaskListBloc(repository: repository),
      child: const TaskListView(),
    );
  }
}

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    // final repo = context.read(Repository);
    return BlocProvider<TaskListBloc>(
      create: (context) => context.read<TaskListBloc>()
      ..add(const TaskListStateInitRequested()),
      child: BlocBuilder<TaskListBloc, TaskListState>(
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Theme.of(context).colorScheme.inversePrimary,
              title: Text(l.taskListPageName),
            ),
            body: ListView(
              children: [
                for (final (index, task) in state.tasks.values.indexed)
                  TaskListTile(
                    title: task.title,
                    value: task.isCompleted,
                    backgroundColor: index.isEven ? 
                      Theme.of(context).colorScheme.surface : 
                      Color.lerp(
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.primary,
                        0.07),
                    onValueChanged: (bool? isComplited) {
                      BlocProvider.of<TaskListBloc>(context).add(
                        TaskCompletionRequested(
                          task: task,
                          isComplited: isComplited ?? false
                        )
                      );
                    },
                    onTitleSubmitted: (submittedText) {
                      BlocProvider.of<TaskListBloc>(context).add(
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
            //     BlocProvider.of<TaskListBloc>(context).add(
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
