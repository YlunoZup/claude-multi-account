@echo off
setlocal enabledelayedexpansion

set "PROFILES_DIR=%USERPROFILE%\.claude-profiles"
set "CONFIG=%PROFILES_DIR%\config.json"
set "ARG1=%~1"

:: ── cc add [name] — add a new account ──────────────────────
if /i "%ARG1%"=="add" (
    shift
    set "CUSTOM_NAME=%~2 %~3 %~4 %~5"
    :: Trim trailing spaces
    for /f "tokens=*" %%a in ("!CUSTOM_NAME!") do set "CUSTOM_NAME=%%a"

    :: Find next account number
    for /f "delims=" %%n in ('node -e "var fs=require('fs');var c={accounts:{}};try{c=JSON.parse(fs.readFileSync('%CONFIG:\=/%','utf8'))}catch(e){}var k=Object.keys(c.accounts).map(Number).filter(function(n){return !isNaN(n)});console.log(Math.max.apply(null,k.concat([0]))+1)" 2^>nul') do set "NEXT=%%n"

    if not defined NEXT (
        echo   Error: could not determine next account number.
        exit /b 1
    )

    set "DIR_NAME=account!NEXT!"
    set "ACCT_DIR=%PROFILES_DIR%\!DIR_NAME!"

    :: Prompt for name if not provided
    if "!CUSTOM_NAME!"=="" (
        set /p "CUSTOM_NAME=  Account name [Account !NEXT!]: "
        if "!CUSTOM_NAME!"=="" set "CUSTOM_NAME=Account !NEXT!"
    )

    :: Create directory
    if not exist "!ACCT_DIR!" mkdir "!ACCT_DIR!"

    :: Add to config.json
    node -e "var fs=require('fs');var c={accounts:{}};try{c=JSON.parse(fs.readFileSync('%CONFIG:\=/%','utf8'))}catch(e){}c.accounts['!NEXT!']={name:'!CUSTOM_NAME!',configDir:'!DIR_NAME!'};fs.writeFileSync('%CONFIG:\=/%',JSON.stringify(c,null,2)+'\n')" 2>nul

    :: Create settings.json with statusline
    node -e "var fs=require('fs'),h=require('os').homedir().replace(/\\/g,'/');var s={statusLine:{type:'command',command:'node '+h+'/.claude-profiles/statusline.js'}};fs.writeFileSync('!ACCT_DIR:\=/!/settings.json',JSON.stringify(s,null,2)+'\n')" 2>nul

    echo.
    echo   Account !NEXT! added!
    echo.
    echo   Name:      !CUSTOM_NAME!
    echo   Directory:  !ACCT_DIR!
    echo.
    echo   Run "cc !NEXT!" to log in and start using it.
    echo.
    exit /b 0
)

:: ── cc ^<number^> — quick-switch ─────────────────────────────
echo %ARG1%| findstr /r "^-*[0-9][0-9]*$" >nul 2>nul
if %ERRORLEVEL% equ 0 goto quickswitch
goto picker

:quickswitch
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
