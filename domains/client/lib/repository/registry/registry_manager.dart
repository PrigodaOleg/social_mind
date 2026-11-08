import 'dart:async';

import 'package:closers/local_storage/local_storage.dart';
import 'package:closers/remote_storage/remote_storage.dart';

import '../models/models.dart';

/// Абстрактное бизнес-событие "изменились модели" для бизнес-слоя.
///
/// Не содержит деталей реестров: ни registryId, ни Transaction, ни changeType -
/// бизнес-логика ничего не должна знать о механизме реестров.
/// [actorId] - кто внес изменения (автор транзакции) - бизнес-информация
/// "кто изменил", а не "из какого реестра".
/// [containerId] - id домена/пользователя-контейнера (резолвится из parentId
/// реестра внутри слоя реестров).
/// [changedModels] - изменившиеся модели по id.
class ModelsChangedEvent {
  ModelsChangedEvent({
    required this.actorId,
    required this.containerId,
    required this.changedModels,
  });

  final String actorId;
  final String containerId;
  final Map<String, Model> changedModels;
}

typedef ModelsChangedListener = void Function(ModelsChangedEvent event);

/// # Слой реестров: инкапсулирует всю работу с реестрами изменений.
///
/// ВХОДЯЩИЙ конвейер (чужие изменения) живет здесь: подписки на изменения
/// реестров в удаленных хранилищах, маршрутизация чтения реестров по
/// storageKey родителя, диффинг входящих транзакций, дочитывание изменившихся
/// моделей и их сохранение в локальное хранилище. Наружу отдаются только
/// абстрактные бизнес-события [ModelsChangedEvent] - бизнес-логика не знает
/// ни о реестрах, ни о транзакциях.
///
/// ИСХОДЯЩИЙ путь (свои изменения: построение транзакций, ребейз, коллизии
/// записи) пока остается в Repository - он тесно связан с транспортной
/// логикой коллизий записи и может мигрировать в этот слой позже. Чтение
/// реестров ([readRegistriesRouted], [readRegistriesRoutedCounts]) уже
/// размещено здесь и используется исходящим путем Repository.
class RegistryManager {
  RegistryManager({
    required LocalStorage localStorage,
    required Map<String, RemoteStorage> remoteStorages,
    required Future<Map<String, Model>> Function(List<String> ids) fetchModels,
    required String? Function() getMyId,
    required void Function(List<String> modelIds, Map<String, Model> models) onModelsStored,
  })  : _localStorage = localStorage,
        _remoteStorages = remoteStorages,
        _fetchModels = fetchModels,
        _getMyId = getMyId,
        _onModelsStored = onModelsStored;

  final LocalStorage _localStorage;

  // Живая ссылка на карту подключенных хранилищ Repository (изменения через
  // addConnectedStorage видны и здесь).
  final Map<String, RemoteStorage> _remoteStorages;

  // Дочитывание моделей по ID с маршрутизацией по хранилищам (реализует
  // Repository - та же маршрутизация используется исходящим путем).
  final Future<Map<String, Model>> Function(List<String> ids) _fetchModels;
  final String? Function() _getMyId;

  // Хук Repository: после сохранения приехавших моделей уведомить sync-слушателей
  // и пометить модели синхронизированными в этой сессии.
  final void Function(List<String> modelIds, Map<String, Model> models) _onModelsStored;

  // Карта registryId -> storageKey родителя (домена/пользователя). Заполняется
  // при подписке и используется для маршрутизации чтения реестров.
  final Map<String, String> registryStorageKeys = {};

  // # Подписки на изменения реестров в удаленных хранилищах.
  final registryWatchSubscriptions = <RemoteStorage, StreamSubscription>{};
  Set<String> watchedRegistryIds = {};

  /// Подписаться на изменения реестров [registryIds] в соответствующих хранилищах.
  /// Входящие события обрабатываются через [onRemoteRegistryChange].
  Future<void> watchRegistries(Set<String> registryIds) async {
    final newIds = registryIds.difference(watchedRegistryIds);
    if (newIds.isEmpty) return;
    watchedRegistryIds.addAll(newIds);
    for (var storageEntry in _remoteStorages.entries) {
      // Реестры маршрутизируем по storageKey родителя; для простоты подписываемся
      // на все новые ID в каждом подключенном хранилище, лишние события отфильтруются
      // при чтении (реестр не найдется в этом хранилище).
      if (registryWatchSubscriptions.containsKey(storageEntry.value)) {
        await registryWatchSubscriptions[storageEntry.value]?.cancel();
      }
      registryWatchSubscriptions[storageEntry.value] = storageEntry.value
          .watchRegistries(watchedRegistryIds.toList())
          .listen((event) => onRemoteRegistryChange(event.registryId));
    }
  }

  Future<void> stopWatchingRegistries() async {
    for (var sub in registryWatchSubscriptions.values) {
      await sub.cancel();
    }
    registryWatchSubscriptions.clear();
    watchedRegistryIds.clear();
  }

  /// Обновить подписки: [userRegistries] - карта registryId -> storageKey
  /// родителя (домена/пользователя). Сбор этой карты - пользовательская логика,
  /// она остается в Repository; здесь - только реестровая работа.
  Future<void> updateWatches(Map<String, String> userRegistries) async {
    registryStorageKeys.addAll(userRegistries);
    await watchRegistries(userRegistries.keys.toSet());
  }

  // # Бизнес-события "изменились модели".
  final modelsChangedListeners = <int, ModelsChangedListener>{};
  int _modelsChangedListenersCounter = 0;

  int addModelsChangedListener(ModelsChangedListener listener) {
    modelsChangedListeners[_modelsChangedListenersCounter] = listener;
    return _modelsChangedListenersCounter++;
  }

