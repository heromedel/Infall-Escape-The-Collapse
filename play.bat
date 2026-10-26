@echo off
rem Infall: Escape The Collapse. Launches the built game. Builds first if there is no build yet.
setlocal
cd /d "%~dp0"

if not exist build\main.js (
    echo No build yet. Building first...
    call build.bat
    if not exist build\main.js exit /b 1
)

call npm run play
if errorlevel 1 (
    echo.
    echo The game did not start. Send the text above to the coding session.
    pause
    exit /b 1
)
endlocal
