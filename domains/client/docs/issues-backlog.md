# GitHub issues для реализации плана (создать командами `gh issue create` после установки gh CLI)

Каждый блок ниже - отдельный issue. Порядок = порядок реализации.

---

## Issue 1: [repo] Маршрутизация удаленных хранилищ по storageKey (фаза 1)

**Status: РЕАЛИЗОВАНО** (см. `lib/repository/repository/repository.dart`, `lib/repository/models/domain.dart`, `lib/repository/models/user.dart`)

Поле `storageKey` на Domain/User, маршрутизация `_saveToAllRemoteStorages`/`_getFromAllRemoteStorages`/`readRegistries` по хранилищу родителя, фолбэк на первое подключенное хранилище для старых данных. Тесты: `test/collaboration_test.dart` (group `Repository storage routing`).

Остаток: полноценная страница настроек хранилищ (подключение/отключение/выбор при создании домена в UI) - сейчас подключение выполняется через настройки пользователя и автоматически при принятии приглашения.

---

## Issue 2: [repo] Firestore и Supabase реализации RemoteStorage (фаза 1)

**Status: РЕАЛИЗОВАНО** (см. `lib/remote_storage/cloud_firestore.dart`, `lib/remote_storage/supabase.dart`)

Полный контракт включая `watchRegistries`, collision-семантика (Firestore transaction по lastIdx, Supabase условный UPDATE). Требуется: миграции БД для Supabase (таблицы models/registries/registry_transactions/raw_storage), parity-тесты collision на реальных инстансах (эмуляторы), настройка SUPABASE_ANON_KEY.

---

## Issue 3: [repo] Реалтайм: подписка на реестры + быстрая отправка (фаза 2)

**Status: РЕАЛИЗОВАНО** (см. `Repository.watchRegistries/onRemoteRegistryChange/updateRegistryWatches`, `saveModel(..., immediate)`)

Подписка только на `registries/<id>/lastIdx`, по событиям дочитываются изменившиеся модели, сохраняются в Isar и уведомляются sync-слушатели блоков. Немедленная отправка важных изменений.

Остаток: интеграционный сценарий «два пользователя» на реальном/эмуляторном Firebase.

---

## Issue 4: [repo] Модель Invitation и сервис знакомства/приглашений (фаза 3)

**Status: РЕАЛИЗОВАНО** (см. `lib/repository/models/invitation.dart`, `lib/repository/repository/invitations.dart`)

Знакомство: QR инициатора → ответное приглашение в `invitations/by-user/<userId>` → создание домена на двоих + контакты. Приглашение в домен: `invitations/<id>`, консенсус через `approvals` с кворумом «все участники», авто-подключение и регистрация в хранилище домена при принятии. Тесты: `test/collaboration_test.dart`.

Остаток: сканирование QR камерой (сейчас - вставка данных QR в поле), deep link по invitationId, security rules для путей invitations.

---

## Issue 5: [repo] Пуши: firebase_messaging + локальные уведомления + правила (фаза 4)

**Status: ЧАСТИЧНО РЕАЛИЗОВАНО** (см. `lib/notifications/push_notification_service.dart`, `lib/state/notifications/notifications.dart`, `lib/ui/pages/notifications.dart`)

Есть: локальные уведомления на всех платформах, FCM на android/ios/macos, токены в `push_tokens/<userId>/<deviceId>`, правила `{eventTypes, actorIds, sourceDomainIds, minPriority, action}` локально, грубая выгрузка в `notification_rules/<userId>`, дефолтные правила (приглашения и назначения задач). События task_assigned/task_detected обнаруживаются при обработке входящих транзакций.

Остаток: Cloud Function / отправитель-скрипт для офлайн-доставки, публикация правил при старте, UI настройки правил подробнее, интеграция NotificationsBloc в корень приложения.

---

## Issue 6: [repo] Инфраструктура Supabase: миграции и CI

Создать SQL-миграции таблиц: `models(id text primary key, data jsonb)`, `registries(id text primary key, parent_id text, last_idx int)`, `registry_transactions(registry_id text, idx int, data jsonb, primary key(registry_id, idx))`, `raw_storage(path text primary key, data jsonb)`. RLS-политики: запись только аутентифицированным владельцем модели/домена. Добавить parity-тесты collision-записи реестров в CI.

---

## Issue 7: [repo] Deep links для приглашений

Настроить app links (android) / universal links (iOS) для открытия приглашения по `invitationId` из QR/ссылки. Роут `/invitations/<id>` в `lib/app.dart`. presently приглашение передается только вставкой данных QR.
