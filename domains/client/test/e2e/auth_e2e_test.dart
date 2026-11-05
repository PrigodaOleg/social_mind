
// End-to-end auth tests against the Firebase Local Emulator Suite
// (Auth + Realtime Database) with the PRODUCTION security rules applied
// (lib/remote_storage/firebase_realtime_database_rules.json, sanitized by
// tool/prepare_firebase_rules.py — see tool/run_auth_e2e_tests.sh).
//
// The tests exercise the same flows the UI login page drives
// (lib/ui/pages/login.dart):
//   - new user creation + login
//   - existing user login
//   - blank user login
//   - repeated login/logout cycles
//   - negative scenarios (wrong secret, empty secret, unknown user)
//
// The scenarios live in auth_e2e_scenarios.dart (shared with the native
// integration_test/auth_e2e_test.dart runner for the iOS simulator /
// android emulator — the test body is platform-agnostic, it talks to the
// emulator over TCP).
//
// Web run:
//   tool/run_auth_e2e_tests.sh
//   (== firebase emulators + flutter test --platform chrome)
@TestOn('browser')
library auth_e2e_test;

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:firebase_auth_web/firebase_auth_web.dart' as fb_auth_web;
import 'package:firebase_core_web/firebase_core_web.dart' as fb_core_web;
import 'package:firebase_database_web/firebase_database_web.dart' as fb_db_web;

import 'package:closers/remote_storage/remote_storage.dart';

import 'auth_e2e_scenarios.dart';

Future<FirebaseApp> _initApp(String name) async {
  return Firebase.initializeApp(
    name: name,
    options: const FirebaseOptions(
      apiKey: 'test-api-key',
      appId: '1:1:web:1',
      messagingSenderId: '1',
      projectId: project,
      databaseURL: 'http://localhost:$dbPort/?ns=$project',
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  if (!const bool.fromEnvironment('RUN_EMULATOR_TESTS')) {
    throw Skip('Requires Firebase emulator: '
        'flutter test --platform chrome --dart-define=RUN_EMULATOR_TESTS=true');
  }

  final registrar = Registrar();
  fb_core_web.FirebaseCoreWeb.registerWith(registrar);
  fb_auth_web.FirebaseAuthWeb.registerWith(registrar);
  fb_db_web.FirebaseDatabaseWeb.registerWith(registrar);

  late FirebaseApp app;
  late fb_auth.FirebaseAuth auth;
  // Independent probe used to poll the emulator from the tests.
  late FirebaseStorage fsProbe;

  setUpAll(() async {
    // Registered under the default instance name so that
    // Repository.tryLogin / initRemoteStorages resolve it.
    app = await _initApp(defaultInstance);
    auth = fb_auth.FirebaseAuth.instanceFor(app: app);
    await auth.useAuthEmulator('localhost', authPort);
    fsProbe = FirebaseStorage();
    await fsProbe.init(defaultInstance);
  });

  tearDownAll(() async {
    await auth.signOut();
    await app.delete();
  });

  runAuthE2eScenarios(
    ctx: () => AuthE2eContext(
      app: () => app,
      auth: () => auth,
      probe: () => fsProbe,
    ),
    registerTest: test,
  );
}
