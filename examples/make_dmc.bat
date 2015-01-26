@ECHO OFF
ECHO --- Building BriefLZ Digital Mars C/C++ example ---
ECHO.

dmc -mn -o+all -I..\include %1 %2 %3 %4 blzpack.c ..\lib\omf\brieflz.lib
