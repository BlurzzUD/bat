@echo off
setlocal ENABLEDELAYEDEXPANSION

:: ================= CONFIG =================
set TS_URL=https://pkgs.tailscale.com/stable/tailscale-setup-latest.exe
set INSTALLER=%TEMP%\tailscale-setup.exe
set AUTHKEY=%1
set MODE=%2
:: MODE = auto | admin | user
:: =========================================

if "%AUTHKEY%"=="" (
    echo Auth key missing
    exit /b 1
)

echo Downloading Tailscale...
powershell -Command "Invoke-WebRequest -Uri '%TS_URL%' -OutFile '%INSTALLER%'" || exit /b 1

:: ---------- ADMIN INSTALL ----------
if "%MODE%"=="admin" goto ADMIN
if "%MODE%"=="auto" goto ADMIN
if "%MODE%"=="user" goto USER

:ADMIN
echo Attempting admin install...

powershell -Command ^
    "Start-Process '%INSTALLER%' -ArgumentList '/quiet /norestart ALLUSERS=1' -Verb RunAs" || goto USER

timeout /t 5 >nul

if exist "C:\Program Files\Tailscale\tailscale.exe" (
    echo Admin install succeeded
    "C:\Program Files\Tailscale\tailscale.exe" up --authkey=%AUTHKEY% --unattended
    exit /b 0
)

if "%MODE%"=="admin" exit /b 1

:: ---------- USER INSTALL ----------
:USER
echo Attempting user-mode install...

"%INSTALLER%" /quiet /norestart ALLUSERS=0

timeout /t 5 >nul

set TS_USER=%LOCALAPPDATA%\Tailscale\tailscale.exe

if exist "%TS_USER%" (
    echo User-mode install succeeded
    "%TS_USER%" up --authkey=%AUTHKEY% --unattended --user
    exit /b 0
)

echo Installation failed
exit /b 1
