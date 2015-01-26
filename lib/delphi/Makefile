##
## BriefLZ  -  small fast Lempel-Ziv
##
## Delphi makefile (GNU Make)
##
## Copyright (c) 2002-2015 by Joergen Ibsen / Jibz
## All Rights Reserved
##
## http://www.ibsensoftware.com/
##

## --- paths ------------------------------------------------------

srcdir   = ..\..\src\fast


## --- files ------------------------------------------------------

targets  = brieflz.obj crc32.obj depack.obj


## --- flags ------------------------------------------------------


## --- rules -------------------------------------------------------

.PHONY: all clean

all: $(targets)

%.obj : $(srcdir)\%.nas
	nasm -o $@ -f obj -DLCM_OBJ -O3 -i$(srcdir)/ $<

%.obj : $(srcdir)\%.c
	wcc386 -d0 -ot -i=..\..\include $<

clean:
	$(RM) $(targets)


## --- dependencies -----------------------------------------------
