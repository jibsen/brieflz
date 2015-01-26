@ECHO OFF
ECHO --- Building BriefLZ MinGW example ---
ECHO.

gcc -s -Wall -O2 -I../include %1 %2 %3 %4 blzpack.c ../lib/vc/brieflz.lib -o blzpack.exe
