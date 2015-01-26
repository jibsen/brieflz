##
## BriefLZ  -  small fast Lempel-Ziv
##
## DJGPP makefile (GNU Make)
##
## Copyright (c) 2002-2015 by Joergen Ibsen / Jibz
## All Rights Reserved
##
## http://www.ibsensoftware.com/
##

## --- paths ------------------------------------------------------

srcdir   = ..\..\src\fast


## --- files ------------------------------------------------------

target   = brieflz.a
objects  = brieflz.o crc32.o depack.o


## --- flags ------------------------------------------------------


## --- rules -------------------------------------------------------

.PHONY: all clean

all: $(target)

$(target): $(objects)
	$(RM) $@
	ar -frsv $@ $^
	ranlib $@

%.o : $(srcdir)\%.nas
	nasm -o $@ -f coff -O3 -i$(srcdir)/ $<
	strip -x -g $@

%.o : $(srcdir)\%.c
	gcc -s -Wall -O2 -I..\..\include -c $<
	strip -x -g $@

clean:
	$(RM) $(target) $(objects)


## --- dependencies -----------------------------------------------
