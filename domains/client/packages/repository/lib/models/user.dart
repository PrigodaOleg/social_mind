part of 'models.dart';


@HiveType(typeId: 1)
class User extends Model {
  User({
    super.id,
    required this.name,
    this.domainsIds = const <String>[]
  });

  User.fromJson(super.json) :
    name = json['name'] as String,
    domainsIds = List<String>.from(json['domainsIds'] ?? []),
    super.fromJson();
    
  @override
  final String type = (User).toString();

  @HiveField(1)
  final String name;

  @HiveField(2)
  final List<String> domainsIds;

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({
    "name": name,
    "domainsIds": domainsIds
  });

  @override
  List<Object> get props => super.props + [name, domainsIds];
}