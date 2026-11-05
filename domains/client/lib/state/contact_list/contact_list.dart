import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:closers/repository/repository.dart';

/// Bloc for the user's own contact list: shows contacts stored in the
/// current user's [ContactList] and allows adding, editing and deleting them.
///
/// Contacts are saved to local and remote storage through the existing
/// link/unlink mechanism (`Model.linkTo` / `Model.unlinkFrom`) and
/// `Repository.saveModel`.
class ContactListBloc extends Bloc<ContactListEvent, ContactListState> {
  ContactListBloc({required Repository repository})
      : _repo = repository,
        super(const ContactListState()) {
    on<ContactListInitRequested>(_onInit);
    on<ContactListContactCreated>(_onContactCreated);
    on<ContactListContactEdited>(_onContactEdited);
    on<ContactListContactDeleted>(_onContactDeleted);
    on<ContactListContactsSynced>(_onContactsSynced);
  }

  final Repository _repo;
  late final int listenerId;

  @override
  Future<void> close() {
    // After the page is closed we no longer need to listen for model changes.
    _repo.removeSyncListener(listenerId);
    return super.close();
  }

  /// Finds the contact list of the current user, creating one if it does not
  /// exist yet, and loads all contacts it links to.
  Future<void> _onInit(
    ContactListInitRequested event,
    Emitter<ContactListState> emit,
  ) async {
    // Register a callback on model changes so the page can react to sync.
    listenerId = _repo.addSyncListener(
      (id, item) {
        if (!isClosed && item is Contact) {
          add(ContactListContactsSynced(contacts: {id: item}));
        }
      },
      (localChanges, remoteChanges) {},
    );

    final User me = _repo.me;

    // Find the contact list of the current user among his children.
    ContactList? contactList;
    final contactListIds = me.ids<ContactList>();
    if (contactListIds.isNotEmpty) {
      contactList = _repo.getModels<ContactList>(contactListIds, listenerId)
          .values
          .firstOrNull;
    }
    if (contactList == null) {
      // No contact list yet - create one and link it to the user.
      contactList = ContactList(originatorId: me.id);
      await me.linkTo(contactList, listenerId);
    }

    // Load all contacts referenced by the contact list.
    final contacts =
        _repo.getModels<Contact>(contactList.contactList, listenerId);

    emit(state.copyWith(
      contactList: () => contactList,
      contacts: () => contacts,
      status: () => ContactListStatus.ready,
    ));
  }

  /// Creates a new contact and links it to the user's contact list
  /// (the linkTo mechanism saves both models to local and remote DBs).
  Future<void> _onContactCreated(
    ContactListContactCreated event,
    Emitter<ContactListState> emit,
  ) async {
    final contactList = state.contactList;
    if (contactList == null) return;

    final contact = Contact(
      userId: event.userId,
      name: event.name,
    );
    await contactList.linkTo(contact, listenerId);

    emit(state.copyWith(
      contactList: () => contactList,
      contacts: () => {...state.contacts, contact.id: contact},
    ));
  }

  /// Edits the name of an existing contact and saves it.
  Future<void> _onContactEdited(
    ContactListContactEdited event,
    Emitter<ContactListState> emit,
  ) async {
    final contact = state.contacts[event.contactId];
    if (contact == null) return;

    final updated = contact.copyWith(name: event.name);
    await _repo.saveModel(updated, listenerId);

    emit(state.copyWith(
      contacts: () => {...state.contacts}..[updated.id] = updated,
    ));
  }

  /// Deletes a contact by unlinking it from the contact list.
  /// The unlinkFrom mechanism removes the link and deletes the contact
  /// from local and remote storages.
  Future<void> _onContactDeleted(
    ContactListContactDeleted event,
    Emitter<ContactListState> emit,
  ) async {
    final contactList = state.contactList;
    final contact = state.contacts[event.contactId];
    if (contactList == null || contact == null) return;

    await contactList.unlinkFrom(contact, listenerId);

    final contacts = {...state.contacts}..remove(contact.id);
    emit(state.copyWith(
      contactList: () => contactList,
      contacts: () => contacts,
    ));
  }

  /// Applies incoming sync changes to the state.
  void _onContactsSynced(
    ContactListContactsSynced event,
    Emitter<ContactListState> emit,
  ) {
    var contacts = {...state.contacts};
    contacts.addAll(event.contacts);
    for (final id in event.removedIds) {
      contacts.remove(id);
    }
    emit(state.copyWith(contacts: () => contacts));
  }
}

enum ContactListStatus { initial, loading, ready }

class ContactListState extends Equatable {
  const ContactListState({
    this.status = ContactListStatus.initial,
    this.contactList,
    this.contacts = const {},
  });

  final ContactListStatus status;
  final ContactList? contactList;
  final Map<String, Contact> contacts;

  ContactListState copyWith({
    ContactListStatus Function()? status,
    ContactList? Function()? contactList,
    Map<String, Contact> Function()? contacts,
  }) {
    return ContactListState(
      status: status != null ? status() : this.status,
      contactList: contactList != null ? contactList() : this.contactList,
      contacts: contacts != null ? contacts() : this.contacts,
    );
  }

  @override
  List<Object?> get props => [status, contactList, contacts];
}

sealed class ContactListEvent extends Equatable {
  const ContactListEvent();

  @override
  List<Object?> get props => [];
}

final class ContactListInitRequested extends ContactListEvent {
  const ContactListInitRequested();
}

final class ContactListContactCreated extends ContactListEvent {
  const ContactListContactCreated({
    required this.name,
    required this.userId,
  });

  final String name;
  final String userId;

  @override
  List<Object?> get props => [name, userId];
}

final class ContactListContactEdited extends ContactListEvent {
  const ContactListContactEdited({
    required this.contactId,
    required this.name,
  });

  final String contactId;
  final String name;

  @override
  List<Object?> get props => [contactId, name];
}

final class ContactListContactDeleted extends ContactListEvent {
  const ContactListContactDeleted({required this.contactId});

  final String contactId;

  @override
  List<Object?> get props => [contactId];
}

final class ContactListContactsSynced extends ContactListEvent {
  const ContactListContactsSynced({
    required this.contacts,
    this.removedIds = const {},
  });

  final Map<String, Contact> contacts;
  final Set<String> removedIds;

  @override
  List<Object?> get props => [contacts, removedIds];
}
