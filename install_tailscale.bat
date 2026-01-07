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

if "%MODE%"=="" (
    echo Mode missing
    exit /b 1
)

echo Downloading Tailscale...
powershell -Command "Invoke-WebRequest -Uri '%TS_URL%' -OutFile '%INSTALLER%'" || exit /b 1

:: ================= MODE DISPATCH =================

if /i "%MODE%"=="user"  goto USER_ONLY
if /i "%MODE%"=="admin" goto ADMIN_ONLY
if /i "%MODE%"=="auto"  goto AUTO_MODE

echo Invalid mode
exit /b 1

:: ================= AUTO MODE =================

:AUTO_MODE
echo Auto mode: attempting admin install first...

call :ADMIN_INSTALL
if %ERRORLEVEL%==0 exit /b 0

echo Admin install failed or declined, falling back to user install...
call :USER_INSTALL
exit /b %ERRORLEVEL%

:: ================= ADMIN ONLY =================

:ADMIN_ONLY
echo Admin-only mode selected.
call :ADMIN_INSTALL
exit /b %ERRORLEVEL%

:: ================= USER ONLY =================

:USER_ONLY
echo User-only mode selected.
call :USER_INSTALL
exit /b %ERRORLEVEL%

:: ================= INSTALL FUNCTIONS =================

:ADMIN_INSTALL
echo Requesting elevation...

powershell -Command ^
  "Start-Process '%INSTALLER%' -ArgumentList '/quiet /norestart ALLUSERS=1' -Verb RunAs" || exit /b 1

timeout /t 5 >nul

if exist "C:\Program Files\Tailscale\tailscale.exe" (
    echo Admin install successful
    "C:\Program Files\Tailscale\tailscale.exe" up --authkey=%AUTHKEY% --unattended
    exit /b 0
)

exit /b 1

:USER_INSTALL
echo Installing in user mode (no admin)...

"%INSTALLER%" /quiet /norestart ALLUSERS=0

timeout /t 5 >nul

set TS_USER=%LOCALAPPDATA%\Tailscale\tailscale.exe

if exist "%TS_USER%" (
    echo User install successful
    "%TS_USER%" up --authkey=%AUTHKEY% --unattended --user
    exit /b 0
)

exit /b 1
