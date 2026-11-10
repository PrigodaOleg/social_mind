# Supabase (локальная разработка)

Локальный стек Supabase используется для разработки и тестирования
`SupabaseStorage` (`lib/remote_storage/supabase.dart`).

## Запуск

```bash
supabase start
```

При первом запуске применяются миграции из `supabase/migrations/`.

## Пересоздание базы (миграции)

```bash
supabase db reset
```

Команда пересоздает базу с нуля и накатывает все миграции
(удобно после правки `0001_init.sql`).

## Подключение приложения

Приложение подключается к локальному проекту:

- URL: `http://127.0.0.1:54321`
- anon key: локальный ключ, который печатает `supabase start`
  (передается через `--dart-define=SUPABASE_ANON_KEY=...`).

## Realtime

Миграция добавляет таблицу `registries` в публикацию `supabase_realtime` —
это нужно для `SupabaseStorage.watchRegistries`.
