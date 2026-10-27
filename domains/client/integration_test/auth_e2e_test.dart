

// End-to-end auth tests against the Firebase Local Emulator Suite running on
// NATIVE platforms (iOS simulator / android emulator), driven by the
// integration_test binding:
//
//   flutter test integration_test/auth_e2e_test.dart -d <device-udid> \
//     --dart-define=RUN_EMULATOR_TESTS=true
//
// (tool/run_auth_e2e_tests.sh --platform ios does exactly this: it starts the
// emulators, boots a simulator, runs the tests and shuts everything down.)
//
// The scenarios are shared with the web runner (test/e2e/auth_e2e_test.dart) —
// the test body is platform-agnostic, it talks to the emulator over TCP.
// From the simulator/emulator "localhost" is the host machine, where the
// Firebase Local Emulator Suite (Auth :9099, Realtime Database :9000) runs.
//
// The Firebase app is registered with dummy options under the default
// instance name (see auth_e2e_scenarios.dart) — the emulators do not validate
// api keys / app ids, and Repository.tryLogin resolves the app by that name.
library auth_e2e_test;

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:closers/remote_storage/remote_storage.dart';

import '../test/e2e/auth_e2e_scenarios.dart';

Future<FirebaseApp> _initApp(String name) async {
  return Firebase.initializeApp(
    name: name,
    options: const FirebaseOptions(
      apiKey: 'test-api-key',
      appId: '1:1:ios:1',
      messagingSenderId: '1',
      projectId: project,
      databaseURL: 'http://localhost:$dbPort/?ns=$project',
    ),
  );
}

Future<void> main() async {
  // The integration test binding reports results back to the flutter tool.
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (!const bool.fromEnvironment('RUN_EMULATOR_TESTS')) {
    // Nothing to report against a plain `flutter test` run: skip silently.
    return;
  }

  // Registered under the default instance name so that
  // Repository.tryLogin / initRemoteStorages resolve it.
  final app = await _initApp(defaultInstance);
  final auth = fb_auth.FirebaseAuth.instanceFor(app: app);
  await auth.useAuthEmulator('localhost', authPort);
  final fsProbe = FirebaseStorage();
  await fsProbe.init(defaultInstance);

  runAuthE2eScenarios(
    ctx: () => AuthE2eContext(
      app: () => app,
      auth: () => auth,
      probe: () => fsProbe,
    ),
    registerTest: (description, body) => testWidgets(description, (_) => body()),
  );
}

