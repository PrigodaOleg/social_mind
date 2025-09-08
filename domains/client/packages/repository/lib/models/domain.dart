part of 'models.dart';


@HiveType(typeId: 2)
// ignore: must_be_immutable
class Domain extends Model {
  Domain({
    super.title,
    super.id,
    super.description,
    this.isPersonal = false,
    required this.originatorId,
    List<String>? participantsIds,
    List<String>? observersIds,
    Map<String, String>? models
  }) :
    participantsIds = participantsIds ?? <String>[],
    observersIds = observersIds ?? <String>[],
    models = models ?? <String, String>{};
  
  Domain.fromJson(super.json) :
    isPersonal = (json['isCompleted'] ?? false) as bool,
    originatorId = (json['originatorId'] ?? []) as String,
    participantsIds = List<String>.from(json['executorId'] ?? []),
    observersIds = List<String>.from(json['executorId'] ?? []),
    models = Map<String, String>.from(json['models'] ?? {}),
    super.fromJson();
    
  @override
  // ignore: overridden_fields
  final String type = (Domain).toString();
  
  @HiveField(6)
  final bool isPersonal;

  @HiveField(7)
  final String originatorId;

  @HiveField(8)
  List<String> participantsIds = <String>[];

  @HiveField(9)
  List<String> observersIds;

  // Model ID: Model Type
  @HiveField(10)
  Map<String, String> models;

  Domain copyWith({
    String? id,
    String? title,
    String? description,
    bool? isPersonal,
    String? originatorId,
    List<String>? participantsIds,
    List<String>? observersIds,
    Map<String, String>? models
  }) {
    return Domain(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isPersonal: isPersonal ?? this.isPersonal,
      originatorId: originatorId ?? this.originatorId,
      participantsIds: participantsIds ?? this.participantsIds,
      observersIds: observersIds ?? this.observersIds,
      models: models ?? this.models,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({
    "isPersonal": isPersonal,
    "originatorId": originatorId,
    "participantsIds": participantsIds,
    "observersIds": observersIds,
    "models": models,
  });

  // @override
  // void link(Model to) {
  //   switch (to) {
  //     case User():
  //       observersIds.add(to.id);
  //     default:
  //       models[to.id] = to.type;
  //   }
  // }

  // @override
  // void unlink(Model from) {
  // }

  @override
  List<Object> get props => super.props + [isPersonal, originatorId, participantsIds, observersIds, models];
}