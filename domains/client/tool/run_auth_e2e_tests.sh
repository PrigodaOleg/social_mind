
#!/usr/bin/env bash
# Run the end-to-end auth tests (test/e2e/auth_e2e_test.dart) against the
# Firebase Local Emulator Suite (Auth + Realtime Database) with the PRODUCTION
# security rules applied.
#
# Usage:
#   tool/run_auth_e2e_tests.sh                     # headless run on web (chrome)
#   tool/run_auth_e2e_tests.sh --debug             # verbose test output
#   tool/run_auth_e2e_tests.sh --interactive       # keep a web build running
#                                                  # so a human can interact
#                                                  # with the app manually
#   tool/run_auth_e2e_tests.sh --help
#
# Extensibility: --platform selects where the app under test runs. Only "web"
# is implemented today; "android" (android emulator), "ios" (ios simulator) and
# usb devices (android/ios phones over USB) are reserved for the future — the
# test body is platform-agnostic (it talks to the emulator over TCP).
set -euo pipefail
cd "$(dirname "$0")/.."

MODE="test"          # test | interactive
DEBUG=0
PLATFORM="web"       # web | android | ios (android/ios reserved)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --interactive) MODE="interactive" ;;
    --debug) DEBUG=1 ;;
    --platform) shift; PLATFORM="$1" ;;
    -h|--help)
      sed -n '2,25p' "$0"; exit 0 ;;
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

run_android() {
  echo "ERROR: android emulator target is reserved for future work" >&2
  exit 2
}

run_ios() {
  echo "ERROR: ios simulator target is reserved for future work" >&2
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
  android:test)    run_android ;;
  ios:test)        run_ios ;;
  android-usb:test)    run_android_usb ;;
  ios-usb:test)        run_ios_usb ;;
  *) echo "ERROR: platform '$PLATFORM' does not support mode '$MODE'" >&2; exit 2 ;;
esac
