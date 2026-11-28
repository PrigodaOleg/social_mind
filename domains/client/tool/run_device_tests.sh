#!/usr/bin/env bash
# Локальный «mini device farm» runner: запуск UI/интеграционных e2e-тестов
# (integration_test/*.dart) на подключённых ФИЗИЧЕСКИХ устройствах:
#   - android (USB/Wi-Fi adb: Samsung Galaxy A15 и др.) — полная поддержка;
#   - iOS (iPhone 8 через usbmuxd/flutter) — см. «iOS physical device» ниже.
#
# Экраны: устройства НЕ должны оставаться с постоянно включённым экраном.
#   - android: перед тестами будим экран (KEYCODE_WAKEUP + MENU-свайп
#     разблокировки; устройства с PIN-кодом нужно один раз разблокировать
#     вручную) и на время прогона включаем stay_on_while_plugged_in=7
#     («Stay awake» — иначе экран гаснет по таймауту и android СУСПЕНДИТ
#     приложение: тесты «did not complete»), после тестов гасим экран
#     (KEYCODE_SLEEP) и сбрасываем stay_on_while_plugged_in=0.
#   - iOS: публичного CLI-управления экраном нет (devicectl не умеет ни
#     wake, ни lock). Экран будим запуском приложения (установка/запуск из
#     Xcode/flutter выводит экран изо сна при отсутствии пароля); перед
#     первым запуском телефон нужно разблокировать вручную. После тестов
#     экран гаснет сам по таймауту автоблокировки устройства.
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
#      - ОДИН запуск ОБЕИХ e2e-сьютов через объединённый entrypoint
#        integration_test/device_farm_e2e_test.dart (--dart-define=
#        RUN_EMULATOR_TESTS=true --dart-define=E2E_EMULATOR_HOST=...,
#        --timeout 300s). Один инсталл на устройство: на iOS reinstall
#        сбрасывает доверие developer-профиля, поэтому вторая установка
#        между сьютами недопустима; pm clear больше не нужен —
#        create_buttons сбрасывает Isar сам внутри теста.
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
# Android: серийники устройств в состоянии 'device' (offline/unauthorized
# игнорируем — на них тесты всё равно не встать).
# bash 3.2 (macOS) совместимость: без mapfile/readarray (bash 4+).
DEVICES=()
while IFS= read -r d; do
  DEVICES+=("$d")
done < <("$ADB" devices | awk 'NR>1 && $2=="device" {print $1}')

# iOS physical device (flutter device id, напр. 4c81366c...). Устройство
# перечисляется через `flutter devices --machine` (devicectl не видит
# iOS 16-устройства); в ферме берём ПЕРВЫЙ ios-телефон. Требования:
# телефон подключён кабелем, разблокирован, «Доверять этому компьютеру»
# подтверждён, профиль разработчика доверенный (после этого uninstall
# делать НЕЛЬЗЯ — доверие сбросится, поэтому состояние сбрасывает сам
# тест, см. integration_test/create_buttons_e2e_test.dart).
IOS_DEVICE_ID="${IOS_DEVICE_ID:-}"
if [ -z "$IOS_DEVICE_ID" ]; then
  IOS_DEVICE_ID=$(flutter devices --machine 2>/dev/null |
    python3 -c "import json,sys;d=json.load(sys.stdin);print(next((x['id'] for x in d if x.get('targetPlatform')=='ios' and not x.get('emulator')), ''))" || true)
fi

if [ "${#DEVICES[@]}" -eq 0 ] && [ -z "$IOS_DEVICE_ID" ]; then
  echo "ERROR: no connected Android devices in state 'device' and no iOS device found." >&2
  echo "" >&2
  echo "Как подключить физическое устройство (Samsung Galaxy A15 и др.):" >&2
  echo "  1. Включите «Параметры разработчика» (7 тапов по «Номеру сборки» в «Сведения о телефоне»)." >&2
  echo "  2. Включите «Отладка по USB» (USB debugging)." >&2
  echo "  3. Подключите кабелем и подтвердите на устройстве запрос «Разрешить отладку по USB»." >&2
  echo "  4. Если устройство не видно, перезапустите adb-сервер:" >&2
  echo "       adb kill-server && adb start-server && adb devices" >&2
  exit 1
