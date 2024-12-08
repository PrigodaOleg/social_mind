part of 'models.dart';


@HiveType(typeId: 0)
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
  final String type = (Task).toString();

  /// Whether the `todo` is completed.
  ///
  /// Defaults to `false`.
  @HiveField(4)
  final bool isCompleted;

  @HiveField(5)
  final String originatorId;

  @HiveField(6)
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

  Map<String, dynamic> toJson() => super.toJson()..addAll({
    "isCompleted": isCompleted,
    "originatorId": originatorId, 
    "executorId": executorId, 
  });

  @override
  List<Object> get props => super.props + [isCompleted, originatorId, executorId];
}