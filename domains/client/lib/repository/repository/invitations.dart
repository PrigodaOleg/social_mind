import 'dart:convert';

import 'package:closers/repository/models/models.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:hashlib/hashlib.dart';

import 'repository.dart';

/// Строгий allowlist для ID, попадающих в пути удаленного хранилища.
/// Защита от path injection через поля QR-кодов (/, ., $, #, [, ] - спецсимволы путей RTDB).
final _safeIdRegExp = RegExp(r'^[A-Za-z0-9_-]+$');

bool isSafeRemotePathId(String? id) {
  if (id == null || id.isEmpty || id.length > 128) return false;
  return _safeIdRegExp.hasMatch(id);
}

/// Сервис знакомства и приглашений.
///
/// Знакомство (acquaintance):
/// 1. Инициатор показывает QR со своим userId (и instance своего хранилища).
/// 2. Приглашаемый сканирует QR, добавляет инициатора в контакты, создает
///    Invitation (acquaintance) и кладет его в путь invitations/by-user/<userId
///    инициатора> в удаленном хранилище.
/// 3. Инициатор при возврате онлайн читает входящие приглашения, создает
///    общий домен на двоих и контакт.
///
/// Приглашение в домен (domainJoin):
/// 1. Участник домена создает Invitation (domainJoin) в удаленном хранилище
///    домена по пути invitations/<invitationId>, payload не шифруется в RTDB,
///    но содержит только IDs (никаких чувствительных данных).
/// 2. Приглашаемому лично передается QR с invitationId (+ ключом шифрования
///    payload, когда payload будет содержать чувствительные данные).
/// 3. При принятии: подключение хранилища домена (с подтверждением) и
///    авто-регистрация пользователя в нем.
/// 4. Участники домена голосуют (approvals), при достижении кворума
///    приглашаемый добавляется в participantsIds домена.
class InvitationService {
  InvitationService(this._repo);

  final Repository _repo;

  // # Знакомство

  /// Пayload для QR-кода инициатора знакомства.
  Map<String, String> acquaintanceQrPayload() {
    final me = _repo.me;
    return {
      'type': 'acquaintance',
      'userId': me.id,
      'name': me.name,
      'storageKey': me.storageKey.isNotEmpty
          ? me.storageKey
          : _repo.connectedStorages.keys.firstOrNull ?? '',
      'storageInstance': me.settings.getDeep('remote_storages.${me.storageKey}.instance') ?? '',
    };
  }

