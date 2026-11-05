#!/usr/bin/env bash
# setup_host.sh — устанавливает хостовый тулинг для разработки:
#   Flutter SDK, Android SDK, Java, git, curl, unzip, xz, cmake, ninja,
#   clang/pkg-config, Linux desktop deps, Node.js, Firebase CLI, FlutterFire CLI.
#   Также запускает flutter doctor.
#
# Поддерживаемые ОС: Linux, macOS.
# Для Windows используйте tool/setup_host.ps1.
#
# Использование:
#   ./tool/setup_host.sh           # автоопределение ОС
#   ./tool/setup_host.sh --dry-run # только показать, что будет установлено

set -euo pipefail

DRY_RUN=0
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=1
fi

info() { echo -e "\033[34m[INFO]\033[0m  $*"; }
ok()   { echo -e "\033[32m[OK]\033[0m    $*"; }
warn() { echo -e "\033[33m[WARN]\033[0m  $*"; }
err()  { echo -e "\033[31m[ERROR]\033[0m $*" >&2; }

detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux";;
    Darwin*) echo "macos";;
    *)       echo "unknown";;
  esac
}

OS=$(detect_os)

if [ "$OS" = "unknown" ]; then
  err "Скрипт запущен на неподдерживаемой ОС ($(uname -s)). Используйте tool/setup_host.ps1 для Windows."
  exit 1
fi

info "ОС: $OS"
info "Устанавливаем зависимости..."

ensure_home_bin() {
  if ! [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
    mkdir -p "$HOME/.local/bin"
    info "Добавьте в PATH: export PATH=\"\$HOME/.local/bin:\$PATH\" и перезапустите терминал."
  fi
}

install_base_linux_apt() {
  info "Обновляем apt и устанавливаем базовые пакеты..."
  sudo apt-get update
  sudo apt-get install -y \
    git curl wget unzip xz-utils \
    cmake ninja-build clang pkg-config \
    libglu1-mesa libgtk-3-dev libblkid-dev liblzma-dev \
    openjdk-21-jdk-headless
}

install_base_linux_dnf() {
  info "Устанавливаем базовые пакеты через dnf..."
  sudo dnf install -y \
    git curl wget unzip xz cmake ninja-build clang pkgconfig \
    mesa-libGLU gtk3-devel libblkid-devel xz-devel \
    java-21-openjdk-devel
}

install_base_linux_pacman() {
  info "Устанавливаем базовые пакеты через pacman..."
  sudo pacman -Syu --needed --noconfirm \
    git curl wget unzip xz cmake ninja clang pkgconf \
    glu gtk3 libblkid xz openjdk21
}

install_chrome_linux() {
  if command -v google-chrome >/dev/null 2>&1; then
    ok "google-chrome уже установлен."
    return
  fi
  if command -v chromium >/dev/null 2>&1; then
    ok "chromium уже установлен."
    return
  fi
  info "Устанавливаем Google Chrome (для flutter doctor и web-тестов)..."
  if command -v apt-get >/dev/null 2>&1; then
    curl -fsSL https://dl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
    sudo apt-get update
    sudo apt-get install -y google-chrome-stable
  elif command -v dnf >/dev/null 2>&1; then
    sudo dnf config-manager --add-repo https://dl.google.com/linux/chrome/rpm/stable/x86_64
    sudo dnf install -y google-chrome-stable
  else
    warn "Не удалось установить Chrome автоматически. Установите Google Chrome вручную."
  fi
}

install_nodejs() {
  if command -v node >/dev/null 2>&1; then
    ok "node уже установлен: $(node -v)"
    return
  fi
  info "Устанавливаем Node.js LTS через NodeSource..."
  if [ "$OS" = "macos" ]; then
    brew install node || true
  else
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    if command -v apt-get >/dev/null 2>&1; then
      sudo apt-get install -y nodejs
    elif command -v dnf >/dev/null 2>&1; then
      sudo dnf install -y nodejs
    else
      warn "Установите Node.js вручную."
    fi
  fi
}

install_firebase_cli() {
  if command -v firebase >/dev/null 2>&1; then
    ok "firebase cli уже установлен: $(firebase --version 2>&1 | head -1)"
    return
  fi
  info "Устанавливаем Firebase CLI..."
  curl -sL https://firebase.tools/bin/linux/latest -o "$HOME/.local/bin/firebase"
  chmod +x "$HOME/.local/bin/firebase"
  ok "Firebase CLI установлен."
}

install_flutterfire_cli() {
  if command -v flutterfire >/dev/null 2>&1; then
    ok "flutterfire cli уже установлен: $(flutterfire --version 2>&1 | head -1)"
    return
  fi
  info "Устанавливаем FlutterFire CLI..."
  dart pub global activate flutterfire_cli
  ok "FlutterFire CLI установлен."
}

install_flutter_linux() {
  if command -v flutter >/dev/null 2>&1; then
    ok "flutter уже установлен: $(flutter --version 2>&1 | head -1)"
    return
  fi
  info "Устанавливаем Flutter SDK в ~/flutter..."
  git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
  ok "Flutter SDK склонирован. Добавьте в PATH: export PATH=\"\$HOME/flutter/bin:\$PATH\"."
}

install_android_sdk_linux() {
  if [ -n "${ANDROID_HOME:-}" ] && [ -d "$ANDROID_HOME" ]; then
    ok "Android SDK уже настроен: $ANDROID_HOME"
    return
  fi
  info "Устанавливаем Android SDK в ~/Android/Sdk..."
  mkdir -p "$HOME/Android/Sdk/cmdline-tools"
  if [ -d "$HOME/Android/Sdk/cmdline-tools/latest" ]; then
    ok "Android SDK уже скачан."
  else
    local url="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
    local tmp_zip
    tmp_zip=$(mktemp)
    curl -fsSL "$url" -o "$tmp_zip"
    unzip -q "$tmp_zip" -d "$HOME/Android/Sdk/cmdline-tools"
    mv "$HOME/Android/Sdk/cmdline-tools/cmdline-tools" "$HOME/Android/Sdk/cmdline-tools/latest"
    rm -f "$tmp_zip"
  fi
  export ANDROID_HOME="$HOME/Android/Sdk"
  export PATH="$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
  ok "Android SDK установлен. Принимаем лицензии..."
  yes | sdkmanager --licenses >/dev/null 2>&1 || true
  ok "Android SDK готов."
}

install_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    info "Устанавливаем Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  info "Устанавливаем пакеты через brew..."
  brew install git curl wget unzip xz cmake ninja pkg-config llvm openjdk@21 node
  brew install --cask android-studio google-chrome
  if ! command -v flutter >/dev/null 2>&1; then
    brew install --cask flutter
  else
    ok "flutter уже установлен."
  fi
  # CocoaPods
  if ! command -v pod >/dev/null 2>&1; then
    info "Устанавливаем CocoaPods..."
    sudo gem install cocoapods
  fi
}

