import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:repository/repository/repository.dart';
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

// ignore: must_be_immutable
sealed class Model extends Equatable {
  Model({
    String? id,
    this.title = '',
    this.description = '',
    Map<String, String>? children,
    Map<String, String>? parents
  }) : 
  assert(id == null || id.isNotEmpty, 'id must be null or not empty'),
  id = id ?? const Uuid().v4(),
  location = Location.local,
  children = children ?? <String, String>{},
  parents = parents ?? <String, String>{};

  Model.fromJson(Map<String, dynamic> json) :
    id = (json['id'] ?? '') as String,
    title = (json['title'] ?? '') as String,
    description = (json['description'] ?? '') as String,
    location = (json['location'] ?? Location.remote) as Location,
    children = Map<String, String>.from(json['children'] ?? {}),
    parents = Map<String, String>.from(json['parents'] ?? {});

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

  /// Model ID: Model Type
  @HiveField(4)
  Map<String, String> children;

  /// Model ID: Model Type
  @HiveField(5)
  Map<String, String> parents;

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title, 
    "description": description,
    "type": type,
    "location": location.toString(),
    "children": children,
    "parents": parents
  };

  void link({
    Model? to,
    Model? from
  }) {
    if (to != null) children[to.id] = to.type;
    if (from != null) parents[from.id] = from.type;
  }

  void unlink({
    Model? to,
    Model? from
  }) {
    if (to != null) children.remove(to.id);
    if (from != null) parents.remove(from.id);
  }

  /// (from this as a parent)--->(to child)
  Future<Model> linkTo(
    Model to,
    [int? subscriberId]
  ) async {
    link(to: to);
    to.link(from: this);
    await Repository.instance.saveModels([this, to], subscriberId);
    return this;
  }

  /// (from parent)<-X->(to this as a child)
  Future<Model> linkFrom(
    Model from,
    [int? subscriberId]
  ) async {
    link(from: from);
    from.link(to: this);
    await Repository.instance.saveModels([this, from], subscriberId);
    return this;
  }

  /// (from)<-X->(this)
  Future<Model> unlinkFrom(
    Model from,
    [int? subscriberId]
  ) async {
    unlink(from: from, to: from);
    from.unlink(from: this, to: from);
    await Repository.instance.saveModel(this, subscriberId);
    Repository.instance.deleteModel(from, subscriberId);  //TODO: Зачем же тут сразу удалять модель? Кажется, что для этого нужен отдельный метод с удалением
    return this;
  }

  // Returns list of children IDs with specified type
  List<String> ids<T>() {
    return children.keys.where((k) => children[k] == (T).toString()).toList();
  }

  @override
  List<Object> get props => [id, title, description, location, children, parents];
}