fi

# Целевое устройство(а): ANDROID_DEVICE_SERIAL ограничивает одним серийником
# (android), IOS_DEVICE_ID — одним id (iOS).
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
if [ -n "$IOS_DEVICE_ID" ]; then
  echo "  ios: $IOS_DEVICE_ID"
fi

# ------------------------------------------- функции управления экраном ----
# android wake: будим экран, свайпаем вверх (KEYCODE 82 / MENU работает как
# разблокировка БЕЗ PIN-кода; устройства с PIN-кодом нужно один раз
# разблокировать вручную — автоматической разблокировки с паролем нет) и
# включаем «Stay awake» на время прогона: без него экран гаснет по таймауту
# и android суспендит приложение под тестом (сценарии «did not complete»).
android_wake() {
  local serial="$1"
  "$ADB" -s "$serial" shell settings put global stay_on_while_plugged_in 7 || true
  "$ADB" -s "$serial" shell input keyevent KEYCODE_WAKEUP || true
  "$ADB" -s "$serial" shell input keyevent 82 || true
}

# android screen off: гасим экран после тестов (устройства не должны
# оставаться с включённым экраном).
android_screen_off() {
  local serial="$1"
  "$ADB" -s "$serial" shell input keyevent KEYCODE_SLEEP || true
}

# Сбрасываем «не гаснуть пока на зарядке» в конце android-прогона
# (android_wake ставил 7 на время тестов): 0 — дефолт, экран снова гаснет
# по таймауту устройства.
android_reset_stay_awake() {
  local serial="$1"
  "$ADB" -s "$serial" shell settings put global stay_on_while_plugged_in 0 || true
}

# ios wake: публичного wake-CLI нет НИ У devicectl, ни у ios-deploy (как и
# lock). Пытаемся будить экран ЗАПУСКОМ приложения: devicectl (iOS 17+),
# затем ios-deploy (работает и на iOS 16, где devicectl устройство вообще
# не видит). Запуск выводит iPhone изо сна ТОЛЬКО если на телефоне нет
# пароля; с паролем (или если телефон уже залочен) — нужно разблокировать
# вручную, иначе launch падает с ошибкой про trust/signature. Отказ не
# фатален: flutter test сам ставит и запускает приложение своим механизмом.
IOS_BUNDLE_ID=com.example.closers
ios_wake_by_launch() {
  local device_id="$1"
  echo "== [ios $device_id] wake attempt: launching $IOS_BUNDLE_ID =="
  if xcrun devicectl device process launch --device "$device_id" "$IOS_BUNDLE_ID" >/dev/null 2>&1; then
    echo "   (devicectl launch ok)"
    return 0
  fi
  if [ -d build/ios/iphoneos/Runner.app ]; then
    if ios-deploy --id "$device_id" --bundle build/ios/iphoneos/Runner.app \
         --justlaunch --no-wifi >/dev/null 2>&1; then
      echo "   (ios-deploy launch ok)"
      return 0
    fi
  fi
  echo "   (wake-by-launch failed — если экран iPhone залочен, разблокируйте вручную;" >&2
  echo "    CLI-управления экраном iOS не существует; flutter test попробует запустить сам)" >&2
  return 0
}

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
  # host: 0.0.0.0 — на ФИЗИЧЕСКОМ iPhone «localhost» хоста недостижим; телефон
  # стучится на IP Mac'а в общей Wi-Fi-сети (E2E_EMULATOR_HOST). android идёт
  # через adb reverse на 127.0.0.1 — ему привязка к 0.0.0.0 тоже не мешает.
  # ВАЖНО: host надо задавать КАЖДОМУ эмулятору — глобальный ключ
  # "emulators.host" firebase-tools игнорирует (15.x). Без этого эмуляторы
  # слушают только 127.0.0.1 и физический iPhone не достучится.
  cat > "$EMULATOR_DIR/firebase.json" <<EOF
{
  "database": {
    "rules": "rules.json"
  },
  "emulators": {
    "auth": { "port": $AUTH_PORT, "host": "0.0.0.0" },
    "database": { "port": $DB_PORT, "host": "0.0.0.0" },
    "hub": { "port": $HUB_PORT },
    "ui": { "enabled": false }
  }
}
EOF
  (cd "$EMULATOR_DIR" && firebase emulators:start --only auth,database --project "$PROJECT" &> firebase.log &)
  EMULATORS_OWNED=1
  trap 'pkill -f "firebase emulators:start" 2>/dev/null || true; pkill -f "firebase-database-emulator" 2>/dev/null || true' EXIT

  for i in $(seq 1 90); do
    # Готовность ОБАИХ эмуляторов: database отвечает и auth принимает
    # соединения (auth поднимается последним; без этой проверки android-тесты
    # стартуют раньше и падают "Failed to connect to 127.0.0.1:9099").
    if emulators_up &&
       curl -s -o /dev/null "http://127.0.0.1:$DB_PORT/.info/connected.json?ns=$PROJECT" 2>/dev/null &&
       curl -s -o /dev/null "http://127.0.0.1:$AUTH_PORT/" 2>/dev/null; then
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

