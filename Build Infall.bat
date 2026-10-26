@echo off
setlocal
cd /d "%~dp0"
rem the folder, kept for the subroutines (inside a CALLed label, %0 is the label)
set "HERE=%~dp0"
title Infall: Escape The Collapse - Build
rem Builds Infall from the source in this folder into build\. "Play Infall.bat" launches the result.
rem First run installs Node.js if it is missing (with winget) and the game's packages (npm install, which
rem downloads Electron once, a few hundred MB); later builds take seconds.

set "BUILT="

rem the version about to be built (and its branch), shown before anything is chosen
call :plans

rem "build": build only, no menu and no launch, for scripts; the exit code says whether it was built
if /i "%~1"=="build" goto :buildonly

:menu
cls
echo ==========================================================
echo    INFALL: ESCAPE THE COLLAPSE
echo    Build
if defined PLANS echo    Building: %PLANS%
echo ==========================================================
echo.
echo    0: Exit
echo    1: Build Infall
echo    2: Build Infall with a desktop shortcut
echo       (adds a shortcut to Play Infall on your desktop)
echo    3: Build Infall and play
echo       (launches the game once it is built)
echo.
choice /c 0123 /n /m "   Input -> "
if errorlevel 4 goto :buildlaunch
if errorlevel 3 ( call :construct && call :quicklink & goto :after )
if errorlevel 2 ( call :construct & goto :after )
exit /b 0

:buildlaunch
call :construct
if defined BUILT ( call :launch & exit /b 0 )
goto :after

:after
echo.
if not defined BUILT ( pause & exit /b 0 )
echo    0: Exit
echo    1: Play Infall
echo.
choice /c 01 /n /m "   Input -> "
if errorlevel 2 call :launch
exit /b 0

rem ---- :buildonly: a build and nothing else ----
:buildonly
call :construct
if defined BUILT exit /b 0
exit /b 1

rem ---- :launch: opens the game ----
rem through cmd /c, so this window closes once the game is up (a batch file started on its own leaves a prompt open)
:launch
start "Infall: Escape The Collapse" /d "%HERE%" cmd /c call "%HERE%Play Infall.bat"
exit /b 0

rem ---- :plans: the version in package.json, and the branch the files come from (when this folder is a git clone) ----
:plans
set "PLANS="
for /f "tokens=2 delims=:, " %%v in ('findstr /c:"\"version\"" package.json 2^>nul') do ( set "PLANS=%%~v" & goto :planbranch )
:planbranch
if not defined PLANS exit /b 0
set "HEADREF="
if exist ".git\HEAD" set /p HEADREF=<".git\HEAD"
if not defined HEADREF exit /b 0
if "%HEADREF:~0,16%"=="ref: refs/heads/" set "PLANS=%PLANS% (%HEADREF:~16%)"
exit /b 0

rem ---- :construct: Node.js and the packages if missing, then the build ----
:construct
echo.
where node >nul 2>nul
if errorlevel 1 call :node || exit /b 1
if not exist node_modules call :packages || exit /b 1

echo Building Infall...
call npm run build
if errorlevel 1 (
    echo.
    echo The build failed: see the messages above. Send them to the coding session.
    exit /b 1
)
echo.
echo Infall built and ready in build\.
if defined PLANS echo Version: %PLANS%
echo To play, run "Play Infall.bat".
set "BUILT=1"
exit /b 0

rem ---- :node: installs Node.js with winget; Windows needs a new window to see it afterwards ----
:node
echo ==========================================================
echo  Node.js is not installed. Installing it with winget ...
echo ==========================================================
winget install --id OpenJS.NodeJS.LTS --exact --accept-source-agreements --accept-package-agreements
if errorlevel 1 (
    echo.
    echo Node.js could not be installed automatically. Install it from https://nodejs.org and run this again.
    exit /b 1
)
echo.
echo Node.js is installed. Close this window, open "Build Infall.bat" again, and the build will carry on.
echo (A new window is needed so Windows picks up the new program.)
pause
exit /b 1

rem ---- :packages: the first build gathers the game's packages, Electron among them ----
:packages
echo ==========================================================
echo  FIRST BUILD: this one takes a while.
echo.
echo  The game's packages are being downloaded into node_modules\
echo  (Electron among them, a few hundred MB). They're kept there,
echo  so every build after this one takes seconds.
echo.
echo  Leave this window open until it says Infall is built.
echo ==========================================================
echo.
call npm install --no-audit --no-fund
if errorlevel 1 (
    echo.
    echo The packages could not be installed: see the messages above. Check the connection and run this again.
    exit /b 1
)
exit /b 0

rem ---- :quicklink: a desktop shortcut to Play Infall ----
rem No icon yet: the shortcut keeps the default until the game has one.
:quicklink
echo.
echo Adding a shortcut to Play Infall on your desktop ...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$s = (New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Desktop') + '\Infall.lnk');" ^
  "$s.TargetPath = '%HERE%Play Infall.bat'; $s.WorkingDirectory = '%HERE%';" ^
  "$s.Description = 'Infall: Escape The Collapse'; $s.Save()"
if errorlevel 1 ( echo The shortcut could not be made: see the message above. The game itself is built. & exit /b 1 )
echo Shortcut ready: "Infall" on your desktop.
exit /b 0
