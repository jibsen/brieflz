@ECHO OFF
ECHO --- Building BriefLZ DJGPP example ---
ECHO.

gcc -s -Wall -O2 -I../include %1 %2 %3 %4 blzpack.c ../lib/djgpp/brieflz.a -o blzpack.exe
