
#!/usr/bin/env bash
# Интерактивный запуск web-версии приложения против Firebase Local Emulator Suite.
#
# 1. Санитизирует продакшн-правила RTDB (tool/prepare_firebase_rules.py).
# 2. Запускает эмуляторы Auth + Database с этими правилами (актуальные правила).
# 3. Запускает web-версию приложения с --dart-define=CLOSERS_FIREBASE_EMULATOR=true.
#
# Тестировщик взаимодействует с приложением вручную в браузере.
#
# Режим отладки: ./tool/run_web_emulator.sh --debug
# (flutter run --debug: hot reload по клавише r, hot restart по R, DevTools URL).
set -euo pipefail
export CHROME_EXECUTABLE=${CHROME_EXECUTABLE:-/usr/bin/chromium}
cd "$(dirname "$0")/.."

RULES_SRC=lib/remote_storage/firebase_realtime_database_rules.json
EMULATOR_DIR=.dart_tool/firebase_emulator
PROJECT=closers-test
MODE=release
if [ "${1:-}" = "--debug" ]; then
  MODE=debug
fi

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
    "ui": { "enabled": true }
  }
}
EOF

(cd "$EMULATOR_DIR" && firebase emulators:start --only auth,database --project "$PROJECT" &> firebase.log &)
trap 'kill $(jobs -pr) 2>/dev/null || true' EXIT

# Ждем готовности эмуляторов.
for i in $(seq 1 90); do
  if curl -s -o /dev/null "http://127.0.0.1:4400/emulators" 2>/dev/null &&
     curl -s -o /dev/null "http://127.0.0.1:9000/.info/connected.json?ns=$PROJECT" 2>/dev/null; then
    break
  fi
  sleep 1
done

# Загружаем актуальные правила в запущенный эмулятор (CLI не умеет парсить
# оригинальный файл правил, поэтому применяем через REST-эндпоинт эмулятора).
for i in $(seq 1 10); do
  if curl -s -X PUT -H "Authorization: Bearer owner" \
    "http://127.0.0.1:9000/.settings/rules.json?ns=$PROJECT" \
    -d @"$EMULATOR_DIR/rules.json"; then
    echo
    break
  fi
  sleep 2
done

echo "Firebase emulators: auth http://localhost:9099, database http://localhost:9000 (ns=$PROJECT)"
echo "Запуск web-версии ($MODE) против эмулятора..."

if [ "$MODE" = "debug" ]; then
  flutter run -d chrome --debug \
    --dart-define=CLOSERS_FIREBASE_EMULATOR=true \
    --dart-define=CLOSERS_EMULATOR_HOST=localhost \
    --dart-define=CLOSERS_EMULATOR_AUTH_PORT=9099 \
    --dart-define=CLOSERS_EMULATOR_DB_PORT=9000
else
  flutter run -d chrome --release \
    --dart-define=CLOSERS_FIREBASE_EMULATOR=true \
    --dart-define=CLOSERS_EMULATOR_HOST=localhost \
    --dart-define=CLOSERS_EMULATOR_AUTH_PORT=9099 \
    --dart-define=CLOSERS_EMULATOR_DB_PORT=9000
fi
