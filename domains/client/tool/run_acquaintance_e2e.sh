#!/usr/bin/env bash
# Двухфизический e2e-тест знакомства (QR через камеру) и синхронизации данных
# через общий домен: integration_test/acquaintance_e2e_test.dart.
#
# ВАЖНО: нужны РОВНО ДВА подключенных Android-устройства:
#   - AYya T1  (initiator — показывает QR; экран на максимальной яркости,
#               stay awake на время прогона);
#   - Samsung Galaxy A15 (scanner — сканирует камерой QR с экрана AYya).
# Роли назначаются переменными INITIATOR_SERIAL / SCANNER_SERIAL (по умолчанию
# определяется автоматически: AYya — по префиксу 'YY' серийника, A15 — по
# 'R58X'). Оба устройства должны быть в состоянии 'device' (AYya — через
# Wi-Fi TLS-пару, см. AGENTS/docs: adb-YY210621002776-...._adb-tls-connect).
#
# Что делает скрипт (зеркало tool/run_device_tests.sh):
#   1. Поднимает Firebase-эмуляторы (auth:9099, db:9000, ns closers-test),
#      если ещё не запущены (та же схема, что в run_device_tests.sh).
#   2. adb reverse портов эмуляторов на ОБА устройства.
#   3. Заранее выдаёт разрешение CAMERA на сканере (иначе mobile_scanner
#      молча показывает заглушку «нет разрешения»).
#   4. Max brightness + stay awake на инициативном устройстве (QR должен
#      читаться камерой A15 с расстояния; stay awake — android суспендит
#      приложение под тестом при погасшем экране).
#   5. Запускает ОДИН общий APK (сборка один раз) на обоих устройствах
#      параллельно: роли зашиты в разные entrypoint-файлы
#      (integration_test/acquaintance_e2e_initiator_test.dart /
#      acquaintance_e2e_scanner_test.dart; dart-define-роль нельзя — оба
#      процесса делят kernel-кэш и получают одну и ту же роль), общий runId
#      (метка времени) через E2E_RUN_ID.
#   6. Гасит экраны, сбрасывает brightness/stay-awake, чистит reverse.
#
# Использование:
#   tool/run_acquaintance_e2e.sh                    # авто-детект двух устройств
#   INITIATOR_SERIAL=YY210621002776 SCANNER_SERIAL=R58X6110Q7W tool/run_acquaintance_e2e.sh
#   FLUTTER_TEST_TIMEOUT=900s tool/run_acquaintance_e2e.sh
set -euo pipefail
cd "$(dirname "$0")/.."

# ------------------------------------------------------------- окружение ----
find_adb() {
  local sdk="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-}}"
  local candidates=(
    "${sdk:+$sdk/platform-tools/adb}"
    "$HOME/Library/Android/sdk/platform-tools/adb"
    "$HOME/Android/Sdk/platform-tools/adb"
    /opt/android-sdk/platform-tools/adb
    /usr/lib/android-sdk/platform-tools/adb
  )
  local c
  for c in "${candidates[@]}"; do
    [ -n "$c" ] && [ -x "$c" ] && { echo "$c"; return; }
  done
  command -v adb || true
}

if ! java -version >/dev/null 2>&1; then
  for jh in \
    "/Applications/Android Studio.app/Contents/jbr/Contents/Home" \
    "$HOME/Library/Java/JavaVirtualMachines"/*/Contents/Home \
    /Library/Java/JavaVirtualMachines/*/Contents/Home; do
    if [ -x "$jh/bin/java" ]; then
      export JAVA_HOME="$jh"
      export PATH="$JAVA_HOME/bin:$PATH"
      break
    fi
  done
fi

ADB="$(find_adb)"
if [ -z "$ADB" ]; then
  echo "ERROR: adb not found." >&2
  exit 1
fi

# ------------------------------------------------------------- устройства ---
# Ровно два устройства в состоянии 'device'.
DEVICES=()
while IFS= read -r d; do
  DEVICES+=("$d")
