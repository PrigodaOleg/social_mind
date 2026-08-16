import 'dart:io';

import 'package:closers/local_storage/isar/isar_storage.dart';
import 'package:closers/repository/models/models.dart';
import 'package:closers/repository/navigation/navigation_stack.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_plus/isar_plus.dart';

void main() async {

  late final IsarStorage storage;
  
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        // Intercept the specific method call
        if (methodCall.method == 'getApplicationDocumentsDirectory') {
          return '.'; // Return a mock path string
        }
        return null;
      },
    );
    
    // https://github.com/ahmtydn/isar_plus/releases?q=1.2.6&expanded=true
    if (Platform.isWindows) await Isar.initialize('test/isar_windows_x64.dll');
    if (Platform.isLinux) await Isar.initialize('test/libisar_linux_x64.so');
    storage = IsarStorage();
    await storage.init();
  });

  tearDownAll(() {
    storage.isar.close(deleteFromDisk: true); // Assuming you have a close method in your storage class
  });

  group('IsarStorage', () {

    test('Write and read userId', () async {
      storage.setUserId('test_id');
      final result = storage.getUserId();
      expect(result, 'test_id');
    });

    test('Write and read operational value', () async {
      storage.setOperational('test_key', 'test_value');
      final result = storage.getOperational('test_key');
      expect(result, 'test_value');
    });

    test('Write and read operational item', () async {
      final testItem = User(name: 'test_user');
      storage.storeOpItem('test_id', testItem);
      final result = storage.getOpItem('test_id');
      expect(result, testItem);
    });

    test('Write and read list to operational box', () async {
      final testOpItem = [
        NavStackEntry('test_nav_entry', {'test_arg': 'test_arg_value'})
      ];
      storage.storeOpItem('test_id', testOpItem);
      final result = storage.getOpItem('test_id');
      expect(result, testOpItem);
    });

    test('Write and read model item', () async {
      final testItem = User(name: 'test_user');
      await storage.storeItem(testItem);
      final result = await storage.getItem(id: testItem.id);
      expect(result, testItem);
    });

    test('Write and read multiple model items', () async {
      final testItem1 = User(name: 'test_user_1');
      final testItem2 = User(name: 'test_user_2');
      await storage.storeItem(testItem1);
      await storage.storeItem(testItem2);
      final result = storage.getItems([testItem1.id, testItem2.id]);
      expect(result.length, 2);
      expect(result[testItem1.id], testItem1);
      expect(result[testItem2.id], testItem2);
    });

    test('Write and read list of models', () async {
      final testItems = [
        User(name: 'test_user_1'),
        User(name: 'test_user_2')
      ];
      final testItemsMap = Map.fromEntries(testItems.map((item) => MapEntry(item.id, item)));
      final stored = await storage.storeItems(testItemsMap);
      expect(stored, testItemsMap.length);
      final result = storage.getItems(testItemsMap.keys.toList());
      expect(result, testItemsMap);
    });

    test('Write and delete model', () async {
      final testItem = User(name: 'test_user');
      await storage.storeItem(testItem);
      final read = await storage.getItem(id: testItem.id);
      expect(read, testItem);
      await storage.deleteItem(testItem.id);
      final result = await storage.getItem(id: testItem.id);
      expect(result, null);
    });

    test('Write multiple and read one model', () async {
      final testItems = [
        User(name: 'test_user_1'),
        Domain(originatorId: 'test_user_2'),
        User(name: 'test_user_3')
      ];
      final testItemsMap = Map.fromEntries(testItems.map((item) => MapEntry(item.id, item)));
      final stored = await storage.storeItems(testItemsMap);
      expect(stored, testItems.length);
      final getIds = testItemsMap.keys.toList().sublist(1, 2);
      final result = storage.getItems<Domain>(getIds);
      expect(result.length, 1);
      expect(result.values.toList()[0], testItemsMap[getIds[0]]);
    });

    test('Write and read nothing', () async {
      final testItem = User(name: 'test_user');
      await storage.storeItem(testItem);
      final result = storage.getItems([]);
      expect(result.length, 0);
    });

    test('Write, read, modify, write and read model item again', () async {
      final testItem = User(name: 'test_user');
      await storage.storeItem(testItem);
      var result = await storage.getItem(id: testItem.id);
      expect(result, testItem);
      testItem.domainsIds.add("test_domain_id");
      await storage.storeItem(testItem);
      result = await storage.getItem(id: testItem.id);
      expect(result, testItem);
    });

    test('Write item with registry', () async {
      final testItems = {
        'test_user_id': User(name: 'test_user_1'),
        'test_user_registry_id': Registry(
          id: 'test_user_registry_id',
          parentId: 'test_user_id',
          transactions: {
            0: Transaction.zero(
              'test_originator_id',
              'test_change_details',
              'test_change_type',
              <String>['test_change'],
              'test_path'
            )
          }
        )
      };
      final stored = await storage.storeItems(testItems);
      expect(stored, testItems.length);
      final result = storage.getRegistry(parentId: 'test_user_id');
      // final result = storage.getRegistry(id: 'test_user_registry_id');
      expect(result?.metadata, (testItems['test_user_registry_id'] as Registry).metadata);
      expect(result?.transactions, (testItems['test_user_registry_id'] as Registry).transactions);
    });

    test('Write and read many transactions', () async {
      var registry = Registry(
        id: 'test_user_registry_id',
        parentId: 'test_parent_id',
        transactions: {
          0: Transaction.zero(
            'test_originator_id',
            'test_change_details',
            'test_change_type',
            <String>['test_first_change'],
            'test_path'
          )
        }
      );
      // First attempt
      var stored = await storage.storeItems({registry.id!: registry});
      expect(stored, 1);
      var readRegistry = storage.getRegistry(parentId: 'test_parent_id', count: 1);
      expect(readRegistry, registry);
      expect(readRegistry?.transactions.length, 1);
      expect(readRegistry?.lastTransaction, registry.lastTransaction);
      expect(readRegistry?.lastTransaction!.changes[0], 'test_first_change');

      // Second attempt
      registry = readRegistry!;
      var newIndex = registry.transactions.keys.last + 1;
      registry.addNewTransaction(Transaction.next(
        registry.lastTransaction,
        'test_originator_id',
        'test_change_details',
        'test_change_type',
        <String>['test_second_change'],
        'test_path'
      ));
      stored = await storage.storeItems({registry.id!: registry});
      expect(stored, 2);
      readRegistry = storage.getRegistry(parentId: 'test_parent_id', count: 1);
      // expect(readRegistry, registry);
      expect(readRegistry?.transactions.length, 1);
      expect(readRegistry?.lastTransaction, registry.lastTransaction);
      expect(readRegistry?.lastTransaction!.changes[0], 'test_second_change');

      // Third attempt
      registry = readRegistry!;
      newIndex = registry.transactions.keys.last + 1;
      registry.addNewTransaction(Transaction.next(
        registry.lastTransaction,
        'test_originator_id',
        'test_change_details',
        'test_change_type',
        <String>['test_third_change'],
        'test_path'
      ));
      stored = await storage.storeItems({registry.id!: registry});
      expect(stored, 2);
      readRegistry = storage.getRegistry(parentId: 'test_parent_id', count: 1);
      // expect(readRegistry, registry);
      expect(readRegistry?.transactions.length, 1);
      expect(readRegistry?.lastTransaction, registry.lastTransaction);
      expect(readRegistry?.lastTransaction!.changes[0], 'test_third_change');
    });

    test('Check history of one item', () async {
      storage.clearHistoryQueueHead();
      // Сперва просто пишем и читаем с проверкой истории
      final testItem0 = User(name: 'test_user');
      await storage.storeItem(testItem0);
      final result0 = storage.getItem(id: testItem0.id);
      expect(result0, testItem0);
      final historicalResult0 = storage.getNextItemsFromHistoryQueue();
      expect(historicalResult0.length, 1);
      expect(historicalResult0[testItem0.id], testItem0);

      // Потом меняем объект, и также проверяем историю, она должна сохраниться с первого раза
      final testItem1 = User.fromJson(testItem0.toJson())..registryId = 'changed_test_user_1';
      await storage.storeItem(testItem1);
      final result1 = storage.getItem(id: testItem0.id);
      expect(result1, testItem1);
      final historicalResult1 = storage.getNextItemsFromHistoryQueue();
      expect(historicalResult1.length, 1);
      expect(historicalResult1[testItem0.id], testItem0);
      storage.clearHistoryQueueHead();

      // Потом меняем 2 раза, а история должна сохраниться от первого, потом от третьего
      final testItem2 = User.fromJson(testItem0.toJson())..registryId = 'changed_test_user_2';
      await storage.storeItem(testItem2);
      final result2 = storage.getItem(id: testItem0.id);
      expect(result2, testItem2);
      final testItem3 = User.fromJson(testItem0.toJson())..registryId = 'changed_test_user_3';
      await storage.storeItem(testItem3);
      final result3 = storage.getItem(id: testItem0.id);
      expect(result3, testItem3);
      final historicalResult2 = storage.getNextItemsFromHistoryQueue();
      expect(historicalResult2.length, 1);
      expect(historicalResult2[testItem0.id], testItem1);
      storage.clearHistoryQueueHead();
      final historicalResult3 = storage.getNextItemsFromHistoryQueue();
      expect(historicalResult3.length, 1);
      expect(historicalResult3[testItem0.id], testItem3); // Тут должен быть последний
      storage.clearHistoryQueueHead();
    });

    test('Check history of many items', () async {
      storage.clearHistoryQueueHead();
      // Сперва просто пишем и читаем с проверкой истории
      final testItem0 = User(name: 'test_user');
      await storage.storeItems({testItem0.id: testItem0});
      final result0 = storage.getItems([testItem0.id]);
      expect(result0.length, 1);
      expect(result0[testItem0.id], testItem0);
      final historicalResult0 = storage.getNextItemsFromHistoryQueue();
      expect(historicalResult0.length, 1);
      expect(historicalResult0[testItem0.id], testItem0);

      // Потом меняем объект, и также проверяем историю, она должна сохраниться с первого раза
      final testItem1 = User.fromJson(testItem0.toJson())..registryId = 'changed_test_user_1';
      await storage.storeItems({testItem1.id: testItem1});
      final result1 = storage.getItems([testItem0.id]);
      expect(result1[testItem0.id], testItem1);
      final historicalResult1 = storage.getNextItemsFromHistoryQueue();
      expect(historicalResult1.length, 1);
      expect(historicalResult1[testItem0.id], testItem0);
      storage.clearHistoryQueueHead();

      // // Потом меняем 2 раза, а история должна сохраниться от первого, потом от третьего
      final testItem2 = User.fromJson(testItem0.toJson())..registryId = 'changed_test_user_2';
      await storage.storeItems({testItem2.id: testItem2});
      final result2 = storage.getItems([testItem0.id]);
      expect(result2[testItem0.id], testItem2);
      final testItem3 = User.fromJson(testItem0.toJson())..registryId = 'changed_test_user_3';
      await storage.storeItems({testItem3.id: testItem3});
      final result3 = storage.getItems([testItem0.id]);
      expect(result3[testItem0.id], testItem3);
      final historicalResult2 = storage.getNextItemsFromHistoryQueue();
      expect(historicalResult2.length, 1);
      expect(historicalResult2[testItem0.id], testItem1);
      storage.clearHistoryQueueHead();
      final historicalResult3 = storage.getNextItemsFromHistoryQueue();
      expect(historicalResult3.length, 1);
      expect(historicalResult3[testItem0.id], testItem3); // Тут должен быть последний
      storage.clearHistoryQueueHead();
    });

  });
}