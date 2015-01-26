##
## BriefLZ  -  small fast Lempel-Ziv
##
## Watcom C/C++ OMF makefile (GNU Make)
##
## Copyright (c) 2002-2015 by Joergen Ibsen / Jibz
## All Rights Reserved
##
## http://www.ibsensoftware.com/
##

## --- paths ------------------------------------------------------

srcdir   = ..\..\src\fast


## --- files ------------------------------------------------------

target   = brieflz.lib
objects  = brieflz.obj crc32.obj depack.obj


## --- flags ------------------------------------------------------


## --- rules -------------------------------------------------------

.PHONY: all clean

all: $(target)

$(target): $(objects)
	$(RM) $@
	wlib -c -n -q -s -fo -io $@ $(patsubst %,+%,$(objects))

%.obj : $(srcdir)\%.nas
	nasm -o $@ -f obj -DLCM_OBJ -O3 -i$(srcdir)/ $<

%.obj : $(srcdir)\%.c
	wcc386 -d0 -ot -i=..\..\include $<

clean:
	$(RM) $(target) $(objects)


## --- dependencies -----------------------------------------------
