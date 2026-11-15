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
    final bloc = context.read<TaskListBloc>();
    // Контроллер принадлежит виджету диалога, а не вызывающему коду:
    // dispose после await showDialog срабатывает, пока exit-переход ещё
    // строит TextField с этим контроллером, что приводит к ассерту
    // фреймворка '_dependents.isEmpty'. State.dispose() вызывается только
    // после полного удаления маршрута.
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) =>
          _EditSettingsDialog(initialTitle: list.title),
    );
    if (result == null || result.isEmpty) return;
    bloc.add(TaskListTitleChanged(result));
  }
}

class _EditSettingsDialog extends StatefulWidget {
  const _EditSettingsDialog({required this.initialTitle});
  final String initialTitle;

  @override
  State<_EditSettingsDialog> createState() => _EditSettingsDialogState();
}

class _EditSettingsDialogState extends State<_EditSettingsDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.editTaskListSettings),
      content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l.taskListName)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.cancel)),
        FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: Text(l.save)),
      ],
    );
  }
}
