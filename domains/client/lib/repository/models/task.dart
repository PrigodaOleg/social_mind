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
  });

  Task.fromJson(super.json) :
    isCompleted = (json['isCompleted'] ?? false) as bool,
    originatorId = (json['originatorId'] ?? '') as String,
    executorId = (json['executorId'] ?? '') as String,
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
  
  /// Returns a copy of this `todo` with the given values updated.
  ///
  /// {@macro todo_item}
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? originatorId,
    String? executorId
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
      originatorId: originatorId ?? this.originatorId,
      executorId: executorId ?? this.executorId,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({
    "isCompleted": isCompleted,
    "originatorId": originatorId, 
    "executorId": executorId, 
  });

  @override
  List<Object> get props => super.props + [isCompleted, originatorId, executorId];
}