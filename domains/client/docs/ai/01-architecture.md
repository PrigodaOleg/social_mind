# Архитектура: слои, зависимости, поток данных

## Слои и их файлы

- **UI** — `lib/ui/pages/*.dart`, `lib/ui/widgets/*.dart`, `lib/ui/navigation.dart`, экспортируется через `lib/ui/ui.dart`.
- **State (BLoC)** — `lib/state/task_list/task_list.dart`, `lib/state/domain_list/domain_list.dart`, `lib/state/contact_list/contact_list.dart`, экспортируются через `lib/state/state.dart`.
- **Repository (координация)** — `lib/repository/repository/repository.dart` (класс `Repository`).
- **Models (данные)** — `lib/repository/models/models.dart` (`Model`), `user.dart` (`User`), `domain.dart` (`Domain`), `task.dart` (`Task`), `registry.dart` (`Registry`, `Transaction`).
- **LocalStorage** — `lib/local_storage/local_storage.dart` (абстракция `LocalStorage`), реализация `lib/local_storage/isar/isar_storage.dart` (`IsarStorage`).
- **RemoteStorage** — `lib/remote_storage/remote_storage.dart` (абстракция `RemoteStorage`), реализация `lib/remote_storage/firebase_realtime_database.dart` (`FirebaseStorage`).
- **Navigation model** — `lib/repository/navigation/navigation_stack.dart` (`NavStackEntry`).

## Направление зависимостей (импорты)

- `lib/ui/pages/*.dart` импортирует `package:closers/state/state.dart` и `package:closers/repository/repository.dart` — пример: `lib/ui/pages/task_list.dart:3-7`.
- `lib/state/task_list/task_list.dart` импортирует `package:closers/repository/repository.dart` (`bloc` + `Repository`) — `lib/state/task_list/task_list.dart:1-3`.
- `lib/state/contact_list/contact_list.dart` импортирует `package:closers/repository/repository.dart` — `lib/state/contact_list/contact_list.dart:2`.
- `lib/repository/repository/repository.dart` импортирует `package:closers/local_storage/local_storage.dart` и `package:closers/remote_storage/remote_storage.dart` — `lib/repository/repository/repository.dart:6-7`.
- `lib/local_storage/local_storage.dart` импортирует `package:closers/repository/models/models.dart` — `lib/local_storage/local_storage.dart:6`.
- `lib/remote_storage/remote_storage.dart` импортирует `package:closers/repository/models/models.dart` — `lib/remote_storage/remote_storage.dart:3`.
- `lib/repository/models/models.dart` импортирует `package:closers/repository/repository/repository.dart` (обратная зависимость модели → `Repository.instance`) — `lib/repository/models/models.dart:6`.
- `Model.linkTo`/`Model.linkFrom`/`Model.unlinkFrom` вызывают `Repository.instance.saveModels(...)` / `Repository.instance.deleteModel(...)` — `lib/repository/models/models.dart:122-153`.

UI не импортирует `local_storage`/`remote_storage` напрямую ни в одном файле `lib/ui/pages/*.dart` — доступ к данным всегда идёт через объект `Repository`, переданный в конструктор страницы (например `TaskListPage(this.repository, ...)` — `lib/ui/pages/task_list.dart:15-21`).

## Границы ответственности

### UI (`lib/ui/`)
- Строит виджеты и оборачивает страницу в `BlocProvider`, создавая нужный BLoC: `TaskListBloc(repository: repository, parentId: id ?? repository.myId ?? '')` — `lib/ui/pages/task_list.dart:27-28`.
- Отправляет события в BLoC через `context.read<TaskListBloc>().add(...)` / `BlocProvider.of<TaskListBloc>(context).add(...)` — `lib/ui/pages/task_list.dart:66-71, 74-79`.
- Рендерит `state` через `BlocBuilder<TaskListBloc, TaskListState>` — `lib/ui/pages/task_list.dart:46-47`.
- Прямой вызов модели из UI без BLoC также встречается: `domain.linkTo(Task(originatorId: repository.me.id))` в `lib/ui/pages/domain_content.dart:57`, и прямое чтение `repository.getModel<Domain>(id!)` в `lib/ui/pages/domain_content.dart:23`.
- Роутинг между страницами — `Navigator.of(context).pushNamed(...)`, обрабатывается `AppRouterDelegate` (`lib/ui/navigation.dart:62-179`), таблица маршрутов задаётся в `lib/app.dart:56-63`.

