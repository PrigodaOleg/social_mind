
@echo off
REM Удобный launcher для Windows:
REM   setup_host.bat [dry-run]
REM Пример:
REM   setup_host.bat
REM   setup_host.bat dry-run
powershell -ExecutionPolicy Bypass -File "%~dp0setup_host.ps1" %*
