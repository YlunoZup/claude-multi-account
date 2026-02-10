@echo off
setlocal enabledelayedexpansion

:: claude-multi-account installer for Windows CMD

echo.
echo   claude-multi-account installer
echo   --------------------------------
echo.

:: ── Check prerequisites ─────────────────────────────────────
where node >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo   [ERR] Node.js is required but not found. Install from https://nodejs.org
    exit /b 1
)
for /f "tokens=*" %%v in ('node --version') do echo   [ OK] Node.js found: %%v

where claude >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo   [WARN] Claude Code CLI not found in PATH. Make sure it's installed.
) else (
    echo   [ OK] Claude Code CLI found
)

:: ── Set paths ───────────────────────────────────────────────
set "PROFILES_DIR=%USERPROFILE%\.claude-profiles"
set "ACCOUNT2_DIR=%PROFILES_DIR%\account2"
set "CLAUDE_DIR=%USERPROFILE%\.claude"
set "SCRIPT_DIR=%~dp0"

:: ── Create directories ──────────────────────────────────────
echo.
echo   [INFO] Creating profile directories...
if not exist "%PROFILES_DIR%" mkdir "%PROFILES_DIR%"
if not exist "%ACCOUNT2_DIR%" mkdir "%ACCOUNT2_DIR%"
echo   [ OK] Created %PROFILES_DIR%
echo   [ OK] Created %ACCOUNT2_DIR%

:: ── Copy picker.mjs ─────────────────────────────────────────
echo   [INFO] Installing picker...
copy /Y "%SCRIPT_DIR%src\picker.mjs" "%PROFILES_DIR%\picker.mjs" >nul
echo   [ OK] Installed picker.mjs

:: ── Copy config (if not exists) ─────────────────────────────
if not exist "%PROFILES_DIR%\config.json" (
    copy /Y "%SCRIPT_DIR%config.example.json" "%PROFILES_DIR%\config.json" >nul
    echo   [ OK] Created config.json from template
) else (
    echo   [ OK] config.json already exists, skipping
)

:: ── Set up shared data (junctions from account2 -> .claude) ─
echo   [INFO] Setting up shared data for Account 2...

:: Share directories via junctions
for %%d in (projects todos statsig .statsig) do (
    if exist "%CLAUDE_DIR%\%%d" (
        if not exist "%ACCOUNT2_DIR%\%%d" (
            mklink /J "%ACCOUNT2_DIR%\%%d" "%CLAUDE_DIR%\%%d" >nul 2>nul
            if !ERRORLEVEL! equ 0 (
                echo   [ OK] Junction: %%d
            ) else (
                echo   [WARN] Could not create junction for %%d
            )
        )
    )
)

:: Share files via copy (hard links require admin on some Windows versions)
for %%f in (settings.json) do (
    if exist "%CLAUDE_DIR%\%%f" (
        if not exist "%ACCOUNT2_DIR%\%%f" (
            mklink /H "%ACCOUNT2_DIR%\%%f" "%CLAUDE_DIR%\%%f" >nul 2>nul
            if !ERRORLEVEL! equ 0 (
                echo   [ OK] Linked: %%f
            ) else (
                copy /Y "%CLAUDE_DIR%\%%f" "%ACCOUNT2_DIR%\%%f" >nul
                echo   [ OK] Copied: %%f ^(hard link not available^)
            )
        )
    )
)

:: ── Install launcher script ─────────────────────────────────
echo   [INFO] Installing launcher script...

set "BIN_DIR=%USERPROFILE%\.local\bin"
if not "%~1"=="" set "BIN_DIR=%~1"

if not exist "%BIN_DIR%" mkdir "%BIN_DIR%"

copy /Y "%SCRIPT_DIR%bin\cc.bat" "%BIN_DIR%\cc.bat" >nul
echo   [ OK] Installed cc.bat -^> %BIN_DIR%\cc.bat

copy /Y "%SCRIPT_DIR%bin\cc" "%BIN_DIR%\cc" >nul
echo   [ OK] Installed cc -^> %BIN_DIR%\cc

:: ── Check PATH ──────────────────────────────────────────────
echo %PATH% | findstr /I /C:"%BIN_DIR%" >nul
if %ERRORLEVEL% neq 0 (
    echo.
    echo   [WARN] %BIN_DIR% is not in your PATH.
    echo.
    echo   Add it via System Settings ^> Environment Variables,
    echo   or run:
    echo.
    echo     setx PATH "%%PATH%%;%BIN_DIR%"
    echo.
)

:: ── Done ────────────────────────────────────────────────────
echo.
echo   Installation complete!
echo.
echo   Usage:
echo     cc          Open account picker
echo     cc 1        Launch with Account 1 (default)
echo     cc 2        Launch with Account 2
echo     cc 2 -c     Launch Account 2 in continue mode
echo.
echo   First-time setup for Account 2:
echo     Run "cc 2" and log in when prompted.
echo.

endlocal
