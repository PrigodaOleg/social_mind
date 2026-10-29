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

.PHONY:all analyze build-apk build-linux build-web clean deps format help ios ios-build ios-sync secrets setup-host test test-auth-e2e test-auth-e2e-android test-auth-e2e-android-debug test-auth-e2e-android-interactive test-auth-e2e-debug test-auth-e2e-interactive test-auth-e2e-ios test-auth-e2e-ios-debug test-auth-e2e-ios-interactive

help: ## Показать список целей
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

setup-host: ## Установить хостовый тулинг (Flutter, Android SDK, Firebase CLI и т.д.)
ifeq ($(OS),Windows_NT)
	tool/setup_host.bat
else
	tool/setup_host.sh
endif

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

test-auth-e2e: ## E2E-тесты авторизации на Firebase-эмуляторе (web, продакшн-правила)
	tool/run_auth_e2e_tests.sh

test-auth-e2e-debug: ## E2E-тесты авторизации в режиме отладки (verbose)
	tool/run_auth_e2e_tests.sh --debug

test-auth-e2e-interactive: ## Интерактивный запуск web-версии против эмулятора (ручное тестирование)
	tool/run_auth_e2e_tests.sh --interactive

test-auth-e2e-ios: ## E2E-тесты авторизации на iOS-симуляторе (macOS; Firebase-эмулятор на той же машине)
	tool/run_auth_e2e_tests.sh --platform ios

test-auth-e2e-ios-debug: ## E2E-тесты авторизации на iOS-симуляторе в режиме отладки (verbose)
	tool/run_auth_e2e_tests.sh --platform ios --debug

test-auth-e2e-ios-interactive: ## Интерактивный запуск iOS-приложения на симуляторе против эмулятора (ручное тестирование)
	tool/run_auth_e2e_tests.sh --platform ios --interactive

test-auth-e2e-android: ## E2E-тесты авторизации на android-эмуляторе (headless)
	tool/run_auth_e2e_tests.sh --platform android

test-auth-e2e-android-debug: ## E2E-тесты на android-эмуляторе в режиме отладки (verbose)
	tool/run_auth_e2e_tests.sh --platform android --debug

test-auth-e2e-android-interactive: ## Интерактивный запуск на android-эмуляторе (ручное тестирование)
	tool/run_auth_e2e_tests.sh --platform android --interactive

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
