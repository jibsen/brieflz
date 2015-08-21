##
## BriefLZ - small fast Lempel-Ziv
##
## DJGPP makefile (GNU Make)
##
## Copyright (c) 2002-2015 Joergen Ibsen
##
## This software is provided 'as-is', without any express or implied
## warranty. In no event will the authors be held liable for any damages
## arising from the use of this software.
##
## Permission is granted to anyone to use this software for any purpose,
## including commercial applications, and to alter it and redistribute it
## freely, subject to the following restrictions:
##
##   1. The origin of this software must not be misrepresented; you must
##      not claim that you wrote the original software. If you use this
##      software in a product, an acknowledgment in the product
##      documentation would be appreciated but is not required.
##
##   2. Altered source versions must be plainly marked as such, and must
##      not be misrepresented as being the original software.
##
##   3. This notice may not be removed or altered from any source
##      distribution.
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
