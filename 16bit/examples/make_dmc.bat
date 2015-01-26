@ECHO OFF
ECHO --- Building BriefLZ 16-bit Digital Mars C/C++ example ---
ECHO.

dmc -0 -mc -o+all -I..\include %1 %2 %3 %4 blzpack.c ..\lib\brieflz.lib
