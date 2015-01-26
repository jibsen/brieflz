@ECHO OFF
ECHO --- Building BriefLZ Watcom C/C++ example ---
ECHO.

wcl386 -d0 -ot -i=..\include %1 %2 %3 %4 blzpack.c /"library ..\lib\omf\brieflz"
