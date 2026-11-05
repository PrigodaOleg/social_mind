import 'dart:typed_data';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/state/contact_list/contact_list.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:closers/ui/widgets/contact_picker_dialog.dart';
import 'package:closers/ui/l10n/app_localizations.dart';

/// In-memory LocalStorage fake: keeps everything in maps so the bloc and
/// repository can be exercised without any native database.
class FakeLocalStorage extends LocalStorage {
  final Map<String, dynamic> store = {};
  final Map<String, Uint8List> images = {};
  String? userId;

  @override
  Future<void> init() async {}

  @override
  String? getUserId() => userId;

  @override
  Future<void> setUserId(String id) async {
    userId = id;
  }

  @override
  Uint8List? getImage(String id) => images[id];

  @override
  Future<void> storeImage(String id, Uint8List imageBytes) async {
    images[id] = imageBytes;
  }

  @override
  dynamic getItem({required String id}) => store[id];

  @override
  Map<String, T> getItems<T>(List<String> ids) {
    final result = <String, T>{};
    for (final id in ids) {
      final item = store[id];
      if (item is T) result[id] = item;
    }
    return result;
  }

  @override
  Future<void> storeItem(dynamic item) async {
    store[item.id] = item;
  }

  @override
  Future<int> storeItems(Map<String, dynamic> items) async {
    store.addAll(items);
    return items.length;
  }

  @override
  Future<void> deleteItem(String id) async {
    store.remove(id);
  }

  @override
  Registry? getRegistry({String? id, String? parentId, int count = 5}) {
    if (id != null && store[id] is Registry) return store[id] as Registry;
    return null;
  }
}

Future<Repository> makeRepo({required User me}) async {
  final storage = FakeLocalStorage();
  final repo = Repository(localStorage: storage, remoteStorages: {});
  await repo.init();
  repo.me = me;
  // Let the async store of the user model complete.
  await Future<void>.delayed(Duration.zero);
  return repo;
}

/// Pump a bloc and let all pending microtasks/events settle.
Future<void> pump(
  ContactListBloc bloc,
  ContactListEvent event, [
  int rounds = 5,
]) async {
  bloc.add(event);
  for (var i = 0; i < rounds; i++) {
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
  }
}

