@ECHO OFF
ECHO --- Building BriefLZ Visual C/C++ example ---
ECHO.

cl /nologo /W3 /O2 /I..\include %1 %2 %3 %4 blzpack.c ..\lib\mscoff\brieflz.lib
