import 'dart:async';
import 'dart:math';

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

/// # Слой реестров: инкапсулирует только работу с реестрами изменений.
///
/// ВХОДЯЩИЙ конвейер (чужие изменения) живет здесь: подписки на изменения
/// реестров в удаленных хранилищах, маршрутизация чтения реестров по
/// storageKey родителя, диффинг входящих транзакций, дочитывание изменившихся
/// моделей и их сохранение в локальное хранилище. Наружу отдаются только
/// абстрактные бизнес-события [ModelsChangedEvent] - бизнес-логика не знает
/// ни о реестрах, ни о транзакциях.
///
/// ИСХОДЯЩИЙ реестровый путь (свои изменения) тоже живет здесь: построение
/// транзакций (_buildTransactions), ребейз и разрешение конфликтов слияния
/// (_rebaseTransaction), откат неудачной транзакции (_rollbackLastTransaction)
/// и цикл борьбы с коллизиями записи ([syncWithRemoteStorage]).
///
/// Транспорт (debounce-таймер синхронизации, очереди исходящих изменений и
/// удалений, маршрутизация моделей по подключенным хранилищам, чтение/запись/
/// удаление моделей, sync-слушатели и их уведомления, публичный интерфейс
/// репозитория) остается в Repository и внедряется сюда через колбэки
/// конструктора: слой реестров знает только ID изменившихся моделей,
/// чтение/запись моделей выполняют внедренные транспортные колбэки, а события
/// отдаются Repository для уведомления слушателей. Автор транзакций (myId)
/// в слой реестров не попадает - Repository передает originatorId параметром.
class RegistryManager {
  RegistryManager({
    required LocalStorage localStorage,
    required Map<String, RemoteStorage> remoteStorages,
    required Future<Map<String, Model>> Function(List<String> ids) fetchModels,
    required Map<Model, Map<String, dynamic>> Function(Map<String, dynamic> items) clusterByParent,
    required Future<int> Function(Map<String, Model> items, Map<String, Registry> registries) saveToRemote,
    required void Function(List<String> modelIds, Map<String, Model> models) onIncomingModelsStored,
    required void Function(ModelsChangedEvent event) onModelsChanged,
    required void Function(Map<String, dynamic> items) onAccessDenied,
    required void Function(Map<String, Model> localItems, Map<String, Model> remoteItems) onMergeConflict,
  })  : _localStorage = localStorage,
        _remoteStorages = remoteStorages,
        _fetchModels = fetchModels,
        _clusterByParent = clusterByParent,
        _saveToRemote = saveToRemote,
        _onIncomingModelsStored = onIncomingModelsStored,
        _onModelsChanged = onModelsChanged,
        _onAccessDenied = onAccessDenied,
        _onMergeConflict = onMergeConflict;

  final LocalStorage _localStorage;

  // Живая ссылка на карту подключенных хранилищ Repository (изменения через
  // addConnectedStorage видны и здесь).
  final Map<String, RemoteStorage> _remoteStorages;

  // # Транспортные колбэки (реализуются Repository).

  // Дочитывание моделей по ID с маршрутизацией по хранилищам. Используется
  // и входящим конвейером, и циклом [syncWithRemoteStorage]: слой реестров
  // знает только ID изменившихся моделей, чтение моделей - транспорт.
  final Future<Map<String, Model>> Function(List<String> ids) _fetchModels;

  // Кластеризация моделей по родителю (домену/пользователю). Модельная
  // иерархия - не реестровая работа; для ассоциации изменений с реестрами
  // слой реестров пользуется этим колбэком.
  final Map<Model, Map<String, dynamic>> Function(Map<String, dynamic> items) _clusterByParent;

  // Запись моделей и реестров в подключенные хранилища с маршрутизацией по
  // storageKey родителя (используется циклом [syncWithRemoteStorage]).
  final Future<int> Function(Map<String, Model> items, Map<String, Registry> registries) _saveToRemote;

  // Хук Repository: после сохранения приехавших моделей уведомить sync-слушателей
  // и пометить модели синхронизированными в этой сессии.
  final void Function(List<String> modelIds, Map<String, Model> models) _onIncomingModelsStored;