install_linux() {
  if command -v apt-get >/dev/null 2>&1; then
    install_base_linux_apt
  elif command -v dnf >/dev/null 2>&1; then
    install_base_linux_dnf
  elif command -v pacman >/dev/null 2>&1; then
    install_base_linux_pacman
  else
    err "Неизвестный пакетный менеджер Linux."
    exit 1
  fi

  install_chrome_linux
  install_flutter_linux
  install_android_sdk_linux
  install_nodejs
  install_firebase_cli
  install_flutterfire_cli
}

# --- main ---
if [ "$DRY_RUN" -eq 1 ]; then
  info "DRY RUN: будет установлено на $OS:"
  echo "  - git, curl, wget, unzip, xz"
  echo "  - cmake, ninja, clang, pkg-config"
  echo "  - Java JDK 21"
  echo "  - Flutter SDK (если не установлен)"
  echo "  - Android SDK (если не установлен)"
  echo "  - Google Chrome / Chromium"
  echo "  - Node.js + npm"
  echo "  - Firebase CLI + FlutterFire CLI"
  exit 0
fi

ensure_home_bin

case "$OS" in
  linux) install_linux ;;
  macos) install_macos ;;
esac

if command -v flutter >/dev/null 2>&1; then
  info "Запускаем flutter doctor..."
  flutter doctor
else
  warn "flutter не найден в PATH. Добавьте путь к flutter/bin в PATH и запустите flutter doctor вручную."
fi

ok "Установка хостового тулинга завершена."
