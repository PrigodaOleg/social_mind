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
  });
}
