import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:closers/repository/repository.dart';
import 'package:equatable/equatable.dart';

/// Bloc управления знакомствами и приглашениями.
class InvitationBloc extends Bloc<InvitationEvent, InvitationState> {
  InvitationBloc({required Repository repository})
      : _repo = repository,
        _invitationService = InvitationService(repository),
        super(const InvitationState()) {
    on<InvitationStateInitRequested>(_onStateInit);
    on<AcquaintanceQrGenerated>(_onAcquaintanceQrGenerated);
    on<AcquaintanceQrScanned>(_onAcquaintanceQrScanned);
    on<IncomingAcquaintancesAccepted>(_onIncomingAcquaintancesAccepted);
    on<DomainInvitationCreated>(_onDomainInvitationCreated);
    on<DomainInvitationQrScanned>(_onDomainInvitationQrScanned);
    on<DomainInvitationAccepted>(_onDomainInvitationAccepted);
    on<InvitationVoted>(_onInvitationVoted);
  }

  final Repository _repo;
  final InvitationService _invitationService;

  @override
  Future<void> close() {
    return super.close();
  }

  Future<void> _onStateInit(
    InvitationStateInitRequested event,
    Emitter<InvitationState> emit,
  ) async {
    final me = _repo.me;
    // Собираем входящие приглашения-знакомства из удаленного хранилища
    final service = _invitationService;
    final pendingDomainInvitations = <Invitation>[];
    // Проверяем локально сохраненные приглашения в домены, ожидающие консенсуса
    // (в реальной системе они приходят по подписке на реестры домена).
    emit(state.copyWith(
      myId: () => me.id,
      myName: () => me.name,
    ));
  }

  /// Сгенерировать QR-данные для знакомства (показать свою сторону).
  Future<void> _onAcquaintanceQrGenerated(
    AcquaintanceQrGenerated event,
    Emitter<InvitationState> emit,
  ) async {
    final payload = _invitationService.acquaintanceQrPayload();
    emit(state.copyWith(acquaintanceQrPayload: () => jsonEncode(payload)));
  }

  /// Отсканирован QR инициатора знакомства - отправляем ответное приглашение.
  Future<void> _onAcquaintanceQrScanned(
    AcquaintanceQrScanned event,
    Emitter<InvitationState> emit,
  ) async {
    final parsed = InvitationService.parseAcquaintanceQr(event.qrData);
    if (parsed == null) {
      emit(state.copyWith(error: () => 'Invalid QR code'));
      return;
    }
    try {
      await _invitationService.sendAcquaintanceInvitation(
        initiatorId: parsed.userId,
        initiatorName: parsed.name,
        storageKey: parsed.storageKey,
        storageInstance: parsed.storageInstance,
      );
      emit(state.copyWith(lastAction: () => 'acquaintance_sent:${parsed.userId}'));
    } catch (e) {
      emit(state.copyWith(error: () => e.toString()));
    }
  }

  /// Принять все входящие приглашения-знакомства (создать домены на двоих).
  Future<void> _onIncomingAcquaintancesAccepted(
    IncomingAcquaintancesAccepted event,
    Emitter<InvitationState> emit,
  ) async {
    try {
      final domains = await _invitationService.acceptAcquaintanceInvitations();
      emit(state.copyWith(
        createdDomains: () => domains,
        lastAction: () => 'acquaintances_accepted:${domains.length}',
      ));
    } catch (e) {
      emit(state.copyWith(error: () => e.toString()));
    }
  }

  /// Создать приглашение в домен (участником).
  Future<void> _onDomainInvitationCreated(
    DomainInvitationCreated event,
    Emitter<InvitationState> emit,
  ) async {
    try {
      final invitation = await _invitationService.createDomainInvitation(
        domain: event.domain,
        inviteeId: event.inviteeId,
        role: event.role,
      );
      final qrData = _invitationService.domainInvitationQrPayload(invitation);
      emit(state.copyWith(
        domainInvitationQrPayload: () => qrData,
        lastInvitation: () => invitation,
        lastAction: () => 'domain_invitation_created:${invitation.id}',
      ));
    } catch (e) {
      emit(state.copyWith(error: () => e.toString()));
    }
  }

  /// Отсканирован QR приглашения в домен - читаем приглашение и принимаем.
  Future<void> _onDomainInvitationQrScanned(
    DomainInvitationQrScanned event,
    Emitter<InvitationState> emit,
  ) async {
    final parsed = InvitationService.parseDomainInvitationQr(event.qrData);
    if (parsed == null) {
      emit(state.copyWith(error: () => 'Invalid QR code'));
      return;
    }
    try {
      final invitation = await _invitationService.readDomainInvitation(parsed.invitationId);
      if (invitation == null) {
        emit(state.copyWith(error: () => 'Invitation not found'));
        return;
      }
      emit(state.copyWith(lastInvitation: () => invitation, lastAction: () => 'domain_invitation_read'));
    } catch (e) {
      emit(state.copyWith(error: () => e.toString()));
    }
  }

