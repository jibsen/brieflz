@ECHO OFF
ECHO --- Building BriefLZ .NET dll wrapper ---
ECHO.

csc /nologo /w:3 /t:library /debug- /o+ /out:IbsenSoftware.BriefLZ.dll IbsenSoftware\BriefLZ\*.cs
