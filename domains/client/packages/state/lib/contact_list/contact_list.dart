import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:repository/repository.dart';


class ContactListBloc extends Bloc<ContactEvent, ContactListState> {
  ContactListBloc({
    required Repository repository
    }) : _repo = repository,
     super(const ContactListState()) {
    on<ContactListStateInitRequested>(_onStateInit);
    on<ContactInvitationRequested>(_onInvitation);
    on<ContactHandshakeRequested>(_onHandshake);
    on<ContactCreateUserProjectionRequested>(_onCreateUserProjection);
    on<ContactUserSyncRequested>(_onUserSync);
    on<ContactDomainSyncRequested>(_onDomainSync);
  }

  final Repository _repo;
  late final int listenerId;
  
  @override
  Future<void> close() {
    // При закрытии страницы нам больше не нужно следить за изменениями в репозитории
    _repo.removeSyncListener(listenerId);
    return super.close();
  }

  Future<void> _onStateInit(
    ContactListStateInitRequested event,
    Emitter<ContactListState> emit,
  ) async {
    // При открытии страницы с контактами регистрируем обратный вызов на изменение моделей.
    // Причем, нас интересует только изменение пользователей или доменов.
    listenerId = _repo.addSyncListener((id, item) {
      if (!isClosed) {
        switch (item) {
          case User _:
            add(ContactUserSyncRequested(contacts: {id: item}));
            break;
          case Domain _:
            add(ContactDomainSyncRequested(domains: {id: item}));
            break;
          default:
        }
      }
    });
    User me = _repo.me;
    _repo.subscribeToSync(me.id, listenerId);
    Map<String, Domain> contactDomains = _repo.getModels<Domain>(me.domainsIds, listenerId);
    List<String> userIds = [];
    for (final domain in contactDomains.values) {
      userIds.addAll(domain.participantsIds);
    }
    Map<String, User> contacts = _repo.getModels<User>(userIds, listenerId);
    emit(state.copyWith(contacts: () => contacts));
  }

  Future<void> _onInvitation(
    ContactInvitationRequested event,
    Emitter<ContactListState> emit,
  ) async {
    // Пригласить нового пользователя (которого нет в базе,
    // то есть ему нужно послать ссылку на скачивание приложения)
  }

  Future<void> _onHandshake(
    ContactHandshakeRequested event,
    Emitter<ContactListState> emit,
  ) async {
    // Начать контактировать с пользователем, который уже есть в базе,
    // и мы знаем его ID. Для этого достаточно создать с ним новый домен
    // или добавить его в один из существующих.
  }

  Future<void> _onCreateUserProjection(
    ContactCreateUserProjectionRequested event,
    Emitter<ContactListState> emit,
  ) async {
    // Третий вариант - не приглашать пользователя, а создать некую его проекцию,
    // которая будет выполнять роль пользователя, и которую можно в последствии
    // превратить в настоящего пользователя, или перенести контекст проекции на
    // существующего пользователя. Это кажется мощным инструментом.
  }

  Future<void> _onUserSync(
    ContactUserSyncRequested event,
    Emitter<ContactListState> emit,
  ) async {
    // При изменении пользователя может измениться число доменов, в которые он входит,
    // соответственно и число пользователей в этом списке.
  }

  Future<void> _onDomainSync(
    ContactDomainSyncRequested event,
    Emitter<ContactListState> emit,
  ) async {
    // При обновлении состояния домена нужно пересчитать пользователей,
    // поскольку, если какой-то пользователь будет исключен из домена,
    // то он пропадет и из этого списка.
  }
}

class ContactListState {
  // Наше состояние хранит таблицу с пользователями
  const ContactListState({
    this.contacts = const {}
  });
  final Map<String, User> contacts;

  ContactListState copyWith({
    Map<String, User> Function()? contacts,
  }) {
    return ContactListState(
      contacts: contacts != null ? contacts() : this.contacts,
    );
  }
}

sealed class ContactEvent extends Equatable{
  const ContactEvent();

  @override
  List<Object> get props => [];
}

final class ContactListStateInitRequested extends ContactEvent {
  // Событие создания состояния. Оно ничего не принимает.
  const ContactListStateInitRequested();
}

final class ContactInvitationRequested extends ContactEvent {
  // Событие на кнопку "пригласить пользователя".
  // Чтобы пригласить пользователя, нужно иметь канал связи с ним.
  // В современном мире это мессенджеры, более архаично по почте или смс.
  // Соответственно, мы должны принимать какой-то текст приглашения,
  // а также способ отправки этого сообщения.
  // К сообщению также нужно приложить ссылку на скачивание нашего приложения
  // под платформу пользователя или ссылку на web версию.
  // Кстати, мы можем послать ссылку на вход под проекцией,
  // которая при этом станет настоящим пользователем.
  const ContactInvitationRequested(
    this.name,
    this.invitationMessage,
    this.communicationChannel
  );
  final String name;
  final String invitationMessage;
  final String communicationChannel;
}

final class ContactHandshakeRequested extends ContactEvent {
  // Событие на кнопку "контактировать".
  // Мы заранее знаем ID пользователя и приглашаем его в один из доменов.
  // Попутно мы можем создать с ним приватный домен, если нужно.
  const ContactHandshakeRequested(
    this.id
  );
  final String id;
}

final class ContactCreateUserProjectionRequested extends ContactEvent {
  // Когда мы хотим создать проекцию пользователя,
  // то нам нужно знать хотя бы его имя. Можно, также указать канал связи с ним.
  // Также возможен вариант, что создается проекция существующего пользователя.
  // В этом случае нужно также указать ID.
  const ContactCreateUserProjectionRequested(
    this.name,
    [this.communicationChannel,
    this.id]
  );
  final String name;
  final String? communicationChannel;
  final String? id;
}

final class ContactUserSyncRequested extends ContactEvent {
  // Событие от репозитория на изменение пользователя, на которого ранее была настроена подписка.
  const ContactUserSyncRequested({
    required this.contacts
  });
  final Map<String, User> contacts;
}

final class ContactDomainSyncRequested extends ContactEvent {
  // Событие от репозитория на изменение домена, на который ранее была настроена подписка.
  const ContactDomainSyncRequested({
    required this.domains
  });
  final Map<String, Domain> domains;
}