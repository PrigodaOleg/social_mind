import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:repository/repository.dart';


class DomainListBloc extends Bloc<DomainEvent, DomainListState> {
  // Domain can be:
  // created
  // deleted
  DomainListBloc({
    required Repository repository
    }) : _repo = repository,
     super(const DomainListState()) {
    on<DomainListStateInitRequested>(_onStateInit);
    on<DomainCreationRequested>(_onCreation);
    on<DomainDeletionRequested>(_onDeletion);
    on<DomainChangingRequested>(_onChanging);
    on<DomainSyncRequested>(_onSync);
  }

  final Repository _repo;
  late final int listenerId;
  
  @override
  Future<void> close() {
    //cancel streams
    _repo.removeSyncListener(listenerId);
    return super.close();
  }

  Future<void> _onStateInit(
    DomainListStateInitRequested event,
    Emitter<DomainListState> emit,
  ) async {
    listenerId = _repo.addSyncListener((id, item) {
      if (!isClosed) {
        add(DomainSyncRequested(domains: {id: item}));
      }
    });
    User me = await _repo.me();
    Map<String, Domain> domains = await _repo.getModels<Domain>(me.domainsIds, listenerId);
    emit(state.copyWith(domains: () => domains));
  }

  Future<void> _onCreation(
    DomainCreationRequested event,
    Emitter<DomainListState> emit,
  ) async {
    User me = await _repo.me();
    var newDomain = Domain(originatorId: me.id, title: event.title);
    me.linkTo(newDomain);
    
    await _repo.saveModels([me, newDomain], listenerId);
    
    Map<String, Domain> domains = await _repo.getModels<Domain>(me.domainsIds, listenerId);
    emit(state.copyWith(domains: () => domains));
  }

  Future<void> _onSync(
    DomainSyncRequested event,
    Emitter<DomainListState> emit,
  ) async {
    emit(state.copyWith(domains: () => state.domains..addAll(event.domains)));
  }
  
  Future<void> _onDeletion(
    DomainDeletionRequested event,
    Emitter<DomainListState> emit,
  ) async {
    if (event.domain.title == '') {
      return;
    }
    final domainToDelete = event.domain;
    User me = await _repo.me();
    me.unlinkFrom(domainToDelete);
    await _repo.deleteModel(domainToDelete);
    await _repo.saveModel(me, listenerId);

    Map<String, Domain> domains = await _repo.getModels<Domain>(me.domainsIds, listenerId);
    emit(state.copyWith(domains: () => domains));
  }

  Future<void> _onChanging(
    DomainChangingRequested event,
    Emitter<DomainListState> emit,
  ) async {
    Domain domainToChange = event.domain;
    domainToChange = domainToChange.copyWith(title: (listenerId).toString());
    emit(state.copyWith(domains: () => state.domains..addAll({domainToChange.id: domainToChange})));
  }
}

class DomainListState {
  const DomainListState({
    this.domains = const {}
  });
  final Map<String, Domain> domains;

  DomainListState copyWith({
    Map<String, Domain> Function()? domains,
  }) {
    return DomainListState(
      domains: domains != null ? domains() : this.domains,
    );
  }
}

sealed class DomainEvent extends Equatable{
  const DomainEvent();

  @override
  List<Object> get props => [];
}

final class DomainListStateInitRequested extends DomainEvent {
  const DomainListStateInitRequested();
}

final class DomainCreationRequested extends DomainEvent {
  const DomainCreationRequested(
    this.title
  );
  final String title;
}

final class DomainChangingRequested extends DomainEvent {
  const DomainChangingRequested({
    required this.domain
  });
  final Domain domain;
}

final class DomainDeletionRequested extends DomainEvent {
  const DomainDeletionRequested({
    required this.domain
  });
  final Domain domain;
}

final class DomainSyncRequested extends DomainEvent {
  const DomainSyncRequested({
    required this.domains
  });
  final Map<String, Domain> domains;
}