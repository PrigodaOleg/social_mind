// Merged device-farm entrypoint: runs BOTH e2e suites in ONE process
// (ONE app install per device run):
//   1. create_buttons_e2e_test  — offline UI flows on the real IsarStorage;
//   2. auth_e2e_test            — Repository auth flows against the Firebase
//                                 emulators (Auth + Realtime Database).
//
// WHY one entrypoint: a personal (free) Apple developer profile resets the
// "Trust this developer" setting on EVERY uninstall+reinstall, so each extra
// `flutter test integration_test/...` invocation on a physical iPhone costs a
// manual Settings round-trip. testWidgets only REGISTERS tests with the global
// binding; the runner executes everything registered after main() completes —
// so calling both suite mains sequentially in one file works and both suites
// run under a single install.
//
// ORDER (create_buttons FIRST, then auth) — safe by construction:
//   - create_buttons starts with resetIsarFiles() (deletes the Isar files).
//     At that point NO Isar instance is open in this process: the suite runs
//     before anything opened Isar (auth uses MemoryLocalStorage and never
//     touches Isar; the app's main.dart does not run under `flutter test
//     integration_test/...`). Deleting files with no open instance cannot
//     corrupt anything on any platform. IsarStorage has no close() API, so an
//     auth-first order would not change this (Isar would still be closed at
//     reset time) — create-first is kept as the canonical documented order.
//   - auth_e2e_test is fully self-sufficient: every scenario creates its own
//     users on the emulator (uuid names, safe to re-run), local state lives in
//     MemoryLocalStorage, and it makes NO assumptions about a clean device —
//     whatever create_buttons left in Isar is irrelevant to it.
//   - Note: auth.main() sets binding.framePolicy = fullyLive during merged
//     main(), before any test executes — create_buttons therefore runs under
//     fullyLive here (the recommended integration-test policy) instead of its
//     standalone default; its pumps/taps are policy-agnostic.
//
// Run (ONE install, both suites):
//   flutter test integration_test/device_farm_e2e_test.dart -d <device> \
//     --dart-define=RUN_EMULATOR_TESTS=true \
//     --dart-define=E2E_EMULATOR_HOST=<host> --timeout 900s
// (create_buttons ignores the defines harmlessly; RUN_EMULATOR_TESTS is not a
// guard in either suite — tests are registered unconditionally, see
// auth_e2e_test.dart for why.)
import 'auth_e2e_test.dart' as auth;
import 'create_buttons_e2e_test.dart' as create;

void main() {
  // Registration order == execution order: offline UI suite first (it resets
  // its own Isar state), emulator-backed auth suite second.
  create.main();
  auth.main();
}