done < <("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')

if [ "${#DEVICES[@]}" -lt 2 ]; then
  echo "ERROR: need exactly 2 connected Android devices (initiator + scanner), found ${#DEVICES[@]}:" >&2
  printf '  %s\n' "${DEVICES[@]}" >&2
  echo "" >&2
  echo "AYya T1 подключается по Wi-Fi TLS: после pairing он виден как" >&2
  echo "adb-YY210621002776-..._adb-tls-connect._tcp (adb devices)." >&2
  exit 1
fi

# Назначение ролей: INITIATOR_SERIAL/SCANNER_SERIAL, иначе по префиксу.
INITIATOR_SERIAL="${INITIATOR_SERIAL:-}"
SCANNER_SERIAL="${SCANNER_SERIAL:-}"
if [ -z "$INITIATOR_SERIAL" ] || [ -z "$SCANNER_SERIAL" ]; then
  for d in "${DEVICES[@]}"; do
    case "$d" in
      # AYya T1: серийник YY210621002776; по Wi-Fi TLS adb видит его как
      # 'adb-YY210621002776-..._adb-tls-connect._tcp' — поэтому *YY*, не YY*.
      *YY*) [ -z "$INITIATOR_SERIAL" ] && INITIATOR_SERIAL="$d" ;;
      *)    [ -z "$SCANNER_SERIAL" ]   && SCANNER_SERIAL="$d" ;;
    esac
  done
fi
if [ -z "$INITIATOR_SERIAL" ] || [ -z "$SCANNER_SERIAL" ]; then
  echo "ERROR: could not assign roles. Set INITIATOR_SERIAL and SCANNER_SERIAL." >&2
  printf '  devices: %s\n' "${DEVICES[@]}" >&2
  exit 1
fi
echo "== Initiator (QR on screen): $INITIATOR_SERIAL =="
echo "== Scanner  (camera):        $SCANNER_SERIAL =="

# ----------------------------------------------- Firebase-эмуляторы ---------
RULES_SRC=database/database.rules.json
EMULATOR_DIR=.dart_tool/firebase_emulator
PROJECT=closers-test
AUTH_PORT=9099
DB_PORT=9000
HUB_PORT=4400

EMULATORS_OWNED=0
emulators_up() {
  curl -s -o /dev/null "http://127.0.0.1:$HUB_PORT/emulators" 2>/dev/null
}

if emulators_up; then
  echo "== Firebase emulators already running =="
else
  echo "== Starting Firebase emulators (auth:$AUTH_PORT db:$DB_PORT, project $PROJECT) =="
  mkdir -p "$EMULATOR_DIR"
  python3 tool/prepare_firebase_rules.py "$RULES_SRC" "$EMULATOR_DIR/rules.json"
  (
    cd "$EMULATOR_DIR"
    firebase emulators:start --only auth,database --project "$PROJECT" \
      >emulator.log 2>&1 &
  )
  EMULATORS_OWNED=1
  for i in $(seq 1 60); do
    if curl -s -o /dev/null "http://127.0.0.1:$HUB_PORT/emulators" 2>/dev/null; then break; fi
    sleep 1
  done
  if ! emulators_up; then
    echo "ERROR: firebase emulators failed to start (see $EMULATOR_DIR/emulator.log)" >&2
    exit 1
  fi
fi