### State / BLoC (`lib/state/`)
- Каждый BLoC хранит ссылку на `Repository`, переданную через конструктор: `TaskListBloc({required this.repository, required this.parentId})` — `lib/state/task_list/task_list.dart:7-10`.
- Обрабатывает события (`on<TaskEvent>`) и вызывает методы `Repository` для чтения/записи: `repository.getModel<Model>(parentId)`, `repository.getModels<Task>(parent.ids<Task>())` — `lib/state/task_list/task_list.dart:27-29`; `await repository.saveModel(changedTask)` — `lib/state/task_list/task_list.dart:50`.
- `ContactListBloc` подписывается на изменения через `_repo.addSyncListener(...)` в `_onStateInit` и снимает подписку в `close()` через `_repo.removeSyncListener(listenerId)` — `lib/state/contact_list/contact_list.dart:22-27, 35-54`.
- Эмитит новое `State` через `emit(state.copyWith(...))`, например `emit(state.copyWith(tasks: () => tasks..addAll(...)))` — `lib/state/task_list/task_list.dart:31`.

### Repository (`lib/repository/repository/repository.dart`)
- Единая точка входа для UI/BLoC к данным: хранит `_localStorage` (`LocalStorage`) и `_remoteStorages` (`Map<String, RemoteStorage>`) — `lib/repository/repository/repository.dart:110-115`.
- `Repository.init()` инициализирует локальное хранилище, затем при известном `myId` — удалённые хранилища и запускает периодическую синхронизацию через `Timer` (`_sync = Timer(_delayedSync); _sync.start();`) — `lib/repository/repository/repository.dart:145-156`.
- Чтение модели: `getModel<T>(modelId, subscriberId)` читает из `_localStorage.getItem(id: modelId)`, регистрирует подписчика через `subscribeToSync(...)` — `lib/repository/repository/repository.dart:406-414`.
- Запись модели: `saveModel(model, subscriberId)` сохраняет в `_localStorage.storeItem(model)`, ставит модель в очередь `outgoingChanges`, откладывает синхронизацию через `_sync.postpone()` — `lib/repository/repository/repository.dart:396-404`.
- Синхронизация выполняется в `_delayedSync()`: отправка удалений (`_deleteFromAllRemoteStorages`), отправка изменений (`syncWithRemoteStorage`), подтягивание изменений по подпискам (`_remoteStorages.values.first.getItems(idsToSync)`) — `lib/repository/repository/repository.dart:269-350`.
- Конфликты слияния разрешаются в `syncWithRemoteStorage` через реестры (`Registry`) и `_rebaseTransaction`/`_rebaseModel` — `lib/repository/repository/repository.dart:566-634, 728-811`.
- `Repository.instance` — статический синглтон, устанавливаемый в конце `init()` (`instance = this;`), используется моделями для `linkTo`/`linkFrom` без явной передачи репозитория — `lib/repository/repository/repository.dart:90, 154`, `lib/repository/models/models.dart:128, 139, 150-151`.

