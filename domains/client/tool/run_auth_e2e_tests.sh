#!/usr/bin/env bash
# Run the end-to-end auth tests (test/e2e/auth_e2e_test.dart on web,
# integration_test/auth_e2e_test.dart on android) against the Firebase Local
# Emulator Suite (Auth + Realtime Database) with the PRODUCTION security rules
# applied.
#
# Usage:
#   tool/run_auth_e2e_tests.sh                                # headless run on web (chrome)
#   tool/run_auth_e2e_tests.sh --debug                        # verbose test output
#   tool/run_auth_e2e_tests.sh --interactive                  # keep a web build running
#                                                             # so a human can interact
#                                                             # with the app manually
#   tool/run_auth_e2e_tests.sh --platform android             # headless run on the
#                                                             # android emulator
#   tool/run_auth_e2e_tests.sh --platform android --interactive
#                                                             # keep the app running on
#                                                             # the android emulator
#   tool/run_auth_e2e_tests.sh --platform ios                 # headless run on the iOS
#                                                             # simulator (macOS only)
#   tool/run_auth_e2e_tests.sh --platform ios --debug
#   tool/run_auth_e2e_tests.sh --platform ios --interactive
#                                                             # run the app on the iOS
#                                                             # simulator against the
#                                                             # emulators for manual
#                                                             # testing
#   tool/run_auth_e2e_tests.sh --help
#
# Android emulator notes:
#   - The script creates the AVD (closers-e2e) on first run and boots it
#     headless unless a DISPLAY is available and --headed is passed.
#   - Requires: android sdk (emulator, avdmanager, adb), system image
#     "system-images;android-34;google_apis;x86_64" (override with
#     ANDROID_SYSTEM_IMAGE), KVM/HAXM acceleration for reasonable speed.
#   - The app under test reaches the firebase emulators via 10.0.2.2 (the
#     emulator's alias of the host loopback).
#
# iOS specifics (macOS with Xcode required):
#   - the simulator is picked with --device <name> or IOS_DEVICE env var,
#     default "iPhone 16", falling back to the first available iPhone;
#   - the script boots the simulator, waits for it to finish booting, runs
#     the tests / the app, and shuts the simulator down afterwards
#     (set IOS_NO_SHUTDOWN=1 to keep it booted);
#   - the first run builds the app for the simulator (pod install may take
#     10-15 minutes);
#   - the emulators listen on the host, and "localhost" from the simulator
#     is the host, so no extra networking is needed.
#
# Extensibility: --platform selects where the app under test runs. "web",
# "android" and "ios" are implemented; usb devices (android/ios phones over
# USB) are reserved for the future — the test body is platform-agnostic
# (it talks to the emulator over TCP).
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="test"          # test | interactive
DEBUG=0
PLATFORM="web"       # web | android | ios
HEADLESS=""          # "" | --headless | --headed (android only)
IOS_DEVICE="${IOS_DEVICE:-iPhone 16}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --platform)
      [ $# -ge 2 ] || { echo "ERROR: --platform requires a value" >&2; exit 1; }
      PLATFORM="$2"; shift 2 ;;
    --device)
      [ $# -ge 2 ] || { echo "ERROR: --device requires a value" >&2; exit 1; }
      IOS_DEVICE="$2"; shift 2 ;;
    --interactive) MODE="interactive"; shift ;;
    --debug) DEBUG=1; shift ;;
    --headless) HEADLESS="--headless"; shift ;;
    --headed) HEADLESS="--headed"; shift ;;
    -h|--help)
      sed -n '2,45p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

# Android emulator settings (override via environment).
AVD_NAME="${AVD_NAME:-closers-e2e}"
ANDROID_SYSTEM_IMAGE="${ANDROID_SYSTEM_IMAGE:-system-images;android-34;google_apis;x86_64}"
ANDROID_DEVICE_PROFILE="${ANDROID_DEVICE_PROFILE:-pixel_5}"
BOOT_TIMEOUT="${BOOT_TIMEOUT:-600}"

RULES_SRC=lib/remote_storage/firebase_realtime_database_rules.json
EMULATOR_DIR=.dart_tool/firebase_emulator
PROJECT=closers-test
AUTH_PORT=9099
DB_PORT=9000

# ---------------------------------------------------------------- emulator --
mkdir -p "$EMULATOR_DIR"
python3 tool/prepare_firebase_rules.py "$RULES_SRC" "$EMULATOR_DIR/rules.json"

