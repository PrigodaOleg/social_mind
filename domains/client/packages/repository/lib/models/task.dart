import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'task.g.dart';


@HiveType(typeId: 0)
class Task extends Equatable {
  Task({
    this.title = '',
    String? id,
    this.description = '',
    this.isCompleted = false
  }) : assert(
    id == null || id.isNotEmpty, 'id must be null or not empty'
  ),
  id = id ?? const Uuid().v4();

  Task.fromJson(Map<String, dynamic> json) :
    id = json['id'] as String,
    title = json['title'] as String,
    description = json['description'] as String,
    isCompleted = json['isCompleted'] as bool;
  
  /// The unique identifier of the `task`.
  ///
  /// Cannot be empty.
  @HiveField(0)
  final String id;

  /// The title of the `todo`.
  ///
  /// Note that the title may be empty.
  @HiveField(1)
  final String title;

  /// The description of the `todo`.
  ///
  /// Defaults to an empty string.
  @HiveField(2)
  final String description;

  /// Whether the `todo` is completed.
  ///
  /// Defaults to `false`.
  @HiveField(3)
  final bool isCompleted;
  
  /// Returns a copy of this `todo` with the given values updated.
  ///
  /// {@macro todo_item}
  Task copyWith({
    String? id,
    String? title,
    String? description,
    bool? isCompleted,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title, 
    "description": description, 
    "isCompleted": isCompleted 
  };

  @override
  List<Object> get props => [id, title, description, isCompleted];
}