part of 'models.dart';


@HiveType(typeId: 2)
class Domain extends Model {
  Domain({
    super.title,
    super.id,
    super.description,
    this.isPersonal = false,
    required this.originatorId,
    this.participantsIds = const <String>[],
    this.observersIds = const <String>[],
    this.models = const <String, String>{}
  });
  
  Domain.fromJson(super.json) :
    isPersonal = (json['isCompleted'] ?? false) as bool,
    originatorId = (json['originatorId'] ?? []) as String,
    participantsIds = List<String>.from(json['executorId'] ?? []),
    observersIds = List<String>.from(json['executorId'] ?? []),
    models = Map<String, String>.from(json['models'] ?? {}),
    super.fromJson();
    
  @override
  final String type = (Domain).toString();
  
  @HiveField(4)
  final bool isPersonal;

  @HiveField(5)
  final String originatorId;

  @HiveField(6)
  final List<String> participantsIds;

  @HiveField(7)
  final List<String> observersIds;

  // Model ID: Model Type
  @HiveField(8)
  final Map<String, String> models;

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

  @override
  List<Object> get props => super.props + [isPersonal, originatorId, participantsIds, observersIds, models];
}