@echo off
title Random Inputs Bruteforce
: save variable path (change to match your own)
set path="%USERPROFILE%\Downloads\mario\v2\lua\tasbots\InputBruteforce"

set /p count="How many instances? "

: write to instanceCount.txt "0,%count%"
echo 0,%count% > "%path%\instanceCount.txt"

: also change the .exe to match your own mupen64's version (1.1.9 recommended)
cd "%USERPROFILE%\Downloads\mario\v2"
for /L %%i in (1,1,%count%) do (
    start "" "mupen64-119-msvc-avx2.exe" --rom "%USERPROFILE%\Downloads\mario\roms\Super Mario 64 (USA).z64" --lua "%path%\main.lua"
    timeout /t 1 >nul
)
echo Done.
exit