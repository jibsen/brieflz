@ECHO OFF
ECHO --- Building BriefLZ 16-bit library ---
ECHO.

if exist brieflz.lib del brieflz.lib >nul
if exist brieflz.obj del brieflz.obj >nul
if exist crc32.obj   del crc32.obj   >nul
if exist depack.obj  del depack.obj  >nul

nasm -o brieflz.obj -f obj -O3 ..\src\brieflz.nas
if errorlevel 1 goto end

nasm -o crc32.obj -f obj -O3 ..\src\crc32.nas
if errorlevel 1 goto end

nasm -o depack.obj -f obj -O3 ..\src\depack.nas
if errorlevel 1 goto end

wlib -c -n -q -s -fo -io brieflz.lib +brieflz.obj +crc32.obj +depack.obj
if errorlevel 1 goto end

ECHO Done.

:end
