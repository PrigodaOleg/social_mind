
#!/usr/bin/env bash
# Run the end-to-end auth tests (test/e2e/auth_e2e_test.dart on web,
# integration_test/auth_e2e_test.dart on native platforms) against the
# Firebase Local Emulator Suite (Auth + Realtime Database) with the PRODUCTION
# security rules applied.
#
# Usage:
#   tool/run_auth_e2e_tests.sh                     # headless run on web (chrome)
#   tool/run_auth_e2e_tests.sh --debug             # verbose test output
#   tool/run_auth_e2e_tests.sh --interactive       # keep a web build running
#                                                  # so a human can interact
#                                                  # with the app manually
#   tool/run_auth_e2e_tests.sh --platform ios      # headless run on the iOS
#                                                  # simulator (macOS only)
#   tool/run_auth_e2e_tests.sh --platform ios --debug
#   tool/run_auth_e2e_tests.sh --platform ios --interactive
#                                                  # run the app on the iOS
#                                                  # simulator against the
#                                                  # emulators for manual
#                                                  # testing
#   tool/run_auth_e2e_tests.sh --help
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
# Extensibility: --platform selects where the app under test runs. "web" and
# "ios" are implemented; "android" (android emulator) and usb devices
# (android/ios phones over USB) are reserved for the future — the test body
# is platform-agnostic (it talks to the emulator over TCP).
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="test"          # test | interactive
DEBUG=0
PLATFORM="web"       # web | android | ios (android/usb reserved)
IOS_DEVICE="${IOS_DEVICE:-iPhone 16}"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interactive) MODE="interactive"; shift ;;
    --debug) DEBUG=1; shift ;;
    --platform)
      [ $# -ge 2 ] || { echo "ERROR: --platform requires a value" >&2; exit 1; }
      PLATFORM="$2"; shift 2 ;;
    --device)
      [ $# -ge 2 ] || { echo "ERROR: --device requires a value" >&2; exit 1; }
      IOS_DEVICE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,45p' "$0"; exit 0 ;;
    *) echo "Unknown option: $1" >&2; exit 1 ;;
  esac
done

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

# ------------------------------------------------------------------ ios -----
# Resolve the target simulator: exact name first, then any available iPhone.
# Prints the UDID.
resolve_ios_device() {
  local name="$1" udid=""
  udid=$(xcrun simctl list devices available | awk -v name="$name" '
    $0 ~ "-- iOS" {inios=1}
    inios && index($0, name) && /Booted|Shutdown/ {print $NF; exit}')
  if [ -z "$udid" ]; then
    # Fall back to the first available iPhone in the iOS section.
    udid=$(xcrun simctl list devices available | awk '
      $0 ~ "-- iOS" {inios=1}
      inios && /iPhone/ && /Booted|Shutdown/ {print $NF; exit}')
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
  # The first build for the simulator may take 10-15 minutes (pod install).
  # ${extra[@]+...} keeps this safe with `set -u` on bash 3.2 (macOS).
  flutter test integration_test/auth_e2e_test.dart -d "$udid" \
    --dart-define=RUN_EMULATOR_TESTS=true \
    --timeout 180s ${extra[@]+"${extra[@]}"}
  shutdown_ios_device "$udid"
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

# ------------------------------------------------------------------ targets --
run_web_tests() {
  local extra=()
  [ "$DEBUG" -eq 1 ] && extra+=(--verbose)
  # ${extra[@]+...} keeps this safe with `set -u` on bash 3.2 (macOS).
  flutter test --platform chrome test/e2e/auth_e2e_test.dart \
    --dart-define=RUN_EMULATOR_TESTS=true \
    --timeout 180s ${extra[@]+"${extra[@]}"}
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

run_android() {
  echo "ERROR: android emulator target is reserved for future work" >&2
  exit 2
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
  ios:test)        run_ios_tests ;;
  ios:interactive) run_ios_interactive ;;
  android:test)    run_android ;;
  android-usb:test)    run_android_usb ;;
  ios-usb:test)        run_ios_usb ;;
  *) echo "ERROR: platform '$PLATFORM' does not support mode '$MODE'" >&2; exit 2 ;;
esac
