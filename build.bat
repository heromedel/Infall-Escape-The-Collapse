@echo off
rem Infall: Escape The Collapse. Installs what the game needs, if anything, then builds it.
rem Run this after the code changes. play.bat launches the result.
setlocal
cd /d "%~dp0"

where node >nul 2>nul
if errorlevel 1 (
    echo Node.js is not installed. Installing it with winget...
    winget install --id OpenJS.NodeJS.LTS --exact --accept-source-agreements --accept-package-agreements
    if errorlevel 1 (
        echo.
        echo Could not install Node.js automatically. Install it from https://nodejs.org and run this again.
        pause
        exit /b 1
    )
    echo.
    echo Node.js installed. Close this window, open a new one, and run build.bat again so the PATH is picked up.
    pause
    exit /b 0
)

if not exist node_modules (
    echo First run: installing the game's packages. This downloads Electron once, a few hundred MB.
    call npm install --no-audit --no-fund
    if errorlevel 1 (
        echo.
        echo npm install failed. Send the text above to the coding session.
        pause
        exit /b 1
    )
)

echo Building Infall...
call npm run build
if errorlevel 1 (
    echo.
    echo The build failed. Send the text above to the coding session.
    pause
    exit /b 1
)
echo Build done. Run play.bat to launch the game.
endlocal
