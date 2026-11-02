import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:closers/repository/models/models.dart';
import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';

// Базовые классы абстрактны, поэтому для проверки карт десериализации
// используем пустые заглушки (по аналогии с моками из repository_test.dart).
class _DummyLocalStorage extends LocalStorage {
  @override
  Uint8List? getImage(String id) => null;
}

class _DummyRemoteStorage extends RemoteStorage {}

void main() {
  group('ContactList', () {
    group('construction', () {
      test('with only originatorId has correct defaults', () {
        final list = ContactList(originatorId: 'user-1');

        expect(list.originatorId, 'user-1');
        expect(list.contactList, isEmpty);
        expect(list.id, isNotEmpty);
        expect(list.type, 'ContactList');
        expect(list.sync, SyncStatus.no);
        expect(list.location, Location.local);
        expect(list.children, isEmpty);
        expect(list.parents, isEmpty);
      });

      test('preserves explicitly passed values', () {
        final list = ContactList(
          id: 'cl-1',
          title: 'Friends',
          description: 'My contacts',
          originatorId: 'user-1',
          contactList: ['contact-a', 'contact-b'],
        );

        expect(list.id, 'cl-1');
        expect(list.title, 'Friends');
        expect(list.description, 'My contacts');
        expect(list.originatorId, 'user-1');
        expect(list.contactList, ['contact-a', 'contact-b']);
      });

      test('null contactList becomes empty list', () {
        final list = ContactList(originatorId: 'user-1', contactList: null);

        expect(list.contactList, isEmpty);
      });
    });

    group('serialization', () {
      test('toJson/fromJson round-trip keeps all fields', () {
        final list = ContactList(
          id: 'cl-1',
          title: 'Friends',
          description: 'My contacts',
          originatorId: 'user-1',
          contactList: ['contact-a', 'contact-b'],
        );
        list.link(to: ContactList(id: 'other', originatorId: 'user-2'));

        final restored = ContactList.fromJson(list.toJson());

        expect(restored.id, list.id);
        expect(restored.title, list.title);
        expect(restored.description, list.description);
        expect(restored.type, list.type);
        expect(restored.originatorId, list.originatorId);
        expect(restored.contactList, list.contactList);
        expect(restored.location, list.location);
        expect(restored.children, list.children);
        expect(restored.parents, list.parents);
      });

      test('fromJson tolerates missing keys', () {
        final restored = ContactList.fromJson({'id': 'cl-1'});

        expect(restored.id, 'cl-1');
        expect(restored.originatorId, '');
        expect(restored.contactList, isEmpty);
        expect(restored.title, '');
        expect(restored.description, '');
      });

      test('fromJson accepts map-shaped contactList (Firebase format)', () {
        final restored = ContactList.fromJson({
          'id': 'cl-1',
          'originatorId': 'user-1',
          'contactList': {'contact-a': true, 'contact-b': true},
        });

        expect(restored.contactList, ['contact-a', 'contact-b']);
      });
    });

    group('equality', () {
      test('models with same fields are equal', () {
        final a = ContactList(
          id: 'cl-1',
          originatorId: 'user-1',
          contactList: ['c-1', 'c-2'],
        );
        final b = ContactList(
          id: 'cl-1',
          originatorId: 'user-1',
          contactList: ['c-1', 'c-2'],
        );

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different originatorId makes models unequal', () {
        final a = ContactList(id: 'cl-1', originatorId: 'user-1');
        final b = ContactList(id: 'cl-1', originatorId: 'user-2');

        expect(a, isNot(equals(b)));
      });

      test('different contactList makes models unequal', () {
        final a = ContactList(originatorId: 'user-1', contactList: ['c-1']);
        final b = ContactList(originatorId: 'user-1', contactList: ['c-2']);

        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('overrides provided fields and keeps the rest', () {
        final original = ContactList(
          id: 'cl-1',
          title: 'Friends',
          originatorId: 'user-1',
          contactList: ['c-1'],
        );

        final updated = original.copyWith(
          title: 'Work',
          contactList: ['c-2'],
        );

        expect(updated.title, 'Work');
        expect(updated.contactList, ['c-2']);
        expect(updated.id, 'cl-1');
        expect(updated.originatorId, 'user-1');
      });

      test('null arguments keep original list instance', () {
        final original = ContactList(
          originatorId: 'user-1',
          contactList: ['c-1'],
        );

        final copy = original.copyWith();

        expect(copy.contactList, same(original.contactList));
      });
    });

    group('mutability', () {
      test('contactList can be extended after creation', () {
        final list = ContactList(originatorId: 'user-1', contactList: ['c-1']);

        list.contactList.add('c-2');

        expect(list.contactList, ['c-1', 'c-2']);
        final json = list.toJson();
        expect(json['contactList'], containsAll(['c-1', 'c-2']));
      });
    });

    group('deserializer registration', () {
      test('LocalStorage models map restores ContactList', () {
        final factory = _DummyLocalStorage().models['ContactList'];

        expect(factory, isNotNull);
        final restored = factory!({
          'id': 'cl-1',
          'originatorId': 'user-1',
          'contactList': ['c-1'],
        });

        expect(restored, isA<ContactList>());
        expect((restored as ContactList).originatorId, 'user-1');
        expect(restored.contactList, ['c-1']);
      });

      test('RemoteStorage models map restores ContactList', () {
        final factory = _DummyRemoteStorage().models['ContactList'];

        expect(factory, isNotNull);
        final restored = factory!({
          'id': 'cl-1',
          'originatorId': 'user-1',
          'contactList': ['c-1'],
        });

        expect(restored, isA<ContactList>());
        expect((restored as ContactList).originatorId, 'user-1');
        expect(restored.contactList, ['c-1']);
      });
    });

    group('link/unlink', () {
      test('link with Contact adds its id to contactList', () {
        final list = ContactList(originatorId: 'user-1');
        final contact = Contact(userId: 'user-2', name: 'Bob');

        list.link(to: contact);

        expect(list.contactList, [contact.id]);
        expect(list.children, isEmpty);
      });

      test('link with non-Contact model does not change contactList', () {
        final list = ContactList(originatorId: 'user-1');
        final other = ContactList(id: 'other', originatorId: 'user-2');

        list.link(to: other);

        expect(list.contactList, isEmpty);
        expect(list.children, {'other': 'ContactList'});
      });

      test('linkFrom with Contact adds its id to contactList', () {
        final list = ContactList(originatorId: 'user-1');
        final contact = Contact(userId: 'user-2', name: 'Bob');

        list.link(from: contact);

        expect(list.contactList, [contact.id]);
        expect(list.children, isEmpty);
      });

      test('link with Contact does not add it to contactList children', () {
        final list = ContactList(originatorId: 'user-1');
        final contact = Contact(userId: 'user-2', name: 'Bob');

        list.link(to: contact);
        contact.link(from: list);

        // Contacts are tracked only via contactList,
        // so they never appear in children of the ContactList.
        expect(list.children, isEmpty);
        expect(list.contactList, contains(contact.id));
      });

      test('unlink with Contact removes its id from contactList', () {
        final contact = Contact(userId: 'user-2', name: 'Bob');
        final list = ContactList(
          originatorId: 'user-1',
          contactList: [contact.id],
        );

        list.unlink(to: contact);

        expect(list.contactList, isEmpty);
        expect(list.children, isEmpty);
      });

      test('unlink removes id from contactList but keeps other entries', () {
        final contact = Contact(userId: 'user-2', name: 'Bob');
        final list = ContactList(
          originatorId: 'user-1',
          contactList: ['c-0', contact.id],
        );

        list.unlink(to: contact);

        expect(list.contactList, ['c-0']);
      });

      test('unlink with non-Contact model does not change contactList', () {
        final other = ContactList(id: 'other', originatorId: 'user-2');
        final list = ContactList(
          originatorId: 'user-1',
          contactList: ['c-1'],
        );

        list.unlink(to: other);

        expect(list.contactList, ['c-1']);
      });
    });
  });

  group('Contact', () {
    group('construction', () {
      test('with userId only has correct defaults', () {
        final contact = Contact(userId: 'user-2');

        expect(contact.userId, 'user-2');
        expect(contact.name, '');
        expect(contact.id, isNotEmpty);
        expect(contact.type, 'Contact');
        expect(contact.sync, SyncStatus.no);
        expect(contact.location, Location.local);
      });

      test('preserves explicitly passed values', () {
        final contact = Contact(
          id: 'contact-1',
          title: 'Bob',
          userId: 'user-2',
          name: 'Bob',
        );

        expect(contact.id, 'contact-1');
        expect(contact.title, 'Bob');
        expect(contact.userId, 'user-2');
        expect(contact.name, 'Bob');
      });
    });

    group('serialization', () {
      test('toJson/fromJson round-trip keeps all fields', () {
        final contact = Contact(
          id: 'contact-1',
          title: 'Bob',
          userId: 'user-2',
          name: 'Bob',
        );

        final restored = Contact.fromJson(contact.toJson());

        expect(restored.id, contact.id);
        expect(restored.title, contact.title);
        expect(restored.description, contact.description);
        expect(restored.type, contact.type);
        expect(restored.userId, contact.userId);
        expect(restored.name, contact.name);
        expect(restored.location, contact.location);
      });

      test('fromJson tolerates missing keys', () {
        final restored = Contact.fromJson({'id': 'contact-1'});

        expect(restored.id, 'contact-1');
        expect(restored.userId, '');
        expect(restored.name, '');
      });
    });

    group('equality', () {
      test('models with same fields are equal', () {
        final a = Contact(id: 'contact-1', userId: 'user-2', name: 'Bob');
        final b = Contact(id: 'contact-1', userId: 'user-2', name: 'Bob');

        expect(a, equals(b));
        expect(a.hashCode, b.hashCode);
      });

      test('different name makes models unequal', () {
        final a = Contact(id: 'contact-1', userId: 'user-2', name: 'Bob');
        final b = Contact(id: 'contact-1', userId: 'user-2', name: 'Alice');

        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('overrides provided fields and keeps the rest', () {
        final original = Contact(
          id: 'contact-1',
          userId: 'user-2',
          name: 'Bob',
        );

        final updated = original.copyWith(name: 'Robert');

        expect(updated.name, 'Robert');
        expect(updated.id, 'contact-1');
        expect(updated.userId, 'user-2');
      });
    });

    group('deserializer registration', () {
      test('LocalStorage models map restores Contact', () {
        final factory = _DummyLocalStorage().models['Contact'];

        expect(factory, isNotNull);
        final restored = factory!({
          'id': 'contact-1',
          'userId': 'user-2',
          'name': 'Bob',
        });

        expect(restored, isA<Contact>());
        expect((restored as Contact).userId, 'user-2');
        expect(restored.name, 'Bob');
      });

      test('RemoteStorage models map restores Contact', () {
        final factory = _DummyRemoteStorage().models['Contact'];

        expect(factory, isNotNull);
        final restored = factory!({
          'id': 'contact-1',
          'userId': 'user-2',
          'name': 'Bob',
        });

        expect(restored, isA<Contact>());
        expect((restored as Contact).userId, 'user-2');
        expect(restored.name, 'Bob');
      });
    });
  });
}
