part of 'models.dart';


@HiveType(typeId: 1)
// ignore: must_be_immutable
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
  // ignore: overridden_fields
  final String type = (User).toString();

  @HiveField(6)
  final String name;

  @HiveField(7)
  List<String> domainsIds;

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({
    "name": name,
    "domainsIds": domainsIds
  });

  @override
  void link({
    Model? to,
    Model? from
  }) {
    switch (to) {
      case Domain():
        domainsIds.add(to.id);
      default:
        super.link(to: to, from: from);
        break;
    }
  }

  @override
  void unlink({
    Model? to,
    Model? from
  }) {
    switch (from) {
      case Domain():
        domainsIds.remove(from.id);
      default:
        super.unlink(to: to, from: from);
        break;
    }
  }

  @override
  List<Object> get props => super.props + [name, domainsIds];
}