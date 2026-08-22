part of 'models.dart';

@HiveType(typeId: 1)
// ignore: must_be_immutable
class User extends Model {
  User({
    super.id,
    required this.name,
    registryId,
    List<String>? domainsIds,
    avatarUrl,
    firstName,
    lastName,
    description,
  })  : domainsIds = domainsIds ?? <String>[],
        registryId = registryId ?? '',
        avatarUrl = avatarUrl ?? '',
        firstName = firstName ?? '',
        lastName = lastName ?? '',
        description = description ?? '';

  User.fromJson(super.json)
      : name = json['name'] as String,
        domainsIds = List<String>.from(json['domainsIds'] ?? []),
        registryId = (json['registryId'] ?? []) as String,
        avatarUrl = json['avatarUrl'] as String,
        firstName = json['firstName'] as String,
        lastName = json['lastName'] as String,
        description = json['description'] as String,
        super.fromJson();

  @override
  // ignore: overridden_fields
  final String type = "User";

  @HiveField(6)
  final String name;

  @HiveField(7)
  List<String> domainsIds;

  String registryId;

  String avatarUrl;
  String firstName;
  String lastName;
  String description;

  Map<String, dynamic> settings = {
    'remote_storages': <String, dynamic>{
      'FirebaseRealtimeDatabase': <String, dynamic>{'instance': 'closers-cd24f'}
    }
  };

  Map<String, dynamic> secrets = {
    'remote_storages': <String, dynamic>{
      'FirebaseRealtimeDatabase': <String, dynamic>{'hashed_password': null}
    }
  };

  // Введенный человеком секрет храним в оперативной памяти до завершения сессии или до экспорта учетных данных во вне.
  // Да, пока выглядит ужасно, нужно полностью отказаться от хранения секрета.
  // Можно писать его в файл или отправлять в мессенджер.
  String? secret;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "name": name,
      "domainsIds": domainsIds,
      "registryId": registryId,
      'avatarUrl': avatarUrl,
      'firstName': firstName,
      'lastName': lastName,
      'description': description,
    });

  @override
  void link({Model? to, Model? from}) {
    switch (to) {
      case Domain():
        domainsIds.add(to.id);
      default:
        super.link(to: to, from: from);
        break;
    }
  }

  @override
  void unlink({Model? to, Model? from}) {
    switch (from) {
      case Domain():
        domainsIds.remove(from.id);
      default:
        super.unlink(to: to, from: from);
        break;
    }
  }

  User copyWith({
    String? id,
    String? name,
    String? registryId,
    List<String>? domainsIds,
    String? avatarUrl,
    String? firstName,
    String? lastName,
    String? description,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      registryId: registryId ?? this.registryId,
      domainsIds: domainsIds ?? this.domainsIds,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      description: description ?? this.description,
    );
  }

  List<Map<String,dynamic>> propsList(){
    return [
      {'propId':'id','value':id,'isEditable':false},
      {'propId':'name','value':name,'isEditable':true},
      {'propId':'avatarUrl','value':avatarUrl,'isEditable':true},
      {'propId':'firstName','value':firstName,'isEditable':true},
      {'propId':'lastName','value':lastName,'isEditable':true},
      {'propId':'description','value':description,'isEditable':true},
    ];
  }

  //todo
  User copyWithList(List<Map<String,dynamic>> list){

    String? name;
    String? avatarUrl;
    String? firstName;
    String? lastName;
    String? description;
   
   for(final record in list){
     final propId = record['propId'];
     switch(propId){
     case 'name': name = record['value'];
     case 'avatarUrl': avatarUrl = record['value'];
     case 'firstName': firstName = record['value'];
     case 'lastName': lastName = record['value'];
     case 'description': description = record['value'];
     }
   }
    return copyWith(
      name: name,
      avatarUrl: avatarUrl,
      firstName: firstName,
      lastName: lastName,
      description: description,
    );


  }

  @override
  List<Object> get props => super.props + [name, domainsIds, registryId, avatarUrl, firstName, lastName, description];
}