cleanup() {
  for serial in "$INITIATOR_SERIAL" "$SCANNER_SERIAL"; do
    "$ADB" -s "$serial" shell settings put global stay_on_while_plugged_in 0 >/dev/null 2>&1 || true
    "$ADB" -s "$serial" reverse --remove-all >/dev/null 2>&1 || true
    # Гасим экран (KEYCODE_SLEEP) — устройства не должны оставаться с
    # включённым экраном (как в run_device_tests.sh).
    "$ADB" -s "$serial" shell input keyevent KEYCODE_SLEEP >/dev/null 2>&1 || true
  done
  # Возвращаем яркость инициативного экрана.
  if [ -n "${INIT_BRIGHTNESS:-}" ]; then
    "$ADB" -s "$INITIATOR_SERIAL" shell settings put system screen_brightness "$INIT_BRIGHTNESS" >/dev/null 2>&1 || true
  fi
  if [ "$EMULATORS_OWNED" -eq 1 ]; then
    echo "== Stopping firebase emulators =="
    pkill -f 'firebase emulators' >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

# Применяем правила БД (после старта эмулятора).
curl -s -X PUT -H "Authorization: Bearer owner" \
  "http://127.0.0.1:$DB_PORT/.settings/rules.json?ns=$PROJECT" \
  -d @"$EMULATOR_DIR/rules.json" >/dev/null

# --------------------------------------------------- подготовка устройств ---
# Force-stop: осиротевший процесс прошлого прогона мог остаться с открытой
# камерой — новое приложение тогда не сможет её захватить.
APPLICATION_ID=com.example.closers
for serial in "$INITIATOR_SERIAL" "$SCANNER_SERIAL"; do
  "$ADB" -s "$serial" shell am force-stop "$APPLICATION_ID" >/dev/null 2>&1 || true
done

# Запоминаем текущую яркость инициативного экрана, чтобы вернуть после прогона.
INIT_BRIGHTNESS=$("$ADB" -s "$INITIATOR_SERIAL" shell settings get system screen_brightness | tr -d '\r')
echo "== Initiator current brightness: $INIT_BRIGHTNESS =="

# wake: будим экран и свайпаем вверх (KEYCODE 82/MENU разблокирует БЕЗ PIN;
# устройства с PIN-кодом нужно один раз разблокировать вручную) + stay awake
# на время прогона (иначе экран гаснет и android суспендит приложение).
for serial in "$INITIATOR_SERIAL" "$SCANNER_SERIAL"; do
  "$ADB" -s "$serial" shell settings put global stay_on_while_plugged_in 7 || true
  "$ADB" -s "$serial" shell input keyevent KEYCODE_WAKEUP || true
  "$ADB" -s "$serial" shell input keyevent 82 || true
  "$ADB" -s "$serial" reverse --remove-all >/dev/null 2>&1 || true
  "$ADB" -s "$serial" reverse "tcp:$AUTH_PORT" "tcp:$AUTH_PORT"
  "$ADB" -s "$serial" reverse "tcp:$DB_PORT" "tcp:$DB_PORT"
done
# Max brightness только на инициативном экране (QR должен читаться камерой).
"$ADB" -s "$INITIATOR_SERIAL" shell settings put system screen_brightness 255 || true

# ------------------------------------------------------------- запуск -------
EMULATOR_HOST=127.0.0.1
RUN_ID="$(date +%s)"
TEST_TIMEOUT="${FLUTTER_TEST_TIMEOUT:-900s}"

# Запуск как в run_device_tests.sh: flutter test сам собирает, ставит и
# запускает тест на устройстве (опции --use-application-binary у
# `flutter test` нет — это опция flutter drive). Роль и runId — через
# --dart-define, они запекаются в kernel конкретного прогона.
echo "== Running initiator on $INITIATOR_SERIAL and scanner on $SCANNER_SERIAL (run $RUN_ID) =="

run_role() {
  local entrypoint="$1" serial="$2" log="$3"
  flutter test "$entrypoint" \
    -d "$serial" \
    --dart-define=E2E_RUN_ID="$RUN_ID" \
    --dart-define=E2E_EMULATOR_HOST="$EMULATOR_HOST" \
    --timeout "$TEST_TIMEOUT" >"$log" 2>&1
}

INIT_LOG=.dart_tool/acquaintance_initiator.log
SCAN_LOG=.dart_tool/acquaintance_scanner.log
rm -f "$INIT_LOG" "$SCAN_LOG"

# CAMERA-грант на сканере: flutter test ставит APK сам, и установка может
# сбросить runtime-разрешения (системный диалог никто не нажмёт — тест
# упадёт). Грант идемпотентен, поэтому крутим его фоном каждые 2 секунды всё
# время прогона: как только приложение установлено, разрешение уже выдано.
(
  for i in $(seq 1 450); do
    "$ADB" -s "$SCANNER_SERIAL" shell pm grant "$APPLICATION_ID" android.permission.CAMERA >/dev/null 2>&1 || true
    sleep 2
  done
) &
CAMERA_PID=$!

# Запуск со сдвигом: сначала инициатор (его gradle-сборка + установка),
# сканер стартует, когда инициатор дошел до 'Installing' — иначе два
# параллельных flutter-процесса делят один build/ и adb-server (был случай
# зависания установки). Роли — в разных entrypoint-файлах (dart-define-роль
# перезаписывала общий kernel: оба устройства получали роль scanner).
run_role integration_test/acquaintance_e2e_initiator_test.dart \
  "$INITIATOR_SERIAL" "$INIT_LOG" &
INIT_PID=$!

for i in $(seq 1 120); do
  grep -q 'Installing' "$INIT_LOG" 2>/dev/null && break
  if ! kill -0 "$INIT_PID" 2>/dev/null; then break; fi
  sleep 1
done

run_role integration_test/acquaintance_e2e_scanner_test.dart \
  "$SCANNER_SERIAL" "$SCAN_LOG" &
SCAN_PID=$!

INIT_RC=0
SCAN_RC=0
wait "$INIT_PID" || INIT_RC=$?
wait "$SCAN_PID" || SCAN_RC=$?

echo
echo "== initiator log (tail) =="; tail -n 20 "$INIT_LOG" || true
echo
echo "== scanner log (tail) =="; tail -n 20 "$SCAN_LOG" || true

if [ "$INIT_RC" -ne 0 ] || [ "$SCAN_RC" -ne 0 ]; then
  echo "ERROR: acquaintance e2e FAILED (initiator rc=$INIT_RC, scanner rc=$SCAN_RC)" >&2
  echo "Full logs: $INIT_LOG, $SCAN_LOG" >&2
  exit 2
fi
echo "Acquaintance e2e PASSED (run $RUN_ID)."