### LocalStorage (`lib/local_storage/`)
- Интерфейс `LocalStorage` определяет контракт (`init`, `getItem`, `storeItem`, `storeItems`, `deleteItem`, `getRegistry`, `getUserId`/`setUserId`, `getOpItem`/`storeOpItem`, историю очереди) — `lib/local_storage/local_storage.dart:9-58`.
- Активная реализация — `IsarStorage` (`lib/local_storage/isar/isar_storage.dart:90-...`), использует коллекции Isar `ModelBox`, `OperationalBox`, `RegistryBox`, `HistoryQueueHeadIdx`, `HistoryQueueTailIdx` — `lib/local_storage/isar/isar_storage.dart:22-88`.
- `IsarStorage.init()` открывает БД через `Isar.open(schemas: [...], directory: dir, engine: engine)` — `lib/local_storage/isar/isar_storage.dart:106-115`.
- Модели сериализуются в JSON и хранятся как строка в `ModelBox.modelData`/`OperationalBox.data` (`jsonEncode(item)` при записи, `jsonDecode(serializedItem)` при чтении) — `lib/local_storage/isar/isar_storage.dart:157-179`.
- Альтернативная реализация `HiveStorage` существует в `lib/local_storage/hive/hive_storage.dart`, но не подключена (`export` закомментирован в `lib/local_storage/local_storage.dart:3`), поэтому не участвует в текущем потоке данных.

### RemoteStorage (`lib/remote_storage/`)
- Интерфейс `RemoteStorage` определяет контракт (`init`, `createUserAndAuth`, `auth`, `getItem`, `getItems`, `saveItems`, `deleteItems`, `readRegistry`/`readRegistries`) — `lib/remote_storage/remote_storage.dart:18-57`.
- Реализация `FirebaseStorage` использует `firebase_database` (`DatabaseReference`) и `firebase_auth` — `lib/remote_storage/firebase_realtime_database.dart:1-21`.
- `FirebaseStorage.init(instance)` подключается к нужному именованному приложению Firebase: `app = Firebase.app(instance); database = FirebaseDatabase.instanceFor(app: app).ref();` — `lib/remote_storage/firebase_realtime_database.dart:16-20`.
- `Repository` регистрирует известные удалённые хранилища по строковому ключу в `knownRemoteStorages = {'FirebaseRealtimeDatabase': () => FirebaseStorage()}` — `lib/repository/repository/repository.dart:141-143`, и выбирает их из настроек пользователя `me.settings.getDeep('remote_storages', ...)` — `lib/repository/repository/repository.dart:159`.

### Models (`lib/repository/models/`)
- `Model` — общий базовый класс (`sealed class Model extends Equatable`) с полями `id`, `title`, `description`, `location`, `children`, `parents`, `sync` — `lib/repository/models/models.dart:39-93`.
- `Model.toJson()`/`Model.fromJson()` формируют/разбирают сериализованное представление, используемое всеми хранилищами — `lib/repository/models/models.dart:53-59, 95-103`.
- Конкретные модели — `Task` (`lib/repository/models/task.dart:6`), `Domain` (`lib/repository/models/domain.dart:6`), `User` (`lib/repository/models/user.dart:6`), `Registry`/`Transaction` (`lib/repository/models/registry.dart:26`).
- Оба интерфейса хранилищ (`LocalStorage.models`, `RemoteStorage.models`) держат одинаковую таблицу `{'Domain': Domain.fromJson, 'User': User.fromJson, 'Task': Task.fromJson}` для десериализации по полю `type` — `lib/local_storage/local_storage.dart:12-16`, `lib/remote_storage/remote_storage.dart:21-25`.

## Поток данных: чтение (открытие `TaskListPage`)

