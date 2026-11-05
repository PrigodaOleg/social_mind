part of 'models.dart';

enum InvitationType { acquaintance, domainJoin }
enum InvitationStatus { pending, approved, declined, accepted, canceled }
enum InvitationRole { participant, observer }

InvitationType invitationTypeFromString(String? value) =>
    InvitationType.values.firstWhere((t) => t.name == value, orElse: () => InvitationType.acquaintance);

InvitationStatus invitationStatusFromString(String? value) =>
    InvitationStatus.values.firstWhere((s) => s.name == value, orElse: () => InvitationStatus.pending);

InvitationRole invitationRoleFromString(String? value) =>
    InvitationRole.values.firstWhere((r) => r.name == value, orElse: () => InvitationRole.participant);

/// Приглашение. Бывает двух типов:
/// - acquaintance - знакомство: обмен userId между двумя пользователями.
///   Создается приглашаемым (тем, кто отсканировал QR инициатора) и кладется
///   в путь invitations/by-user/<userId инициатора> в удаленном хранилище.
/// - domainJoin - приглашение в домен: создается участником домена, требует
///   консенсуса остальных участников (кворум = все текущие участники).
///
/// Чувствительные данные (ключи расшифровки payload) не хранятся в модели -
/// payload шифруется симметричным ключом, который передается лично через QR.
// ignore: must_be_immutable
class Invitation extends Model {
  Invitation({
    super.id,
    super.title,
    super.description,
    required this.originatorId,
    this.inviteeId = '',
    this.invitationType = InvitationType.acquaintance,
    this.status = InvitationStatus.pending,
    this.role = InvitationRole.participant,
    this.domainId = '',
    this.storageKey = '',
    this.storageInstance = '',
    Map<String, bool>? approvals,
  }) : approvals = approvals ?? <String, bool>{};

  Invitation.fromJson(super.json)
      : originatorId = (json['originatorId'] ?? '') as String,
        inviteeId = (json['inviteeId'] ?? '') as String,
        invitationType = invitationTypeFromString(json['invitationType'] as String?),
        status = invitationStatusFromString(json['status'] as String?),
        role = invitationRoleFromString(json['role'] as String?),
        domainId = (json['domainId'] ?? '') as String,
        storageKey = (json['storageKey'] ?? '') as String,
        storageInstance = (json['storageInstance'] ?? '') as String,
        approvals = Map<String, bool>.from((json['approvals'] is Map
            ? (json['approvals'] as Map).map((k, v) => MapEntry(k.toString(), v == true || v == 'true'))
            : <String, bool>{})),
        super.fromJson();

  @override
  // ignore: overridden_fields
  final String type = "Invitation";

  /// Кто создал приглашение (userId инициатора).
  final String originatorId;

  /// Кого приглашают (userId приглашаемого).
  String inviteeId;

  InvitationType invitationType;

  /// pending -> approved (кворум набран) -> accepted/declined/canceled
  InvitationStatus status;

  /// Роль, с которой приглашают в домен.
  InvitationRole role;

  /// Домен, в который приглашают (для domainJoin). Пуст для acquaintance.
  String domainId;

  /// Хранилище, в котором лежит домен (для domainJoin) или через которое
  /// идет обмен ответными приглашениями (для acquaintance).
  String storageKey;
  String storageInstance;

  /// Голоса участников домена за добавление приглашаемого: userId -> одобрено.
  /// Мержится существующим механизмом rebase (расширение словаря по ключам).
  Map<String, bool> approvals;

  /// Кворум достигнут: все участники домена, кроме наблюдателей и самого
  /// приглашаемого, одобрили приглашение.
  /// [participantsCount] - количество участников домена на момент проверки.
  bool isQuorumReached(int participantsCount) {
    if (participantsCount <= 0) return false;
    final approvalsCount = approvals.values.where((v) => v).length;
    return approvalsCount >= participantsCount;
  }

  /// Поставить голос текущего участника.
  void approve(String userId, {bool approved = true}) {
    approvals[userId] = approved;
  }

  Invitation copyWith({
    String? id,
    String? title,
    String? description,
    String? originatorId,
    String? inviteeId,
    InvitationType? invitationType,
    InvitationStatus? status,
    InvitationRole? role,
    String? domainId,
    String? storageKey,
    String? storageInstance,
    Map<String, bool>? approvals,
  }) {
    return Invitation(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      originatorId: originatorId ?? this.originatorId,
      inviteeId: inviteeId ?? this.inviteeId,
      invitationType: invitationType ?? this.invitationType,
      status: status ?? this.status,
      role: role ?? this.role,
      domainId: domainId ?? this.domainId,
      storageKey: storageKey ?? this.storageKey,
      storageInstance: storageInstance ?? this.storageInstance,
      approvals: approvals ?? Map.from(this.approvals),
    );
  }

  @override
  Map<String, dynamic> toJson() => super.toJson()..addAll({
        'originatorId': originatorId,
        'inviteeId': inviteeId,
        'invitationType': invitationType.name,
        'status': status.name,
        'role': role.name,
        'domainId': domainId,
        'storageKey': storageKey,
        'storageInstance': storageInstance,
        'approvals': approvals,
      });

  @override
  List<Object> get props => super.props + [
        originatorId,
        inviteeId,
        invitationType,
        status,
        role,
        domainId,
        storageKey,
        storageInstance,
        approvals,
      ];
}
