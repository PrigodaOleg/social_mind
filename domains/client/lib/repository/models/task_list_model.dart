part of 'models.dart';

@HiveType(typeId: 9)
class TaskList extends Model {
  TaskList({
    super.id,
    super.title,
    super.description,
    super.parents,
    super.children,
    Map<String, String>? tasks,
    this.viewMode = TaskListViewMode.creation,
  }) : tasks = tasks ?? <String, String>{};

  TaskList.fromJson(super.json)
      : tasks = Map<String, String>.from(json['tasks'] ?? {}),
        viewMode = taskListViewModeFromString(json['viewMode'] as String?),
        super.fromJson();

  @override
  final String type = 'TaskList';

  @HiveField(6)
  Map<String, String> tasks;

  @HiveField(7)
  TaskListViewMode viewMode;

  List<String> get taskIds => tasks.keys.toList(growable: false);

  void addTask(Task task) {
    tasks[task.id] = task.type;
    task.parents[id] = type;
  }

  void removeTask(Task task) {
    tasks.remove(task.id);
    task.parents.remove(id);
  }

  List<Task> order(Iterable<Task> values) {
    final result = values.where((task) => tasks.containsKey(task.id)).toList();
    final maxDate = DateTime.fromMillisecondsSinceEpoch(8640000000000000);
    switch (viewMode) {
      case TaskListViewMode.creation:
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case TaskListViewMode.activeOnly:
        result.removeWhere((task) => task.isCompleted);
        result.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case TaskListViewMode.activeFirst:
        result.sort((a, b) {
          final group = (a.isCompleted ? 1 : 0).compareTo(
            b.isCompleted ? 1 : 0,
          );
          if (group != 0) return group;
          final aTime =
              a.isCompleted ? (a.completedAt ?? a.createdAt) : a.createdAt;
          final bTime =
              b.isCompleted ? (b.completedAt ?? b.createdAt) : b.createdAt;
          return aTime.compareTo(bTime);
        });
      case TaskListViewMode.dueTime:
        result.sort(
          (a, b) => (a.dueAt ?? maxDate).compareTo(b.dueAt ?? maxDate),
        );
    }
    return result;
  }

  TaskList copyWith({
    String? id,
    String? title,
    String? description,
    Map<String, String>? tasks,
    TaskListViewMode? viewMode,
  }) =>
      TaskList(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        parents: Map.from(parents),
        children: Map.from(children),
        tasks: tasks ?? Map.from(this.tasks),
        viewMode: viewMode ?? this.viewMode,
      );

  @override
  Map<String, dynamic> toJson() =>
      super.toJson()..addAll({'tasks': tasks, 'viewMode': viewMode.name});

  @override
  List<Object> get props => super.props + [tasks, viewMode];
}
