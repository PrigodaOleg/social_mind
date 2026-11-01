part of 'models.dart';


@HiveType(typeId: 0)
// ignore: must_be_immutable
class Task extends Model {
  Task({
    super.title,
    super.id,
    super.description,
    this.isCompleted = false,
    required this.originatorId,
    this.executorId = '',
    this.createdAt,
    this.dueAt,
    this.completedAt,
  });

  Task.fromJson(super.json) :
    isCompleted = (json['isCompleted'] ?? false) as bool,
    originatorId = (json['originatorId'] ?? '') as String,
    executorId = (json['executorId'] ?? '') as String,
    createdAt = DateTime.tryParse((json['createdAt'] ?? '') as String),
    dueAt = DateTime.tryParse((json['dueAt'] ?? '') as String),
    completedAt = DateTime.tryParse((json['completedAt'] ?? '') as String),
    super.fromJson();
    
  @override
  // ignore: overridden_fields
  final String type = "Task";

  /// Whether the `todo` is completed.
  ///
  /// Defaults to `false`.
  @HiveField(6)
  final bool isCompleted;

  @HiveField(7)
  final String originatorId;

  @HiveField(8)
  final String executorId;

  /// Когда задача была создана, или `null`, если дата неизвестна.
  final DateTime? createdAt;

  /// When the task is due, or `null` if the date is unknown.
  final DateTime? dueAt;

  /// When the task was completed, or `null` if it is not completed.
  final DateTime? completedAt;
  
  /// Returns a copy of this `todo` with the given values updated.
  ///
  /// {@macro todo_item}
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? originatorId,
    String? executorId,
    DateTime? createdAt,
    DateTime? dueAt,
    DateTime? completedAt
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      originatorId: originatorId ?? this.originatorId,
      executorId: executorId ?? this.executorId,
      createdAt: createdAt ?? this.createdAt,
      dueAt: dueAt ?? this.dueAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({
    "isCompleted": isCompleted,
    "originatorId": originatorId, 
    "executorId": executorId, 
    "createdAt": createdAt?.toIso8601String(),
    "dueAt": dueAt?.toIso8601String(),
    "completedAt": completedAt?.toIso8601String(),
  });

  @override
  List<Object> get props => super.props + [
    isCompleted,
    originatorId,
    executorId,
    createdAt?.millisecondsSinceEpoch ?? -1,
    dueAt?.millisecondsSinceEpoch ?? -1,
    completedAt?.millisecondsSinceEpoch ?? -1,
  ];
}