  // Диспетчер бизнес-событий [ModelsChangedEvent]: Repository решает, какие
  // события доходят до бизнес-слушателей (в том числе отфильтровывает
  // собственные изменения - локальный пользователь слою реестров неизвестен).
  final void Function(ModelsChangedEvent event) _onModelsChanged;

  // Хуки уведомления sync-слушателей при неудачной записи: отказ в доступе
  // и конфликт слияния. Подписки и сами слушатели живут в Repository.
  final void Function(Map<String, dynamic> items) _onAccessDenied;
  final void Function(Map<String, Model> localItems, Map<String, Model> remoteItems) _onMergeConflict;

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

  /// Обработка события изменения реестра: перечитываем новые транзакции,
  /// определяем изменившиеся модели, дочитываем их (через внедренный
  /// транспортный колбэк) и кладем в локальное хранилище, после чего
  /// уведомляем sync-слушателей через хук Repository и отдаем бизнес-событие
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
      // Определяем изменившиеся модели и дочитываем их: слой реестров знает
      // только ID, чтение моделей - транспортная операция Repository.
      final changedModelIds = freshTransactions.expand((t) => t.changes).toSet().toList();
      if (changedModelIds.isNotEmpty) {
        final remoteModels = await _fetchModels(changedModelIds);
        // Ребейзим с локальными копиями, если они изменены локально
        await _localStorage.storeItems(remoteModels);
        // Хук Repository: sync-слушатели и пометка "синхронизировано в этой сессии".
        _onIncomingModelsStored(changedModelIds, remoteModels);
        // Бизнес-событие "изменились модели": контейнер резолвим из parentId
        // реестра - наружу registryId не выходит.
        final containerId = remoteRegistry.parentId ?? '';
        for (final transaction in freshTransactions) {
          _emitModelsChanged(transaction, containerId, remoteModels);
        }
      }
    } catch (e) {
      print('Error on remote registry change ($registryId): $e');
    }
  }

  /// Собираем бизнес-событие "изменились модели" (без деталей реестров) и
  /// отдаем его диспетчеру Repository. Интерпретация (какие типы уведомлений
  /// порождает событие) - ответственность бизнес-слоя.
  void _emitModelsChanged(Transaction transaction, String containerId, Map<String, Model> models) {
    final changedModels = <String, Model>{
      for (final id in transaction.changes)
        if (models[id] != null) id: models[id]!,
    };
    if (changedModels.isEmpty) return;
    _onModelsChanged(ModelsChangedEvent(
      actorId: transaction.originatorId,
      containerId: containerId,
      changedModels: changedModels,
    ));
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

  // Исходящий реестровый путь: реализация консистентной записи с использованием
  // реестра изменений (построение транзакций, ребейз, коллизии записи).
  // Наружу торчит @visibleForTesting-обертка Repository.syncWithRemoteStorage.
  // Локальный пользователь слою реестров неизвестен - Repository передает автора
  // транзакций параметром [originatorId]; транспортные операции (маршрутизацию
  // записи моделей, чтение изменившихся моделей) выполняют внедренные колбэки.
  Future<int> syncWithRemoteStorage(Map<String, Model> localItems, {String? originatorId}) async {

    // Так как мы начинаем собирать новую транзакцию,
    // то прекращаем сбор исторических данных для текущей локальной копии
    final oldItems = _localStorage.getNextItemsFromHistoryQueue();

    // Проходим по моделям и определяем, к каким доменам/пользователям они относятся.
    Map<Model, Map<String, dynamic>> parentItems = _clusterByParent(localItems);

    var localRegistries = _getRegistries(parentItems.keys.toList());

    var remoteRegistries = <String, Registry>{};
    var latestRemoteRegistries = <String, Registry>{};

    var localchanges = localItems;
    var remoteChanges = <String, Model>{};

    var localUpdates = localItems;
    var remoteUpdates = <String, Model>{};

    bool mergeConflict = false;

    // Флаг, который указывает на то, что мы подозреваем, что в УХ появились новые данные.
    // В первый раз надеемся на то, что данные в ЛХ актуальны
    bool isRemoteRegistriesActual = true;

    // Будем пробовать создавать транзакции много раз, пока не отправим их удачно,
    // или пока не обнаружим отсутствие прав на запись (пока индексы транзакций меняются при перечитывании).
    do {
      if (isRemoteRegistriesActual == false) {
        latestRemoteRegistries = await readRegistriesRouted(localRegistries.keys.toList());
        if (_isIndexesEqual(remoteRegistries, latestRemoteRegistries)) {
          // Индексы не изменились, значит нет прав на запись
          _rollbackLastTransaction(oldItems, localRegistries);
          _localStorage.clearHistoryQueueHead();
          _onAccessDenied(localchanges);
          return 0; // Ошибка доступа
        }
        remoteRegistries = await _getRemoteRegistries(localRegistries, remoteRegistries, latestRemoteRegistries);
        remoteChanges = await _getRemoteChanges(remoteRegistries);
        isRemoteRegistriesActual = true;
        (localUpdates, remoteUpdates, mergeConflict) = _rebaseTransaction(localchanges, remoteChanges, oldItems.cast<String, Model>());
        if (mergeConflict) {
          _rollbackLastTransaction(oldItems, localRegistries);
          _localStorage.clearHistoryQueueHead();
          _onMergeConflict(localUpdates, remoteUpdates);
          return 0; // Конфликт слияния
        }
      } else {
        remoteUpdates = localUpdates;
      }
      remoteRegistries = _buildTransactions(remoteRegistries, remoteUpdates, originatorId);
      try {
        if (remoteUpdates.isNotEmpty) await _saveToRemote(remoteUpdates, remoteRegistries.map((k, v) => MapEntry(k, v.onlyLastTransaction())));
        // Залилось
        localRegistries = remoteRegistries;
        if (localUpdates.isNotEmpty) _localStorage.storeItems({...localUpdates, ...localRegistries});
        _localStorage.clearHistoryQueueHead();
      } on RemoteStorageWriteCollision catch (e) {
        // Не залилось
        isRemoteRegistriesActual = false;
        remoteRegistries.forEach((id, registry) => registry.removeLastTransaction());
        localUpdates = <String, Model>{};
      }

    } while (!_isIndexesEqual(localRegistries, remoteRegistries) || isRemoteRegistriesActual == false);

    return localItems.length;
  }

  Map<String, Registry> _getRegistries(List<Model> items) {
    var registries = <String, Registry>{};
    for (final item in items) {
      final registry =
         // Реестр уже существует, сценарий 3
        _localStorage.getRegistry(parentId: item.id, count: 1)
        // Реестра еще нет,
        // Нет, тут, кажется, ситуация посложнее. Наверное, при логине старого пользователя нужно подтянуть все домены и реестры.
        // Назовем такую ситуацию - "получить контекст пользователя" (get_user_context()).
        // И тогда они не будут пустыми. Можно поверх них писать транзакции.
        // Тогда ситуация отсутствия реестра будет только в том случае, если пользователь или домен только что создан.
        // Создаем новый реестр с нулевой транзакцией.
        ?? Registry(parentId: item.id);
      // Линкуем реестр к контейнеру и сохраняем в локальное хранилище
      if (item is Domain) item.registryId = registry.id!;
      if (item is User) item.registryId = registry.id!;
      registries[registry.id!] = registry;
    }
    return registries;
  }

  bool _isIndexesEqual(Map<String, Registry> a, Map<String, Registry> b) {
    if (a.length != b.length) return false;
    if (!a.keys.every((key) => b.keys.contains(key))) return false;
    for (final id in a.keys) {
      if (a[id]?.lastTransactionIndex != b[id]?.lastTransactionIndex) return false;
    }
    return true;
  }

  // Вычисляем и читаем опережающие цепочки транзакций по всем реестрам
  // Базовые индексы берем из [localRegistries], известные индексы вычисляем из объединения
  // [remoteRegistries] и [knownFragment]. Причем, так как мы не знаем, появились ли новые транзакции в УХ,
  // то считываем немного больше, и контролируем, попали ли базовые индексы цепочки с новыми индексами.
  // Если нет, то дочитываем еще. Если да, то склеиваем все цепочки и возвращаем все реестры.
  Future<Map<String, Registry>> _getRemoteRegistries(
    Map<String, Registry> localRegistries,
    Map<String, Registry> remoteRegistries,
    Map<String, Registry> knownFragment
  ) async {
    List<(String, int)> registriesIdsToRead = [];
    for (final localRegistry in localRegistries.values) {
      final lastLocalIndex = localRegistry.lastTransactionIndex ?? -1;
      final lastRemoteIndex = remoteRegistries[localRegistry.id]?.lastTransactionIndex ?? -1;
      final firstRemoteIndex = knownFragment[localRegistry.id]?.transactions.keys.reduce(min) ?? -1;
      final lastFragmentIndex = knownFragment[localRegistry.id]?.lastTransactionIndex ?? -1;
      final firstFragmentIndex = knownFragment[localRegistry.id]?.transactions.keys.reduce(min) ?? -1;
      // Просто проверяем, является ли [knownFragment] бесшовным продолжением [remoteRegistries]
      // Если нет, то отбрасываем его, поскольку все равно перечитывать надо будет всё
      int latestRemoteIndex = lastLocalIndex;
      if (latestRemoteIndex >= firstRemoteIndex - 1) latestRemoteIndex = lastRemoteIndex;
      if (latestRemoteIndex >= firstFragmentIndex - 1) latestRemoteIndex = lastFragmentIndex;
      // Читать будем чуть больше, чтобы транзакции точно склеились
      final count = latestRemoteIndex - lastLocalIndex + 2;
      registriesIdsToRead.add((localRegistry.id!, count));
    }
    return await readRegistriesRoutedCounts(registriesIdsToRead);
  }

  // Собираем ID всех моделей из транзакций [registries] и считываем их изменения.
  // Реестр знает только ID; чтение моделей - транспортная операция, внедренная
  // в конструкторе колбэком _fetchModels.
  Future<Map<String, Model>> _getRemoteChanges(Map<String, Registry> registries) async {
    Set<String> allModels = {};
    for (final registry in registries.values) {
      registry.transactions.values.forEach((transaction) => allModels.addAll(transaction.changes));
    }
    return await _fetchModels(allModels.toList());
  }

  // Создаем новые транзакции для каждого реестра в [registries].
  // Тут есть вопрос - как понять, какие из этих изменений к каким реестрам относятся?
  // Заново производить поиск (пока да)?
  // [registries] - свежайшие реестры, на основе которых мы будем делать новые транзакции.
  // [items] - собственно изменения, которые должны войти в транзакции. Однако, тут есть некооторые сложности.
  // А именно, не факт, что для каждого изменения найдется реестр. Не факт, что [registries] не пусты.
  // Получается, что нам все-таки нужно сравнивать с локальными/старыми реестрами.
  // [originatorId] - автор транзакций; Repository передает me.id параметром.
  Map<String, Registry> _buildTransactions(Map<String, Registry> registries, Map<String, Model> items, String? originatorId) {
    Map<Model, Map<String, dynamic>> parentItems = _clusterByParent(items);
    if (parentItems.isEmpty) return registries;
    if (originatorId == null) {
      throw StateError('Local user is unknown: transactions require an originator');
    }
    for (final pItemEntry in parentItems.entries) {
      final pItem = pItemEntry.key;
      final pItemItems = pItemEntry.value;
      var oldRegistry = _localStorage.getRegistry(parentId: pItem.id);
      Registry? recentRegistry;
      if (pItem is User) recentRegistry = registries[pItem.registryId];
      if (pItem is Domain) recentRegistry = registries[pItem.registryId];
      // todo: кажется, забыли про случай, когда нового реестра нет локально (но мы почему-то вносим в него изменения, странно ...)
      final lastOldIndex = oldRegistry?.lastTransactionIndex ?? -1;
      final lastRecentIndex = recentRegistry?.lastTransactionIndex ?? -1;
      Map<int, Transaction> actualTransactionChain = {};
      if (recentRegistry != null) {
        if (lastRecentIndex < lastOldIndex) {
          // добавляем в recentRegistry цепочку старых транзакций из oldRegistry
          oldRegistry = _localStorage.getRegistry(id: pItem.id, count: lastOldIndex - lastRecentIndex);
          actualTransactionChain = oldRegistry?.transactions ?? {};
        }
      } else if (oldRegistry != null) {
        // старый реестр наиболее актуален
        recentRegistry = oldRegistry.copyWith();
      } else {
        // создаем новый реестр
        recentRegistry = Registry(parentId: pItem.id);
        if (pItem is User) pItem.registryId = recentRegistry.id!;
        if (pItem is Domain) pItem.registryId = recentRegistry.id!;
      }
      recentRegistry.transactions.addAll(actualTransactionChain);
      recentRegistry.addNewTransaction(
        Transaction.next(
          recentRegistry.lastTransaction,
          originatorId,
          '\$session - \$app - \$device',
          'creation',
          pItemItems.keys.toList(),
          'path'
        )
      );
      registries[recentRegistry.id!] = recentRegistry;
    }
    return registries;
  }

  // Пробуем смешать данные, если не получили неразрешимой коллизии, то возвращаем изменения, предназначенные для
  // сохранения в ЛХ и УХ.
  // Если получается коллизия, то кидаем исключение.
  // Основные правила ребейза:
  // 1. Если объект новый, то просто сохраняем его в ЛХ и УХ.
  // 2. Если объект изменен (есть и в ЛХ и в УХ), то сравниваем по полям объекта.
  // 3. Чтобы понять, какие поля мы изменили, сравниваем каждое поле с таким же объектом из oldItems.
  // 4. Если поле не менялось, то берем новое значение из объекта из remoteItems.
  // 5. Если поле изменилось, смотрим, изменилось ли оно в УХ, если нет, то берем новое значение из объекта из localItems,
  //    если да, то мы обнаружили конфликт, накапливаем их и кидаем исключение.
  // 6. Для списков также смотрим старое значение, если мы не трогали список, то берем его из remoteItems.
  // 7. Если мы трогали список, то сравниваем его со списком из remoteItems. Если список изменился,
  //    сравниваем элементы списка. Если он только расширился, то спокойно мержим список.
  //    todo: если мы изменили элемент, как понять, с каким элементом из remoteItems его нужно сравниваеть?
  // 8. Для словарей проверяем по ключам на предмет расширения, мержим расширения.
  // 9. Если значения по одинаковым ключам изменились, рекурсивно ребейзим то, что внутри значения то вышеописанным правилам.
  (Map<String, Model>, Map<String, Model>, bool) _rebaseTransaction(
    Map<String, Model> localItems,
    Map<String, Model> remoteItems,
    Map<String, Model> oldItems
  ) {
    var localModels = <String, Model>{};
    var remoteModels = <String, Model>{};
    var conflicts = <String>{};
    var insolubleConflicts = <String>[];
    for (final modelId in localItems.keys) {
      if (remoteItems.containsKey(modelId)) {
        conflicts.add(modelId);
      } else{
        remoteModels[modelId] = localItems[modelId]!;
      }
    }
    for (final modelId in remoteItems.keys) {
      if (localItems.containsKey(modelId)) {
        conflicts.add(modelId);
      } else {
        localModels[modelId] = remoteItems[modelId]!;
      }
    }
    for (final modelId in conflicts) {
      final localModel = localItems[modelId]!;
      final remoteModel = remoteItems[modelId]!;
      final oldModel = oldItems[modelId];
      if (localModel != remoteModel) {
        final rebasedModel = _rebaseModel(localModel, remoteModel, oldModel);
        if (rebasedModel == null) {
          insolubleConflicts.add(modelId);
          continue;
        }
        localModels[modelId] = rebasedModel;
        remoteModels[modelId] = rebasedModel;
      } else {
        localModels[modelId] = localModel;
        remoteModels[modelId] = remoteModel;
      }
    }
    if (insolubleConflicts.isEmpty) {
      return (localModels, remoteModels, false);
    } else {
      return (
        Map.fromEntries(localItems.entries.where((e) => insolubleConflicts.contains(e.key))),
        Map.fromEntries(remoteItems.entries.where((e) => insolubleConflicts.contains(e.key))),
        true
      );
    }
  }

  Model? _rebaseModel(Model localModel, Model remoteModel, Model? oldModel) {
    if (localModel == remoteModel) return localModel;
    final oldMap = oldModel?.toJson() ?? {};
    final localMap = localModel.toJson();
    var remoteMap = remoteModel.toJson();
    final fields = <String>{...localMap.keys, ...remoteMap.keys};
    for (final field in fields) {
      if (oldMap.containsKey(field) && oldMap[field] == localMap[field]) {
        // поле не изменилось
        continue;
      }
      if (remoteMap.containsKey(field)) {
        if (localMap.containsKey(field)) {
          // поле изменилось в обоих местах
          if (remoteMap[field] != localMap[field]) {
            // нужно решить конфликт
            if (remoteMap[field] is Map) {
              remoteMap[field] = _rebaseMap(remoteMap[field], localMap[field]);
            } else if (remoteMap[field] is List) {
              remoteMap[field] = {...remoteMap[field], ...(localMap[field] as List)}.toList();
            } else {
              // в остальных случаях нужно спросить пользователя
              // todo: пока берем удаленную версию, локальные изменения теряем
              return null;
            }
          }
        }
      } else {
        remoteMap[field] = localMap[field];
      }
    }
    return FirebaseStorage().models[remoteModel.type]!(remoteMap);
  }

  Map<String, dynamic>? _rebaseMap(Map<String, dynamic> remoteMap, Map<String, dynamic> localMap) {
    final keys = <String>{...remoteMap.keys, ...localMap.keys};
    for (final key in keys) {
      if (remoteMap.containsKey(key) && localMap.containsKey(key)) {
        if (remoteMap[key] is Map && localMap[key] is Map) {
          final rebasedMap = _rebaseMap(remoteMap[key], localMap[key]);
          if (rebasedMap == null) return null;
          remoteMap[key] = rebasedMap;
        } else if ( remoteMap[key] is List && localMap[key] is List) {
          remoteMap[key] = {...remoteMap[key], ...(localMap[key] as List)}.toList();
        } else {
          if (remoteMap[key] != localMap[key]) {
            // нужно решить конфликт
            // todo: пока берем удаленную версию, локальные изменения теряем
            return null;
          }
        }
      } else if (localMap.containsKey(key)) {
        remoteMap[key] = localMap[key];
      }
    }
    return remoteMap;
  }

  void _rollbackLastTransaction(Map<String, dynamic> oldItems, Map<String, Registry> registries) {
    // Что такое последняя транзакция?
    // Работа репозитория устроена так, что поступающие изменения сразу сохраняются в локальное хранилище.
    // При этом репозиторий накапливает эти изменения за некоторый период времени, зависящий от действий пользователя,
    // группирует эти изменения в пачки, после чего пытается выгрузить их в удаленный репозиторий в виде транзакции.
    // Эта транзакция может оказаться неудачной, и подлежащей пересборке. В таком случае, нужно будет откатить всю эту пачку.
    // Соответственно, откат транзакции означает - откат пачки изменений, накопленной между синхронизациями.
    // Соответственно, в локальном репозитории история изменений также должна храниться в виде транзакций,
    // разделенных событиями синхронизации.
    // При этом, в репозитории есть также методы, выполняющие синхронизацию мгновенно.
    // Получается, что в локальном репозитории накапливается цепочка/очередь из транзакций.
    // Откатывать мы хотим её голову. Новые транзакции поступают в хвост.
    _localStorage.storeItems(oldItems);
    registries.values.forEach((e) => e.removeLastTransaction());
  }
}
