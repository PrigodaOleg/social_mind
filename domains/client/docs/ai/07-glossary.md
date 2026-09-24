# Глоссарий: доменные термины и их классы

## Model

- Базовая абстрактная сущность всех доменных объектов: `sealed class Model extends Equatable` — `lib/repository/models/models.dart:39`.
- Поля: `id` (генерируется `const Uuid().v4()`, если не передан), `title`, `description`, `location` (`Location`), `children`/`parents` (`Map<String, String>` — ID связанной модели → её `type`), `sync` (`SyncStatus`) — `lib/repository/models/models.dart:40-93`.
- Каждый наследник переопределяет поле `type` строкой с именем класса: `final String type = "Task"` (`lib/repository/models/task.dart:24`), `"Domain"` (`lib/repository/models/domain.dart:34`), `"User"` (`lib/repository/models/user.dart:24`).
- Сериализация — `toJson()`/`Model.fromJson(json)` — `lib/repository/models/models.dart:53-59, 95-103`; переопределяется в каждом наследнике для добавления собственных полей (`Domain.toJson()` — `lib/repository/models/domain.dart:79-86`, `Task.toJson()` — `lib/repository/models/task.dart:60-64`, `User.toJson()` — `lib/repository/models/user.dart:55-59`).
- Методы связывания моделей: `link`/`unlink` (правка `children`/`parents` in-memory), `linkTo`/`linkFrom`/`unlinkFrom` (правка связей + вызов `Repository.instance.saveModels(...)`/`deleteModel(...)`) — `lib/repository/models/models.dart:105-153`.
- Метод `ids<T>()` возвращает ID детей заданного типа `T` по совпадению с `children[k]` — `lib/repository/models/models.dart:156-158`.

## Task

- Класс `Task extends Model` — `lib/repository/models/task.dart:6`.
- Домен: единица работы пользователя (задача) в терминах AGENTS.md — «таск-менеджер».
- Поля сверх `Model`: `isCompleted` (по умолчанию `false`), `originatorId` (обязателен — автор задачи), `executorId` (по умолчанию `''` — исполнитель) — `lib/repository/models/task.dart:11-36`.
- `copyWith(...)` создаёт новый `Task` с обновлёнными полями — `lib/repository/models/task.dart:41-57`.
- В `LocalStorage.models`/`RemoteStorage.models` зарегистрирован под ключом `'Task'` для десериализации по полю `type` — `lib/local_storage/local_storage.dart:15`, `lib/remote_storage/remote_storage.dart:24`.
- Используется в `TaskListBloc` (`lib/state/task_list/task_list.dart:6`) и на странице `TaskListPage`/`TaskListView` (`lib/ui/pages/task_list.dart:11, 34`), рендерится через виджет `TaskListTile` (`lib/ui/widgets/task_list_tile.dart:3`).

## Domain

- Класс `Domain extends Model` — `lib/repository/models/domain.dart:6`.
- Домен: контейнер для совместной работы нескольких пользователей (или личное пространство при `isPersonal = true`), объединяющий задачи и участников.
- Поля сверх `Model`: `isPersonal` (по умолчанию `false`), `originatorId` (обязателен — создатель домена), `participantsIds`/`observersIds` (`List<String>` — участники/наблюдатели), `registryId` (ID связанного `Registry`), `models` (`Map<String, String>` — карта дочерних моделей) — `lib/repository/models/domain.dart:11-52`.
- `copyWith(...)` — `lib/repository/models/domain.dart:54-76`.
- Зарегистрирован под ключом `'Domain'` в `LocalStorage.models`/`RemoteStorage.models` — `lib/local_storage/local_storage.dart:13`, `lib/remote_storage/remote_storage.dart:22`.
- Используется в `DomainListBloc` (`lib/state/domain_list/domain_list.dart:6`), на страницах `DomainListPage`/`DomainListView` (`lib/ui/pages/domain_list.dart:8, 29`) и `DomainContentPage` (`lib/ui/pages/domain_content.dart:6`).

## User

- Класс `User extends Model` — `lib/repository/models/user.dart:6`.
- Домен: пользователь приложения — как локальный владелец устройства (`Repository.me`), так и запись о контакте в списке `ContactListBloc`.
- Поля сверх `Model`: `name` (обязателен), `domainsIds` (`List<String>` — домены пользователя), `registryId` (ID `Registry`), `settings`/`secrets` (`Map<String, dynamic>` — настройки и хешированные пароли удалённых хранилищ по ключу `'FirebaseRealtimeDatabase'`), `secret` (введённый пользователем секрет, хранится только в памяти) — `lib/repository/models/user.dart:9-52`.
- Переопределяет `link`/`unlink`: связь с `Domain` добавляет/убирает ID из `domainsIds`, остальные случаи делегируются в `super.link`/`super.unlink` — `lib/repository/models/user.dart:62-87`.
- `copyWith(...)` — `lib/repository/models/user.dart:89-101`.
- Зарегистрирован под ключом `'User'` в `LocalStorage.models`/`RemoteStorage.models` — `lib/local_storage/local_storage.dart:14`, `lib/remote_storage/remote_storage.dart:23`.
- `Repository.me`/`Repository.myId` — геттер/сеттер локального текущего пользователя, `Repository.me.id` хранится как отдельный ID в `LocalStorage.getUserId()`/`setUserId(...)` — `lib/repository/repository/repository.dart:454-495`.

## Registry