# ----------------------------------------------------------- android loop ---
for serial in "${TARGETS[@]}"; do
  echo
  echo "============================================================"
  echo "== Device $serial: wake screen + adb reverse (emulator ports) =="
  echo "============================================================"
  # Будим экран: тесты с «спящим» экраном флаттерить нечем тапать (да и
  # wingman-требование: экраны не должны быть always-on; будим только на
  # время прогона).
  android_wake "$serial"

  # Пробрасываем порты эмуляторов на устройство. Физическое устройство не
  # имеет алиаса 10.0.2.2; тест с define E2E_EMULATOR_HOST=127.0.0.1 ходит
  # через reverse-прокси на хост.
  "$ADB" -s "$serial" reverse --remove-all >/dev/null 2>&1 || true
  "$ADB" -s "$serial" reverse "tcp:$AUTH_PORT" "tcp:$AUTH_PORT"
  "$ADB" -s "$serial" reverse "tcp:$DB_PORT" "tcp:$DB_PORT"

  # ОБА сьюта одним процессом = ОДНА установка приложения на устройство
  # (инсталл между сьютами на iOS сбросил бы доверие developer-профиля;
  # на Android это просто вдвое быстрее). create_buttons сбрасывает Isar
  # сам внутри теста, auth использует память + эмуляторы и не зависит от
  # локального состояния устройства — pm clear не нужен ни одному из них.
  rc=0
  echo "== [$serial] Running merged device-farm e2e (create_buttons + auth) =="
  flutter test integration_test/device_farm_e2e_test.dart \
    -d "$serial" \
    --dart-define=RUN_EMULATOR_TESTS=true \
    --dart-define=E2E_EMULATOR_HOST="$EMULATOR_HOST" \
    --timeout "$TEST_TIMEOUT" \
    ${extra_filter[@]+"${extra_filter[@]}"} || rc=$?

  # Чистим reverse-прокси устройства, чтобы не оставлять порты «занятыми»
  # adb-сервером между запусками.
  "$ADB" -s "$serial" reverse --remove-all >/dev/null 2>&1 || true

  # Экран OFF + сброс «Stay awake» (предыдущий запуск фермы ставил
  # stay_on_while_plugged_in=7 на A15): устройства не должны оставаться
  # с постоянно включённым экраном.
  android_screen_off "$serial"
  android_reset_stay_awake "$serial"

  if [ "$rc" -eq 0 ]; then
    PASSED+=("$serial")
    echo "== [$serial] PASSED =="
  else
    FAILED+=("$serial")
    echo "== [$serial] FAILED (rc=$rc) ==" >&2
  fi
done

