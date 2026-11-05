part of 'models.dart';
// ignore: must_be_immutable
class Domain extends Model {
  Domain({
    super.title,
    super.id,
    super.description,
    this.isPersonal = false,
    required this.originatorId,
    registryId,
    List<String>? participantsIds,
    List<String>? observersIds,
    Map<String, String>? models,
    this.storageKey = ''
  }) :
    participantsIds = participantsIds ?? <String>[],
    observersIds = observersIds ?? <String>[],
    registryId = registryId ?? '',
    models = models ?? <String, String>{};
  
  Domain.fromJson(super.json) :
    isPersonal = (json['isPersonal'] ?? json['isCompleted'] ?? false) as bool,
    originatorId = (json['originatorId'] ?? '') as String,
    registryId = (json['registryId'] ?? '') as String,
    // RTDB хранит списки как словари (ключ -> ''), поэтому принимаем обе формы.
    participantsIds = _listFromRemote(json['participantsIds']),
    observersIds = _listFromRemote(json['observersIds']),
    models = Map<String, String>.from(json['models'] ?? {}),
    storageKey = (json['storageKey'] ?? '') as String,
    super.fromJson();
    
  @override
  // ignore: overridden_fields
  final String type = "Domain";
  final bool isPersonal;
  final String originatorId;
  List<String> participantsIds = <String>[];
  List<String> observersIds;

  String registryId;

  // Model ID: Model Type
  Map<String, String> models;

  /// Ключ удаленного хранилища (remote_storages.<storageKey> в настройках
  /// пользователя), в котором синхронизируется домен. Модель существует ровно
  /// в одном удаленном хранилище. Пустая строка - только локально.
  String storageKey;

  Domain copyWith({
    String? id,
    String? title,
    String? description,
    bool? isPersonal,
    String? originatorId,
    String? registryId,
    List<String>? participantsIds,
    List<String>? observersIds,
    Map<String, String>? models,
    String? storageKey,
  }) {
    return Domain(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      isPersonal: isPersonal ?? this.isPersonal,
      originatorId: originatorId ?? this.originatorId,
      registryId: registryId ?? this.registryId,
      participantsIds: participantsIds ?? this.participantsIds,
      observersIds: observersIds ?? this.observersIds,
      models: models ?? this.models,
      storageKey: storageKey ?? this.storageKey,
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({
    "isPersonal": isPersonal,
    "originatorId": originatorId,
    "registryId": registryId,
    "participantsIds": participantsIds,
    "observersIds": observersIds,
    "models": models,
    "storageKey": storageKey,
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
  List<Object> get props => super.props + [isPersonal, originatorId, registryId, participantsIds, observersIds, models, storageKey];
}
/// RTDB не умеет хранить пустые списки и представляет списки словарями
/// (ключ -> ''). Превращаем обе формы обратно в список.
List<String> _listFromRemote(dynamic value) {
  if (value is List) return List<String>.from(value);
  if (value is Map) return value.entries
      .where((e) => e.value == true || e.value == '' || e.value == null)
      .map((e) => e.key.toString())
      .toList();
  return [];
}