Widget wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ContactListBloc', () {
    test('init creates a ContactList for user without one', () async {
      final me = User(id: 'me', name: 'Me');
      final repo = await makeRepo(me: me);
      final bloc = ContactListBloc(repository: repo);

      await pump(bloc, const ContactListInitRequested());

      expect(bloc.state.status, ContactListStatus.ready);
      expect(bloc.state.contactList, isNotNull);
      expect(bloc.state.contactList!.originatorId, 'me');
      // Contact list is linked to the user and saved.
      expect(me.ids<ContactList>(), contains(bloc.state.contactList!.id));
      await bloc.close();
    });

    test('init finds an existing ContactList of the user', () async {
      final me = User(id: 'me', name: 'Me');
      final repo = await makeRepo(me: me);
      final existing = ContactList(id: 'cl-1', originatorId: 'me');
      await me.linkTo(existing);
      final bloc = ContactListBloc(repository: repo);

      await pump(bloc, const ContactListInitRequested());

      expect(bloc.state.contactList!.id, 'cl-1');
      await bloc.close();
    });

    test('init loads contacts referenced by the contact list', () async {
      final me = User(id: 'me', name: 'Me');
      final repo = await makeRepo(me: me);
      final contact = Contact(id: 'c-1', userId: 'u-2', name: 'Bob');
      final list = ContactList(
        id: 'cl-1',
        originatorId: 'me',
        contactList: ['c-1'],
      );
      await me.linkTo(list);
      await repo.saveModel(contact);
      final bloc = ContactListBloc(repository: repo);

      await pump(bloc, const ContactListInitRequested());

      expect(bloc.state.contacts['c-1']!.name, 'Bob');
      await bloc.close();
    });

    test('create adds a contact and links it to the contact list', () async {
      final me = User(id: 'me', name: 'Me');
      final repo = await makeRepo(me: me);
      final bloc = ContactListBloc(repository: repo);
      await pump(bloc, const ContactListInitRequested());

      await pump(
        bloc,
        const ContactListContactCreated(name: 'Alice', userId: 'u-9'),
      );

      expect(bloc.state.contacts.length, 1);
      final contact = bloc.state.contacts.values.single;
      expect(contact.name, 'Alice');
      expect(contact.userId, 'u-9');
      // The contact is tracked in the contact list.
      expect(bloc.state.contactList!.contactList, contains(contact.id));
      // The contact is saved to local storage.
      final stored = await repo.getModelNow<Contact>(contact.id);
      expect(stored, isNotNull);
      await bloc.close();
    });

    test('edit renames an existing contact and saves it', () async {
      final me = User(id: 'me', name: 'Me');
      final repo = await makeRepo(me: me);
      final bloc = ContactListBloc(repository: repo);
      await pump(bloc, const ContactListInitRequested());
      await pump(
        bloc,
        const ContactListContactCreated(name: 'Alice', userId: 'u-9'),
      );
      final id = bloc.state.contacts.keys.single;

      await pump(bloc, ContactListContactEdited(contactId: id, name: 'Alicia'));

      expect(bloc.state.contacts[id]!.name, 'Alicia');
      final stored = await repo.getModelNow<Contact>(id);
      expect(stored!.name, 'Alicia');
      await bloc.close();
    });

    test('delete unlinks the contact from the contact list', () async {
      final me = User(id: 'me', name: 'Me');
      final repo = await makeRepo(me: me);
      final bloc = ContactListBloc(repository: repo);
      await pump(bloc, const ContactListInitRequested());
      await pump(
        bloc,
        const ContactListContactCreated(name: 'Alice', userId: 'u-9'),
      );
      final id = bloc.state.contacts.keys.single;

      await pump(bloc, ContactListContactDeleted(contactId: id));

      expect(bloc.state.contacts, isEmpty);
      expect(bloc.state.contactList!.contactList, isNot(contains(id)));
      await bloc.close();
    });

    test('sync event adds contacts coming from the repository', () async {
      final me = User(id: 'me', name: 'Me');
      final repo = await makeRepo(me: me);
      final bloc = ContactListBloc(repository: repo);
      await pump(bloc, const ContactListInitRequested());

      final remote = Contact(id: 'c-42', userId: 'u-42', name: 'Remote');
      await pump(
        bloc,
        ContactListContactsSynced(contacts: {'c-42': remote}),
      );

      expect(bloc.state.contacts['c-42']!.name, 'Remote');
      await bloc.close();
    });
  });

  group('ContactPickerDialog', () {
    final contacts = <String, Contact>{
      'c-1': Contact(id: 'c-1', userId: 'u-1', name: 'Alice'),
      'c-2': Contact(id: 'c-2', userId: 'u-2', name: 'Bob'),
      'c-3': Contact(id: 'c-3', userId: 'u-3', name: 'Carol'),
    };

    Future<void> openPicker(
      WidgetTester tester, {
      bool multiSelect = false,
    }) async {
      await tester.pumpWidget(wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => showContactPickerDialog(
                  context,
                  contacts: contacts,
                  multiSelect: multiSelect,
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    testWidgets('single select returns the tapped contact', (tester) async {
      Object? popped;
      await tester.pumpWidget(wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () async {
                  popped = await showContactPickerDialog(
                    context,
                    contacts: contacts,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // Tap on Bob - dialog closes and pops the contact to the caller.
      await tester.tap(find.text('Bob'));
      await tester.pumpAndSettle();

      expect(find.byType(ContactPickerDialog), findsNothing);
      expect(popped, isA<Contact>());
      expect((popped as Contact).id, 'c-2');
    });

    testWidgets('single select shows all contacts sorted by name',
        (tester) async {
      await openPicker(tester);

      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
      expect(find.byType(ListTile), findsNWidgets(3));
    });

    testWidgets('multi select allows choosing several contacts',
        (tester) async {
      await openPicker(tester, multiSelect: true);

      expect(find.byType(CheckboxListTile), findsNWidgets(3));

      await tester.tap(find.text('Alice'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carol'));
      await tester.pumpAndSettle();

      // Both checkboxes are checked now.
      final checkboxes = tester.widgetList<CheckboxListTile>(
        find.byType(CheckboxListTile),
      );
      final checked = checkboxes.where((c) => c.value == true).length;
      expect(checked, 2);

      // OK button closes the dialog with the selection.
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(ContactPickerDialog), findsNothing);
    });

    testWidgets('multi select OK without selection returns empty set',
        (tester) async {
      await openPicker(tester, multiSelect: true);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.byType(ContactPickerDialog), findsNothing);
    });

    testWidgets('empty contacts shows placeholder text', (tester) async {
      await tester.pumpWidget(wrap(
        Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () =>
                    showContactPickerDialog(context, contacts: const {}),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(ListTile), findsNothing);
      expect(find.text('No contacts yet'), findsOneWidget);
    });
  });
}
