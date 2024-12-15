part of 'models.dart';


@HiveType(typeId: 1)
class User extends Model {
  User({
    super.id,
    required this.name,
    List<String>? domainsIds
  }) :
    domainsIds = domainsIds ?? <String>[];

  User.fromJson(super.json) :
    name = json['name'] as String,
    domainsIds = List<String>.from(json['domainsIds'] ?? []),
    super.fromJson();
    
  @override
  final String type = (User).toString();

  @HiveField(4)
  final String name;

  @HiveField(5)
  List<String> domainsIds;

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({
    "name": name,
    "domainsIds": domainsIds
  });

  @override
  void link(Model to) {
    switch (to) {
      case Domain():
        domainsIds.add(to.id);
      default:
        break;
    }
  }

  @override
  void unlink(Model from) {
    switch (from) {
      case Domain():
        domainsIds.remove(from.id);
      default:
        break;
    }
  }

  @override
  List<Object> get props => super.props + [name, domainsIds];
}