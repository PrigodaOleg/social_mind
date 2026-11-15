import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:closers/repository/repository.dart';
import 'package:equatable/equatable.dart';


class TaskListsBloc extends Bloc<TaskListsEvent, TaskListsState> {
  // Обзорный список всех списков задач пользователя.
  TaskListsBloc({
    required Repository repository
    }) : _repo = repository,
     super(const TaskListsState()) {
    on<TaskListsStateInitRequested>(_onStateInit);
    on<TaskListCreationRequested>(_onCreation);
  }

  final Repository _repo;
  late final int listenerId;

  @override
  Future<void> close() {
    _repo.removeSyncListener(listenerId);
    return super.close();
  }

  Future<void> _onStateInit(
    TaskListsStateInitRequested event,
    Emitter<TaskListsState> emit,
  ) async {
    listenerId = _repo.addSyncListener(
      (id, item) {
        if (!isClosed) {
          switch (item) {
            case TaskList _:
              add(TaskListsSyncRequested(lists: {id: item}));
              break;
            default:
          }
        }
      },
      (localChanges, remoteChanges) {
        if (!isClosed) {
          print('TaskListsBloc: localChanges=$localChanges, remoteChanges=$remoteChanges');
        }
      }
    );
    User me = _repo.me;
    final listIds = me.children.entries
        .where((e) => e.value == (TaskList).toString())
        .map((e) => e.key)
        .toList();
    Map<String, TaskList> lists = _repo.getModels<TaskList>(listIds, listenerId);
    emit(state.copyWith(lists: () => lists));
  }

  Future<void> _onCreation(
    TaskListCreationRequested event,
    Emitter<TaskListsState> emit,
  ) async {
    User me = _repo.me;

    // Local-first: показываем новый список сразу, сохранение - после.
    // Ошибка сохранения (офлайн/сбой сети) не должна делать кнопку мертвой.
    var newList = TaskList(title: event.title);
    emit(state.copyWith(lists: () => state.lists..addAll({newList.id: newList})));
    try {
      // linkTo добавляет список в children пользователя (parentId) и
      // сохраняет обе модели.
      await me.linkTo(newList, listenerId);
      unawaited(_repo.updateRegistryWatches());
    } catch (error) {
      print('Task list creation persist failed (kept local-only): $error');
    }
  }

  Future<void> _onSync(
    TaskListsSyncRequested event,
    Emitter<TaskListsState> emit,
  ) async {
    emit(state.copyWith(lists: () => state.lists..addAll(event.lists)));
  }
}

class TaskListsState {
  const TaskListsState({
    this.lists = const {}
  });
  final Map<String, TaskList> lists;

  TaskListsState copyWith({
    Map<String, TaskList> Function()? lists,
  }) {
    return TaskListsState(
      lists: lists != null ? lists() : this.lists,
    );
  }
}

sealed class TaskListsEvent extends Equatable {
  const TaskListsEvent();

  @override
  List<Object> get props => [];
}

final class TaskListsStateInitRequested extends TaskListsEvent {
  const TaskListsStateInitRequested();
}

final class TaskListCreationRequested extends TaskListsEvent {
  const TaskListCreationRequested(
    this.title
  );
  final String title;
}

final class TaskListsSyncRequested extends TaskListsEvent {
  const TaskListsSyncRequested({
    required this.lists
  });
  final Map<String, TaskList> lists;
}
