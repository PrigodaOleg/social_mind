#!/usr/bin/env bash
# Run ALL Firebase emulator integration tests (web platform), including
# the collaboration scenario (test/integration/collaboration_emulator_test.dart).
#
# Reuses the setup from run_firebase_emulator_tests.sh: sanitizes the
# production RTDB rules, starts Auth + Database emulators, pushes the rules,
# then runs the integration test directory.
set -euo pipefail
cd "$(dirname "$0")/.."

RULES_SRC=lib/remote_storage/firebase_realtime_database_rules.json
EMULATOR_DIR=.dart_tool/firebase_emulator
PROJECT=closers-test

mkdir -p "$EMULATOR_DIR"
python3 tool/prepare_firebase_rules.py "$RULES_SRC" "$EMULATOR_DIR/rules.json"

cat > "$EMULATOR_DIR/firebase.json" <<EOF
{
  "database": {
    "rules": "rules.json"
  },
  "emulators": {
    "auth": { "port": 9099 },
    "database": { "port": 9000 },
    "hub": { "port": 4400 },
    "ui": { "enabled": false }
  }
}
EOF

(cd "$EMULATOR_DIR" && firebase emulators:start --only auth,database --project "$PROJECT" &> firebase.log &)
trap 'kill $(jobs -pr) 2>/dev/null || true' EXIT

# Wait for the emulator hub and the database emulator.
for i in $(seq 1 90); do
  if curl -s -o /dev/null "http://127.0.0.1:4400/emulators" 2>/dev/null &&
     curl -s -o /dev/null "http://127.0.0.1:9000/.info/connected.json?ns=$PROJECT" 2>/dev/null; then
    break
  fi
  sleep 1
done

# Push the production (sanitized) rules into the running emulator.
for i in $(seq 1 10); do
  if curl -s -X PUT -H "Authorization: Bearer owner" \
    "http://127.0.0.1:9000/.settings/rules.json?ns=$PROJECT" \
    -d @"$EMULATOR_DIR/rules.json"; then
    echo
    break
  fi
  sleep 2
done

flutter test --platform chrome test/integration/firebase_emulator_test.dart \
  test/integration/collaboration_emulator_test.dart \
  --dart-define=RUN_EMULATOR_TESTS=true --timeout 120s

