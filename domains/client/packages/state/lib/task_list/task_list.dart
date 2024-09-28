import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:repository/repository.dart';


class TaskListBloc extends Bloc<TaskEvent, TaskListState> {
  TaskListBloc({
    required Repository repository
    }) : _repository = repository,
     super(const TaskListState()) {
    on<StateInitRequested>(_onStateInit);
    on<TaskAddRequested>(_onTaskAdd);
    on<TaskCompletionRequested>(_onComplited);
    on<TaskSubmitionRequested>(_onSubmitted);
    on<TaskChangingRequested>(_onChanged);
  }

  final Repository _repository;
  late final String selfId;

  Future<void> _onStateInit(
    StateInitRequested event,
    Emitter<TaskListState> emit,
  ) async {
    selfId = (await _repository.getLocalUser())?.id ?? '';
    Map<String, Task> tasks = await _repository.getTasks();
    final placeholderTask = Task(originatorId: selfId);
    emit(state.copyWith(tasks: () => tasks..addAll({placeholderTask.id: placeholderTask})));
  }

  Future<void> _onTaskAdd(
    TaskAddRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final newTask = Task(originatorId: selfId);
    emit(state.copyWith(tasks: () => Map<String, Task>.from(state.tasks)..addAll({newTask.id: newTask})));
  }
  
  Future<void> _onComplited(
    TaskCompletionRequested event,
    Emitter<TaskListState> emit,
  ) async {
    if (event.task.title == '') {
      return;
    }
    final changedTask = event.task.copyWith(isCompleted: event.isComplited);
    await _repository.addTask(changedTask);
    emit(state.copyWith(tasks: () => state.tasks..update(changedTask.id, (v) => changedTask)));
  }
  
  Future<void> _onSubmitted(
    TaskSubmitionRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final changedTask = event.task.copyWith(title: event.submittedText);
    await _repository.addTask(changedTask);
    final placeholderTask = Task(originatorId: selfId);
    emit(state.copyWith(tasks: () => state.tasks
      ..update(changedTask.id, (task) => changedTask)
      ..addAll({placeholderTask.id: placeholderTask})));
  }
  
  Future<void> _onChanged(
    TaskChangingRequested event,
    Emitter<TaskListState> emit,
  ) async {
    final changedTask = event.task.copyWith(title: event.changedText);
    var tasks = state.tasks;
    tasks[changedTask.id] = changedTask;
    emit(state.copyWith(tasks: () => tasks));
  }
}

class TaskListState {
  const TaskListState({
    this.tasks = const {}
  });
  final Map<String, Task> tasks;

  // Iterable<Task> get allTasks => 

  TaskListState copyWith({
    Map<String, Task> Function()? tasks,
  }) {
    return TaskListState(
      tasks: tasks != null ? tasks() : this.tasks,
    );
  }
}

sealed class TaskEvent extends Equatable{
  const TaskEvent();

  @override
  List<Object> get props => [];
}

final class StateInitRequested extends TaskEvent {
  const StateInitRequested();
}

final class TaskCompletionRequested extends TaskEvent {
  const TaskCompletionRequested({
    required this.task,
    required this.isComplited
  });
  final Task task;
  final bool isComplited;
}

final class TaskAddRequested extends TaskEvent {
  const TaskAddRequested();
}

final class TaskSubmitionRequested extends TaskEvent {
  const TaskSubmitionRequested({
    required this.task,
    required this.submittedText
  });
  final Task task;
  final String submittedText;
}

final class TaskChangingRequested extends TaskEvent {
  const TaskChangingRequested({
    required this.task,
    required this.changedText
  });
  final Task task;
  final String changedText;
}