1. `AppRouterDelegate.build` создаёт страницу через `Function.apply(_routes[route.path], [repository], ...)`, передавая единый экземпляр `Repository` — `lib/ui/navigation.dart:98-111`, `AppRouterDelegate.repository = Repository()` — `lib/ui/navigation.dart:85`.
2. `TaskListPage.build` создаёт `TaskListBloc(repository: repository, parentId: ...)` в `BlocProvider` — `lib/ui/pages/task_list.dart:27-28`.
3. `TaskListView.build` добавляет событие `TaskListStateInitRequested()` — `lib/ui/pages/task_list.dart:44-45`.
4. `TaskListBloc._onStateInit` вызывает `repository.getModel<Model>(parentId)` и `repository.getModels<Task>(parent.ids<Task>())` — `lib/state/task_list/task_list.dart:26-29`.
5. `Repository.getModel`/`getModels` читают из `_localStorage.getItem`/`getItems` (`IsarStorage`) — `lib/repository/repository/repository.dart:406-414, 422-431`.
6. `IsarStorage` десериализует `ModelBox.modelData` через `models[type](json)` в конкретный `Task`/`Domain`/`User` — соответствует таблице `models` в `lib/local_storage/local_storage.dart:12-16`.
7. `TaskListBloc` эмитит `TaskListState(tasks: ...)`, `BlocBuilder` в `TaskListView` перерисовывает список `TaskListTile` — `lib/ui/pages/task_list.dart:46-90`, `lib/ui/widgets/task_list_tile.dart:3-15`.

## Поток данных: запись (отметка задачи выполненной)

1. `TaskListTile.onValueChanged` вызывается из UI, страница добавляет событие `TaskCompletionRequested(task: task, isComplited: ...)` в BLoC — `lib/ui/pages/task_list.dart:65-72`.
2. `TaskListBloc._onComplited` строит `changedTask = event.task.copyWith(isCompleted: event.isComplited)` и вызывает `await repository.saveModel(changedTask)` — `lib/state/task_list/task_list.dart:42-51`.
3. `Repository.saveModel` пишет модель в `_localStorage.storeItem(model)`, ставит её в `outgoingChanges`, вызывает `_sync.postpone()` — `lib/repository/repository/repository.dart:396-404`.
4. Таймер `_sync` (класс `Timer` в `lib/repository/repository/repository.dart:33-79`) по истечении периода вызывает `_delayedSync()`.
5. `_delayedSync()` вызывает `syncWithRemoteStorage(...)` с накопленными `outgoingChanges`, которая формирует транзакции реестра (`_generateTransactions`/`_getRegistries`) и вызывает `_saveToAllRemoteStorages(remoteUpdates, ...)` — `lib/repository/repository/repository.dart:329-336, 566-634`.
6. `_saveToAllRemoteStorages` вызывает `rStorage.value.saveItems({...items, ...registries})` для каждого зарегистрированного `RemoteStorage`, то есть `FirebaseStorage.saveItems(...)` — `lib/repository/repository/repository.dart:532-539`.
7. После успешной отправки локальный `Registry` обновляется (`localRegistries = remoteRegistries`) и изменения сохраняются локально повторно — `lib/repository/repository/repository.dart:619-623`.

## Поток данных: обратная синхронизация (входящие изменения)

1. Подписка на конкретную модель регистрируется через `Repository.subscribeToSync(modelId, subscriberId)`, вызываемую из `getModel`/`getModels`/`saveModel` — `lib/repository/repository/repository.dart:362-369, 411, 427`.
2. `_delayedSync()` для всех `id` из `incomingSyncIds`, не синхронизированных в этом цикле, вызывает `_remoteStorages.values.first.getItems(idsToSync)` и сохраняет их в `_localStorage.storeItems(syncedModels)` — `lib/repository/repository/repository.dart:338-346`.
3. Для каждого такого `id` вызывается `_findAndCallListeners(id)`, который читает свежую модель через `_remoteStorages.values.first.getItem(id: id)` и вызывает подписанные `syncListeners[subscriberId]?.call(id, model)` — `lib/repository/repository/repository.dart:352-360`.
4. `ContactListBloc` — пример подписчика: его callback в `addSyncListener` при получении `User`/`Domain` добавляет событие `ContactUserSyncRequested`/`ContactDomainSyncRequested` в себя — `lib/state/contact_list/contact_list.dart:35-47`.
5. Обработчик события (`_onUserSync`/`_onDomainSync`) обновляет `ContactListState` и тем самым триггерит перерисовку `BlocBuilder<ContactListBloc, ContactListState>` в `lib/ui/pages/contact_list.dart:42-87`.
