##
## BriefLZ  -  small fast Lempel-Ziv
##
## Visual C/C++ dll makefile (GNU Make)
##
## Copyright (c) 2002-2005 by Joergen Ibsen / Jibz
## All Rights Reserved
##
## http://www.ibsensoftware.com/
##

## --- paths ------------------------------------------------------

srcdir   = ..\..\src\fast


## --- files ------------------------------------------------------

target   = brieflz.dll
objects  = brieflz.obj crc32.obj depack.obj

temps    = brieflz.lib brieflz.exp


## --- flags ------------------------------------------------------


## --- rules -------------------------------------------------------

.PHONY: all clean

all: $(target)

$(target): $(objects)
	$(RM) $@
	link /dll /nodefaultlib /noentry /def:brieflz.def /filealign:512 /out:$@ $^

%.obj : $(srcdir)\%.nas
	nasm -o $@ -f obj -DLCM_OBJ -DLCM_DLL -O3 -i$(srcdir)/ $<

%.obj : $(srcdir)\%.c
	cl /nologo /W3 /O2 /Zl /c /DBLZ_DLL_BUILD /I. $<

clean:
	$(RM) $(target) $(objects) $(temps)


## --- dependencies -----------------------------------------------