# ------------------------------------------------------ iOS physical device --
# ОГРАНИЧЕНИЯ iOS (честно):
#   - wake: публичного wake-CLI нет; будим запуском приложения (работает
#     только если на телефоне НЕТ пароля — иначе нужен ручной unlock).
#   - screen off после тестов: публичного lock-CLI нет — экран гаснет сам
#     по таймауту автоблокировки телефона. not fixable from CLI.
#   - uninstall для сброса состояния НЕ применяем сознательно: reinstall
#     сбрасывает доверие developer-профиля («Untrusted Developer») и требует
#     ручного обхода Settings; состояние сбрасывает сам тест (in-test Isar
#     file reset, см. integration_test/create_buttons_e2e_test.dart).
if [ -n "$IOS_DEVICE_ID" ]; then
  echo
  echo "============================================================"
  echo "== iOS device $IOS_DEVICE_ID: wake-by-launch =="
  echo "============================================================"
  ios_wake_by_launch "$IOS_DEVICE_ID"

  # Физический iPhone не имеет алиаса хоста: до эмуляторов добирается через
  # LAN/Wi-Fi IP Mac'а (эмуляторы слушают 0.0.0.0, см. конфиг выше). Телефон и
  # Mac должны быть в ОДНОЙ Wi-Fi-сети; "localhost"/127.0.0.1 с телефона это
  # сам телефон. CLOSERS_* defines — те же, что в run_auth_e2e_tests.sh
  # (ios_emulator_defines): firebase_options.dart читает их для iOS.
  # IP Mac'а в LAN: en0 (стандартный Wi-Fi) или en1 (эта машина), можно
  # переопределить IOS_EMULATOR_HOST=<ip>.
  IOS_EMULATOR_HOST="${IOS_EMULATOR_HOST:-$(ipconfig getifaddr en0 || ipconfig getifaddr en1 || true)}"
  if [ -z "$IOS_EMULATOR_HOST" ]; then
    echo "ERROR: no en0/en1 IP (Mac not on Wi-Fi?) — физический iPhone не достучится до эмуляторов" >&2
    exit 1
  fi
  echo "== [ios] emulators host: $IOS_EMULATOR_HOST =="

  # Один инсталл на оба сьюта: reinstall на iOS сбрасывает доверие
  # developer-профиля (личный Apple ID) — запускать обе сьюты можно ТОЛЬКО
  # из одного процесса (integration_test/device_farm_e2e_test.dart).
  ios_rc=0
  echo "== [ios] Running merged device-farm e2e (create_buttons + auth) =="
  flutter test integration_test/device_farm_e2e_test.dart \
    -d "$IOS_DEVICE_ID" \
    --dart-define=RUN_EMULATOR_TESTS=true \
    --dart-define=E2E_EMULATOR_HOST="$IOS_EMULATOR_HOST" \
    --dart-define=CLOSERS_PROJECT_ID="$PROJECT" \
    --dart-define=CLOSERS_PROJECT_NUMBER=1 \
    --dart-define=CLOSERS_IOS_API_KEY=test-api-key \
    --dart-define=CLOSERS_IOS_APP_ID=1:1:ios:1 \
    --dart-define=CLOSERS_DATABASE_URL="http://$IOS_EMULATOR_HOST:$DB_PORT/?ns=$PROJECT" \
    --timeout "$TEST_TIMEOUT" \
    ${extra_filter[@]+"${extra_filter[@]}"} || ios_rc=$?

  # Screen off на iOS из CLI недоступен (нет публичного lock-API) — экран
  # гаснет сам по таймауту автоблокировки телефона.
  if [ "$ios_rc" -eq 0 ]; then
    PASSED+=("ios:$IOS_DEVICE_ID")
    echo "== [ios $IOS_DEVICE_ID] PASSED =="
  else
    FAILED+=("ios:$IOS_DEVICE_ID")
    echo "== [ios $IOS_DEVICE_ID] FAILED (rc=$ios_rc) ==" >&2
  fi
fi

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
