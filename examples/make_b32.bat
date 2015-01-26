@ECHO OFF
ECHO --- Building BriefLZ Borland C/C++ example ---
ECHO.

bcc32 -a16 -O2 -OS -I..\include %1 %2 %3 %4 blzpack.c ..\lib\omf\brieflz.lib
