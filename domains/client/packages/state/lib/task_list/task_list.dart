import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:state/task.dart';


Map<String, Task> g_tasks = {};
int id = 0;

class TaskListBloc extends Bloc<TaskEvent, TaskListState> {
  TaskListBloc() : super(const TaskListState()) {
    on<TaskAddRequested>(_onTaskAdd);
    on<TaskCompletionRequested>(_onComplited);
    on<TaskSubmitionRequested>(_onSubmitted);
    on<TaskChangingRequested>(_onChanged);
  }

  Future<void> _onTaskAdd(
    TaskAddRequested event,
    Emitter<TaskListState> emit
  ) async {
    var newTask = Task();
    emit(state.copyWith(tasks: () => List<Task>.from(state.tasks)..add(newTask)));
  }
  
  Future<void> _onComplited(
    TaskCompletionRequested event,
    Emitter<TaskListState> emit
  ) async {
    final changedTask = event.task.copyWith(isCompleted: event.isComplited);
    var index = state.tasks.indexWhere((element) => element.id == event.task.id);
    var newlist =  List<Task>.from(state.tasks);
    newlist[index] = changedTask;
    emit(state.copyWith(tasks: () => newlist));
  }
  
  Future<void> _onSubmitted(
    TaskSubmitionRequested event,
    Emitter<TaskListState> emit
  ) async {
    final changedTask = event.task.copyWith(title: event.submittedText);
    var index = state.tasks.indexWhere((element) => element.id == event.task.id);
    var newlist =  List<Task>.from(state.tasks);
    newlist[index] = changedTask;
    var newTask = Task();
    newlist.add(newTask);
    emit(state.copyWith(tasks: () => newlist));
  }
  
  Future<void> _onChanged(
    TaskChangingRequested event,
    Emitter<TaskListState> emit
  ) async {
    final changedTask = event.task.copyWith(title: event.changedText);
    var index = state.tasks.indexWhere((element) => element.id == event.task.id);
    var newlist =  List<Task>.from(state.tasks);
    newlist[index] = changedTask;
    emit(state.copyWith(tasks: () => newlist));
  }
}

class TaskListState {
  const TaskListState({
    this.tasks = const []
  });
  final List<Task> tasks;

  TaskListState copyWith({
    List<Task> Function()? tasks,
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
