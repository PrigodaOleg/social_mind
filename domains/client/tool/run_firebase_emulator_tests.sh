

#!/usr/bin/env bash
# Run the Firebase emulator integration tests (web platform).
#
# 1. Sanitizes the production RTDB rules (see prepare_firebase_rules.py).
# 2. Starts the Auth + Database emulators with the sanitized rules.
# 3. Pushes the rules to the running Database emulator (the CLI cannot parse
#    the original rules file, so the rules are applied via the emulator's
#    settings REST endpoint).
# 4. Runs flutter test on chrome with RUN_EMULATOR_TESTS=true.
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
  --dart-define=RUN_EMULATOR_TESTS=true --timeout 120s

