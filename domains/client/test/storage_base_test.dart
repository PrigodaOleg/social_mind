
import 'dart:typed_data';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:closers/repository/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Concrete subclass exercising all default implementations of the abstract
/// [LocalStorage] API.
class BareLocalStorage extends LocalStorage {
  final Map<String, dynamic> store = {};
  final Map<String, Uint8List> images = {};

  @override
  String? getUserId() => store['userId'] as String?;

  @override
  Future<void> setUserId(String userId) async => store['userId'] = userId;

  @override
  String? getOperational(String key) => store['op:$key'] as String?;

  @override
  Future<void> setOperational(String key, String value) async =>
      store['op:$key'] = value;

  @override
  Uint8List? getImage(String id) => images[id];

  @override
  Future<void> storeImage(String id, Uint8List imageBytes) async =>
      images[id] = imageBytes;

  @override
  dynamic getOpItem(String id) => store['opitem:$id'];

  @override
  Future<void> storeOpItem(String id, dynamic item) async =>
      store['opitem:$id'] = item;

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
  Future<void> storeItem(dynamic item) async => store[item.id] = item;

  @override
  Future<void> deleteItem(String id) async => store.remove(id);

  @override
  Registry? getRegistry({String? id, String? parentId, int count = 5}) =>
      store[id] is Registry ? store[id] as Registry : null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocalStorage base defaults', () {
    test('init is a no-op that completes', () async {
      final storage = BareLocalStorage();
      await expectLater(storage.init(), completes);
    });

    test('setUserId/getUserId roundtrip', () async {
      final storage = BareLocalStorage();
      expect(storage.getUserId(), isNull);
      await storage.setUserId('u1');
      expect(storage.getUserId(), 'u1');
    });

    test('setOperational/getOperational roundtrip', () async {
      final storage = BareLocalStorage();
      expect(storage.getOperational('k'), isNull);
      await storage.setOperational('k', 'v');
      expect(storage.getOperational('k'), 'v');
    });

    test('storeImage/getImage roundtrip', () async {
      final storage = BareLocalStorage();
      final bytes = Uint8List.fromList([4, 5, 6]);
      expect(storage.getImage('img'), isNull);
      await storage.storeImage('img', bytes);
      expect(storage.getImage('img'), bytes);
    });

    test('storeOpItem/getOpItem roundtrip', () async {
      final storage = BareLocalStorage();
      expect(storage.getOpItem('x'), isNull);
      await storage.storeOpItem('x', {'a': 1});
      expect(storage.getOpItem('x'), {'a': 1});
    });

    test('default storeItems returns length', () async {
      final storage = BareLocalStorage();
      final n = await storage.storeItems({'a': 1, 'b': 2});
      expect(n, 2);
    });

    test('default getNextItemsFromHistoryQueue returns empty map', () {
      final storage = BareLocalStorage();
      expect(storage.getNextItemsFromHistoryQueue(), isEmpty);
    });

    test('default clearHistoryQueueHead is a no-op', () {
      final storage = BareLocalStorage();
      expect(storage.clearHistoryQueueHead, returnsNormally);
    });

    test('deleteItem removes stored item', () async {
      final storage = BareLocalStorage();
      final user = User(id: 'u1', name: 'n');
      await storage.storeItem(user);
      expect(storage.getItem(id: 'u1'), same(user));
      await storage.deleteItem('u1');
      expect(storage.getItem(id: 'u1'), isNull);
    });

    test('models factory map constructs models from json', () {
      final storage = BareLocalStorage();
      final user = storage.models['User']!({'id': 'u9', 'name': 'nn'}) as User;
      expect(user.id, 'u9');
      expect(user.name, 'nn');
      final domain = storage.models['Domain']!({'id': 'd9'}) as Domain;
      expect(domain.id, 'd9');
      final task = storage.models['Task']!({'id': 't9'}) as Task;
      expect(task.id, 't9');
    });

    test('getRegistry returns stored registry or null', () async {
      final storage = BareLocalStorage();
      expect(storage.getRegistry(id: 'r1'), isNull);
    });

    test('getItems filters by type', () async {
      final storage = BareLocalStorage();
      final u = User(id: 'u1', name: 'n');
      final d = Domain(id: 'd1', originatorId: 'u1');
      await storage.storeItem(u);
      await storage.storeItem(d);
      expect(storage.getItems<User>(['u1', 'd1']).keys, ['u1']);
      expect(storage.getItems<Domain>(['u1', 'd1']).keys, [d.id]);
    });
  });

  group('RemoteStorage base defaults', () {
    late BareRemoteStorage rs;

    setUp(() {
      rs = BareRemoteStorage();
    });

    test('init returns false by default', () async {
      expect(await rs.init('any'), isFalse);
    });

    test('createUserAndAuth and auth return false by default', () async {
      expect(await rs.createUserAndAuth('login', 'pass'), isFalse);
      expect(await rs.auth('login', 'pass'), isFalse);
    });

    test('getItem returns null by default', () async {
      expect(await rs.getItem(id: 'x'), isNull);
    });

    test('getItems returns empty map by default', () async {
      expect(await rs.getItems(['a', 'b']), isEmpty);
    });

    test('saveItems returns 0 by default', () async {
      expect(await rs.saveItems({}), 0);
    });

    test('deleteItems returns 0 by default', () async {
      expect(await rs.deleteItems({}), 0);
    });

    test('readRegistry returns null by default', () async {
      expect(await rs.readRegistry('r1'), isNull);
    });

    test('readRegistries returns empty map by default', () async {
      expect(await rs.readRegistries(ids: ['a']), isEmpty);
      expect(await rs.readRegistries(idsCounts: [('a', 1)]), isEmpty);
      expect(await rs.readRegistries(count: 3), isEmpty);
    });

    test('models factory map constructs models from json', () {
      final user = rs.models['User']!({'id': 'u1', 'name': 'n'}) as User;
      expect(user.name, 'n');
      final domain = rs.models['Domain']!({'id': 'd1'}) as Domain;
      expect(domain.id, 'd1');
      final task = rs.models['Task']!({'id': 't1'}) as Task;
      expect(task.id, 't1');
    });

    test('RemoteStorageWriteCollision formats message and status', () {
      final e = RemoteStorageWriteCollision('denied', 403);
      expect(e.message, 'denied');
      expect(e.statusCode, 403);
      expect(e.toString(), 'RemoteStorageWriteCollision (403): denied');
      expect(e, isA<Exception>());
    });
  });
}

/// Subclass exposing base [RemoteStorage] default behavior.
class BareRemoteStorage extends RemoteStorage {}

