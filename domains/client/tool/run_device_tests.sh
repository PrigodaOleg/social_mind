#!/usr/bin/env bash
# Локальный «mini device farm» runner: запуск UI/интеграционных e2e-тестов
# (integration_test/*.dart) на всех ПОДКЛЮЧЁННЫХ ФИЗИЧЕСКИХ android-устройствах
# (USB/Wi-Fi adb: Samsung Galaxy A15 сейчас, другие позже).
#
# Чем отличается от tool/run_auth_e2e_tests.sh --platform android:
#   - там всегда создаётся и загружается эмулятор (AVD closers-e2e);
#   - здесь эмулятор НЕ создаётся: гоняем на реальных устройствах, которые
#     уже подключены к хосту (основа для будущего local test farm на каждый PR).
#
# Что делает:
#   1. Находит adb (ANDROID_HOME/ANDROID_SDK_ROOT/PATH) и перечисляет
#      подключённые устройства: `adb devices`, состояние 'device'.
#      Нет устройств -> печатает инструкцию (USB debugging, adb kill-server/
#      start-server) и выходит с кодом 1.
#   2. ANDROID_DEVICE_SERIAL=<serial> — гоняет только на указанном устройстве;
#      иначе — последовательно на всех подключённых.
#   3. Поднимает Firebase-эмуляторы (auth + database), если ещё не запущены:
#      переиспользуем логику tool/run_auth_e2e_tests.sh — тот же набор правил
#      (python3 tool/prepare_firebase_rules.py), тот же firebase.json, тот же
#      project 'closers-test' и порты (auth 9099, database 9000, hub 4400).
#      Если эмуляторы УЖЕ подняты (hub 4400 отвечает) — не трогаем их.
#      Запущенные нами эмуляторы останавливаются через trap EXIT.
#   4. Для каждого устройства:
#      - `adb reverse` пробрасывает порты эмуляторов на устройство (физическое
#        устройство, в отличие от эмулятора, НЕ имеет алиаса 10.0.2.2 —
#        поэтому тест получает хост 'localhost' через
#        --dart-define=E2E_EMULATOR_HOST, см. integration_test/auth_e2e_test.dart);
#      - `flutter test integration_test/auth_e2e_test.dart -d <serial>` с теми
#        же параметрами, что и CI-джоба e2e-android (--dart-define=
#        RUN_EMULATOR_TESTS=true, --timeout 300s);
#      - `adb shell pm clear com.example.closers` + create_buttons_e2e_test
#        (как в CI: тесту нужен чистый локальный Isar -> экран логина).
#      Результат (pass/fail) собирается по каждому устройству.
#   5. FILTER=<plain-name> — передаётся во flutter test как --plain-name
#      (запуск одного сценария вместо всего набора).
#
# Код выхода: 0 — все устройства прошли; 1 — нет устройств/не поднялись
# эмуляторы/ошибка окружения; 2 — хотя бы одно устройство провалилось.
#
# Usage:
#   tool/run_device_tests.sh                      # все подключённые устройства
#   ANDROID_DEVICE_SERIAL=R58Nxxxx tool/run_device_tests.sh   # одно устройство
#   FILTER="new user" tool/run_device_tests.sh    # один сценарий по --plain-name
#   FLUTTER_TEST_TIMEOUT=600s tool/run_device_tests.sh        # свой таймаут
set -euo pipefail
cd "$(dirname "$0")/.."

# ------------------------------------------------------------- окружение ----
# adb: как в run_auth_e2e_tests.sh (find_android_sdk), с фолбэком на PATH.
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

# Java для firebase-эмуляторов: на macOS без установленного JDK используем
# JBR из Android Studio (эмулятору database нужна Java VM). /usr/bin/java на
# macOS — это заглушка: она есть, но падает, поэтому проверяем работоспособность.
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
  echo "Установите Android SDK platform-tools (или задайте ANDROID_SDK_ROOT)," >&2
  echo "например: brew install --cask android-platform-tools" >&2
  exit 1
fi

# ------------------------------------------------------------- устройства ---
# Список серийников устройств в состоянии 'device' (offline/unauthorized
# игнорируем — на них тесты всё равно не встать).
# bash 3.2 (macOS) совместимость: без mapfile/readarray (bash 4+).
DEVICES=()
while IFS= read -r d; do
  DEVICES+=("$d")
