@echo off
setlocal
cd /d "%~dp0"
title Infall: Escape The Collapse
rem Launches the built game. It never builds on its own: run "Build Infall.bat" after the code changes.
rem Uses the Node.js the build put in tools\, if there is one; otherwise the computer's own.
if exist "%~dp0tools\node\node.exe" set "PATH=%~dp0tools\node;%PATH%"

if not exist build\main.js (
    echo Infall has not been built yet. Run "Build Infall.bat" first.
    pause
    exit /b 1
)
if not exist node_modules (
    echo The game's packages are missing. Run "Build Infall.bat" first.
    pause
    exit /b 1
)

call npm run play
if errorlevel 1 (
    echo.
    echo The game did not start: see the messages above. Send them to the coding session.
    pause
    exit /b 1
)
exit /b 0
