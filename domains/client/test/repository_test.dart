import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';
import 'package:closers/repository/repository.dart';
import 'package:flutter_test/flutter_test.dart';

class MockLocalStorage extends LocalStorage {
  Map<String, Model> lastModels = {};
  Map<String, Registry> lastRegistries = {};
  Map<String, dynamic> get lastItems => {...lastModels, ...lastRegistries};
  Map<String, Model> oldModels = {};

  @override
  Future<int> storeItems(Map<String, dynamic> items) async {
    for (final item in items.values) {
      if (item is Model) {
        if (lastModels.containsKey(item.id)) {
          oldModels[item.id] = models[item.type]!(lastModels[item.id]!.toJson());
        }
        lastModels[item.id] = item;
      }
      if (item is Registry) {
        if (lastRegistries.containsKey(item.id)) {
          lastRegistries[item.id!]?.transactions.addAll(item.transactions);
        } else {
          lastRegistries[item.id!] = item;
        }
      }
    }
    return items.length;
  }

  @override
  String? getUserId() {
    return 'me';
  }

  @override
  dynamic getItem({required String id}) {
    if (id == 'me') return User(id: 'me', name: 'me');
  }

  @override
  Registry? getRegistry({String? id, String? parentId, int count = 5}) {
    if (id != null) return lastRegistries[id];
    if (parentId != null) return lastRegistries[(lastModels[parentId] as User?)?.registryId];
    return null;
  }

  Map<String, dynamic> getNextItemsFromHistoryQueue() {
    return oldModels..clear();
  }
}

class MockRemoteStorage extends RemoteStorage {
  Map<String, Model> lastModels = {};
  Map<String, Registry> lastRegistries = {};
  Map<String, dynamic> get lastItems => {...lastModels, ...lastRegistries};
  @override
  Future<int> saveItems(Map<String, dynamic> items) async {
    for (final item in items.values.toList().reversed) {
      if (item is Registry) {
        if ((item.lastTransactionIndex ?? -1) <= (lastRegistries[item.id]?.lastTransactionIndex ?? -1)) {
          throw RemoteStorageWriteCollision('message', -1);
        }
        if (lastRegistries.containsKey(item.id)) {
          lastRegistries[item.id!]?.transactions.addAll(item.transactions);
        } else {
          lastRegistries[item.id!] = item.copyWith();
        }
      }
      if (item is Model) lastModels[item.id] = models[item.type]!(item.toJson()); // ignore: avoid-async-in-sync-methods
    }
    return items.length;
  }

  @override
  Future<Map<String, Registry>> readRegistries({List<String>? ids, List<(String id, int? count)>? idsCounts, int count = 1}) async {
    if (ids != null) return Map.fromEntries(lastRegistries.entries.where((e) => ids.contains(e.key)).map((e) => MapEntry(e.key, e.value.copyWith())));
    if (idsCounts != null) return Map.fromEntries(idsCounts.map((rec) => MapEntry(lastRegistries[rec.$1]!.id!, lastRegistries[rec.$1]!.copyWith())));
    return {};
  }

  @override
  Future<Map<String, Model>> getItems(List ids) async {
    return Map.fromEntries(lastModels.entries.where((e) => ids.contains(e.key)).map((e) => MapEntry(e.key, models[e.value.type]!(e.value.toJson()))));
  }
}