  void removeModelsChangedListener(int id) {
    modelsChangedListeners.remove(id);
  }

  /// Обработка события изменения реестра: перечитываем новые транзакции,
  /// определяем изменившиеся модели, дочитываем их и кладем в локальное
  /// хранилище, после чего уведомляем sync-слушателей и отдаем бизнес-событие
  /// [ModelsChangedEvent] (без деталей реестров).
  Future<void> onRemoteRegistryChange(String registryId) async {
    if (_remoteStorages.isEmpty) return;
    try {
      final localRegistry = _localStorage.getRegistry(id: registryId, count: 1);
      final lastLocalIndex = localRegistry?.lastTransactionIndex ?? -1;
      // Читаем транзакции, опережающие локальную голову
      final remoteRegistries = await readRegistriesRoutedCounts([(registryId, 50)]);
      final remoteRegistry = remoteRegistries[registryId];
      if (remoteRegistry == null) return;
      final freshTransactions = remoteRegistry.transactions.entries
          .where((e) => e.key > lastLocalIndex)
          .map((e) => e.value)
          .toList();
      if (freshTransactions.isEmpty) return;
      // Сохраняем реестр локально
      await _localStorage.storeItems({registryId: remoteRegistry});
      // Определяем изменившиеся модели и дочитываем их
      final changedModelIds = freshTransactions.expand((t) => t.changes).toSet().toList();
      if (changedModelIds.isNotEmpty) {
        final remoteModels = await _fetchModels(changedModelIds);
        // Ребейзим с локальными копиями, если они изменены локально
        await _localStorage.storeItems(remoteModels);
        _onModelsStored(changedModelIds, remoteModels);
        // Бизнес-событие "изменились модели": контейнер резолвим из parentId
        // реестра - наружу registryId не выходит.
        final containerId = remoteRegistry.parentId ?? '';
        for (final transaction in freshTransactions) {
          _notifyModelsChanged(transaction, containerId, remoteModels);
        }
      }
    } catch (e) {
      print('Error on remote registry change ($registryId): $e');
    }
  }

  /// Уведомляем слушателей о бизнес-событии "изменились модели". Никаких
  /// деталей реестров не отдаем: интерпретация (какие типы уведомлений
  /// порождает событие) - ответственность бизнес-слоя.
  void _notifyModelsChanged(Transaction transaction, String containerId, Map<String, Model> models) {
    // Собственные изменения (эхо своей транзакции) событий не порождают.
    if (transaction.originatorId == _getMyId()) return;
    final changedModels = <String, Model>{
      for (final id in transaction.changes)
        if (models[id] != null) id: models[id]!,
    };
    if (changedModels.isEmpty) return;
    final event = ModelsChangedEvent(
      actorId: transaction.originatorId,
      containerId: containerId,
      changedModels: changedModels,
    );
    for (final listener in modelsChangedListeners.values.toList()) {
      listener(event);
    }
  }

  // Резолвим хранилище для реестра: сперва по карте registryStorageKeys
  // (заполняется при подписке), затем по storageKey локальной модели-родителя
  // (registry.parentId), затем фолбэк на первое подключенное хранилище.
  RemoteStorage? _storageByKey(String? storageKey) {
    if (storageKey == null || storageKey.isEmpty) return null;
    return _remoteStorages[storageKey];
  }

  RemoteStorage? _storageForRegistry(String registryId) {
    final storageKey = registryStorageKeys[registryId];
    if (storageKey != null) {
      final byKey = _storageByKey(storageKey);
      if (byKey != null) return byKey;
    }
    final localRegistry = _localStorage.getRegistry(id: registryId, count: 1);
    final parentId = localRegistry?.parentId;
    if (parentId != null && parentId.isNotEmpty) {
      final parentModel = _localStorage.getItem(id: parentId);
      if (parentModel != null) {
        // Родитель реестра - всегда контейнер (домен или пользователь)
        if (parentModel is Domain) return _storageByKey(parentModel.storageKey);
        if (parentModel is User) return _storageByKey(parentModel.storageKey);
      }
    }
    return _remoteStorages.values.firstOrNull;
  }

  // Читаем реестры из их удаленных хранилищ. Каждый реестр лежит рядом со своим
  // родителем (доменом или пользователем), поэтому маршрутизируем по storageKey родителя.
  // Используется также исходящим путем Repository.
  Future<Map<String, Registry>> readRegistriesRouted(List<String> ids) async {
    Map<String, Registry> registries = {};
    final idsByStorage = <RemoteStorage, List<String>>{};
    for (final id in ids) {
      final storage = _storageForRegistry(id);
      if (storage == null) continue;
      idsByStorage.putIfAbsent(storage, () => []).add(id);
    }
    for (var entry in idsByStorage.entries) {
      registries.addAll(await entry.key.readRegistries(ids: entry.value));
    }
    return registries;
  }

  // Читаем реестры с указанным количеством транзакций, маршрутизируя по storageKey родителя.
  // Используется также исходящим путем Repository.
  Future<Map<String, Registry>> readRegistriesRoutedCounts(List<(String, int)> registriesIdsToRead) async {
    Map<String, Registry> registries = {};
    final idsByStorage = <RemoteStorage, List<(String, int)>>{};
    for (final (id, count) in registriesIdsToRead) {
      final storage = _storageForRegistry(id);
      if (storage == null) continue;
      idsByStorage.putIfAbsent(storage, () => []).add((id, count));
    }
    for (var entry in idsByStorage.entries) {
      registries.addAll(await entry.key.readRegistries(idsCounts: entry.value));
    }
    return registries;
  }
}
