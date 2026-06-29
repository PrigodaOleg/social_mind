import 'dart:io';

import 'package:closers/repository/navigation/navigation_stack.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

import 'package:isar_plus/isar_plus.dart';
import 'package:closers/repository/models/models.dart';

import 'package:closers/local_storage/isar/isar_storage.dart';

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

  });
}