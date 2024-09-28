import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'domain.g.dart';


@HiveType(typeId: 0)
class Domain extends Equatable {
  Domain({
    this.title = '',
    String? id,
    this.description = '',
    this.isPersonal = false,
    required this.originatorId,
    this.participantsIds = const <String>[],
    this.observersIds = const <String>[],
    this.tasksIds = const <String>[]
  }) : 
  assert(id == null || id.isNotEmpty, 'id must be null or not empty'),
  id = id ?? const Uuid().v4();
  
  Domain.fromJson(Map<String, dynamic> json) :
    id = (json['id'] ?? '') as String,
    title = (json['title'] ?? '') as String,
    description = (json['description'] ?? '') as String,
    isPersonal = (json['isCompleted'] ?? false) as bool,
    originatorId = (json['originatorId'] ?? []) as String,
    participantsIds = (json['executorId'] ?? []) as List<String>,
    observersIds = (json['executorId'] ?? []) as List<String>,
    tasksIds = (json['tasksIds'] ?? []) as List<String>;
  
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

  /// Some information about domain to understand domain context.
  ///
  /// Defaults to an empty string.
  @HiveField(2)
  final String description;

  @HiveField(3)
  final bool isPersonal;

  @HiveField(4)
  final String originatorId;

  @HiveField(5)
  final List<String> participantsIds;

  @HiveField(6)
  final List<String> observersIds;

  @HiveField(7)
  final List<String> tasksIds;

  @override
  List<Object> get props => [id, title, description, isPersonal, originatorId, participantsIds, observersIds, tasksIds];
}