- Класс `Registry extends Equatable` — `lib/repository/models/registry.dart:160`.
- Домен: журнал изменений (список транзакций), привязанный к одному `Domain` или `User` через `RegistryMetadata.parentId`; используется для разрешения конфликтов при синхронизации — комментарий-описание в коде (`lib/repository/models/registry.dart:3-23`).
- Поля: `metadata` (`RegistryMetadata` — `id`/`parentId`), `transactions` (`Map<int, Transaction>`, ключ — инкрементальный индекс транзакции) — `lib/repository/models/registry.dart:170-189`.
- Геттеры `id`/`parentId` делегируют в `metadata`; `lastTransaction`/`lastTransactionIndex` берут последний элемент `transactions` — `lib/repository/models/registry.dart:211-216`.
- Методы `addNewTransaction(transaction)` (добавляет с новым инкрементальным индексом), `removeLastTransaction()`, `onlyLastTransaction()` (копия реестра с одной последней транзакцией) — `lib/repository/models/registry.dart:218-229`.
- Каждый `Domain`/`User` хранит ссылку на свой реестр в поле `registryId` — `lib/repository/models/domain.dart:48`, `lib/repository/models/user.dart:32`.
- Создаётся/читается в `Repository._generateTransactions`/`_getRegistries` через `_localStorage.getRegistry(parentId: ..., count: 1)` — `lib/repository/repository/repository.dart:649-697, 853-872`.

## Transaction

- Класс `Transaction extends Equatable` — `lib/repository/models/registry.dart:26`.
- Домен: одно консистентное изменение (создание/изменение/удаление) одной или нескольких моделей, входящее в `Registry.transactions`.
- Поля: `id`, `prevId`/`prevHash` (связь с предыдущей транзакцией в цепочке), `timeStamp`, `originatorId`, `changeDetails`, `changeType`, `changes` (`List<String>` — ID изменившихся моделей), `path` — `lib/repository/models/registry.dart:44-64`.
- Конструкторы `Transaction.zero(...)` (первая транзакция без предшественника), `Transaction.fromPrev(prev, ...)`/`Transaction.next(prev, ...)` (вычисляют `prevHash`/`prevId` от переданной предыдущей транзакции) — `lib/repository/models/registry.dart:31-42, 96-103`.
- `tHash()` — хеш содержимого транзакции через `sha256.string(jsonEncode(toJson())).hex()` (пакет `hashlib`) — `lib/repository/models/registry.dart:92-94`.
- Строится и добавляется в реестр в `Repository._generateTransactions` через `registry.addNewTransaction(Transaction.next(registry.lastTransaction, me.id, ...))` — `lib/repository/repository/repository.dart:678-687`.

## Repository

- Класс `Repository` — `lib/repository/repository/repository.dart:89`.
- Домен: фасад-координатор, единая точка доступа UI/BLoC к данным; скрывает разницу между `LocalStorage` и `RemoteStorage`, отвечает за очередь синхронизации и разрешение конфликтов.
- Статический синглтон `Repository.instance`, устанавливается в конце `init()` — `lib/repository/repository/repository.dart:90, 154`; используется моделями в `Model.linkTo`/`linkFrom`/`unlinkFrom` — `lib/repository/models/models.dart:122-153`.
- Основные операции с моделями: `getModel<T>`, `getModels<T>`, `saveModel`, `saveModels`, `deleteModel`, `getModelNow<T>` — `lib/repository/repository/repository.dart:396-442, 406-420`.
- Подписка на изменения: `addSyncListener`/`removeSyncListener`/`subscribeToSync`/`subscribeToSyncAll` — `lib/repository/repository/repository.dart:233-254, 362-376`.

## LocalStorage / RemoteStorage

- `abstract class LocalStorage` — контракт доступа к локальным данным (`init`, `getItem`, `storeItem`, `getRegistry`, `getUserId`/`setUserId`, операционные элементы) — `lib/local_storage/local_storage.dart:9`.
- `abstract class RemoteStorage` — контракт доступа к удалённому хранилищу (`init`, `auth`, `createUserAndAuth`, `getItems`, `saveItems`, `readRegistries`) — `lib/remote_storage/remote_storage.dart:18`.
- Активные реализации: `IsarStorage extends LocalStorage` (`lib/local_storage/isar/isar_storage.dart:90`), `FirebaseStorage extends RemoteStorage` (`lib/remote_storage/firebase_realtime_database.dart:8`).

## SyncStatus / Location

- `enum SyncStatus { synced, syncing, no }` — состояние синхронизации конкретного экземпляра `Model.sync` с удалённым хранилищем — `lib/repository/models/models.dart:32-36, 63`.
- `enum Location { local, remote, both }` — где физически размещена модель, поле `Model.location`, по умолчанию `Location.local` — `lib/repository/models/models.dart:17-24, 49, 85`.

## NavStackEntry

- Класс `NavStackEntry extends Equatable` — `lib/repository/navigation/navigation_stack.dart:8`.
- Домен: один элемент сохранённого стека навигации (путь маршрута + аргументы), используется для восстановления UI-состояния между запусками приложения.
- Поля: `path` (`String`), `args` (`Map<String, dynamic>`) — `lib/repository/navigation/navigation_stack.dart:14-18`.
- Хранится через `Repository.lastNavStack` → `LocalStorage.storeOpItem('lastNavStack', ...)` — `lib/repository/repository/repository.dart:508-518`.

## RebaseCollision / RemoteStorageWriteCollision

- `class RebaseCollision implements Exception` — ошибка недоступного слияния изменений в `Repository` — `lib/repository/repository/repository.dart:22`.
- `class RemoteStorageWriteCollision implements Exception` — ошибка конкурентной записи в удалённое хранилище, бросается `FirebaseStorage.saveItems` при `FirebaseException.code == 'permission-denied'` и перехватывается в `Repository.syncWithRemoteStorage` для повторного ребейза — `lib/remote_storage/remote_storage.dart:8`, `lib/remote_storage/firebase_realtime_database.dart:139-144`, `lib/repository/repository/repository.dart:624-629`.
