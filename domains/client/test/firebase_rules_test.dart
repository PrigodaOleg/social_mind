
// Unit tests for the Firebase RTDB rules file.
//
// The production rules file
// (lib/remote_storage/firebase_realtime_database_rules.json) contains
// // comments and literal newlines inside string values, which the Firebase
// CLI and the RTDB emulator cannot parse (the emulator silently falls back to
// fully permissive rules in that case). tool/prepare_firebase_rules.py
// produces a sanitized strict-JSON copy. These tests make sure the sanitized
// rules stay parseable and keep the invariants the client relies on, so that
// deploying them (see tool/check_rules_backward_compatibility.py and the
// firebase-rules-compat CI job) cannot silently break the app.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  // Directory.current is the package root (domains/client) when running
  // `flutter test`.
  final rulesFile = File(
      'lib/remote_storage/firebase_realtime_database_rules.json');
  final prepareScript = File('tool/prepare_firebase_rules.py');

  // tool/prepare_firebase_rules.py prints a status line to stdout, so the
  // sanitized output is written to a temp file instead of /dev/stdout.
  final tmpDir = Directory.systemTemp.createTempSync('firebase_rules_test');
  final sanitizedPath = '${tmpDir.path}/rules.json';
  tearDownAll(() {
    tmpDir.deleteSync(recursive: true);
  });

  ProcessResult runSanitize() => Process.runSync('python3', [
        prepareScript.path,
        rulesFile.path,
        sanitizedPath,
      ]);

  test('rules file exists', () {
    expect(rulesFile.existsSync(), isTrue,
        reason: 'rules file must exist at '
            'lib/remote_storage/firebase_realtime_database_rules.json');
    expect(prepareScript.existsSync(), isTrue,
        reason: 'tool/prepare_firebase_rules.py must exist');
  });

  test('sanitized rules are valid JSON with a top-level "rules" node', () {
    final sanitized = runSanitize();
    expect(sanitized.exitCode, 0,
        reason: 'prepare_firebase_rules.py must succeed: '
            '${sanitized.stderr}');
    final decoded = jsonDecode(File(sanitizedPath).readAsStringSync())
        as Map<String, dynamic>;
    expect(decoded, contains('rules'));
    final rules = decoded['rules'] as Map<String, dynamic>;
    expect(rules, isNotEmpty);
  });

  test('sanitized rules keep the client-critical nodes and invariants', () {
    final sanitized = runSanitize();
    expect(sanitized.exitCode, 0, reason: 'sanitize must succeed');
    final rules = (jsonDecode(File(sanitizedPath).readAsStringSync())
        as Map<String, dynamic>)['rules'] as Map<String, dynamic>;

    // The client reads/writes these paths (see
    // lib/remote_storage/firebase_realtime_database.dart).
    for (final node in ['models', 'registries']) {
      expect(rules.keys, contains(node),
          reason: 'rules must cover the "$node" subtree');
    }
    final registries = rules['registries'] as Map<String, dynamic>;
    expect(registries.keys, contains('\$rid'),
        reason: 'registries must be parameterized by \$rid');
    final rid = registries['\$rid'] as Map<String, dynamic>;
    expect(rid.keys, contains('transactions'),
        reason: 'registries/\$rid must contain transactions');

    // Transactions are sequential: $tidx must be validated against the
    // registry's lastIdx counter (the client's transaction log protocol).
    final transactions = rid['transactions'] as Map<String, dynamic>;
    expect(transactions.keys, contains('\$tidx'),
        reason: 'transactions must be parameterized by \$tidx');
    final tidx = transactions['\$tidx'] as Map<String, dynamic>;
    final validate = tidx['.validate'].toString();
    expect(validate, contains('lastIdx'),
        reason: 'transaction validation must reference the registry lastIdx '
            'counter');

    // Models belong to a registry and are created through the transaction
    // log (changes/$mid must exist in the referenced transaction).
    final models = rules['models'] as Map<String, dynamic>;
    expect(models.keys, contains('\$mid'),
        reason: 'models must be parameterized by \$mid');
    final modelsValidate =
        (models['\$mid'] as Map<String, dynamic>)['.validate'].toString();
    expect(modelsValidate, contains('registryId'),
        reason: 'model validation must tie the model to a registry');
    expect(modelsValidate, contains('transactions'),
        reason: 'model validation must require the creating transaction to '
            'exist in the registry log');

    // Auth is enforced for every write: the root .validate requires an
    // authenticated user (see the root rule in the rules file).
    final rootValidate = rules['.validate'];
    expect(rootValidate, isNotNull, reason: 'root .validate rule must exist');
    expect(rootValidate.toString(), contains('auth'),
        reason: 'root .validate must depend on auth');
  });
}
