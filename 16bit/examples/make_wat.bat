@ECHO OFF
ECHO --- Building BriefLZ 16-bit Watcom C/C++ example ---
ECHO.

wcl -0 -s -d0 -ot -fpc -bt=dos -mc -i=..\include %1 %2 %3 %4 blzpack.c /"library ..\lib\brieflz"
