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
    DateTime? createdAt,
    this.dueAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Task.fromJson(super.json)
      : isCompleted = (json['isCompleted'] ?? false) as bool,
        originatorId = (json['originatorId'] ?? '') as String,
        executorId = (json['executorId'] ?? '') as String,
        createdAt = DateTime.tryParse((json['createdAt'] ?? '') as String) ??
            DateTime.fromMillisecondsSinceEpoch(0),
        dueAt = DateTime.tryParse((json['dueAt'] ?? '') as String),
        completedAt = DateTime.tryParse((json['completedAt'] ?? '') as String),
        super.fromJson();

  @override
  final String type = 'Task';

  @HiveField(6)
  final bool isCompleted;
  @HiveField(7)
  final String originatorId;
  @HiveField(8)
  final String executorId;
  final DateTime createdAt;
  final DateTime? dueAt;
  final DateTime? completedAt;

  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
    String? originatorId,
    String? executorId,
    DateTime? createdAt,
    DateTime? dueAt,
    DateTime? completedAt,
  }) =>
      Task(
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

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'isCompleted': isCompleted,
      'originatorId': originatorId,
      'executorId': executorId,
      'createdAt': createdAt.toIso8601String(),
      'dueAt': dueAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    });

  @override
  List<Object> get props =>
      super.props +
      [
        isCompleted,
        originatorId,
        executorId,
        dueAt?.millisecondsSinceEpoch ?? -1,
        completedAt?.millisecondsSinceEpoch ?? -1,
      ];
}
