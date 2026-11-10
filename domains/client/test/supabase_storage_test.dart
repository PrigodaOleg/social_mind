// Integration tests for the Supabase schema/migration against a local
// Supabase stack (supabase/migrations/0001_init.sql).
//
// Uses the pure-dart `supabase` package (dependency of supabase_flutter),
// so no Flutter bindings are needed.
//
// Run locally with the stack up (domains/client/supabase):
//   supabase start
//   flutter test test/supabase_storage_test.dart \
//     --dart-define=SUPABASE_TEST_URL=http://127.0.0.1:54321 \
//     --dart-define=SUPABASE_TEST_SERVICE_ROLE_KEY=<key from `supabase status`>
//
// In CI (job supabase-tests in dart.yml) the stack is started with
// `supabase db start` and the keys are passed the same way. Without the
// defines the tests are skipped, so plain `flutter test` stays green.
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

const url = String.fromEnvironment('SUPABASE_TEST_URL', defaultValue: '');
const serviceRoleKey =
    String.fromEnvironment('SUPABASE_TEST_SERVICE_ROLE_KEY', defaultValue: '');

// Уникальный префикс, чтобы тесты не зависели от состояния стека и его
// можно было гонять параллельно с другими прогонами.
final runId = DateTime.now().microsecondsSinceEpoch.toRadixString(36);

void main() {
  // Без dart-define (обычный `flutter test` без локального стека) весь набор
  // skip'ается через skip-параметр группы, поэтому локальный прогон зеленый.
  final stackConfigured = url.isNotEmpty && serviceRoleKey.isNotEmpty;
  const skipReason = 'Requires local Supabase stack: '
      'flutter test --dart-define=SUPABASE_TEST_URL=... '
      '--dart-define=SUPABASE_TEST_SERVICE_ROLE_KEY=...';

  // service_role bypasses RLS - локальные политики из миграции пермиссивные
  // только для authenticated, а сервисный ключ имитирует запись "из бэкенда".
  final client = SupabaseClient(
    url.isEmpty ? 'http://127.0.0.1:54321' : url,
    serviceRoleKey.isEmpty ? 'stub' : serviceRoleKey,
  );

  /// Проверяет достижимость стека: недоступный стек -> skip (как в CI,
  /// так и локально), а не красный тест.
  Future<void> requireStack() async {
    try {
      await client.from('registries').select().limit(1).timeout(
            const Duration(seconds: 10),
          );
    } catch (e) {
      throw Skip('Local Supabase stack is not reachable at $url: $e');
    }
  }

  tearDownAll(() => client.dispose());

  group('supabase migration', skip: stackConfigured ? false : skipReason, () {
    test('migration created expected tables', () async {
      await requireStack();
      // Каждая таблица из миграции должна быть читаема без ошибок.
      await client.from('models').select().limit(1);
      await client.from('registries').select().limit(1);
      await client.from('registry_transactions').select().limit(1);
      await client.from('raw_storage').select().limit(1);
    });

    test('models: upsert and read back', () async {
      await requireStack();
      final id = 'test_model_$runId';
      final data = {'type': 'User', 'id': id, 'name': 'tester'};
      await client.from('models').upsert({'id': id, 'data': data});
      final rows = await client.from('models').select().eq('id', id).limit(1);
      expect(rows, hasLength(1));
      expect(rows.first['data'], data);
      await client.from('models').delete().eq('id', id);
      expect(
        await client.from('models').select().eq('id', id).limit(1),
        isEmpty,
      );
    });

    test('raw_storage: upsert, read, prefix scan', () async {
      await requireStack();
      final prefix = 'invitations/test/$runId/';
      await client.from('raw_storage').upsert({
        'path': '${prefix}a',
        'data': {'k': 'a'}
      });
      await client.from('raw_storage').upsert({
        'path': '${prefix}b',
        'data': {'k': 'b'}
      });

      final byPath = await client
          .from('raw_storage')
          .select()
          .eq('path', '${prefix}a')
          .limit(1);
      expect(byPath, hasLength(1));
      expect(byPath.first['data'], {'k': 'a'});

      final byPrefix =
          await client.from('raw_storage').select().gte('path', prefix);
      expect(byPrefix, hasLength(2));

      await client.from('raw_storage').delete().gte('path', prefix);
      expect(
        await client.from('raw_storage').select().gte('path', prefix),
        isEmpty,
      );
    });

    test('registry guarded head update: collision semantics', () async {
      await requireStack();
      final registryId = 'test_registry_$runId';

      // Воссоздаем последовательность SupabaseStorage._saveRegistryTransactionally:
      // 1) upsert строки головы (без last_idx), 2) идемпотентный upsert транзакции,
      // 3) условный UPDATE головы c .lt('last_idx', наш индекс).
      Future<List<dynamic>> writeHead(int idx) async {
        await client.from('registries').upsert({
          'id': registryId,
          'parent_id': 'test_parent_$runId',
        });
        await client.from('registry_transactions').upsert({
          'registry_id': registryId,
          'idx': idx,
          'data': {'id': 't\$idx', 'path': '/', 'changes': []},
        });
        return client
            .from('registries')
            .update({'last_idx': idx})
            .eq('id', registryId)
            .lt('last_idx', idx)
            .select();
      }

      // Новая голова имеет last_idx = -1, поэтому первая запись проходит.
      final firstWrite = await writeHead(1);
      expect(firstWrite, hasLength(1));

      // Читаем реестр (как SupabaseStorage.readRegistry).
      final headRows = await client
          .from('registries')
          .select()
          .eq('id', registryId)
          .limit(1);
      expect((headRows as List).first['last_idx'], 1);

      // Вторая запись: 1 < 2, апдейт проходит.
      final secondWrite = await writeHead(2);
      expect(secondWrite, hasLength(1));

      // Стеалый клиент (устаревшая голова last_idx=2) повторяет запись idx=2:
      // условие .lt('last_idx', 2) не выполняется (2 >= 2), UPDATE возвращает
      // 0 строк -> коллизия (RemoteStorageWriteCollision).
      final staleWrite = await writeHead(2);
      expect(staleWrite, isEmpty,
          reason: 'устаревшая запись должна детектироваться как коллизия');
      // Голова не изменилась.
      final head = await client
          .from('registries')
          .select()
          .eq('id', registryId)
          .limit(1);
      expect((head as List).first['last_idx'], 2);

      // Уборка.
      await client
          .from('registry_transactions')
          .delete()
          .eq('registry_id', registryId);
      await client.from('registries').delete().eq('id', registryId);
    });
  });
}
