import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:closers/repository/repository.dart';

class TaskListBloc extends Bloc<TaskEvent, TaskListState> {
  TaskListBloc({required this.repository, required this.parentId})
      : super(const TaskListState()) {
    on<TaskListStateInitRequested>(_onInit);
    on<TaskAddRequested>(_onAdd);
    on<TaskDeleteRequested>(_onDelete);
    on<TaskCompletionRequested>(_onComplete);
    on<TaskSubmitionRequested>(_onSubmit);
    on<TaskChangingRequested>(_onChange);
    on<TaskListViewModeChanged>(_onModeChanged);
    on<TaskListTitleChanged>(_onTitleChanged);
    _subscriberId = repository.addSyncListener(_onRemoteChange, (_, __) {});
  }

  final Repository repository;
  final String parentId;
  late final int _subscriberId;
  String get selfUserId => repository.myId ?? '';

  void _onRemoteChange(String id, dynamic value) {
    if (value is TaskList || value is Task)
      add(const TaskListStateInitRequested());
  }

  bool _legacyParent = false;
  Model? _legacyModel;

  Future<void> _onInit(
      TaskListStateInitRequested event, Emitter<TaskListState> emit) async {
    final parent = repository.getModel<Model>(parentId, _subscriberId);
    if (parent == null) return;
    final list = parent is TaskList
        ? parent
        : TaskList(
            id: parent.id,
            title: parent.title,
            description: parent.description,
            parents: Map.from(parent.parents),
            children: Map.from(parent.children),
            tasks: {
              for (final taskId in parent.ids<Task>()) taskId: 'Task',
            },
          );
    _legacyParent = parent is! TaskList;
    _legacyModel = parent;
    final tasks = repository.getModels<Task>(list.taskIds, _subscriberId);
    final ordered = list.order(tasks.values);
    final taskMap = <String, Task>{for (final task in ordered) task.id: task};
    if (_legacyParent) {
      final placeholder = Task(originatorId: selfUserId);
      taskMap[placeholder.id] = placeholder;
    }
    emit(TaskListState(list: list, tasks: taskMap));
  }

  Future<void> _onAdd(
      TaskAddRequested event, Emitter<TaskListState> emit) async {
    final list = state.list;
    if (list == null) return;
    final task = Task(originatorId: selfUserId);
    list.addTask(task);
    await repository.saveModels([list, task], _subscriberId);
    final updated = Map<String, Task>.from(state.tasks)..[task.id] = task;
    if (_legacyParent && _legacyModel != null) {
      _legacyModel!.linkTo(task, _subscriberId);
    }
    emit(state.copyWith(list: list, tasks: updated));
  }

  Future<void> _onDelete(
      TaskDeleteRequested event, Emitter<TaskListState> emit) async {
    final list = state.list;
    if (list == null) return;
    list.removeTask(event.task);
    await repository.saveModel(list, _subscriberId);
    repository.deleteModel(event.task, _subscriberId);
    final updated = Map<String, Task>.from(state.tasks)..remove(event.task.id);
    emit(state.copyWith(list: list, tasks: updated));
  }

  Future<void> _onComplete(
      TaskCompletionRequested event, Emitter<TaskListState> emit) async {
    final list = state.list;
    if (list == null || event.task.title.isEmpty) return;
    final task = event.task.copyWith(
        isCompleted: event.isComplited,
        completedAt: event.isComplited ? DateTime.now() : null);
    await repository.saveModel(task, _subscriberId);
    final updated = Map<String, Task>.from(state.tasks)..[task.id] = task;
    emit(state.copyWith(tasks: updated));
  }

  Future<void> _onSubmit(
      TaskSubmitionRequested event, Emitter<TaskListState> emit) async {
    final list = state.list;
    if (list == null || event.submittedText.trim().isEmpty) return;
    final task = event.task.copyWith(title: event.submittedText);
    list.addTask(task);
    if (_legacyParent && _legacyModel != null) {
      _legacyModel!.linkTo(task, _subscriberId);
    } else {
      await repository.saveModel(list, _subscriberId);
    }
    await repository.saveModel(task, _subscriberId);
    final updated = Map<String, Task>.from(state.tasks)..[task.id] = task;
    if (_legacyParent) {
      final placeholder = Task(originatorId: selfUserId);
      updated[placeholder.id] = placeholder;
    }
    emit(state.copyWith(list: list, tasks: updated));
  }

  void _onChange(TaskChangingRequested event, Emitter<TaskListState> emit) {
    final updated = Map<String, Task>.from(state.tasks);
    updated[event.task.id] = event.task.copyWith(title: event.changedText);
    emit(state.copyWith(tasks: updated));
  }

  Future<void> _onModeChanged(
      TaskListViewModeChanged event, Emitter<TaskListState> emit) async {
    final list = state.list;
    if (list == null) return;
    final changed = list.copyWith(viewMode: event.mode);
    await repository.saveModel(changed, _subscriberId);
    emit(state.copyWith(list: changed));
  }

  Future<void> _onTitleChanged(
      TaskListTitleChanged event, Emitter<TaskListState> emit) async {
    final list = state.list;
    if (list == null) return;
    final changed = list.copyWith(title: event.title);
    await repository.saveModel(changed, _subscriberId);
    emit(state.copyWith(list: changed));
  }

  @override
  Future<void> close() {
    repository.removeSyncListener(_subscriberId);
    return super.close();
  }
}

class TaskListState extends Equatable {
  const TaskListState({this.list, this.tasks = const {}});
  final TaskList? list;
  final Map<String, Task> tasks;
  List<Task> get orderedTasks =>
      list?.order(tasks.values) ?? tasks.values.toList();
  TaskListState copyWith({TaskList? list, Map<String, Task>? tasks}) =>
      TaskListState(list: list ?? this.list, tasks: tasks ?? this.tasks);
  @override
  List<Object?> get props => [list, tasks];
}

sealed class TaskEvent extends Equatable {
  const TaskEvent();
  @override
  List<Object> get props => [];
}

class TaskListStateInitRequested extends TaskEvent {
  const TaskListStateInitRequested();
}

class TaskAddRequested extends TaskEvent {
  const TaskAddRequested();
}

class TaskDeleteRequested extends TaskEvent {
  const TaskDeleteRequested(this.task);
  final Task task;
}

class TaskCompletionRequested extends TaskEvent {
  const TaskCompletionRequested(
      {required this.task, required this.isComplited});
  final Task task;
  final bool isComplited;
}

class TaskSubmitionRequested extends TaskEvent {
  const TaskSubmitionRequested(
      {required this.task, required this.submittedText});
  final Task task;
  final String submittedText;
}

class TaskChangingRequested extends TaskEvent {
  const TaskChangingRequested({required this.task, required this.changedText});
  final Task task;
  final String changedText;
}

class TaskListViewModeChanged extends TaskEvent {
  const TaskListViewModeChanged(this.mode);
  final TaskListViewMode mode;
}

class TaskListTitleChanged extends TaskEvent {
  const TaskListTitleChanged(this.title);
  final String title;
}
