##
## BriefLZ - small fast Lempel-Ziv
##
## Visual C/C++ MS COFF makefile (GNU Make)
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

srcdir   = ..\..\src\small


## --- files ------------------------------------------------------

target   = brieflz.lib
objects  = brieflz.obj depack.obj


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
