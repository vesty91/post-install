@echo off
title DevSoftInstaller - Mode Silencieux
echo ========================================
echo    DevSoftInstaller - Mode Silencieux
echo ========================================
echo.
echo Telechargement automatique des packages...
echo.

REM Détecter PowerShell Core ou classique
where pwsh >nul 2>&1
if %errorlevel% equ 0 (
    echo [INFO] PowerShell Core detecte
    pwsh -ExecutionPolicy Bypass -File "DevSoftInstaller-GUI.ps1" -Quiet
) else (
    echo [INFO] PowerShell classique utilise
    powershell -ExecutionPolicy Bypass -File "DevSoftInstaller-GUI.ps1" -Quiet
)

echo.
echo Telechargements termines !
pause
