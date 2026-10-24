# Makefile для Flutter-приложения "Closers" (/workspace/social_mind/domains/client)

# Секреты сборки (KEY=VALUE) — НЕ коммитить, содержимое не показывать
BUILD_ENV_FILE ?= /tmp/pw-secrets/build.env
GOOGLE_SERVICES_SRC ?= /tmp/pw-secrets/google-services.json

# iMac (macOS) для iOS-сборки
IMAC_HOST ?= pwworker@192.168.88.19
IMAC_KEY ?= /tmp/pw-imac-key
IMAC_DIR ?= /Users/pwworker/personal_worker/client

SSH_OPTS := -i $(IMAC_KEY) -o StrictHostKeyChecking=accept-new

# Преобразуем KEY=VALUE из build.env в аргументы --dart-define
DART_DEFINES := $(shell [ -f "$(BUILD_ENV_FILE)" ] && sed -E 's/^([A-Za-z_][A-Za-z0-9_]*)=(.*)$$/--dart-define \1=\2/' $(BUILD_ENV_FILE))

.PHONY: help deps secrets analyze format test test-e2e run-web-emulator run-web-emulator-debug build-linux build-web build-apk ios-sync ios-build ios all clean \
        test-e2e-android-emulator test-e2e-ios-simulator test-e2e-android-usb test-e2e-ios-usb

help: ## Показать список целей
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

deps: ## Установить зависимости (flutter pub get)
	flutter pub get

format: ## Форматирование кода
	dart format .

analyze: ## Статический анализ
	flutter analyze

secrets: ## Скопировать google-services.json в android/app/ (если его там нет)
	@if [ ! -f android/app/google-services.json ]; then \
		if [ -f "$(GOOGLE_SERVICES_SRC)" ]; then \
			install -m 600 "$(GOOGLE_SERVICES_SRC)" android/app/google-services.json; \
			echo "google-services.json скопирован"; \
		else \
			echo "WARNING: $(GOOGLE_SERVICES_SRC) не найден"; \
		fi; \
	else \
		echo "android/app/google-services.json уже существует"; \
	fi


test: ## Запустить тесты
	flutter test

# --- E2E-тесты авторизации (Firebase Local Emulator Suite) ---

# Запуск e2e-тестов на web-версии: поднимает эмуляторы (auth + database) с
# актуальными правилами из lib/remote_storage/firebase_realtime_database_rules.json
# и гоняет test/e2e + test/integration на chrome.
test-e2e: ## E2E-тесты авторизации на web (Firebase emulator, актуальные правила)
	./tool/run_firebase_emulator_tests.sh

# Интерактивный запуск web-версии против эмулятора: тестировщик взаимодействует
# с приложением вручную (эмуляторы auth+database с актуальными правилами).
run-web-emulator: ## Интерактивный запуск web-версии против Firebase emulator
	./tool/run_web_emulator.sh

# То же, но в режиме отладки (flutter run --debug, hot reload/restart, DevTools).
run-web-emulator-debug: ## Интерактивный запуск web-версии против Firebase emulator в режиме отладки
	./tool/run_web_emulator.sh --debug

# --- Задел на будущее: android emulator / ios simulator / usb-устройства ---
# Требуют установленных Android SDK / Xcode. Реализуются по аналогии с web:
# эмуляторы Firebase поднимает run_firebase_emulator_tests.sh (или вручную),
# приложение собирается с --dart-define=CLOSERS_FIREBASE_EMULATOR=true.

test-e2e-android-emulator: ## (задел) E2E на android emulator
	@echo "TODO: запустите android emulator (flutter emulators --launch <id>), затем:"; \
	echo "  firebase emulators:start --only auth,database --project closers-test"; \
	echo "  flutter run --dart-define=CLOSERS_FIREBASE_EMULATOR=true -d <emulator-id>"; \
	echo "  flutter test integration_test -d <emulator-id> --dart-define=CLOSERS_FIREBASE_EMULATOR=true"

test-e2e-ios-simulator: ## (задел) E2E на ios simulator (только macOS)
	@echo "TODO: только на macOS: xcrun simctl boot, затем flutter run/test -d <simulator-id> --dart-define=CLOSERS_FIREBASE_EMULATOR=true"

test-e2e-android-usb: ## (задел) E2E на реальном android-устройстве по USB
	@echo "TODO: подключите устройство (adb devices), затем flutter run/test -d <usb-id> --dart-define=CLOSERS_FIREBASE_EMULATOR=true (эмулятор Firebase - на хосте, используйте adb reverse tcp:9099 tcp:9099 и adb reverse tcp:9000 tcp:9000)"

test-e2e-ios-usb: ## (задел) E2E на реальном ios-устройстве по USB (только macOS)
	@echo "TODO: только на macOS: подключите устройство, flutter run/test -d <usb-id> --dart-define=CLOSERS_FIREBASE_EMULATOR=true"

rules-compat-check: ## Проверка обратной совместимости Firebase RTDB правил (эмулятор; old = origin/main)
	python3 tool/check_rules_backward_compatibility.py --base origin/main

build-linux: ## Сборка под Linux
	flutter build linux

build-web: ## Сборка web (release) с dart-define из build.env
	flutter build web --release --base-href /social_mind/ $(DART_DEFINES)

build-apk: ## Сборка APK (release, split-per-abi) с dart-define из build.env
	flutter build apk --release --split-per-abi $(DART_DEFINES)

ios-sync: ## Скопировать проект на iMac (без build-артефактов)
	tar -C . --exclude=build --exclude=.dart_tool -cf - . | \
		ssh $(SSH_OPTS) $(IMAC_HOST) 'mkdir -p $(IMAC_DIR) && tar -xf - -C $(IMAC_DIR)'

ios-build: ## iOS-сборка на iMac (без подписи). ВНИМАНИЕ: тесты на iMac не запускать — isar_plus на macOS тестах падает из-за отсутствия нативного символа
	ssh $(SSH_OPTS) $(IMAC_HOST) 'cd $(IMAC_DIR) && flutter build ios --release --no-codesign'

ios: ios-sync ios-build ## iOS: копирование + сборка на iMac

all: deps secrets test build-linux build-web build-apk ios ## Полный цикл проверок и сборок

clean: ## Очистить артефакты сборки
	flutter clean
