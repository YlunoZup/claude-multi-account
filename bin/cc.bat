@echo off
setlocal enabledelayedexpansion

set "PROFILES_DIR=%USERPROFILE%\.claude-profiles"
set "CONFIG=%PROFILES_DIR%\config.json"
set "ARG1=%~1"

:: Check if first arg is a number (account quick-switch)
echo %ARG1%| findstr /r "^-*[0-9][0-9]*$" >nul 2>nul
if %ERRORLEVEL% equ 0 goto quickswitch
goto picker

:quickswitch
:: Strip leading dash if present
set "ACCT=%ARG1:-=%"
shift

if "%ACCT%"=="1" (
    endlocal
    set "CLAUDE_CONFIG_DIR="
    claude %1 %2 %3 %4 %5 %6 %7 %8 %9
    goto :eof
)

:: Look up configDir from config.json
for /f "delims=" %%d in ('node -e "try{var c=JSON.parse(require('fs').readFileSync('%CONFIG:\=/%','utf8'));var a=c.accounts['%ACCT%'];if(a&&a.configDir)process.stdout.write(a.configDir);else if(a)process.stdout.write('__DEFAULT__')}catch{}" 2^>nul') do set "CFGDIR=%%d"

if "%CFGDIR%"=="__DEFAULT__" (
    endlocal
    set "CLAUDE_CONFIG_DIR="
    claude %1 %2 %3 %4 %5 %6 %7 %8 %9
    goto :eof
)

if not "%CFGDIR%"=="" (
    endlocal
    set "CLAUDE_CONFIG_DIR=%USERPROFILE%\.claude-profiles\%CFGDIR%"
    claude %1 %2 %3 %4 %5 %6 %7 %8 %9
    goto :eof
)

:: Fallback: assume accountN directory
endlocal
set "CLAUDE_CONFIG_DIR=%USERPROFILE%\.claude-profiles\account%ACCT%"
claude %1 %2 %3 %4 %5 %6 %7 %8 %9
goto :eof

:picker
for /f "delims=" %%i in ('node "%PROFILES_DIR%\picker.mjs"') do set "PROFILE_PATH=%%i"
if "%PROFILE_PATH%"=="" goto :eof
if "%PROFILE_PATH%"=="__DEFAULT__" (
    endlocal
    set "CLAUDE_CONFIG_DIR="
) else (
    endlocal
    set "CLAUDE_CONFIG_DIR=%PROFILE_PATH%"
)
claude %*