done < <("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')

if [ "${#DEVICES[@]}" -eq 0 ]; then
  echo "ERROR: no connected Android devices in state 'device'." >&2
  echo "" >&2
  echo "Как подключить физическое устройство (Samsung Galaxy A15 и др.):" >&2
  echo "  1. Включите «Параметры разработчика» (7 тапов по «Номеру сборки» в «Сведения о телефоне»)." >&2
  echo "  2. Включите «Отладка по USB» (USB debugging)." >&2
  echo "  3. Подключите кабелем и подтвердите на устройстве запрос «Разрешить отладку по USB»." >&2
  echo "  4. Если устройство не видно, перезапустите adb-сервер:" >&2
  echo "       adb kill-server && adb start-server && adb devices" >&2
  exit 1
fi

# Целевое устройство(а): ANDROID_DEVICE_SERIAL ограничивает одним серийником.
TARGETS=()
if [ -n "${ANDROID_DEVICE_SERIAL:-}" ]; then
  found=0
  for d in "${DEVICES[@]}"; do
    if [ "$d" = "$ANDROID_DEVICE_SERIAL" ]; then TARGETS+=("$d"); found=1; break; fi
  done
  if [ "$found" -ne 1 ]; then
    echo "ERROR: device '$ANDROID_DEVICE_SERIAL' not found among connected:" >&2
    printf '  %s\n' "${DEVICES[@]}" >&2
    exit 1
  fi
else
  TARGETS=("${DEVICES[@]}")
fi

echo "== Connected devices (targets) =="
printf '  %s\n' "${TARGETS[@]}"

# ----------------------------------------------- Firebase-эмуляторы ---------
# Та же конфигурация, что в run_auth_e2e_tests.sh / run_emulator_tests.sh.
RULES_SRC=database/database.rules.json
EMULATOR_DIR=.dart_tool/firebase_emulator
PROJECT=closers-test
AUTH_PORT=9099
DB_PORT=9000
HUB_PORT=4400

EMULATORS_OWNED=0   # 1 — эмуляторы подняты этим скриптом (останавливаем в trap)

emulators_up() {
  curl -s -o /dev/null "http://127.0.0.1:$HUB_PORT/emulators" 2>/dev/null
}

if emulators_up; then
  echo "== Firebase emulators already running (hub :$HUB_PORT) — reusing =="
else
  echo "== Starting Firebase emulators (auth:$AUTH_PORT, database:$DB_PORT) =="
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
    "hub": { "port": $HUB_PORT },
    "ui": { "enabled": false }
  }
}
EOF
  (cd "$EMULATOR_DIR" && firebase emulators:start --only auth,database --project "$PROJECT" &> firebase.log &)
  EMULATORS_OWNED=1
  trap 'pkill -f "firebase emulators:start" 2>/dev/null || true; pkill -f "firebase-database-emulator" 2>/dev/null || true' EXIT

  for i in $(seq 1 90); do
    if emulators_up &&
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
fi

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

# ------------------------------------------------------------- запуск -------
# Хост эмуляторов с устройства: порты проброшены adb reverse -> loopback.
# (На эмуляторе тест по умолчанию берёт 10.0.2.2; физическому устройству
# нужен явный define — см. integration_test/auth_e2e_test.dart.)
# ВАЖНО: именно 127.0.0.1, а не "localhost" — нативный firebase-android-sdk
# молча подменяет хост "localhost" на 10.0.2.2 (алиас эмулятора), который
# на физическом устройстве недостижим -> firebase_auth/network-request-failed.
EMULATOR_HOST=127.0.0.1
TEST_TIMEOUT="${FLUTTER_TEST_TIMEOUT:-300s}"

# Фильтр сценариев: FILTER -> --plain-name (пустой FILTER — без фильтра).
extra_filter=()
if [ -n "${FILTER:-}" ]; then
  extra_filter+=(--plain-name "$FILTER")
fi

FAILED=()
PASSED=()

for serial in "${TARGETS[@]}"; do
  echo
  echo "============================================================"
  echo "== Device $serial: adb reverse (emulator ports) =="
  echo "============================================================"
  # Пробрасываем порты эмуляторов на устройство. Физическое устройство не
  # имеет алиаса 10.0.2.2; тест с define E2E_EMULATOR_HOST=127.0.0.1 ходит
  # через reverse-прокси на хост.
  "$ADB" -s "$serial" reverse --remove-all >/dev/null 2>&1 || true
  "$ADB" -s "$serial" reverse "tcp:$AUTH_PORT" "tcp:$AUTH_PORT"
  "$ADB" -s "$serial" reverse "tcp:$DB_PORT" "tcp:$DB_PORT"

  rc=0
  echo "== [$serial] Running auth e2e tests =="
  flutter test integration_test/auth_e2e_test.dart \
    -d "$serial" \
    --dart-define=RUN_EMULATOR_TESTS=true \
    --dart-define=E2E_EMULATOR_HOST="$EMULATOR_HOST" \
    --timeout "$TEST_TIMEOUT" \
    ${extra_filter[@]+"${extra_filter[@]}"} || rc=$?

  # create_buttons_e2e_test требует чистого состояния приложения (пустой Isar
  # -> экран логина), как и в CI: сначала pm clear, затем тест. Firebase ему
  # не нужен, но reverse не мешает.
  if [ "$rc" -eq 0 ] && [ -z "${FILTER:-}" ]; then
    echo "== [$serial] Running create-buttons e2e tests =="
    "$ADB" -s "$serial" shell pm clear com.example.closers || true
    flutter test integration_test/create_buttons_e2e_test.dart \
      -d "$serial" \
      --timeout "$TEST_TIMEOUT" \
      ${extra_filter[@]+"${extra_filter[@]}"} || rc=$?
  fi

  # Чистим reverse-прокси устройства, чтобы не оставлять порты «занятыми»
  # adb-сервером между запусками.
  "$ADB" -s "$serial" reverse --remove-all >/dev/null 2>&1 || true

  if [ "$rc" -eq 0 ]; then
    PASSED+=("$serial")
    echo "== [$serial] PASSED =="
  else
    FAILED+=("$serial")
    echo "== [$serial] FAILED (rc=$rc) ==" >&2
  fi
done

echo
echo "============================================================"
echo "== Device farm summary =="
echo "============================================================"
echo "passed: ${#PASSED[@]} ${PASSED[*]:-}"
echo "failed: ${#FAILED[@]} ${FAILED[*]:-}"

if [ "${#FAILED[@]}" -ne 0 ]; then
  echo "ERROR: tests failed on devices: ${FAILED[*]}" >&2
  exit 2
fi
echo "All devices passed."
