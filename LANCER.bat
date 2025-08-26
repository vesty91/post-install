@echo off
title DevSoftInstaller
echo ========================================
echo    DevSoftInstaller - Lanceur Unique
echo ========================================
echo.

REM Détecter PowerShell Core ou classique
where pwsh >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] PowerShell Core detecte
    pwsh -ExecutionPolicy Bypass -File "DevSoftInstaller-GUI.ps1"
) else (
    echo [INFO] PowerShell classique utilise
    powershell -ExecutionPolicy Bypass -File "DevSoftInstaller-GUI.ps1"
)

echo.
echo Interface fermee.
pause
