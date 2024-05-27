import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

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
  /// The unique identifier of the `todo`.
  ///
  /// Cannot be empty.
  final String id;

  /// The title of the `todo`.
  ///
  /// Note that the title may be empty.
  final String title;

  /// The description of the `todo`.
  ///
  /// Defaults to an empty string.
  final String description;

  /// Whether the `todo` is completed.
  ///
  /// Defaults to `false`.
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

  @override
  List<Object> get props => [id, title, description, isCompleted];
}