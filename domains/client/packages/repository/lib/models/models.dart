import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'user.dart';
part 'domain.dart';
part 'task.dart';
part 'models.g.dart';

@HiveType(typeId: 3)
enum Location {
  @HiveField(0)
  local,
  @HiveField(1)
  remote,
  @HiveField(2)
  both
}

enum SyncStatus {
  synced,
  syncing,
  no
}

sealed class Model extends Equatable {
  Model({
    String? id,
    this.title = '',
    this.description = '',
  }) : 
  assert(id == null || id.isNotEmpty, 'id must be null or not empty'),
  id = id ?? const Uuid().v4(),
  location = Location.local;

  Model.fromJson(Map<String, dynamic> json) :
    id = (json['id'] ?? '') as String,
    title = (json['title'] ?? '') as String,
    description = (json['description'] ?? '') as String,
    location = (json['location'] ?? Location.remote) as Location;

  final String type = (Model).toString();
  SyncStatus sync = SyncStatus.no;
    
  /// The unique identifier of the model.
  ///
  /// Cannot be empty.
  @HiveField(0)
  final String id;

  /// The title of the model.
  ///
  /// Note that the title may be empty.
  @HiveField(1)
  final String title;

  /// Some information about model to understand it context.
  ///
  /// Defaults to an empty string.
  @HiveField(2)
  final String description;

  /// Where 
  @HiveField(3)
  final Location location;

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title, 
    "description": description,
    "type": type,
    "location": location
  };

  void link(Model to) {}

  void unlink(Model from) {}

  Model linkTo(Model to) {
    link(to);
    to.link(this);
    return this;
  }

  Model unlinkFrom(Model from) {
    unlink(from);
    from.unlink(this);
    return this;
  }

  @override
  List<Object> get props => [id, title, description, location];
}