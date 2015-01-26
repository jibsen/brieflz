@ECHO OFF
ECHO --- Building BriefLZ 16-bit Borland C/C++ example ---
ECHO.

bcc -O1 -Z -N- -mc -I..\include %1 %2 %3 %4 blzpack.c ..\lib\brieflz.lib
