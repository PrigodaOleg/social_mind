import 'dart:convert';
import 'package:closers/repository/navigation/navigation_stack.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'package:isar_plus/isar_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:closers/repository/models/models.dart';

import '../local_storage.dart';

part 'isar_storage.g.dart';


// Вроде как для Isar нужно насоздавать нексолько коллекций. Коллекции - аналог боксов в Hive.
// Нам потребуются коллекции для хранения:
// - моделей (с индексацией по родителям, по времени, а также, возможно, по доменам/пользователям)
// - транзакций (с индексацией по доменам/пользователям, по сути по родителям), а где хранить метаданные реестров (в отдельной коллекции)?
// - оперативыных данных (пользователей, истории навигации)
// - секретов (паролей, ключей и т.п. на время, пока пользователь не соизволил их прикопать где-то у себя или запомнить); пароли тут хранить нельзя...

@embedded
class ModelContainer {}

@collection
class ModelBox {
  // Мы хотим хранить в базе модели либо в бинарном виде (что быстро в рантайме),
  // либо сериализованные модели (что медленней в рантайме и закрывает доступ к поиску по полям модели).
  // Сейчас (25.06.2026) на скорую руку делаем сериализованный подход.
  // todo: переделать на бинарный режим

  late int id;
  @Index(unique: true, hash: true, name: 'byModelId')
  String? modelId;
  String? modelData; // serialized model
  ModelContainer? model; // binary
  String? rootParentId; // domain or used id
}

@collection
class OperationalBox {
  late int id;
  @Index(unique: true, name: 'byName')
  String? name;
  String? data;
}

class IsarStorage extends LocalStorage {
  IsarStorage();

  late Isar isar;

  @override
  Future<void> init() async {
    // open storage
    final String dir = kIsWeb 
      ? '' 
      // ? Isar.sqliteInMemory 
      : (await getApplicationDocumentsDirectory()).path;
    const IsarEngine engine = kIsWeb 
      ? IsarEngine.sqlite 
      : IsarEngine.isar;
    if (kIsWeb) await Isar.initialize();
    isar = Isar.open(
      schemas: [OperationalBoxSchema, ModelBoxSchema],
      directory: dir,
      engine: engine
    );
  }

  // todo: Нужно уменьшить количество интерфейсов для operational box
  String? getUserId() {
    return isar.operationalBoxs.where().nameEqualTo('userId').findFirst()?.data.toString();
  }

  Future<void> setUserId(String userId) async {
    isar.write((isar) {
      isar.operationalBoxs.put(
        OperationalBox()
        ..id = isar.operationalBoxs.autoIncrement()
        ..name = 'userId'
        ..data = userId
      );
    });
  }

  String? getOperational(String key) {
    return isar.operationalBoxs.where().nameEqualTo(key).findFirst()?.data.toString();
  }

  Future<void> setOperational(String key, String value) async {
    isar.write((isar) {
      isar.operationalBoxs.put(
        OperationalBox()
        ..id = isar.operationalBoxs.autoIncrement()
        ..name = key
        ..data = value
      );
    });
  }

  dynamic getOpItem(String id) {
    String? serializedItem = isar.operationalBoxs.where().nameEqualTo(id).findFirst()?.data;
    if (serializedItem != null) {
      final json = jsonDecode(serializedItem);
      if (json is List) {
        return json
          .map((e) => (models[e['type']] ?? NavStackEntry.fromJson).call(e))
          .where((e) => e != null)
          .toList();
      } else {
        return models[json['type']]?.call(json);
      }
    }
  }

  Future<void> storeOpItem(String id, dynamic item) async {
    isar.write((isar) {
      if (item is Model || item is NavStackEntry || item is List<NavStackEntry>) {
        String? serializedItem = jsonEncode(item);
        isar.operationalBoxs.put(
          OperationalBox()
          ..id = isar.operationalBoxs.autoIncrement()
          ..name = id
          ..data = serializedItem
        );
      }
    });
  }

  @override
  dynamic getItem({required String id}) {
    // Get item by ID
    String? serializedItem = isar.modelBoxs.where().modelIdEqualTo(id).findFirst()?.modelData;
    if (serializedItem != null) {
      final json = jsonDecode(serializedItem);
      return models[json['type']]?.call(json);
    }
  }

   @override
  Map<String, T> getItems<T>(List<String> ids) {
    // Get item by ID
    Map<String, T> items = {};
    if (ids.isEmpty) return items;
    final List<ModelBox> rawModels = isar
      .modelBoxs
      .where()
      .anyOf(
        ids,
        (q, String id) => q.modelIdEqualTo(id)
      )
      .findAll();
    final List<String?> serializedItems = rawModels.map((model) => model.modelData).toList();
    serializedItems.forEach((String? serializedItem) {
      if (serializedItem != null) {
        final json = jsonDecode(serializedItem);
        items[json['id']] = models[json['type']]?.call(json);
      }
    });
    return items;
   }

   Future<void> storeItem(dynamic item) async {
    if (item is Model) {
      String? serializedItem = jsonEncode(item);
      isar.write((isar) {
        isar.modelBoxs.put(
          ModelBox()
          ..id = isar.modelBoxs.autoIncrement()
          ..modelId = item.id
          ..modelData = serializedItem
        );
      });
    }
  }

  Future<int> storeItems(Map<String, dynamic> items) async {
    // await _commonBox.putAll(items);
    final rawModels = items
      .entries
      .where((entry) => entry.value is Model)
      .map((entry) => ModelBox()
        ..id = isar.modelBoxs.autoIncrement()
        ..modelId = entry.key
        ..modelData = jsonEncode(entry.value)
    ).toList();
    isar.write((isar) => isar.modelBoxs.putAll(rawModels));
    return rawModels.length;
  }

  Future<void> deleteItem(String id) async {
    isar.write((isar) => isar.modelBoxs.where().modelIdEqualTo(id).deleteFirst());
  }
}