  /// Разбор QR-кода инициатора.
  static ({String userId, String name, String storageKey, String storageInstance})? parseAcquaintanceQr(String qrData) {
    try {
      final json = jsonDecode(qrData) as Map<String, dynamic>;
      if (json['type'] != 'acquaintance') return null;
      final userId = json['userId'] as String;
      if (!isSafeRemotePathId(userId)) return null;
      return (
        userId: userId,
        name: (json['name'] ?? '') as String,
        storageKey: (json['storageKey'] ?? '') as String,
        storageInstance: (json['storageInstance'] ?? '') as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// Шаг приглашаемого: отправить ответное приглашение-знакомство инициатору.
  /// Приглашение кладется в путь invitations/by-user/<userId инициатора>
  /// в удаленном хранилище, доступном обеим сторонам.
  Future<Invitation> sendAcquaintanceInvitation({
    required String initiatorId,
    required String initiatorName,
    required String storageKey,
    required String storageInstance,
  }) async {
    final me = _repo.me;
    final invitation = Invitation(
      originatorId: me.id,
      inviteeId: initiatorId,
      invitationType: InvitationType.acquaintance,
      title: 'Знакомство с ${me.name}',
      storageKey: storageKey,
      storageInstance: storageInstance,
    );
    // Локально сохраняем приглашение (приглашаемому оно нужно для отслеживания статуса)
    await _repo.saveModel(invitation);
    // Кладем в путь инициатора в удаленном хранилище
    await _putInvitationAtPath('by-user/$initiatorId/${invitation.id}', invitation);
    // Записываем контакт
    await _addContact(me.id, initiatorId);
    return invitation;
  }

  /// Шаг инициатора: прочитать входящие приглашения-знакомства и принять их.
  /// Для каждого принятого: создается домен на двоих, контакт, участники.
  Future<List<Domain>> acceptAcquaintanceInvitations() async {
    final me = _repo.me;
    final accepted = <Domain>[];
    final incoming = await _readInvitationsAtPath('by-user/${me.id}');
    for (final invitation in incoming) {
      if (invitation.invitationType != InvitationType.acquaintance) continue;
      if (invitation.status != InvitationStatus.pending) continue;
      // Идемпотентность: если приглашение уже было обработано локально
      // (запись статуса не дошла до remote), не создаем дубликат домена.
      final localCopy = _repo.getModel<Invitation>(invitation.id);
      if (localCopy != null && localCopy.status == InvitationStatus.accepted) continue;
      // Создаем домен на двоих
      final domain = await createMutualDomain(otherUserId: invitation.originatorId, otherUserName: invitation.title);
      // Отмечаем приглашение принятым
      invitation.status = InvitationStatus.accepted;
      await _repo.saveModel(invitation);
      await _putInvitationAtPath('by-user/${me.id}/${invitation.id}', invitation);
      accepted.add(domain);
    }
    return accepted;
  }

  /// Создание общего домена на двоих (при знакомстве).
  Future<Domain> createMutualDomain({required String otherUserId, required String otherUserName}) async {
    final me = _repo.me;
    final domain = Domain(
      title: otherUserName.isNotEmpty ? otherUserName : 'Знакомство',
      originatorId: me.id,
      storageKey: me.storageKey,
    );
    domain.participantsIds.addAll([me.id, otherUserId]);
    me.domainsIds.add(domain.id);
    await _repo.saveModels([domain, me]);
    await _addContact(me.id, otherUserId);
    _repo.updateRegistryWatches();
    return domain;
  }

  // # Приглашение в домен

  /// Создать приглашение в домен (участником домена).
  Future<Invitation> createDomainInvitation({
    required Domain domain,
    required String inviteeId,
    InvitationRole role = InvitationRole.participant,
  }) async {
    final me = _repo.me;
    final invitation = Invitation(
      originatorId: me.id,
      inviteeId: inviteeId,
      invitationType: InvitationType.domainJoin,
      status: InvitationStatus.pending,
      role: role,
      domainId: domain.id,
      title: 'Приглашение в домен ${domain.title}',
      storageKey: domain.storageKey,
      storageInstance: me.settings.getDeep('remote_storages.${domain.storageKey}.instance') ?? '',
    );
    // Голос создателя учитывается сразу
    invitation.approve(me.id);
    await _repo.saveModel(invitation);
    await _putInvitationAtPath('${invitation.id}', invitation);
    return invitation;
  }

  /// Payload QR-кода приглашения в домен (передается лично).
  String domainInvitationQrPayload(Invitation invitation) {
    return jsonEncode({
      'type': 'domainJoin',
      'invitationId': invitation.id,
      'storageKey': invitation.storageKey,
      'storageInstance': invitation.storageInstance,
    });
  }

  static ({String invitationId, String storageKey, String storageInstance})? parseDomainInvitationQr(String qrData) {
    try {
      final json = jsonDecode(qrData) as Map<String, dynamic>;
      if (json['type'] != 'domainJoin') return null;
      final invitationId = json['invitationId'] as String;
      if (!isSafeRemotePathId(invitationId)) return null;
      return (
        invitationId: invitationId,
        storageKey: (json['storageKey'] ?? '') as String,
        storageInstance: (json['storageInstance'] ?? '') as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// Прочитать приглашение по его ID (приглашаемым).
  Future<Invitation?> readDomainInvitation(String invitationId) async {
    final invitation = await _readInvitationAtPath('$invitationId');
    // Читаем приглашение только его получателю: иначе любой с invitationId
    // узнает storageKey/storageInstance домена.
    if (invitation != null && invitation.inviteeId == _repo.myId) {
      // Локально сохраняем и подписываемся на статус
      await _repo.saveModel(invitation);
      return invitation;
    }
    return null;
  }

  /// Приглашаемый принимает приглашение: регистрируется в хранилище домена
  /// (с его собственным секретом) и добавляет домен себе.
  /// [storageInstance] - instance хранилища домена (из QR/приглашения).
  /// [onStorageConfirm] - подтверждение пользователя на подключение нового
  /// хранилища (обязательно перед отправкой кредов на неизвестный сервер).
  Future<Invitation?> acceptDomainInvitation(Invitation invitation, {Future<bool> Function(String storageKey, String instance)? onStorageConfirm}) async {
    if (invitation.inviteeId != _repo.myId) return null;
    final me = _repo.me;
    // 1. Подключаем хранилище домена, если оно еще не подключено
    final storage = _repo.connectedStorages[invitation.storageKey];
    if (storage == null && invitation.storageInstance.isNotEmpty) {
      await _connectAndRegisterStorage(
        invitation.storageKey,
        invitation.storageInstance,
        onConfirm: onStorageConfirm,
      );
    }
    // 2. Читаем домен из хранилища и добавляем себе
    final storage2 = _repo.connectedStorages[invitation.storageKey];
    if (storage2 != null) {
      final domain = await storage2.getItem(id: invitation.domainId) as Domain?;
      if (domain != null) {
        domain.storageKey = invitation.storageKey;
        await _repo.saveModel(domain);
        if (!me.domainsIds.contains(domain.id)) me.domainsIds.add(domain.id);
        await _repo.saveModel(me);
        _repo.updateRegistryWatches();
      }
    }
    // 3. Отмечаем принятие
    invitation.status = InvitationStatus.accepted;
    await _repo.saveModel(invitation);
    await _putInvitationAtPath('${invitation.id}', invitation);
    return invitation;
  }

  /// Голос участника домена за приглашение (консенсус).
  /// Вызывается участником, когда он увидел приглашение (по подписке на
  /// реестр домена - приглашение сохраняется в реестре домена).
  /// [voterId] - по умолчанию текущий пользователь (каждый участник голосует
  /// со своего устройства, где он и есть me).
  Future<void> voteForInvitation(Invitation invitation, Domain domain, {bool approved = true, String? voterId}) async {
    invitation.approve(voterId ?? _repo.myId!, approved: approved);
    if (!approved) {
      invitation.status = InvitationStatus.declined;
    } else if (invitation.isQuorumReached(domain.participantsIds.length)) {
      invitation.status = InvitationStatus.approved;
      // Кворум набран - добавляем приглашаемого в участники
      if (!domain.participantsIds.contains(invitation.inviteeId)) {
        domain.participantsIds.add(invitation.inviteeId);
      }
      if (invitation.role == InvitationRole.observer && !domain.observersIds.contains(invitation.inviteeId)) {
        domain.observersIds.add(invitation.inviteeId);
      }
      await _repo.saveModel(domain);
    }
    await _repo.saveModel(invitation, null, true); // немедленная отправка
    await _putInvitationAtPath('${invitation.id}', invitation);
  }

  // # Внутренние методы

  /// Подключение хранилища (создание записи в настройках пользователя) и
  /// регистрация в нем текущего пользователя (с его собственным секретом).
  /// Подключение нового удаленного хранилища по данным из приглашения.
  /// Требует явного подтверждения пользователя ([onConfirm]) - instance из QR
  /// может указывать на враждебный сервер, куда уйдет производный от секрета пароль.
  /// [onConfirm] получает человекочитаемое описание и решает, подключать ли.
  /// По умолчанию подключение отклоняется (fail-closed).
  Future<bool> _connectAndRegisterStorage(
    String storageKey,
    String instance, {
    Future<bool> Function(String storageKey, String instance)? onConfirm,
  }) async {
    // Валидация: storageKey попадает в пути настроек и БД, instance - в URL.
    if (!isSafeRemotePathId(storageKey)) {
      print('Rejected unsafe storage key: $storageKey');
      return false;
    }
    if (!_isValidInstance(instance)) {
      print('Rejected unsafe storage instance: $instance');
      return false;
    }
    final storageFactory = _repo.knownRemoteStorages[storageKey];
    if (storageFactory == null) return false;
    // Явное подтверждение пользователя (fail-closed по умолчанию)
    final confirmed = onConfirm != null && await onConfirm(storageKey, instance);
    if (!confirmed) return false;
    final me = _repo.me;
    me.settings.setDeep('remote_storages.$storageKey.instance', instance);
    final storage = storageFactory() as RemoteStorage;
    final anonKey = me.settings.getDeep('remote_storages.$storageKey.anon_key');
    if (!await storage.init(instance, anonKey: anonKey)) return false;
    // Регистрируем пользователя с его собственным секретом
    final password = scrypt(utf8.encode(me.secret ?? ''), utf8.encode('$storageKey$instance')).toString();
    final success = await storage.createUserAndAuth(me.id, password);
    if (success) {
      me.secrets.setDeep('remote_storages.$storageKey.hashed_password', password);
      if (me.storageKey.isEmpty) me.storageKey = storageKey;
      await _repo.saveModel(me);
      await storage.auth(me.id, password);
      _repo.addConnectedStorage(storageKey, storage);
    }
    return success;
  }

  /// Allowlist для URL/ID instance: https-URL Supabase или идентификатор Firebase-проекта.
  bool _isValidInstance(String instance) {
    if (instance.isEmpty || instance.length > 256) return false;
    // Firebase project id
    if (isSafeRemotePathId(instance)) return true;
    // Supabase / произвольный https-URL: только https, без credentials в URL
    final uri = Uri.tryParse(instance);
    return uri != null &&
        uri.hasScheme &&
        uri.scheme == 'https' &&
        uri.userInfo.isEmpty &&
        uri.host.isNotEmpty;
  }

  /// Записать приглашение в удаленное хранилище по пути.
  Future<void> _putInvitationAtPath(String path, Invitation invitation) async {
    // Защита от path injection: все сегменты пути должны быть безопасными ID
    if (!path.split('/').every(isSafeRemotePathId)) {
      print('Rejected unsafe invitation path: $path');
      return;
    }
    // Приглашения храним в выделенном пути remote storage (не в models/, чтобы
    // не смешивать с моделями и не требовать прав на запись models)
    for (var storageEntry in _repo.connectedStorages.entries) {
      try {
        await storageEntry.value.saveRaw('invitations/$path', invitation.toJson());
      } catch (e) {
        print('Failed to put invitation to ${storageEntry.key}: $e');
      }
    }
  }
  /// Прочитать одно приглашение по пути.
  Future<Invitation?> _readInvitationAtPath(String path) async {
    if (!path.split('/').every(isSafeRemotePathId)) {
      print('Rejected unsafe invitation path: $path');
      return null;
    }
    for (var storageEntry in _repo.connectedStorages.entries) {
      try {
        final json = await storageEntry.value.readRaw('invitations/$path');
        if (json != null) return Invitation.fromJson(json);
      } catch (e) {
        print('Failed to read invitation from ${storageEntry.key}: $e');
      }
    }
    return null;
  }

  /// Прочитать все приглашения по префиксу пути (входящие).
  Future<List<Invitation>> _readInvitationsAtPath(String pathPrefix) async {
    final result = <Invitation>[];
    if (!pathPrefix.split('/').every(isSafeRemotePathId)) {
      print('Rejected unsafe invitation path prefix: $pathPrefix');
      return result;
    }
    for (var storageEntry in _repo.connectedStorages.entries) {
      try {
        final jsons = await storageEntry.value.readRawPrefix('invitations/$pathPrefix');
        for (final json in jsons) {
          final invitation = Invitation.fromJson(json);
          if (invitation.inviteeId == _repo.myId) result.add(invitation);
        }
      } catch (e) {
        print('Failed to read invitations from ${storageEntry.key}: $e');
      }
    }
    return result;
  }

  /// Добавить пользователя в список контактов текущего пользователя.
  Future<void> _addContact(String myId, String contactId) async {
    final me = _repo.me;
    // Ищем существующий ContactList пользователя среди детей
    final contactListIds = me.children.entries.where((e) => e.value == 'ContactList').map((e) => e.key);
    ContactList? contactList;
    for (final id in contactListIds) {
      final model = _repo.getModel<ContactList>(id);
      if (model != null) {
        contactList = model;
        break;
      }
    }
    contactList ??= ContactList(originatorId: myId, title: 'Контакты');
    if (!contactList.contactList.contains(contactId)) {
      contactList.contactList.add(contactId);
    }
    await _repo.saveModels([me, contactList]);
  }
}
