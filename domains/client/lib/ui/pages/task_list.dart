import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:closers/state/task_list/task_list.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/ui/widgets/task_list_tile.dart';
import '../l10n/app_localizations.dart';

class TaskListPage extends StatelessWidget {
  static const routeName = '/tasklist';

  const TaskListPage(this.repository, {super.key, this.id});
  final Repository repository;
  final String? id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TaskListBloc(repository: repository, parentId: id ?? '')
        ..add(const TaskListStateInitRequested()),
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
    final bloc = context.read<TaskListBloc>();
    return BlocBuilder<TaskListBloc, TaskListState>(
      builder: (context, state) {
        final list = state.list;
        final tasks = state.orderedTasks;
        return Scaffold(
          appBar: AppBar(
            backgroundColor: t.colorScheme.inversePrimary,
            title: Text(list != null && list.title.isNotEmpty
                ? list.title
                : l.taskListPageName),
            actions: [
              PopupMenuButton<TaskListViewMode>(
                tooltip: l.changeTaskListViewMode,
                initialValue: list?.viewMode,
                onSelected: (mode) => bloc.add(TaskListViewModeChanged(mode)),
                itemBuilder: (_) => [
                  PopupMenuItem(
                      value: TaskListViewMode.creation,
                      child: Text(l.taskListViewAll)),
                  PopupMenuItem(
                      value: TaskListViewMode.activeOnly,
                      child: Text(l.taskListViewActiveOnly)),
                  PopupMenuItem(
                      value: TaskListViewMode.activeFirst,
                      child: Text(l.taskListViewActiveFirst)),
                  PopupMenuItem(
                      value: TaskListViewMode.dueTime,
                      child: Text(l.taskListViewDueTime)),
                ],
              ),
              IconButton(
                tooltip: l.editTaskListSettings,
                icon: const Icon(Icons.settings_outlined),
                onPressed:
                    list == null ? null : () => _editSettings(context, list),
              ),
            ],
          ),
          body: ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (_, index) {
              final task = tasks[index];
              return Dismissible(
                key: ValueKey(task.id),
                onDismissed: (_) => bloc.add(TaskDeleteRequested(task)),
                background: Container(color: t.colorScheme.error),
                child: TaskListTile(
                  title: task.title,
                  value: task.isCompleted,
                  backgroundColor: index.isEven
                      ? t.colorScheme.surface
                      : Color.lerp(
                          t.colorScheme.surface, t.colorScheme.primary, 0.07),
                  onValueChanged: (value) =>
                      bloc.add(TaskCompletionRequested(
                          task: task, isComplited: value)),
                  onTitleSubmitted: (value) => bloc.add(
                      TaskSubmitionRequested(task: task, submittedText: value)),
                ),
              );
            },
          ),
          floatingActionButton: FloatingActionButton(
            tooltip: l.addTaskHint,
            onPressed: () => bloc.add(const TaskAddRequested()),
            child: const Icon(Icons.add_task),
          ),
        );
      },
    );
  }

  Future<void> _editSettings(BuildContext context, TaskList list) async {
    final l = AppLocalizations.of(context);
    final bloc = context.read<TaskListBloc>();
    final controller = TextEditingController(text: list.title);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.editTaskListSettings),
        content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l.taskListName)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.cancel)),
          FilledButton(
              onPressed: () {
                bloc.add(TaskListTitleChanged(controller.text));
                Navigator.pop(dialogContext);
              },
              child: Text(l.save)),
        ],
      ),
    );
    controller.dispose();
  }
}