cat > "$EMULATOR_DIR/firebase.json" <<EOF
{
  "database": {
    "rules": "rules.json"
  },
  "emulators": {
    "auth": { "port": $AUTH_PORT },
    "database": { "port": $DB_PORT },
    "hub": { "port": 4400 },
    "ui": { "enabled": false }
  }
}
EOF

echo "== Starting Firebase emulators (auth:$AUTH_PORT, database:$DB_PORT) =="
(cd "$EMULATOR_DIR" && firebase emulators:start --only auth,database --project "$PROJECT" &> firebase.log &)
trap 'pkill -f "firebase emulators:start" 2>/dev/null || true; pkill -f "firebase-database-emulator" 2>/dev/null || true' EXIT

for i in $(seq 1 90); do
  if curl -s -o /dev/null "http://127.0.0.1:4400/emulators" 2>/dev/null &&
     curl -s -o /dev/null "http://127.0.0.1:$DB_PORT/.info/connected.json?ns=$PROJECT" 2>/dev/null; then
    break
  fi
  if [ "$i" -eq 90 ]; then
    echo "ERROR: emulators did not start" >&2
    tail -20 "$EMULATOR_DIR/firebase.log" >&2
    exit 1
  fi
  sleep 1
done

echo "== Applying production rules to the running emulator =="
for i in $(seq 1 10); do
  if curl -s -X PUT -H "Authorization: Bearer owner" \
    "http://127.0.0.1:$DB_PORT/.settings/rules.json?ns=$PROJECT" \
    -d @"$EMULATOR_DIR/rules.json" | grep -q ok; then
    echo "rules applied"
    break
  fi
  if [ "$i" -eq 10 ]; then
    echo "ERROR: could not apply rules" >&2
    exit 1
  fi
  sleep 2
done

# ------------------------------------------------------------------ targets --
run_web_tests() {
  local extra=()
  [ "$DEBUG" -eq 1 ] && extra+=(--verbose)
  flutter test --platform chrome test/e2e/auth_e2e_test.dart \
    --dart-define=RUN_EMULATOR_TESTS=true \
    --timeout 180s "${extra[@]}"
}

run_web_interactive() {
  # Run the web app pointing at the LOCAL EMULATORS (not production Firebase)
  # so a human tester can drive the login flows manually. The emulators keep
  # running while the script is alive; quit the app with 'q', then Ctrl-C
  # stops the emulators.
  #
  # The app reads its Firebase options from CLOSERS_* dart-defines
  # (lib/firebase_options.dart); override them with the emulator values.
  echo
  echo "============================================================"
  echo " Interactive mode (web app against Firebase emulators):"
  echo "   app:       http://localhost:8080/"
  echo "   emulators: auth :$AUTH_PORT, database :$DB_PORT (project $PROJECT)"
  echo "   Quit the app with 'q', then Ctrl-C here to stop emulators."
  echo "============================================================"
  local defines=(
    --dart-define=RUN_EMULATOR_TESTS=true
    --dart-define=CLOSERS_PROJECT_ID=$PROJECT
    --dart-define=CLOSERS_WEB_API_KEY=test-api-key
    --dart-define=CLOSERS_WEB_APP_ID=1:1:web:1
    --dart-define=CLOSERS_PROJECT_NUMBER=1
    --dart-define=CLOSERS_DATABASE_URL=http://localhost:$DB_PORT/?ns=$PROJECT
    --dart-define=CLOSERS_WEB_MEASUREMENT_ID=
  )
  if [ "$DEBUG" -eq 1 ]; then
    flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 \
      ${defines[@]} --verbose
  else
    flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0 \
      ${defines[@]}
  fi
}

