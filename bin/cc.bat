@echo off
setlocal

set "PROFILES_DIR=%USERPROFILE%\.claude-profiles"
set "ARG1=%~1"

if "%ARG1%"=="-1" goto account1
if "%ARG1%"=="1" goto account1
if "%ARG1%"=="-2" goto account2
if "%ARG1%"=="2" goto account2

goto picker

:account1
shift
endlocal
set "CLAUDE_CONFIG_DIR="
claude %1 %2 %3 %4 %5 %6 %7 %8 %9
goto :eof

:account2
shift
endlocal
set "CLAUDE_CONFIG_DIR=%USERPROFILE%\.claude-profiles\account2"
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
