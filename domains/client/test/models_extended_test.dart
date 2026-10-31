import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:closers/repository/models/models.dart';
import 'package:closers/repository/repository.dart';
import 'package:closers/local_storage/local_storage.dart';

void main() {
  group('Location', () {
    test('locationFromString parses all values', () {
      expect(locationFromString('Location.remote'), Location.remote);
      expect(locationFromString('Location.both'), Location.both);
      expect(locationFromString('Location.local'), Location.local);
      expect(locationFromString(null), Location.local);
      expect(locationFromString('garbage'), Location.local);
    });

    test('Location enum values', () {
      expect(Location.values.length, 3);
      expect(Location.local.toString(), 'Location.local');
    });
  });

  group('Model base', () {
    test('constructor generates id when not provided', () {
      final task = Task(originatorId: 'u1');
      expect(task.id, isNotEmpty);
      expect(task.title, '');
      expect(task.description, '');
      expect(task.location, Location.local);
      expect(task.children, isEmpty);
      expect(task.parents, isEmpty);
      expect(task.sync, SyncStatus.no);
      expect(task.type, 'Task');
    });

    test('constructor uses provided id', () {
      final task = Task(id: 'custom-id', originatorId: 'u1');
      expect(task.id, 'custom-id');
    });

    test('constructor asserts on empty id', () {
      expect(() => Task(id: '', originatorId: 'u1'),
          throwsA(isA<AssertionError>()));
    });

    test('link and unlink update children and parents', () {
      final domain = Domain(originatorId: 'u');
      final task = Task(originatorId: 'u');
      // base link is one-directional: link(to:) sets caller's children only
      domain.link(to: task);
      expect(domain.children[task.id], 'Task');
      expect(task.parents, isEmpty);

      domain.unlink(to: task);
      expect(domain.children.containsKey(task.id), isFalse);

      // link(from:) sets caller's parents only
      domain.link(from: task);
      expect(domain.parents[task.id], 'Task');
      expect(task.children, isEmpty);

      domain.unlink(from: task);
      expect(domain.parents.containsKey(task.id), isFalse);

      // link with both arguments sets both maps on the caller
      domain.link(to: task, from: task);
      expect(domain.children[task.id], 'Task');
      expect(domain.parents[task.id], 'Task');
      domain.unlink(to: task, from: task);
      expect(domain.children, isEmpty);
      expect(domain.parents, isEmpty);
    });

    test('link/unlink with null arguments do nothing', () {
      final task = Task(originatorId: 'u');
      task.link();
      task.unlink();
      expect(task.children, isEmpty);
      expect(task.parents, isEmpty);
    });

    test('ids returns children ids of given type', () {
      final domain = Domain(originatorId: 'u');
      final t1 = Task(originatorId: 'u');
      final t2 = Task(originatorId: 'u');
      final u1 = User(name: 'u1');
      domain.link(to: t1);
      domain.link(to: t2);
      domain.link(to: u1);
      expect(domain.ids<Task>(), [t1.id, t2.id]);
      expect(domain.ids<User>(), [u1.id]);
      expect(domain.ids<Domain>(), isEmpty);
    });

    test('toJson includes base fields', () {
      final task =
          Task(id: 't1', title: 'T', description: 'D', originatorId: 'u1');
      final json = task.toJson();
      expect(json['id'], 't1');
      expect(json['title'], 'T');
      expect(json['description'], 'D');
      expect(json['type'], 'Task');
      expect(json['location'], 'Location.local');
      expect(json['children'], isEmpty);
      expect(json['parents'], isEmpty);
    });

    test('Model.fromJson restores base fields', () {
      final json = {
        'id': 'm1',
        'title': 'T',
        'description': 'D',
        'location': 'Location.both',
        'children': {'c1': 'Task'},
        'parents': {'p1': 'Domain'},
      };
      final task = Task.fromJson(json);
      expect(task.id, 'm1');
      expect(task.title, 'T');
      expect(task.description, 'D');
      expect(task.location, Location.both);
      expect(task.children, {'c1': 'Task'});
      expect(task.parents, {'p1': 'Domain'});
    });

    test('Model.fromJson handles missing fields', () {
      final task = Task.fromJson({});
      expect(task.id, '');
      expect(task.title, '');
      expect(task.location, Location.local);
      expect(task.children, isEmpty);
      expect(task.parents, isEmpty);
    });

    test('equatable: same props equal, different not', () {
      final a = Task(id: 't1', title: 'x', originatorId: 'u');
      final b = Task(id: 't1', title: 'x', originatorId: 'u');
      final c = Task(id: 't1', title: 'y', originatorId: 'u');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('Task', () {
    test('constructor defaults', () {
      final task = Task(originatorId: 'u1');
      expect(task.isCompleted, false);
      expect(task.executorId, '');
      expect(task.originatorId, 'u1');
    });

    test('fromJson restores task fields', () {
      final task = Task.fromJson({
        'id': 't1',
        'title': 'Task',
        'isCompleted': true,
        'originatorId': 'u1',
        'executorId': 'u2',
      });
      expect(task.isCompleted, true);
      expect(task.originatorId, 'u1');
      expect(task.executorId, 'u2');
    });

    test('fromJson handles missing fields', () {
      final task = Task.fromJson({});
      expect(task.isCompleted, false);
      expect(task.originatorId, '');
      expect(task.executorId, '');
    });

    test('toJson roundtrip', () {
      final task = Task(
          id: 't1',
          title: 'T',
          description: 'D',
          isCompleted: true,
          originatorId: 'u1',
          executorId: 'u2');
      final restored = Task.fromJson(task.toJson());
      expect(restored, task);
      expect(restored.isCompleted, true);
      expect(restored.executorId, 'u2');
    });

    test('copyWith updates fields and keeps others', () {
      final task =
          Task(id: 't1', title: 'T', originatorId: 'u1', executorId: 'u2');
      final updated = task.copyWith(isCompleted: true, title: 'New');
      expect(updated.id, 't1');
      expect(updated.title, 'New');
      expect(updated.isCompleted, true);
      expect(updated.originatorId, 'u1');
      expect(updated.executorId, 'u2');
    });

    test('copyWith with no args keeps everything', () {
      final task = Task(id: 't1', title: 'T', originatorId: 'u1');
      expect(task.copyWith(), task);
    });
  });

  group('User', () {
    test('constructor defaults', () {
      final user = User(name: 'alice');
      expect(user.name, 'alice');
      expect(user.domainsIds, isEmpty);
      expect(user.registryId, '');
      expect(user.avatarUrl, '');
      expect(user.firstName, '');
      expect(user.lastName, '');
      expect(user.description, '');
      expect(user.type, 'User');
      expect(user.secret, isNull);
      expect(user.settings['remote_storages'], isNotNull);
      expect(user.secrets['remote_storages'], isNotNull);
    });

    test('fromJson restores user fields', () {
      final user = User.fromJson({
        'id': 'u1',
        'name': 'alice',
        'domainsIds': ['d1', 'd2'],
        'registryId': 'r1',
        'avatarUrl': 'http://x',
        'firstName': 'A',
        'lastName': 'B',
        'description': 'desc',
      });
      expect(user.id, 'u1');
      expect(user.name, 'alice');
      expect(user.domainsIds, ['d1', 'd2']);
      expect(user.registryId, 'r1');
      expect(user.avatarUrl, 'http://x');
      expect(user.firstName, 'A');
      expect(user.lastName, 'B');
      expect(user.description, 'desc');
    });

    test('fromJson handles domainsIds as map keys', () {
      final user = User.fromJson({
        'name': 'alice',
        'domainsIds': {'d1': '', 'd2': ''},
      });
      expect(user.domainsIds, ['d1', 'd2']);
    });

    test('fromJson handles missing fields', () {
      final user = User.fromJson({'name': 'bob'});
      expect(user.name, 'bob');
      expect(user.domainsIds, isEmpty);
      expect(user.registryId, '');
      expect(user.avatarUrl, '');
    });

    test('toJson roundtrip', () {
      final user = User(id: 'u1', name: 'alice', firstName: 'A', lastName: 'B');
      final restored = User.fromJson(user.toJson());
      expect(restored, user);
      expect(restored.firstName, 'A');
    });

    test('link to Domain adds to domainsIds', () {
      final user = User(name: 'u');
      final domain = Domain(originatorId: 'u');
      user.link(to: domain);
      expect(user.domainsIds, [domain.id]);
      // base link is not called for Domain
      expect(user.children.containsKey(domain.id), isFalse);
    });

    test('link to non-Domain uses base behavior', () {
      final user = User(name: 'u');
      final task = Task(originatorId: 'u');
      user.link(to: task);
      expect(user.children[task.id], 'Task');
      expect(user.domainsIds, isEmpty);
    });

    test('unlink from Domain removes from domainsIds', () {
      final user = User(name: 'u');
      final domain = Domain(originatorId: 'u');
      user.link(to: domain);
      expect(user.domainsIds, [domain.id]);
      user.unlink(from: domain);
      expect(user.domainsIds, isEmpty);
    });

    test('unlink from non-Domain uses base behavior', () {
      final user = User(name: 'u');
      final task = Task(originatorId: 'u');
      user.link(to: task);
      user.unlink(to: task);
      expect(user.children.containsKey(task.id), isFalse);
    });

    test('copyWith updates fields', () {
      final user = User(id: 'u1', name: 'alice');
      final updated =
          user.copyWith(name: 'bob', firstName: 'B', domainsIds: ['d9']);
      expect(updated.id, 'u1');
      expect(updated.name, 'bob');
      expect(updated.firstName, 'B');
      expect(updated.domainsIds, ['d9']);
      expect(updated.registryId, user.registryId);
    });

    test('propsList returns editable flags', () {
      final user = User(name: 'alice');
      final props = user.propsList();
      expect(props.length, 6);
      expect(props[0]['propId'], 'id');
      expect(props[0]['isEditable'], false);
      for (final p in props.skip(1)) {
        expect(p['isEditable'], true);
      }
      expect(
          props.map((p) => p['propId']),
          containsAll(
              ['name', 'avatarUrl', 'firstName', 'lastName', 'description']));
    });

    test('copyWithList updates provided props', () {
      final user = User(
          id: 'u1',
          name: 'alice',
          firstName: 'A',
          lastName: 'B',
          description: 'd',
          avatarUrl: 'url');
      final updated = user.copyWithList([
        {'propId': 'name', 'value': 'bob'},
        {'propId': 'firstName', 'value': 'F'},
        {'propId': 'lastName', 'value': 'L'},
        {'propId': 'description', 'value': 'new desc'},
        {'propId': 'avatarUrl', 'value': 'newurl'},
      ]);
      expect(updated.name, 'bob');
      expect(updated.firstName, 'F');
      expect(updated.lastName, 'L');
      expect(updated.description, 'new desc');
      expect(updated.avatarUrl, 'newurl');
      expect(updated.id, 'u1');
    });

    test('copyWithList with empty list keeps values', () {
      final user = User(id: 'u1', name: 'alice', firstName: 'A');
      final updated = user.copyWithList([]);
      expect(updated.name, 'alice');
      expect(updated.firstName, 'A');
    });

    test('copyWithList with unknown propId ignores it', () {
      final user = User(id: 'u1', name: 'alice');
      final updated = user.copyWithList([
        {'propId': 'unknown', 'value': 'x'},
      ]);
      expect(updated.name, 'alice');
    });

    test('equatable includes name, domainsIds, registryId', () {
      final a = User(id: 'u1', name: 'alice');
      final b = User(id: 'u1', name: 'alice');
      final c = User(id: 'u1', name: 'bob');
      final d = User(id: 'u1', name: 'alice', registryId: 'r2');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });
  });

  group('Domain', () {
    test('constructor defaults', () {
      final domain = Domain(originatorId: 'u1');
      expect(domain.isPersonal, false);
      expect(domain.originatorId, 'u1');
      expect(domain.participantsIds, isEmpty);
      expect(domain.observersIds, isEmpty);
      expect(domain.registryId, '');
      expect(domain.models, isEmpty);
      expect(domain.type, 'Domain');
    });

    test('fromJson restores domain fields', () {
      final domain = Domain.fromJson({
        'id': 'd1',
        'title': 'D',
        'isPersonal': true,
        'originatorId': 'u1',
        'registryId': 'r1',
        'participantsIds': ['u1'],
        'observersIds': ['u2'],
        'models': {'t1': 'Task'},
      });
      expect(domain.id, 'd1');
      expect(domain.title, 'D');
      expect(domain.isPersonal, true);
      expect(domain.originatorId, 'u1');
      expect(domain.registryId, 'r1');
      expect(domain.participantsIds, ['u1']);
      expect(domain.observersIds, ['u2']);
      expect(domain.models, {'t1': 'Task'});
    });

    test('fromJson reads isPersonal from isCompleted key', () {
      // Domain.fromJson reads 'isCompleted' (existing behavior)
      final domain = Domain.fromJson({'isCompleted': true});
      expect(domain.isPersonal, true);
    });

    test('fromJson handles missing fields', () {
      final domain = Domain.fromJson({});
      expect(domain.isPersonal, false);
      expect(domain.originatorId, '');
      expect(domain.participantsIds, isEmpty);
      expect(domain.observersIds, isEmpty);
      expect(domain.models, isEmpty);
    });

    test('toJson roundtrip', () {
      final domain =
          Domain(id: 'd1', title: 'D', originatorId: 'u1', isPersonal: true);
      final restored = Domain.fromJson(domain.toJson());
      expect(restored.id, 'd1');
      expect(restored.title, 'D');
      expect(restored.isPersonal, true);
    });

    test('copyWith updates fields', () {
      final domain = Domain(id: 'd1', title: 'D', originatorId: 'u1');
      final updated = domain
          .copyWith(title: 'New', isPersonal: true, participantsIds: ['u9']);
      expect(updated.id, 'd1');
      expect(updated.title, 'New');
      expect(updated.isPersonal, true);
      expect(updated.participantsIds, ['u9']);
      expect(updated.originatorId, 'u1');
    });

    test('equatable includes domain fields', () {
      final a = Domain(id: 'd1', originatorId: 'u1');
      final b = Domain(id: 'd1', originatorId: 'u1');
      final c = Domain(id: 'd1', originatorId: 'u1', isPersonal: true);
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('Transaction', () {
    late DateTime ts;
    setUp(() {
      ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);
    });

    test('main constructor with explicit id', () {
      final t = Transaction('id1', 'ph', 'pid', ts, 'orig', 'details',
          'creation', ['m1'], 'path');
      expect(t.id, 'id1');
      expect(t.prevHash, 'ph');
      expect(t.prevId, 'pid');
      expect(t.timeStamp, ts);
      expect(t.originatorId, 'orig');
      expect(t.changeDetails, 'details');
      expect(t.changeType, 'creation');
      expect(t.changes, ['m1']);
      expect(t.path, 'path');
    });

    test('main constructor generates id when null', () {
      final t = Transaction(null, '', '', ts, 'o', 'd', 'c', [], 'p');
      expect(t.id, isNotEmpty);
    });

    test('Transaction.zero', () {
      final t = Transaction.zero('o', 'd', 'c', ['m1'], 'p');
      expect(t.id, isNotEmpty);
      expect(t.prevHash, '');
      expect(t.prevId, '');
      expect(t.timeStamp, isA<DateTime>());
    });

    test('Transaction.fromPrev links to previous', () {
      final t0 = Transaction.zero('o', 'd', 'c', ['m1'], 'p');
      final t1 = Transaction.fromPrev(t0, 'o2', 'd2', 'c2', ['m2'], 'p2');
      expect(t1.prevId, t0.id);
      expect(t1.prevHash, t0.tHash());
      expect(t1.id, isNot(t0.id));
    });

    test('toJson includes all fields', () {
      final t = Transaction('id1', 'ph', 'pid', ts, 'orig', 'details',
          'creation', ['m1'], 'path');
      final json = t.toJson();
      expect(json['id'], 'id1');
      expect(json['prevHash'], 'ph');
      expect(json['prevId'], 'pid');
      expect(json['timeStamp'], ts.toIso8601String());
      expect(json['originatorId'], 'orig');
      expect(json['changeDetails'], 'details');
      expect(json['changeType'], 'creation');
      expect(json['changes'], ['m1']);
      expect(json['path'], 'path');
    });

    test('fromJson restores transaction', () {
      final t = Transaction('id1', 'ph', 'pid', ts, 'orig', 'details',
          'creation', ['m1'], 'path');
      final restored = Transaction.fromJson(t.toJson());
      expect(restored.id, 'id1');
      expect(restored.prevHash, 'ph');
      expect(restored.prevId, 'pid');
      expect(restored.timeStamp, ts);
      expect(restored.changes, ['m1']);
    });

    test('tHash is stable and differs for different content', () {
      final t1 = Transaction('id1', 'ph', 'pid', ts, 'orig', 'details',
          'creation', ['m1'], 'path');
      final t2 = Transaction('id1', 'ph', 'pid', ts, 'orig', 'details',
          'creation', ['m1'], 'path');
      final t3 = Transaction('id1', 'ph', 'pid', ts, 'orig', 'details',
          'creation', ['m2'], 'path');
      expect(t1.tHash(), t2.tHash());
      expect(t1.tHash(), isNot(t3.tHash()));
      expect(t1.tHash().length, 64);
    });

    test('next creates chained transaction', () {
      final t0 = Transaction.zero('o', 'd', 'c', ['m1'], 'p');
      final t1 = t0.next('o2', 'd2', 'c2', ['m2'], 'p2');
      expect(t1.prevId, t0.id);
      expect(t1.prevHash, t0.tHash());
    });

    test('Transaction.next with null prev', () {
      final t = Transaction.next(null, 'o', 'd', 'c', ['m1'], 'p');
      expect(t.prevId, '');
      expect(t.prevHash, '');
    });

    test('copyWith updates fields', () {
      final t = Transaction('id1', 'ph', 'pid', ts, 'orig', 'details',
          'creation', ['m1'], 'path');
      final updated = t.copyWith(changeType: 'deletion', changes: ['m2']);
      expect(updated.id, 'id1');
      expect(updated.changeType, 'deletion');
      expect(updated.changes, ['m2']);
      expect(updated.prevHash, 'ph');
    });

    test('equatable: same fields equal', () {
      final t1 = Transaction('id1', 'ph', 'pid', ts, 'orig', 'details',
          'creation', ['m1'], 'path');
      final t2 = Transaction('id2', 'ph', 'pid', ts, 'orig', 'details',
          'creation', ['m1'], 'path');
      // id is not part of props
      expect(t1, equals(t2));
      final t3 = Transaction('id1', 'other', 'pid', ts, 'orig', 'details',
          'creation', ['m1'], 'path');
      expect(t1, isNot(equals(t3)));
    });
  });

  group('RegistryMetadata', () {
    test('constructor and toJson', () {
      final m = RegistryMetadata(id: 'r1', parentId: 'p1');
      expect(m.id, 'r1');
      expect(m.parentId, 'p1');
      expect(m.toJson(), {'id': 'r1', 'parentId': 'p1'});
    });

    test('fromJson restores metadata', () {
      final m = RegistryMetadata.fromJson({'id': 'r1', 'parentId': 'p1'});
      expect(m.id, 'r1');
      expect(m.parentId, 'p1');
    });

    test('equatable', () {
      final a = RegistryMetadata(id: 'r1', parentId: 'p1');
      final b = RegistryMetadata(id: 'r1', parentId: 'p1');
      final c = RegistryMetadata(id: 'r2', parentId: 'p1');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('Registry', () {
    test('constructor generates id and empty transactions', () {
      final r = Registry(parentId: 'p1');
      expect(r.id, isNotEmpty);
      expect(r.parentId, 'p1');
      expect(r.transactions, isEmpty);
      expect(r.metadata.parentId, 'p1');
    });

    test('constructor asserts on empty id', () {
      expect(() => Registry(id: ''), throwsA(isA<AssertionError>()));
    });

    test('constructor with provided id and transactions', () {
      final t = Transaction.zero('o', 'd', 'c', ['m1'], 'p');
      final r = Registry(id: 'r1', parentId: 'p1', transactions: {0: t});
      expect(r.id, 'r1');
      expect(r.transactions.length, 1);
    });

    test('fromMaps restores registry', () {
      final t = Transaction('id1', 'ph', 'pid', DateTime.now(), 'orig',
          'details', 'creation', ['m1'], 'path');
      final r = Registry(id: 'r1', parentId: 'p1', transactions: {0: t});
      final restored = Registry.fromMaps(
          metadata: r.metadata.toJson(), transactions: {0: t.toJson()});
      expect(restored.id, 'r1');
      expect(restored.transactions.length, 1);
      expect(restored.transactions[0]!.id, 'id1');
    });

    test('toJson/fromJson roundtrip', () {
      final t = Transaction('id1', 'ph', 'pid', DateTime.now(), 'orig',
          'details', 'creation', ['m1'], 'path');
      final r = Registry(id: 'r1', parentId: 'p1', transactions: {0: t});
      final restored = Registry.fromJson(r.toJson());
      expect(restored.id, 'r1');
      expect(restored.parentId, 'p1');
      expect(restored.transactions.length, 1);
      expect(restored.transactions[0]!.id, 'id1');
    });

    test('lastTransaction and lastTransactionIndex', () {
      final t0 = Transaction.zero('o', 'd', 'c', ['m1'], 'p');
      final r = Registry(id: 'r1', parentId: 'p1', transactions: {0: t0});
      expect(r.lastTransactionIndex, 0);
      expect(r.lastTransaction, t0);
      final t1 = Transaction.fromPrev(t0, 'o', 'd', 'c', ['m2'], 'p');
      r.addNewTransaction(t1);
      expect(r.lastTransactionIndex, 1);
      expect(r.lastTransaction, t1);
    });

    test('lastTransaction on empty registry is null', () {
      final r = Registry(parentId: 'p1');
      expect(r.lastTransaction, isNull);
      expect(r.lastTransactionIndex, isNull);
    });

    test('addNewTransaction appends with incrementing index', () {
      final r = Registry(id: 'r1', parentId: 'p1');
      final t1 = Transaction.zero('o', 'd', 'c', ['m1'], 'p');
      final added1 = r.addNewTransaction(t1);
      expect(added1, same(t1));
      expect(r.transactions[0], same(t1));
      final t2 = Transaction.zero('o', 'd', 'c', ['m2'], 'p');
      r.addNewTransaction(t2);
      expect(r.transactions[1], same(t2));
    });

    test('removeLastTransaction removes head', () {
      final r = Registry(id: 'r1', parentId: 'p1');
      r.addNewTransaction(Transaction.zero('o', 'd', 'c', ['m1'], 'p'));
      r.addNewTransaction(Transaction.zero('o', 'd', 'c', ['m2'], 'p'));
      expect(r.transactions.length, 2);
      r.removeLastTransaction();
      expect(r.transactions.length, 1);
      expect(r.lastTransactionIndex, 0);
      r.removeLastTransaction();
      expect(r.transactions, isEmpty);
      // removing from empty is safe
      r.removeLastTransaction();
      expect(r.transactions, isEmpty);
    });

    test('onlyLastTransaction keeps only head for non-empty', () {
      final r = Registry(id: 'r1', parentId: 'p1');
      r.addNewTransaction(Transaction.zero('o', 'd', 'c', ['m1'], 'p'));
      r.addNewTransaction(Transaction.zero('o', 'd', 'c', ['m2'], 'p'));
      final only = r.onlyLastTransaction();
      expect(only.transactions.length, 1);
      expect(only.lastTransactionIndex, 1);
    });

    test('onlyLastTransaction returns same for empty', () {
      final r = Registry(parentId: 'p1');
      expect(r.onlyLastTransaction(), same(r));
    });

    test('copyWith keeps values when no args', () {
      final t = Transaction.zero('o', 'd', 'c', ['m1'], 'p');
      final r = Registry(id: 'r1', parentId: 'p1', transactions: {0: t});
      final copy = r.copyWith();
      expect(copy.id, 'r1');
      expect(copy.parentId, 'p1');
      expect(copy.transactions.length, 1);
    });

    test('copyWith replaces id and parentId', () {
      final r = Registry(id: 'r1', parentId: 'p1');
      final copy = r.copyWith(id: 'r2', parentId: 'p2');
      expect(copy.id, 'r2');
      expect(copy.parentId, 'p2');
    });

    test('copyWith copies transactions when not replaced', () {
      final t = Transaction(
          'id1', '', '', DateTime.now(), 'o', 'd', 'creation', ['m1'], 'p');
      final r = Registry(id: 'r1', parentId: 'p1', transactions: {0: t});
      final copy = r.copyWith();
      copy.transactions[0]!.changeType = 'modified';
      // deep copy: original unchanged
      expect(r.transactions[0]!.changeType, 'creation');
    });

    test('equatable', () {
      final t = Transaction.zero('o', 'd', 'c', ['m1'], 'p');
      final a = Registry(id: 'r1', parentId: 'p1', transactions: {0: t});
      final b = Registry(id: 'r1', parentId: 'p1', transactions: {0: t});
      final c = Registry(id: 'r2', parentId: 'p1', transactions: {0: t});
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('TaskList', () {
    test('links tasks as parents and removes the link', () {
      final list = TaskList(id: 'list-1', title: 'Work');
      final task = Task(id: 'task-1', originatorId: 'u1');

      list.addTask(task);
      expect(list.tasks, {'task-1': 'Task'});
      expect(task.parents[list.id], 'TaskList');

      list.removeTask(task);
      expect(list.tasks, isEmpty);
      expect(task.parents, isEmpty);
    });

    test('orders tasks using each persisted view mode', () {
      final created = DateTime(2024, 1, 1);
      final done = Task(
        id: 'done',
        title: 'done',
        originatorId: 'u',
        createdAt: created.add(const Duration(minutes: 2)),
        completedAt: created.add(const Duration(minutes: 5)),
        isCompleted: true,
      );
      final active = Task(
        id: 'active',
        title: 'active',
        originatorId: 'u',
        createdAt: created.add(const Duration(minutes: 1)),
        dueAt: created.add(const Duration(minutes: 10)),
      );
      final list = TaskList(id: 'list-1', tasks: {
        done.id: done.type,
        active.id: active.type,
      });

      expect(list.order([done, active]).map((task) => task.id),
          ['active', 'done']);
      expect(
          list
              .copyWith(viewMode: TaskListViewMode.activeOnly)
              .order([done, active]).map((task) => task.id),
          ['active']);
      expect(
          list
              .copyWith(viewMode: TaskListViewMode.dueTime)
              .order([done, active]).map((task) => task.id),
          ['active', 'done']);
    });

    test('round trips settings and task membership', () {
      final list = TaskList(
        id: 'list-1',
        title: 'Work',
        viewMode: TaskListViewMode.activeFirst,
        tasks: {'task-1': 'Task'},
      );
      final restored = TaskList.fromJson(list.toJson());
      expect(restored, list);
      expect(restored.viewMode, TaskListViewMode.activeFirst);
      expect(restored.tasks, {'task-1': 'Task'});
    });
  });

  group('Model linkTo/linkFrom/unlinkFrom with Repository', () {
    test('linkTo saves both models via Repository.instance', () async {
      final local = _RecordingLocalStorage();
      final repo = Repository(localStorage: local, remoteStorages: {});
      Repository.instance = repo;
      await repo.init();
      final user = User(id: 'me', name: 'me');
      repo.me = user;
      final domain = Domain(originatorId: user.id);
      final result = await user.linkTo(domain);
      expect(result, same(user));
      expect(local.storedModels[user.id], isNotNull);
      expect(local.storedModels[domain.id], isNotNull);
    });

    test('linkFrom links both directions', () async {
      final local = _RecordingLocalStorage();
      final repo = Repository(localStorage: local, remoteStorages: {});
      Repository.instance = repo;
      await repo.init();
      final user = User(id: 'me', name: 'me');
      repo.me = user;
      final domain = Domain(originatorId: user.id);
      final result = await domain.linkFrom(user);
      expect(result, same(domain));
      // linkFrom: this gets parent; from.link(to: Domain) adds to domainsIds (User override)
      expect(domain.parents[user.id], 'User');
      expect(user.domainsIds, [domain.id]);
      expect(local.storedModels[domain.id], isNotNull);
      expect(local.storedModels[user.id], isNotNull);
    });

    test('unlinkFrom unlinks and queues delete', () async {
      final local = _RecordingLocalStorage();
      final repo = Repository(localStorage: local, remoteStorages: {});
      Repository.instance = repo;
      await repo.init();
      final user = User(id: 'me', name: 'me');
      repo.me = user;
      final domain = Domain(originatorId: user.id);
      await user.linkTo(domain);
      expect(user.domainsIds, [domain.id]);
      final result = await user.unlinkFrom(domain);
      expect(result, same(user));
      // unlinkFrom removes both directions
      expect(user.domainsIds, isEmpty);
      expect(repo.outgoingDeletes, isNotEmpty);
      expect(repo.outgoingDeletes.first.id, domain.id);
    });
  });
}

class _RecordingLocalStorage extends LocalStorage {
  final Map<String, dynamic> storedModels = {};
  final List<String> deletedIds = [];
  String? userId;

  @override
  Uint8List? getImage(String id) => null;

  @override
  String? getUserId() => userId;

  @override
  Future<void> setUserId(String userId) async {
    this.userId = userId;
  }

  @override
  dynamic getItem({required String id}) => storedModels[id];

  @override
  Map<String, T> getItems<T>(List<String> ids) {
    final result = <String, T>{};
    for (final id in ids) {
      final item = storedModels[id];
      if (item != null) result[id] = item as T;
    }
    return result;
  }

  @override
  Future<void> storeItem(dynamic item) async {
    storedModels[item.id as String] = item;
  }

  @override
  Future<int> storeItems(Map<String, dynamic> items) async {
    storedModels.addAll(items);
    return items.length;
  }

  @override
  Future<void> deleteItem(String id) async {
    storedModels.remove(id);
    deletedIds.add(id);
  }
}
