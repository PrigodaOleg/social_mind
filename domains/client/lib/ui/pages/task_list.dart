import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:closers/state/task_list/task_list.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/ui/widgets/task_list_tile.dart';

class TaskListPage extends StatelessWidget {
  static const routeName = '/tasklist';
  const TaskListPage(this.repository, {super.key, this.id});
  final Repository repository;
  final String? id;

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => TaskListBloc(repository: repository, parentId: id ?? '')
          ..add(const TaskListStateInitRequested()),
        child: const TaskListView(),
      );
}

class TaskListView extends StatelessWidget {
  const TaskListView({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<TaskListBloc>();
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        final list = state.list;
        return Scaffold(
          appBar: AppBar(
            title: Text(
                list?.title.isNotEmpty == true ? list!.title : 'Task list'),
            actions: [
              PopupMenuButton<TaskListViewMode>(
                tooltip: 'Change view',
                initialValue: list?.viewMode,
                onSelected: (mode) => bloc.add(TaskListViewModeChanged(mode)),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                      value: TaskListViewMode.creation,
                      child: Text('All tasks')),
                  PopupMenuItem(
                      value: TaskListViewMode.activeOnly,
                      child: Text('Active tasks')),
                  PopupMenuItem(
                      value: TaskListViewMode.activeFirst,
                      child: Text('Active first')),
                  PopupMenuItem(
                      value: TaskListViewMode.dueTime, child: Text('Due time')),
                ],
              ),
              IconButton(
                tooltip: 'Edit list settings',
                icon: const Icon(Icons.settings_outlined),
                onPressed:
                    list == null ? null : () => _editSettings(context, list),
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: state.orderedTasks.length,
            itemBuilder: (_, index) {
              final task = state.orderedTasks[index];
              return Dismissible(
                key: ValueKey(task.id),
                onDismissed: (_) => bloc.add(TaskDeleteRequested(task)),
                background:
                    Container(color: Theme.of(context).colorScheme.error),
                child: TaskListTile(
                  title: task.title,
                  value: task.isCompleted,
                  backgroundColor: index.isEven
                      ? null
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  onValueChanged: (value) => bloc.add(TaskCompletionRequested(
                      task: task, isComplited: value ?? false)),
                  onTitleChanged: (value) => bloc.add(
                      TaskChangingRequested(task: task, changedText: value)),
                  onTitleSubmitted: (value) => bloc.add(
                      TaskSubmitionRequested(task: task, submittedText: value)),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: 'Add task',
            onPressed: () => bloc.add(const TaskAddRequested()),
            child: const Icon(Icons.add_task),
          ),
        );
      },
    );
  }

  Future<void> _editSettings(BuildContext context, TaskList list) async {
    final controller = TextEditingController(text: list.title);
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Task list settings'),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Name')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () {
                context
                    .read<TaskListBloc>()
                    .add(TaskListTitleChanged(controller.text));
                Navigator.pop(context);
              },
              child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
  }
}
