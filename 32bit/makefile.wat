##
## blzpack  -  BriefLZ example
##
## Watcom / OpenWatcom C/C++ makefile (GNU Make)
##
## Copyright (c) 2002-2004 by Joergen Ibsen / Jibz
## All Rights Reserved
##
## http://www.ibsensoftware.com/
##

target  = blzpack.exe
objects = blzpack.obj brieflz.obj depack.obj crc32.obj
system  = nt

cflags  = -bt=$(system) -d0 -ox
ldflags = system $(system)

.PHONY: all clean

all: $(target)

$(target): $(objects)
	wlink $(ldflags) name $@ file {$^}

%.obj : %.c
	wcc386 $(cflags) $<

%.obj : %.nas
	nasm -o $@ -f obj -D_OBJ_ -O3 $<

clean:
	$(RM) $(objects) $(target)
