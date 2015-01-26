##
## BriefLZ  -  small fast Lempel-Ziv
##
## Visual C/C++ MS COFF makefile (GNU Make)
##
## Copyright (c) 2002-2005 by Joergen Ibsen / Jibz
## All Rights Reserved
##
## http://www.ibsensoftware.com/
##

## --- paths ------------------------------------------------------

srcdir   = ..\..\src\small


## --- files ------------------------------------------------------

target   = brieflz.lib
objects  = brieflz.obj crc32.obj depack.obj


## --- flags ------------------------------------------------------


## --- rules -------------------------------------------------------

.PHONY: all clean

all: $(target)

$(target): $(objects)
	$(RM) $@
	ar -frsv $@ $^
#	ranlib $@

%.obj : $(srcdir)\%.nas
	nasm -o $@ -f win32 -O3 -i$(srcdir)/ $<
	strip -x -g $@

%.obj : $(srcdir)\%.c
	cl /nologo /W3 /O2 /Zl /c /I..\..\include $<
	strip -x -g $@

clean:
	$(RM) $(target) $(objects)


## --- dependencies -----------------------------------------------
