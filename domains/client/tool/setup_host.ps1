
# setup_host.ps1 — устанавливает хостовый тулинг для разработки на Windows:
#   Flutter SDK, Android SDK, Java, git, Node.js, Chrome, Firebase CLI,
#   FlutterFire CLI, Visual Studio Build Tools.
#   Также запускает flutter doctor.
#
# Запуск из PowerShell (Run as Administrator):
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#   .\tool\setup_host.ps1

param(
    [switch]$DryRun
)

function Info { param([string]$msg) Write-Host "[INFO]  $msg" -ForegroundColor Cyan }
function Ok    { param([string]$msg) Write-Host "[OK]    $msg" -ForegroundColor Green }
function Warn  { param([string]$msg) Write-Host "[WARN]  $msg" -ForegroundColor Yellow }
function Err   { param([string]$msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

$ErrorActionPreference = "Stop"

function Test-Command {
    param([string]$cmd)
    $null -ne (Get-Command $cmd -ErrorAction SilentlyContinue)
}

function Install-ChocoPackage {
    param([string]$pkg)
    Info "Устанавливаем $pkg через Chocolatey..."
    choco install $pkg -y --no-progress
}

# --- Chocolatey ---
if (-not (Test-Command choco)) {
    Info "Устанавливаем Chocolatey..."
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
    refreshenv
}

if ($DryRun) {
    Info "DRY RUN: будет установлено на Windows:"
    Write-Host "  - git, curl, unzip, wget, xz"
    Write-Host "  - Visual Studio Build Tools / Community (с workload для C++)"
    Write-Host "  - OpenJDK 21"
    Write-Host "  - Android SDK / Android Studio"
    Write-Host "  - Flutter SDK"
    Write-Host "  - Google Chrome"
    Write-Host "  - Node.js LTS"
    Write-Host "  - Firebase CLI + FlutterFire CLI"
    exit 0
}

# --- Базовые пакеты ---
$pkgs = @("git", "curl", "unzip", "wget", "xz", "nodejs", "openjdk", "googlechrome")
foreach ($p in $pkgs) {
    Install-ChocoPackage $p
}

# --- Visual Studio Build Tools (C++ workload) ---
if (-not (Test-Command cl)) {
    Info "Устанавливаем Visual Studio Build Tools с C++ workload..."
    choco install visualstudio2022buildtools -y --no-progress
    choco install visualstudio2022-workload-vctools -y --no-progress
} else {
    Ok "Visual Studio C++ toolchain уже установлен."
}

# --- Android SDK / Android Studio ---
if (-not (Test-Command sdkmanager)) {
    Install-ChocoPackage androidstudio
} else {
    Ok "Android SDK уже настроен."
}

# --- Flutter SDK ---
if (-not (Test-Command flutter)) {
    Install-ChocoPackage flutter
} else {
    Ok "flutter уже установлен: $(flutter --version 2>&1 | Select-Object -First 1)"
}

# --- Firebase CLI ---
if (-not (Test-Command firebase)) {
    Info "Устанавливаем Firebase CLI..."
    npm install -g firebase-tools
} else {
    Ok "firebase cli уже установлен: $(firebase --version 2>&1 | Select-Object -First 1)"
}

# --- FlutterFire CLI ---
if (-not (Test-Command flutterfire)) {
    Info "Устанавливаем FlutterFire CLI..."
    dart pub global activate flutterfire_cli
} else {
    Ok "flutterfire cli уже установлен: $(flutterfire --version 2>&1 | Select-Object -First 1)"
}

Info "Запускаем flutter doctor..."
flutter doctor

Ok "Установка хостового тулинга завершена."
