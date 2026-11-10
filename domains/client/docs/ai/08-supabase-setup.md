# Настройка облачного проекта Supabase

Инструкция по созданию облачного проекта Supabase для `SupabaseStorage`
(`lib/remote_storage/supabase.dart`). Локальный стек для разработки описан
в `docs/ai/05-build.md` («Supabase (локальный стек)») и `supabase/README.md`.

## Что ожидает код (проверить перед настройкой)

- Таблицы `models`, `registries`, `registry_transactions`, `raw_storage` — их создает миграция `supabase/migrations/0001_init.sql` (`:6-34`).
- Realtime: подписки `SupabaseStorage.watchRegistries` слушают изменения таблицы `registries` через публикацию `supabase_realtime` — `lib/remote_storage/supabase.dart:245-270`.
- RLS: все операции требуют роль `authenticated` — приложение логинится через `client.auth.signUp`/`signInWithPassword` (`lib/remote_storage/supabase.dart:66-82`); неаутентифицированный клиент получит отказ политикой (код `42501` — `lib/remote_storage/supabase.dart:137-141`).
- `init(instance)` принимает URL проекта вида `https://<ref>.supabase.co`: только `https`, без credentials в URL, host не пуст — валидация в `lib/remote_storage/supabase.dart:29-45`.
- Anon key берется из аргумента `anonKey` (настройки `remote_storages.<key>.anon_key`) или из `--dart-define=SUPABASE_ANON_KEY` — `lib/remote_storage/supabase.dart:46-53`.

## Создание проекта

1. supabase.com → New project.
2. Регион — ближайший к большинству пользователей.
3. Пароль базы данных — надежный и сохраненный в менеджер паролей (он нужен для прямого подключения к Postgres; самому приложению он не передается).
4. Authentication → Sign In / Providers → Email: отключить «Confirm email». Приложение регистрирует пользователей с синтетическим email `<userId>@a.aa` (`lib/remote_storage/supabase.dart:67`), и с включенным подтверждением новые пользователи не смогут войти.

## Применение миграции

Способ 1 — SQL Editor (dashboard, без установки CLI):

1. Dashboard проекта → SQL Editor → New query.
2. Вставить содержимое `supabase/migrations/0001_init.sql` и выполнить (Run).

Способ 2 — CLI:

```
supabase login
supabase link --project-ref <project-ref>
supabase db push
```

`<project-ref>` — из URL проекта: `https://supabase.com/dashboard/project/<ref>`.

Проверка после применения:

- Table Editor — видны 4 таблицы: `models`, `registries`, `registry_transactions`, `raw_storage`.
- Database → Publications → `supabase_realtime` — в списке таблиц есть `registries` (добавляется DO-блоком в `supabase/migrations/0001_init.sql:85-93`).
- Authentication → Users — после первого входа из приложения появляется пользователь с email вида `<userId>@a.aa`.

## Ключи

Источник: Project Settings → API.

- Legacy anon key (`eyJ...`) — публичный клиентский ключ; safe для встраивания в приложение: права ограничены RLS-политиками.
- Publishable key (`sb_publishable_...`) — новая замена anon-ключа; поддерживается свежими версиями `supabase-dart`/`supabase_flutter` (в проекте `supabase_flutter: ^2.18.3` — `pubspec.yaml:52`). Проверка на текущей версии не проводилась: если с publishable-ключом auth/realtime отдают 401 — использовать legacy anon key. Надежный вариант по умолчанию — legacy anon key.
- `service_role` key обходит RLS — не встраивать в приложение и не передавать как `SUPABASE_ANON_KEY`.

## Подключение приложения

URL проекта из `--dart-define` не читается — `instance` берется из настроек пользователя (`remote_storages.<key>.instance` — `lib/repository/repository/repository.dart:350-363`). Anon key — из настроек `remote_storages.<key>.anon_key` либо из окружения (`lib/remote_storage/supabase.dart:46-53`).

Вариант A — `--dart-define` (для `tryLogin` обязателен: он вызывает `init(instance)` без аргумента `anonKey` — `lib/repository/repository/repository.dart:415`):

```
flutter run -d chrome --dart-define-from-file=.env
```

с `SUPABASE_ANON_KEY=...` в `.env` (механизм `--dart-define-from-file` — см. `docs/ai/05-build.md`).

Вариант B — настройки пользователя: `remote_storages.Supabase.instance` (https-URL проекта) и `remote_storages.Supabase.anon_key`. Эти записи также создаются при подключении хранилища по приглашению с подтверждением пользователя — `lib/repository/repository/invitations.dart:279-311`.

## Realtime

Включен через публикацию `supabase_realtime` (миграция добавляет туда `registries`) — отключать в Database → Publications нельзя, иначе `watchRegistries` перестанет получать события.

Лимиты Free tier (примерные, проверьте актуальные на supabase.com/pricing): до 500 одновременных клиентов Realtime и до 2 млн сообщений в месяц. Для небольшой группы пользователей этого достаточно; превышение — повод переходить на Pro.

## Безопасность

- Текущие RLS-политики пермиссивные: полный доступ любому аутентифицированному пользователю всех 4 таблиц — `supabase/migrations/0001_init.sql:36-79`. TODO: заменить на per-user политики (`auth.uid()` / участники домена) — `supabase/migrations/0001_init.sql:44`.
- Включить MFA у владельца проекта (Account → безопасность аккаунта Supabase) — облачный проект управляется одним аккаунтом.
- Бэкапы: автоматический Point-in-time recovery доступен на плане Pro (на Free — только ежедневные бэкапы ограниченного срока хранения; проверьте актуальные условия).

## Стоимость

- Free tier (примерные цифры, проверьте актуальные): 2 проекта, ~500 MB базы, ~50k MAU Auth, ~2 млн сообщений Realtime/мес, пауза неактивного проекта через неделю.
- Pro (~$25/мес за проект): ~8 GB базы, ~100k MAU, без автопаузы, бэкапы дольше, опция Point-in-time recovery. Нужен при росте объема данных, числа пользователей или требованиях к бэкапам.
