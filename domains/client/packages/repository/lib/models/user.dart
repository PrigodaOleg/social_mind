import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

part 'user.g.dart';


@HiveType(typeId: 1)
class User  extends Equatable {
  User({
    String? id,
    required this.name,
    this.domainsIds = const <String>[]
  }) : assert(
    id == null || id.isNotEmpty, 'id must be null or not empty'
  ),
  id = id ?? const Uuid().v4();

  User.fromJson(Map<String, dynamic> json) :
    id = json['id'] as String,
    name = json['name'] as String,
    domainsIds = (json['domainsIds'] ?? []) as List<String>;

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<String> domainsIds;

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "domainsIds": domainsIds
  };

  @override
  List<Object> get props => [id, name, domainsIds];
}