  /// Приглашаемый принимает приглашение в домен.
  Future<void> _onDomainInvitationAccepted(
    DomainInvitationAccepted event,
    Emitter<InvitationState> emit,
  ) async {
    try {
      final invitation = await _invitationService.acceptDomainInvitation(event.invitation);
      emit(state.copyWith(lastInvitation: () => invitation, lastAction: () => 'domain_invitation_accepted'));
    } catch (e) {
      emit(state.copyWith(error: () => e.toString()));
    }
  }

  /// Участник голосует за приглашение (консенсус).
  Future<void> _onInvitationVoted(
    InvitationVoted event,
    Emitter<InvitationState> emit,
  ) async {
    try {
      await _invitationService.voteForInvitation(event.invitation, event.domain, approved: event.approved);
      emit(state.copyWith(lastAction: () => 'voted:${event.approved}'));
    } catch (e) {
      emit(state.copyWith(error: () => e.toString()));
    }
  }
}

class InvitationState extends Equatable {
  const InvitationState({
    this.myId = '',
    this.myName = '',
    this.acquaintanceQrPayload,
    this.domainInvitationQrPayload,
    this.createdDomains = const [],
    this.lastInvitation,
    this.lastAction,
    this.error,
  });

  final String myId;
  final String myName;
  final String? acquaintanceQrPayload;
  final String? domainInvitationQrPayload;
  final List<Domain> createdDomains;
  final Invitation? lastInvitation;
  final String? lastAction;
  final String? error;

  InvitationState copyWith({
    String Function()? myId,
    String Function()? myName,
    String Function()? acquaintanceQrPayload,
    String Function()? domainInvitationQrPayload,
    List<Domain> Function()? createdDomains,
    Invitation? Function()? lastInvitation,
    String Function()? lastAction,
    String Function()? error,
  }) {
    return InvitationState(
      myId: myId != null ? myId() : this.myId,
      myName: myName != null ? myName() : this.myName,
      acquaintanceQrPayload: acquaintanceQrPayload != null ? acquaintanceQrPayload() : this.acquaintanceQrPayload,
      domainInvitationQrPayload: domainInvitationQrPayload != null ? domainInvitationQrPayload() : this.domainInvitationQrPayload,
      createdDomains: createdDomains != null ? createdDomains() : this.createdDomains,
      lastInvitation: lastInvitation != null ? lastInvitation() : this.lastInvitation,
      lastAction: lastAction != null ? lastAction() : this.lastAction,
      error: error != null ? error() : this.error,
    );
  }

  @override
  List<Object?> get props => [myId, myName, acquaintanceQrPayload, domainInvitationQrPayload, createdDomains, lastInvitation, lastAction, error];
}

sealed class InvitationEvent extends Equatable {
  const InvitationEvent();

  @override
  List<Object?> get props => [];
}

final class InvitationStateInitRequested extends InvitationEvent {
  const InvitationStateInitRequested();
}

final class AcquaintanceQrGenerated extends InvitationEvent {
  const AcquaintanceQrGenerated();
}

final class AcquaintanceQrScanned extends InvitationEvent {
  const AcquaintanceQrScanned(this.qrData);
  final String qrData;

  @override
  List<Object?> get props => [qrData];
}

final class IncomingAcquaintancesAccepted extends InvitationEvent {
  const IncomingAcquaintancesAccepted();
}

final class DomainInvitationCreated extends InvitationEvent {
  const DomainInvitationCreated({required this.domain, required this.inviteeId, this.role = InvitationRole.participant});
  final Domain domain;
  final String inviteeId;
  final InvitationRole role;

  @override
  List<Object?> get props => [domain, inviteeId, role];
}

final class DomainInvitationQrScanned extends InvitationEvent {
  const DomainInvitationQrScanned(this.qrData);
  final String qrData;

  @override
  List<Object?> get props => [qrData];
}

final class DomainInvitationAccepted extends InvitationEvent {
  const DomainInvitationAccepted(this.invitation);
  final Invitation invitation;

  @override
  List<Object?> get props => [invitation];
}

final class InvitationVoted extends InvitationEvent {
  const InvitationVoted({required this.invitation, required this.domain, required this.approved});
  final Invitation invitation;
  final Domain domain;
  final bool approved;

  @override
  List<Object?> get props => [invitation, domain, approved];
}