# ------------------------------------------------------------------ ios -----
# Resolve the target simulator: exact name first, then any available iPhone.
# Prints the UDID.
resolve_ios_device() {
  local name="$1" udid=""
  # Extract the UDID (a 36-char UUID) from the device line, e.g.:
  #     iPhone 16 (XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX) (Shutdown)
  local extract_udid='grep -Eo "[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}" | head -n 1 || true'
  udid=$(xcrun simctl list devices available | awk -v name="$name" '
    $0 ~ "-- iOS" {inios=1}
    inios && index($0, name) && /Booted|Shutdown/' | eval "$extract_udid")
  if [ -z "$udid" ]; then
    # Fall back to the first available iPhone in the iOS section.
    udid=$(xcrun simctl list devices available | awk '
      $0 ~ "-- iOS" {inios=1}
      inios && /iPhone/ && /Booted|Shutdown/' | eval "$extract_udid")
  fi
  if [ -z "$udid" ]; then
    echo "ERROR: no iOS simulator found (requested: '$name')" >&2
    xcrun simctl list devices available >&2
    exit 1
  fi
  echo "$udid"
}

boot_ios_device() {
  local udid="$1"
  local state
  state=$(xcrun simctl list devices | grep "$udid" | sed -E 's/.*\((Booted|Shutdown|Creating)\).*/\1/')
  if [ "$state" != "Booted" ]; then
    echo "== Booting iOS simulator ($udid) =="
    xcrun simctl boot "$udid"
  else
    echo "== iOS simulator already booted ($udid) =="
  fi
  # Wait until the device is fully booted.
  xcrun simctl bootstatus "$udid" -b
}

shutdown_ios_device() {
  local udid="$1"
  if [ "${IOS_NO_SHUTDOWN:-0}" -eq 1 ]; then
    echo "== Keeping iOS simulator booted (IOS_NO_SHUTDOWN=1) =="
    return
  fi
  echo "== Shutting iOS simulator down ($udid) =="
  xcrun simctl shutdown "$udid" 2>/dev/null || true
}

# Dart-defines pointing the app at the LOCAL EMULATORS (not production
# Firebase). The app reads its Firebase options from CLOSERS_* dart-defines
# (lib/firebase_options.dart); on iOS the CLOSERS_IOS_* values are overridden.
ios_emulator_defines() {
  printf '%s\n' \
    --dart-define=RUN_EMULATOR_TESTS=true \
    --dart-define=CLOSERS_PROJECT_ID=$PROJECT \
    --dart-define=CLOSERS_PROJECT_NUMBER=1 \
    --dart-define=CLOSERS_IOS_API_KEY=test-api-key \
    --dart-define=CLOSERS_IOS_APP_ID=1:1:ios:1 \
    --dart-define=CLOSERS_DATABASE_URL=http://localhost:$DB_PORT/?ns=$PROJECT
}

run_ios_tests() {
  local udid extra=()
  udid=$(resolve_ios_device "$IOS_DEVICE")
  boot_ios_device "$udid"
  [ "$DEBUG" -eq 1 ] && extra+=(--verbose)
  # Полный лог приложения: нативные крэши (NSException от FIRApp/FIRDatabase)
  # не проходят через фильтр flutter-tools (sender ENDSWITH Flutter), поэтому
  # пишем ВСЁ от процесса Runner и печатаем хвост при падении.
  local app_log=.dart_tool/ios_app_log.txt
  : > "$app_log"
  xcrun simctl spawn "$udid" log stream --style compact \
    --predicate 'processImagePath ENDSWITH "Runner"' >> "$app_log" 2>&1 &
  local log_pid=$!
  # The first build for the simulator may take 10-15 minutes (pod install).
  # ${extra[@]+...} keeps this safe with `set -u` on bash 3.2 (macOS).
  #
  # flutter drive, а не `flutter test -d`: на iOS host-харнесс `flutter test`
  # завершается с "No tests were found" (exit 79), не дождавшись результатов
  # устройства, хотя все сценарии на симуляторе проходят. flutter drive +
  # integration_test_driver_extended — документированный CI-путь для iOS.
  local rc=0
  flutter drive \
    --driver=test_driver/integration_test.dart \
    --target=integration_test/auth_e2e_test.dart \
    -d "$udid" \
    --debug \
    --dart-define=RUN_EMULATOR_TESTS=true ${extra[@]+"${extra[@]}"} || rc=$?
  sleep 2
  kill "$log_pid" 2>/dev/null || true
  if [ "$rc" -ne 0 ]; then
    echo "== iOS app log (tail 120; причины нативного крэша — здесь) =="
    tail -120 "$app_log" || true
  fi
  shutdown_ios_device "$udid"
  return "$rc"
}

run_ios_interactive() {
  # Run the app on the simulator pointing at the LOCAL EMULATORS (not
  # production Firebase) so a human tester can drive the login flows manually.
  # The emulators keep running while the script is alive; quit the app with
  # 'q', then Ctrl-C stops the emulators.
  local udid
  udid=$(resolve_ios_device "$IOS_DEVICE")
  boot_ios_device "$udid"
  local defines=()
  while IFS= read -r line; do defines+=("$line"); done < <(ios_emulator_defines)
  echo
  echo "============================================================"
  echo " Interactive mode (iOS simulator against Firebase emulators):"
  echo "   device:    $IOS_DEVICE ($udid)"
  echo "   emulators: auth :$AUTH_PORT, database :$DB_PORT (project $PROJECT)"
  echo "   Quit the app with 'q', then Ctrl-C here to stop emulators."
  echo "============================================================"
  if [ "$DEBUG" -eq 1 ]; then
    flutter run -d "$udid" ${defines[@]} --verbose
  else
    flutter run -d "$udid" ${defines[@]}
  fi
  shutdown_ios_device "$udid"
}

# ------------------------------------------------------- android emulator --
# Resolve the emulator binary (ANDROID_HOME / ANDROID_SDK_ROOT / common paths).
find_android_sdk() {
  local sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
  if [ -z "$sdk" ]; then
    for candidate in "$HOME/Android/Sdk" /opt/android-sdk /usr/lib/android-sdk; do
      [ -d "$candidate" ] && sdk="$candidate" && break
    done
  fi
  echo "$sdk"
}

# Boot the AVD (creating it first if needed) and wait until it is fully up.
# Sets ANDROID_SERIAL to the adb serial of the emulator (e.g. emulator-5554).
boot_android_emulator() {
  local sdk
  sdk="$(find_android_sdk)"
  if [ -z "$sdk" ]; then
    echo "ERROR: Android SDK not found (set ANDROID_SDK_ROOT)" >&2
    exit 1
  fi
  local avdmanager="$sdk/cmdline-tools/latest/bin/avdmanager"
  local emulator="$sdk/emulator/emulator"
  local adb="$sdk/platform-tools/adb"
  [ -x "$avdmanager" ] || avdmanager="$(command -v avdmanager || true)"
  [ -x "$emulator" ] || emulator="$(command -v emulator || true)"
  [ -x "$adb" ] || adb="$(command -v adb || true)"
  for tool in "$avdmanager" "$emulator" "$adb"; do
    if [ -z "$tool" ] || [ ! -x "$tool" ]; then
      echo "ERROR: android sdk tools (avdmanager/emulator/adb) not found" >&2
      exit 1
    fi
  done

  # Create the AVD on first run.
  # ВАЖНО: avdmanager и emulator ищут AVD в разных местах, если не согласовать
  # ANDROID_AVD_HOME (реальный случай, GHA-раннер, PR #53): avdmanager кладёт
  # .ini в $HOME/.android/avd одного окружения, emulator не находит его —
  # 'Unknown AVD name'. Явно задаём общий путь.
  export ANDROID_AVD_HOME="${ANDROID_AVD_HOME:-$HOME/.android/avd}"
  mkdir -p "$ANDROID_AVD_HOME"
  if ! "$avdmanager" list avd 2>/dev/null | grep -q "Name: $AVD_NAME"; then
    echo "== Creating AVD $AVD_NAME ($ANDROID_SYSTEM_IMAGE, $ANDROID_DEVICE_PROFILE) =="
    echo no | "$avdmanager" create avd -n "$AVD_NAME" \
      -k "$ANDROID_SYSTEM_IMAGE" -d "$ANDROID_DEVICE_PROFILE" --force
  fi
  if [ ! -f "$ANDROID_AVD_HOME/$AVD_NAME.ini" ]; then
    echo "ERROR: AVD $AVD_NAME was not created at $ANDROID_AVD_HOME" >&2
    ls -la "$ANDROID_AVD_HOME" >&2 || true
    exit 1
  fi

  # Headless by default when there is no display (CI); --headed/--headless
  # override the automatic choice.
  local window_args=()
  if [ "$HEADLESS" != "--headed" ] && { [ "$HEADLESS" == "--headless" ] || [ -z "${DISPLAY:-}" ]; }; then
    window_args+=(-no-window)
  fi

  echo "== Booting android emulator (AVD $AVD_NAME) =="
  "$emulator" -avd "$AVD_NAME" \
    ${window_args[@]+"${window_args[@]}"} \
    -no-audio -no-boot-anim -no-snapshot \
    -gpu swiftshader_indirect \
    &> /tmp/closers_e2e_emulator.log &
  EMULATOR_PID=$!

  # Wait for the device to appear and finish booting.
  # ВАЖНО: wait-for-device без таймаута висит вечно, если эмулятор не
  # стартует (реальный случай: GHA-раннер, PR #53) — джоба убивается
  # timeout-minutes через 45 минут без какого-либо диагноза. Ограничиваем
  # сами и показываем лог эмулятора.
  echo "== Waiting for device (up to ${BOOT_TIMEOUT}s) =="
  "$emulator" -accel-check >&2 || true
  if ! timeout "${BOOT_TIMEOUT}" "$adb" wait-for-device; then
    echo "ERROR: android emulator did not come online within ${BOOT_TIMEOUT}s" >&2
    tail -40 /tmp/closers_e2e_emulator.log >&2
    exit 1
  fi
  local i
  for i in $(seq 1 "$BOOT_TIMEOUT"); do
    if [ "$("$adb" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; then
      break
    fi
    if ! kill -0 "$EMULATOR_PID" 2>/dev/null; then
      echo "ERROR: android emulator exited during boot" >&2
      tail -30 /tmp/closers_e2e_emulator.log >&2
      exit 1
    fi
    if [ "$i" -eq "$BOOT_TIMEOUT" ]; then
      echo "ERROR: android emulator did not boot within ${BOOT_TIMEOUT}s" >&2
      tail -30 /tmp/closers_e2e_emulator.log >&2
      exit 1
    fi
    sleep 1
  done
  ANDROID_SERIAL="$("$adb" devices | grep -E '^emulator-' | awk '{print $1}' | head -n 1)"
  echo "emulator booted: $ANDROID_SERIAL"
}

shutdown_android_emulator() {
  local sdk
  sdk="$(find_android_sdk)"
  local adb="${sdk}/platform-tools/adb"
  [ -x "$adb" ] || adb="$(command -v adb || true)"
  if [ -n "${ANDROID_SERIAL:-}" ] && [ -n "$adb" ] && [ -x "$adb" ]; then
    "$adb" -s "$ANDROID_SERIAL" emu kill 2>/dev/null || true
  fi
  if [ -n "${EMULATOR_PID:-}" ]; then
    kill "$EMULATOR_PID" 2>/dev/null || true
  fi
}

run_android_tests() {
  boot_android_emulator
  trap 'shutdown_android_emulator; pkill -f "firebase emulators:start" 2>/dev/null || true; pkill -f "firebase-database-emulator" 2>/dev/null || true' EXIT

  local extra=()
  [ "$DEBUG" -eq 1 ] && extra+=(--verbose)
  echo "== Running e2e tests on android emulator ($ANDROID_SERIAL) =="
  flutter test integration_test/auth_e2e_test.dart \
    -d "$ANDROID_SERIAL" \
    --dart-define=RUN_EMULATOR_TESTS=true \
    --timeout 300s ${extra[@]+"${extra[@]}"}
}

run_android_interactive() {
  boot_android_emulator
  trap 'shutdown_android_emulator; pkill -f "firebase emulators:start" 2>/dev/null || true; pkill -f "firebase-database-emulator" 2>/dev/null || true' EXIT

  # Run the app on the emulator pointing at the LOCAL EMULATORS (not
  # production Firebase) so a human tester can drive the login flows manually.
  # Quit the app with 'q' in the flutter console; the trap then stops the
  # emulator and the firebase emulators.
  echo
  echo "============================================================"
  echo " Interactive mode (android emulator against Firebase emulators):"
  echo "   device:    $ANDROID_SERIAL (AVD $AVD_NAME)"
  echo "   emulators: auth :$AUTH_PORT, database :$DB_PORT (project $PROJECT)"
  echo "   The app reaches them via 10.0.2.2 (host loopback alias)."
  echo "   Quit the app with 'q', then the emulator and emulators stop."
  echo "============================================================"
  local defines=(
    --dart-define=RUN_EMULATOR_TESTS=true
    --dart-define=CLOSERS_PROJECT_ID=$PROJECT
    --dart-define=CLOSERS_ANDROID_API_KEY=test-api-key
    --dart-define=CLOSERS_ANDROID_APP_ID=1:1:android:1
    --dart-define=CLOSERS_PROJECT_NUMBER=1
    --dart-define=CLOSERS_DATABASE_URL=http://10.0.2.2:$DB_PORT/?ns=$PROJECT
  )
  if [ "$DEBUG" -eq 1 ]; then
    flutter run -d "$ANDROID_SERIAL" ${defines[@]} --verbose
  else
    flutter run -d "$ANDROID_SERIAL" ${defines[@]}
  fi
}

run_android_usb() {
  echo "ERROR: physical android device (usb) target is reserved for future work" >&2
  exit 2
}

run_ios_usb() {
  echo "ERROR: physical ios device (usb) target is reserved for future work" >&2
  exit 2
}

case "$PLATFORM:$MODE" in
  web:test)        run_web_tests ;;
  web:interactive) run_web_interactive ;;
  android:test)    run_android_tests ;;
  android:interactive) run_android_interactive ;;
  ios:test)        run_ios_tests ;;
  ios:interactive) run_ios_interactive ;;
  android-usb:test)    run_android_usb ;;
  ios-usb:test)        run_ios_usb ;;
  *) echo "ERROR: platform '$PLATFORM' does not support mode '$MODE'" >&2; exit 2 ;;
esac
