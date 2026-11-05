-- Инициализация схемы для RemoteStorage на Supabase (lib/remote_storage/supabase.dart).
-- Применяется локально через `supabase db reset` (см. supabase/README.md).

-- Сериализованные модели (Model.toJson). Поле type внутри data позволяет
-- восстановить конкретный класс модели на клиенте.
create table if not exists models (
  id   text primary key,
  data jsonb not null
);

-- Реестры изменений: metadata + голова (last_idx, аналог lastIdx в RTDB).
-- parent_id - id родителя (пользователь или домен), используется клиентом
-- для маршрутизации реестра в хранилище по storageKey.
create table if not exists registries (
  id        text primary key,
  parent_id text,
  last_idx  bigint default -1
);

-- Транзакции реестров. Пишутся консистентно: сначала транзакция,
-- затем условный UPDATE головы по last_idx (см. SupabaseStorage._saveRegistryTransactionally).
create table if not exists registry_transactions (
  registry_id text not null references registries(id),
  idx         bigint not null,
  data        jsonb not null,
  primary key (registry_id, idx)
);

-- Произвольные json-данные по строковому пути (saveRaw/readRaw/readRawPrefix),
-- например приглашения: invitations/by-user/<userId>/<invitationId>.
create table if not exists raw_storage (
  path text primary key,
  data jsonb not null
);

-- RLS: пока политики пермиссивные (любой аутентифицированный пользователь
-- имеет полный доступ). Персональные политики (по user_id / участникам домена)
-- будут добавлены позже - см. TODO ниже.
alter table models enable row level security;
alter table registries enable row level security;
alter table registry_transactions enable row level security;
alter table raw_storage enable row level security;

-- TODO: заменить на per-user политики (auth.uid() / участники домена).
create policy "models_select_authenticated" on models
  for select to authenticated using (true);
create policy "models_insert_authenticated" on models
  for insert to authenticated with check (true);
create policy "models_update_authenticated" on models
  for update to authenticated using (true) with check (true);
create policy "models_delete_authenticated" on models
  for delete to authenticated using (true);

create policy "registries_select_authenticated" on registries
  for select to authenticated using (true);
create policy "registries_insert_authenticated" on registries
  for insert to authenticated with check (true);
create policy "registries_update_authenticated" on registries
  for update to authenticated using (true) with check (true);
create policy "registries_delete_authenticated" on registries
  for delete to authenticated using (true);

create policy "registry_transactions_select_authenticated" on registry_transactions
  for select to authenticated using (true);
create policy "registry_transactions_insert_authenticated" on registry_transactions
  for insert to authenticated with check (true);
create policy "registry_transactions_update_authenticated" on registry_transactions
  for update to authenticated using (true) with check (true);
create policy "registry_transactions_delete_authenticated" on registry_transactions
  for delete to authenticated using (true);

create policy "raw_storage_select_authenticated" on raw_storage
  for select to authenticated using (true);
create policy "raw_storage_insert_authenticated" on raw_storage
  for insert to authenticated with check (true);
create policy "raw_storage_update_authenticated" on raw_storage
  for update to authenticated using (true) with check (true);
create policy "raw_storage_delete_authenticated" on raw_storage
  for delete to authenticated using (true);

-- Realtime: подписки SupabaseStorage.watchRegistries слушают изменения таблицы
-- registries. Публикация supabase_realtime создается локальным стеком
-- автоматически, но на всякий случай оборачиваем в DO-блок с обработкой
-- исключений (публикация может не существовать).
do $$
begin
  alter publication supabase_realtime add table registries;
exception
  when duplicate_object then
    null; -- таблица уже добавлена в публикацию
  when undefined_object then
    null; -- публикация supabase_realtime не существует (realtime не включен)
end $$;