void main() {
  group('Repository', () {
    test('syncWithRemoteStorage simple', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      final user = User(name: 'test_user');
      await r.syncWithRemoteStorage({user.id: user});
      expect(localStorage.lastItems.length, 2);
      expect(localStorage.lastRegistries[user.registryId]?.lastTransaction?.changes.contains(user.id), true);
      expect(remoteStorage.lastItems.length, 2);
      expect(remoteStorage.lastRegistries[user.registryId]?.lastTransaction?.changes.contains(user.id), true);
    });

    test('syncWithRemoteStorage re-simple', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      final user = User(name: 'test_user');
      await r.syncWithRemoteStorage({user.id: user});
      expect(localStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 0);
      expect(remoteStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 0);
      await r.syncWithRemoteStorage({user.id: user});
      expect(localStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 1);
      expect(remoteStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 1);
    });

    test('syncWithRemoteStorage collision', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      final user = User(name: 'test_user');
      await r.syncWithRemoteStorage({user.id: user});
      remoteStorage.lastRegistries.values.last.addNewTransaction(
        Transaction.next(
          remoteStorage.lastRegistries.values.last.lastTransaction,
          user.id,
          'changeDetails',
          'changeType',
          [user.id],
          'path'
        )
      );
      expect(localStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 0);
      expect(remoteStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 1);
      await r.syncWithRemoteStorage({user.id: user});
      expect(localStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 2);
      expect(remoteStorage.lastRegistries[user.registryId]?.lastTransactionIndex, 2);
    });

    test('syncWithRemoteStorage no changes', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      await r.syncWithRemoteStorage({});
      expect(localStorage.lastRegistries.length, 0);
      expect(remoteStorage.lastRegistries.length, 0);
    });

    test('syncWithRemoteStorage rebase', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      var user = User(name: 'test_user', domainsIds: ['domain1']);
      await r.syncWithRemoteStorage({user.id: user});
      user = user.copyWith(name: 'test_user_2', domainsIds: [...user.domainsIds, 'domain2']);
      remoteStorage.lastRegistries.values.last.addNewTransaction(
        Transaction.next(
          remoteStorage.lastRegistries.values.last.lastTransaction,
          user.id,
          'changeDetails',
          'changeType',
          [user.id],
          'path'
        )
      );
      remoteStorage.saveItems({user.id: user});
      user = user.copyWith(domainsIds: ['domain3']);
      await r.syncWithRemoteStorage({user.id: user});
      expect((remoteStorage.lastModels[user.id] as User?)?.name, 'test_user_2');
      expect((remoteStorage.lastModels[user.id] as User?)?.domainsIds.contains('domain1'), true);
      expect((remoteStorage.lastModels[user.id] as User?)?.domainsIds.contains('domain2'), true);
      expect((remoteStorage.lastModels[user.id] as User?)?.domainsIds.contains('domain3'), true);
    });

    test('syncWithRemoteStorage rebase with conflict', () async {
      final localStorage = MockLocalStorage();
      final remoteStorage = MockRemoteStorage();
      final r = Repository(localStorage: localStorage, remoteStorages: {'rs': remoteStorage});
      User? localConflictUser;
      User? remoteConflictUser;
      final listenerId = r.addSyncListener(
        (id, syncedItem) => print(syncedItem),
        (localChanges, remoteChanges) {
          if (localChanges.isNotEmpty && remoteChanges.isNotEmpty) {
            localConflictUser = localChanges.values.first as User?;
            remoteConflictUser = remoteChanges.values.first as User?;
          }
        }
      );
      final user1 = User(name: 'test_user');
      r.subscribeToSync(user1.id, listenerId);
      await r.syncWithRemoteStorage({user1.id: user1});
      final user2 = user1.copyWith(name: 'test_user_2');
      remoteStorage.lastRegistries.values.last.addNewTransaction(
        Transaction.next(
          remoteStorage.lastRegistries.values.last.lastTransaction,
          user2.id,
          'changeDetails',
          'changeType',
          [user2.id],
          'path',
        )
      );
      remoteStorage.saveItems({user2.id: user2});
      final user3 = user1.copyWith(name: 'test_user_3');
      await r.syncWithRemoteStorage({user3.id: user3});
      expect((localStorage.lastModels[user1.id] as User?)?.name, 'test_user'); // the local changes have been cancelled
      expect((remoteStorage.lastModels[user1.id] as User?)?.name, 'test_user_2');
      expect(localConflictUser?.name, 'test_user_3');
      expect(remoteConflictUser?.name, 'test_user_2');
    });

  });
}
